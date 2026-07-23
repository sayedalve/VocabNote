"""Quiz feature UI: setup, active quiz, results, and history sections.

Built lazily by VocabNoteApp.open_quiz() on the first visit so the feature
adds zero startup cost. All AI requests run on daemon background threads
with results marshalled back through app.after(0, ...); every database
read/write stays on the UI thread -- the exact contract the rest of the
application follows.

main.py injects its theme and dialog classes through init_ui(), so this
module never imports main.py (no circular imports, no duplicated theme).
"""

import threading
import time
import tkinter as tk

import customtkinter as ctk

from api.quiz_generator import generate_quiz
from database import quiz_db
from database.db_manager import get_all_volumes
from utils.provider_keys import get_provider_key, get_configured_providers

# Injected by init_ui() from main.py before QuizPage is constructed.
Color = None
Font = None
StyledConfirmDialog = None


def init_ui(color_cls, font_cls, confirm_dialog_cls):
    """Injects main.py's theme and dialog classes (avoids circular imports)."""
    global Color, Font, StyledConfirmDialog
    Color = color_cls
    Font = font_cls
    StyledConfirmDialog = confirm_dialog_cls


GENERATION_WATCHDOG_MS = 90000  # quiz generation is heavier than single-word enrichment
BUILD_CHUNK_SIZE = 5            # question cards created per after() tick (UI stays fluid)
HISTORY_PAGE_SIZE = 50
QUESTION_WRAP = 760

ALL_WORDS_LABEL = "All Words"
CURRENT_VOLUME_LABEL = "Current Volume"
NO_PROVIDERS_LABEL = "No API keys saved"
QUESTION_COUNTS = ["10", "20", "30"]
QUESTION_TYPE_CHOICES = ["Mixed", "Meaning", "Synonym", "Antonym"]

_HEADER_TITLES = {
    "setup": "Quiz",
    "active": "Quiz",
    "results": "Quiz Results",
    "history": "Quiz History",
}

# Section subtitles shown under the header title (pure UI polish).
_HEADER_SUBTITLES = {
    "setup": "Configure a quiz and test your vocabulary",
    "active": "Answer every question, then submit",
    "results": "Here's how you did",
    "history": "All of your past attempts",
}


def _fmt_secs(secs):
    secs = max(0, int(secs or 0))
    return f"{secs // 60:02d}:{secs % 60:02d}"


def _fast_label(parent, text, size, color, bg, weight=None, wrap=0, justify="left"):
    """Plain tk.Label twin of CTkLabel for static text.

    CTkLabels are canvas-backed and expensive to move, which made scrolling
    long results/review lists stutter. Flat native labels look identical on
    solid card/app backgrounds and scroll perfectly smoothly.
    """
    font = Font.base(size, weight) if weight else Font.base(size)
    return tk.Label(parent, text=text, font=font, fg=color, bg=bg,
                    wraplength=wrap, justify=justify, bd=0, highlightthickness=0)


class _CanvasList(tk.Frame):
    """Single-canvas scrolling list -- the main word list's rendering
    technique. Content is drawn as canvas items (zero embedded child
    windows), so scrolling only shifts the viewport and never stutters.

    A renderer callback draws everything and returns the content height;
    it re-runs automatically when the width changes (for text wrapping).
    """

    def __init__(self, master, bg):
        super().__init__(master, bg=bg, bd=0, highlightthickness=0)
        self.canvas = tk.Canvas(self, bg=bg, highlightthickness=0, bd=0)
        self.scrollbar = ctk.CTkScrollbar(self, command=self.canvas.yview)
        self.canvas.configure(yscrollcommand=self.scrollbar.set)
        self.scrollbar.pack(side="right", fill="y")
        self.canvas.pack(side="left", fill="both", expand=True)
        self._renderer = None
        self._last_width = 0
        self._last_height = 0
        self.canvas.bind("<Configure>", self._on_configure)

    def set_renderer(self, renderer):
        self._renderer = renderer
        self.rerender()
        self.canvas.yview_moveto(0)

    def _on_configure(self, _event=None):
        w = self.canvas.winfo_width()
        h = self.canvas.winfo_height()
        if abs(w - self._last_width) > 2 or abs(h - self._last_height) > 2:
            self._last_width = w
            self._last_height = h
            self.rerender()

    def rerender(self):
        """Redraws all content, preserving the scroll position."""
        if self._renderer is None:
            return
        try:
            pos = self.canvas.yview()[0]
        except Exception:
            pos = 0
        self.canvas.delete("all")
        try:
            self.canvas.config(cursor="")
        except Exception:
            pass
        width = self.canvas.winfo_width()
        if width <= 1:
            width = 800
        end_y = max(int(self._renderer(self.canvas, width) or 0), 1)
        viewport = self.canvas.winfo_height()
        if viewport > 1 and end_y <= viewport:
            # Content fits inside the viewport: pin the scrollregion to the
            # viewport height so the canvas cannot be scrolled at all (a bare
            # smaller scrollregion lets Tk shift content downward), and hide
            # the scrollbar since there is nothing to scroll.
            self.canvas.configure(scrollregion=(0, 0, 0, viewport))
            self.canvas.yview_moveto(0)
            if self.scrollbar.winfo_manager():
                self.scrollbar.pack_forget()
        else:
            self.canvas.configure(scrollregion=(0, 0, 0, end_y))
            if not self.scrollbar.winfo_manager():
                self.scrollbar.pack(side="right", fill="y")
                self.canvas.pack_forget()
                self.canvas.pack(side="left", fill="both", expand=True)
            self.canvas.yview_moveto(pos)


class QuizPage(ctk.CTkFrame):
    """The Quiz area with four swappable sections: setup, active quiz,
    results, and history. Sections are swapped with pack/pack_forget so
    navigation is instant, mirroring select_frame's map/forget approach."""

    def __init__(self, master, app):
        super().__init__(master, fg_color=Color.APP_BG, corner_radius=0)
        self.app = app
        self._section = "setup"
        self._results_source = "quiz"

        # Lazily-created feature resources (never touched at app startup).
        quiz_db.init_quiz_tables()

        # Generation / build / clock state.
        self._gen_seq = 0
        self._build_timer = None
        self._clock_timer = None
        self._build_queue = []
        self._quiz_in_progress = False
        self._active = None          # {"questions", "answers", "meta", "start_time"}
        self._option_items = {}      # (question idx, option idx) -> canvas item ids
        self._source_map = {}
        self._history_offset = 0
        self._history_rows = []
        self._history_total = 0
        self._load_more_btn = None
        self._results_detail = None
        self.quiz_list = None
        self.results_list = None
        self.history_list = None

        # ---- Header (matches NotebookPage) ----
        header = tk.Frame(self, bg=Color.APP_BG)
        header.pack(fill="x", padx=45, pady=(30, 18))
        title_box = tk.Frame(header, bg=Color.APP_BG)
        title_box.pack(side="left")
        self.header_title = ctk.CTkLabel(
            title_box, text="Quiz", font=Font.base(28, "bold"),
            text_color=Color.TEXT_PRIMARY
        )
        self.header_title.pack(anchor="w")
        self.header_subtitle = ctk.CTkLabel(
            title_box, text=_HEADER_SUBTITLES["setup"], font=Font.base(13),
            text_color=Color.TEXT_MUTED
        )
        self.header_subtitle.pack(anchor="w", pady=(2, 0))

        # ---- Section container ----
        self.body = ctk.CTkFrame(self, fg_color="transparent")
        self.body.pack(fill="both", expand=True)

        self.setup_frame = self._build_setup_view(self.body)
        self.quiz_frame = None      # built per quiz
        self.results_frame = None   # rebuilt per result set
        self.history_frame = None   # built on first history visit

        self._show_section("setup")

    # ==================================================================
    # SECTION SWITCHING
    # ==================================================================

    @property
    def section(self):
        """Nav-facing section. Viewing a saved attempt opened from Quiz
        History still reports 'history', so the sidebar highlight stays on
        the Quiz History item instead of jumping back to Take Quiz."""
        if self._section == "results" and self._results_source == "history":
            return "history"
        return self._section

    def _show_section(self, name):
        frames = {
            "setup": self.setup_frame,
            "active": self.quiz_frame,
            "results": self.results_frame,
            "history": self.history_frame,
        }
        target = frames.get(name)
        if target is None:
            target, name = self.setup_frame, "setup"
        for f in frames.values():
            if f is not None and f is not target:
                f.pack_forget()
        self._section = name
        self.header_title.configure(text=_HEADER_TITLES.get(name, "Quiz"))
        self.header_subtitle.configure(
            text=_HEADER_SUBTITLES.get(name, _HEADER_SUBTITLES["setup"])
        )
        target.pack(fill="both", expand=True)
        try:
            self.app._sync_quiz_nav()
        except Exception:
            pass

    def show_setup(self):
        """Sidebar 'Take Quiz' entry point. Never wipes an unfinished quiz --
        returning mid-quiz resumes it (the timer keeps running)."""
        if self._quiz_in_progress and self.quiz_frame is not None:
            self._show_section("active")
            return
        self._refresh_setup()
        self._show_section("setup")

    def show_history(self):
        """Sidebar 'Quiz History' entry point."""
        self._refresh_history()
        self._show_section("history")

    def get_scroll_targets(self):
        """(widget path prefix, canvas) pairs for the app's global mousewheel
        router -- same contract as the notebook list and volumes scroll."""
        targets = []
        for cl in (
            getattr(self, "quiz_list", None),
            getattr(self, "results_list", None),
            getattr(self, "history_list", None),
        ):
            if cl is not None:
                try:
                    if cl.winfo_exists():
                        targets.append((str(cl), cl.canvas))
                except Exception:
                    pass
        return targets

    # ==================================================================
    # SETUP SECTION
    # ==================================================================

    def _menu_style(self):
        return dict(
            fg_color=Color.INPUT_BG, button_color=Color.INPUT_BG,
            button_hover_color=Color.HOVER_BG, text_color=Color.TEXT_PRIMARY,
            dropdown_fg_color=Color.CARD_BG, dropdown_hover_color=Color.HOVER_BG,
            dropdown_text_color=Color.TEXT_PRIMARY, dropdown_font=Font.base(13),
            font=Font.base(14), height=42, corner_radius=8
        )

    def _build_setup_view(self, parent):
        frame = ctk.CTkFrame(parent, fg_color="transparent")

        card = ctk.CTkFrame(frame, fg_color=Color.CARD_BG, corner_radius=14,
                            border_width=1, border_color=Color.BORDER)
        card.pack(fill="x", padx=45, pady=(5, 0))

        # Card heading: title + helper text + divider (visual hierarchy).
        head = ctk.CTkFrame(card, fg_color="transparent")
        head.pack(fill="x", padx=40, pady=(30, 0))
        ctk.CTkLabel(head, text="Quiz Settings", font=Font.base(17, "bold"),
                     text_color=Color.TEXT_PRIMARY).pack(anchor="w")
        ctk.CTkLabel(head,
                     text="Choose what to practice and how many questions to answer.",
                     font=Font.base(13),
                     text_color=Color.TEXT_MUTED).pack(anchor="w", pady=(3, 0))
        tk.Frame(head, bg=Color.BORDER, height=1).pack(fill="x", pady=(20, 0))

        grid = ctk.CTkFrame(card, fg_color="transparent")
        grid.pack(fill="x", padx=40, pady=(28, 5))
        grid.grid_columnconfigure(0, weight=1, uniform="quizcol")
        grid.grid_columnconfigure(1, weight=1, uniform="quizcol")

        def option_cell(row, col, label_text, variable, values):
            cell = ctk.CTkFrame(grid, fg_color="transparent")
            cell.grid(row=row, column=col, sticky="ew",
                      padx=(0, 20) if col == 0 else (20, 0), pady=(0, 30))
            ctk.CTkLabel(cell, text=label_text.upper(), font=Font.base(11, "bold"),
                         text_color=Color.TEXT_MUTED).pack(anchor="w", pady=(0, 10))
            menu = ctk.CTkOptionMenu(cell, variable=variable, values=values,
                                     **self._menu_style())
            menu.pack(fill="x")
            return menu

        self.source_var = tk.StringVar(value=ALL_WORDS_LABEL)
        self.count_var = tk.StringVar(value=QUESTION_COUNTS[0])
        self.type_var = tk.StringVar(value=QUESTION_TYPE_CHOICES[0])
        self.provider_var = tk.StringVar(value=NO_PROVIDERS_LABEL)

        self.source_menu = option_cell(0, 0, "Word Source", self.source_var, [ALL_WORDS_LABEL])
        self.count_menu = option_cell(0, 1, "Number of Questions", self.count_var, QUESTION_COUNTS)
        self.type_menu = option_cell(1, 0, "Question Type", self.type_var, QUESTION_TYPE_CHOICES)
        # AI Provider is intentionally the LAST option.
        self.provider_menu = option_cell(1, 1, "AI Provider", self.provider_var, [NO_PROVIDERS_LABEL])

        tk.Frame(card, bg=Color.BORDER, height=1).pack(fill="x", padx=40)

        actions = ctk.CTkFrame(card, fg_color="transparent")
        actions.pack(fill="x", padx=40, pady=(22, 30))
        self.start_btn = ctk.CTkButton(
            actions, text="Start Quiz", width=170, height=44, corner_radius=8,
            fg_color=Color.ACCENT, hover_color=Color.ACCENT_HOVER,
            font=Font.base(14, "bold"), command=self._start_quiz
        )
        self.start_btn.pack(side="left")
        self.setup_status = ctk.CTkLabel(
            actions, text="", font=Font.base(13),
            text_color=Color.TEXT_MUTED, wraplength=560, justify="left"
        )
        self.setup_status.pack(side="left", padx=(20, 0))

        return frame

    def _set_setup_status(self, text, color=None):
        self.setup_status.configure(text=text, text_color=color or Color.TEXT_MUTED)

    def _refresh_setup(self):
        """Re-reads volumes and configured providers each time the setup view
        is shown, so new API keys and volumes appear without restarting."""
        # -- Word source options --
        self._source_map = {}
        values = []
        if self.app.current_volume_id is not None:
            self._source_map[CURRENT_VOLUME_LABEL] = self.app.current_volume_id
            values.append(CURRENT_VOLUME_LABEL)
        self._source_map[ALL_WORDS_LABEL] = None
        values.append(ALL_WORDS_LABEL)
        try:
            volumes = get_all_volumes()
        except Exception:
            volumes = []
        for vol in volumes:
            label = f"Volume: {vol['name']} ({vol.get('word_count', 0)})"
            self._source_map[label] = vol["id"]
            values.append(label)
        self.source_menu.configure(values=values)
        if self.source_var.get() not in self._source_map:
            self.source_var.set(values[0])

        # -- AI providers: every provider with a permanently saved key --
        providers = get_configured_providers(list(self.app.API_PRESETS.keys()))
        if providers:
            self.provider_menu.configure(values=providers, state="normal")
            if self.provider_var.get() not in providers:
                settings_choice = self.app.settings_page.provider_var.get()
                self.provider_var.set(
                    settings_choice if settings_choice in providers else providers[0]
                )
            if not self.app._quiz_generation_active:
                self.start_btn.configure(state="normal")
                self._set_setup_status("")
        else:
            self.provider_menu.configure(values=[NO_PROVIDERS_LABEL], state="disabled")
            self.provider_var.set(NO_PROVIDERS_LABEL)
            self.start_btn.configure(state="disabled")
            self._set_setup_status(
                "No AI provider is configured yet. Add an API key in "
                "Settings → API to enable quiz generation."
            )

    # ==================================================================
    # GENERATION (background thread + watchdog, same idiom as add-word)
    # ==================================================================

    def _provider_config_for(self, provider):
        """Uses Settings' live config (honours custom Base URL / Model) when
        the chosen provider matches; otherwise falls back to the preset."""
        sp = self.app.settings_page
        try:
            if sp.provider_var.get() == provider:
                return sp.get_current_provider_config()
        except Exception:
            pass
        preset = self.app.API_PRESETS.get(provider, {})
        return {
            "type": preset.get("type", "openai_compatible"),
            "base_url": preset.get("url", ""),
            "model": preset.get("model", ""),
        }

    def _start_quiz(self):
        # Duplicate-click guard: one generation at a time, app-wide.
        if self.app._quiz_generation_active:
            return

        provider = self.provider_var.get()
        api_key = get_provider_key(provider)
        if not api_key or provider == NO_PROVIDERS_LABEL:
            self._set_setup_status(
                "No API key saved for this provider. Add one in Settings → API.",
                Color.DANGER,
            )
            return

        src_label = self.source_var.get()
        volume_id = self._source_map.get(src_label)
        try:
            words = quiz_db.get_words_for_quiz(volume_id)
        except Exception:
            words = []
        if len(words) < 4:
            StyledConfirmDialog(
                self.app, "Not Enough Words",
                "At least 4 words are needed to build a quiz.\n"
                "Add more words or choose a different word source.",
                confirm_text="OK"
            ).wait_window()
            return

        requested = int(self.count_var.get())
        num_questions = min(requested, len(words))
        qtype = self.type_var.get()
        provider_config = self._provider_config_for(provider)
        meta = {
            "provider_name": provider,
            "model": provider_config.get("model", ""),
            "word_source_label": src_label,
            "volume_id": volume_id,
            "question_type": qtype,
            "num_questions": num_questions,
        }

        self.app._quiz_generation_active = True
        self._gen_seq += 1
        seq = self._gen_seq
        self.start_btn.configure(state="disabled")
        note = "" if num_questions == requested else f" (only {num_questions} words available)"
        self._set_setup_status(
            f"Generating {num_questions} questions with {provider}…{note}",
            Color.ACCENT,
        )
        self.after(GENERATION_WATCHDOG_MS, lambda s=seq: self._generation_watchdog(s))
        threading.Thread(
            target=self._bg_generate,
            args=(seq, words, num_questions, qtype, api_key, provider_config, meta),
            daemon=True,
        ).start()

    def _bg_generate(self, seq, words, num_questions, qtype, api_key, provider_config, meta):
        """Runs on a background thread; never touches the UI directly."""
        try:
            questions, msg = generate_quiz(words, num_questions, qtype, api_key, provider_config)
        except Exception as e:
            questions, msg = None, f"Quiz generation failed: {str(e)}"
        try:
            self.app.after(0, lambda: self._on_generation_done(seq, questions, msg, meta))
        except Exception:
            pass  # the app was closed while the request was in flight

    def _generation_watchdog(self, seq):
        """Releases a stuck generation, mirroring _release_stuck_request."""
        if seq == self._gen_seq and self.app._quiz_generation_active:
            self.app._quiz_generation_active = False
            try:
                self.start_btn.configure(state="normal")
                self._set_setup_status(
                    "Quiz generation timed out. Please try again.", Color.DANGER
                )
            except Exception:
                pass

    def _on_generation_done(self, seq, questions, msg, meta):
        """Runs on the main thread via app.after(0, ...)."""
        if seq != self._gen_seq:
            return  # superseded by a newer generation
        self.app._quiz_generation_active = False
        try:
            self.start_btn.configure(state="normal")
        except Exception:
            return
        if not questions:
            self._set_setup_status(msg or "Quiz generation failed.", Color.DANGER)
            return
        meta = dict(meta)
        meta["num_questions"] = len(questions)
        self._set_setup_status("")
        self._begin_quiz(questions, meta)

    # ==================================================================
    # ACTIVE QUIZ SECTION (all questions on one page)
    # ==================================================================

    def _begin_quiz(self, questions, meta):
        self._teardown_active_quiz()
        self._active = {
            "questions": questions,
            "meta": meta,
            "answers": [None] * len(questions),
            "start_time": time.monotonic(),
        }
        self._quiz_in_progress = True
        self._option_items = {}

        frame = ctk.CTkFrame(self.body, fg_color="transparent")
        self.quiz_frame = frame

        top = ctk.CTkFrame(frame, fg_color="transparent")
        top.pack(fill="x", padx=45, pady=(0, 16))
        ctk.CTkLabel(
            top,
            text=f"{meta['word_source_label']}   ·   {meta['question_type']}   ·   {meta['provider_name']}",
            font=Font.base(13), text_color=Color.TEXT_SECONDARY
        ).pack(side="left")
        self.clock_label = ctk.CTkLabel(top, text="00:00", font=Font.base(14, "bold"),
                                        text_color=Color.TEXT_PRIMARY)
        self.clock_label.pack(side="right")
        self.answered_label = ctk.CTkLabel(
            top, text=f"0 / {len(questions)} answered",
            font=Font.base(13), text_color=Color.TEXT_MUTED
        )
        self.answered_label.pack(side="right", padx=(0, 24))

        # Thin progress bar tracking answered questions (existing colors).
        self.progress_bar = ctk.CTkProgressBar(
            frame, height=6, corner_radius=3,
            fg_color=Color.INPUT_BG, progress_color=Color.ACCENT
        )
        self.progress_bar.set(0)
        self.progress_bar.pack(fill="x", padx=45, pady=(0, 14))

        self.quiz_list = _CanvasList(frame, Color.APP_BG)
        self.quiz_list.pack(fill="both", expand=True, padx=45, pady=(0, 12))

        footer = ctk.CTkFrame(frame, fg_color="transparent")
        footer.pack(fill="x", padx=45, pady=(0, 25))
        self.submit_btn = ctk.CTkButton(
            footer, text="Submit Quiz", width=170, height=44, corner_radius=8,
            fg_color=Color.ACCENT, hover_color=Color.ACCENT_HOVER,
            font=Font.base(14, "bold"), state="disabled", command=self._submit_quiz
        )
        self.submit_btn.pack(side="right")
        ctk.CTkButton(
            footer, text="Cancel Quiz", width=130, height=44, corner_radius=8,
            fg_color="transparent", hover_color=Color.HOVER_BG,
            border_width=1, border_color=Color.BORDER,
            text_color=Color.TEXT_SECONDARY, font=Font.base(14),
            command=self._cancel_quiz
        ).pack(side="right", padx=(0, 12))

        # Every question is drawn as items on ONE canvas (the word list's
        # rendering technique): scrolling only shifts the canvas viewport,
        # so it stays perfectly smooth even with 30 questions on the page.
        self.quiz_list.set_renderer(self._render_quiz)
        self.submit_btn.configure(state="normal")
        self._tick_clock()
        self._show_section("active")

    @staticmethod
    def _rounded(cv, x1, y1, x2, y2, r, fill, outline=None, tags=()):
        """Rounded rectangle as a smoothed polygon (word-list technique)."""
        points = [x1 + r, y1, x2 - r, y1, x2, y1, x2, y1 + r,
                  x2, y2 - r, x2, y2, x2 - r, y2, x1 + r, y2,
                  x1, y2, x1, y2 - r, x1, y1 + r, x1, y1]
        return cv.create_polygon(points, smooth=True, fill=fill,
                                 outline=outline or fill, tags=tags)

    def _draw_canvas_button(self, cv, x, y, w, h, text, fill, text_color, tag,
                            command, outline=None, hover_fill=None, bold=False):
        """Canvas-item button with hover + pressed feedback (word-list style)."""
        rid = self._rounded(cv, x, y, x + w, y + h, 8, fill,
                            outline=outline or fill, tags=(tag,))
        cv.create_text(x + w / 2, y + h / 2 - 1, text=text,
                       font=Font.base(13, "bold") if bold else Font.base(13),
                       fill=text_color, anchor="center", tags=(tag,))
        hf = hover_fill or fill

        def _pressed(e, cb=command):
            try:
                cv.itemconfig(rid, fill=hf)
                cv.update_idletasks()
            except Exception:
                pass
            cb(e)

        cv.tag_bind(tag, "<Button-1>", _pressed)
        if hover_fill:
            cv.tag_bind(tag, "<Enter>", lambda e: (cv.itemconfig(rid, fill=hf),
                                                   cv.config(cursor="hand2")))
            cv.tag_bind(tag, "<Leave>", lambda e: (cv.itemconfig(rid, fill=fill),
                                                   cv.config(cursor="")))
        return y + h

    def _render_quiz(self, cv, width):
        """Draws every question card as canvas items. Re-runs on width
        changes; selection styling is re-applied from state, so answers
        are never lost."""
        self._option_items = {}
        if self._active is None:
            return 0
        questions = self._active["questions"]
        total = len(questions)
        cw = max(width - 4, 360)
        pad = 28
        y = 0
        for idx, q in enumerate(questions):
            top = y
            iy = top + 22

            # Caption row: question number (left) + type pill (right)
            cv.create_text(pad, iy, text=f"QUESTION {idx + 1} OF {total}",
                           font=Font.base(11, "bold"), fill=Color.TEXT_MUTED,
                           anchor="nw")
            bt = cv.create_text(cw - pad - 12, iy - 2,
                                text=str(q["question_type"]).upper(),
                                font=Font.base(10, "bold"), fill=Color.ACCENT,
                                anchor="ne")
            bb = cv.bbox(bt)
            pill = self._rounded(cv, bb[0] - 12, bb[1] - 6, bb[2] + 12,
                                 bb[3] + 6, 10, Color.INPUT_BG,
                                 outline=Color.BORDER)
            cv.tag_lower(pill, bt)

            iy += 30
            tid = cv.create_text(pad, iy, text=q["word"],
                                 font=Font.base(18, "bold"),
                                 fill=Color.TEXT_PRIMARY, anchor="nw",
                                 width=cw - 2 * pad)
            iy = cv.bbox(tid)[3] + 8
            tid = cv.create_text(pad, iy, text=q["question"], font=Font.base(14),
                                 fill=Color.TEXT_SECONDARY, anchor="nw",
                                 width=cw - 2 * pad)
            iy = cv.bbox(tid)[3] + 16

            for opt_i, opt in enumerate(q["options"]):
                iy = self._draw_option(cv, idx, opt_i, opt, pad, iy, cw) + 10

            card = self._rounded(cv, 0, top, cw, iy + 10, 14, Color.CARD_BG,
                                 outline=Color.BORDER)
            cv.tag_lower(card)
            for opt_i in range(len(q["options"])):
                self._style_option(idx, opt_i)
            y = iy + 10 + 20
        return y

    def _draw_option(self, cv, q_idx, opt_i, opt, pad, oy, cw):
        tag = f"q{q_idx}_o{opt_i}"
        tx = pad + 52
        tid = cv.create_text(tx, oy, text=opt, font=Font.base(14),
                             fill=Color.TEXT_PRIMARY, anchor="nw",
                             width=cw - pad - tx - 16, tags=(tag,))
        bb = cv.bbox(tid)
        th = bb[3] - bb[1]
        h = max(48, th + 22)
        cv.move(tid, 0, (h - th) / 2)
        lid = cv.create_text(pad + 20, oy + h / 2, text=chr(65 + opt_i),
                             font=Font.base(13, "bold"), fill=Color.TEXT_MUTED,
                             anchor="w", tags=(tag,))
        rid = self._rounded(cv, pad, oy, cw - pad, oy + h, 10, Color.INPUT_BG,
                            outline=Color.BORDER, tags=(tag,))
        cv.tag_lower(rid, tid)
        self._option_items[(q_idx, opt_i)] = (rid, tid, lid)
        cv.tag_bind(tag, "<Button-1>",
                    lambda e, qi=q_idx, oi=opt_i: self._select_option(qi, oi))
        cv.tag_bind(tag, "<Enter>",
                    lambda e, qi=q_idx, oi=opt_i: self._hover_option(qi, oi, True))
        cv.tag_bind(tag, "<Leave>",
                    lambda e, qi=q_idx, oi=opt_i: self._hover_option(qi, oi, False))
        return oy + h

    def _style_option(self, q_idx, opt_i, hover=False):
        items = self._option_items.get((q_idx, opt_i))
        if not items or self._active is None or self.quiz_list is None:
            return
        rid, tid, lid = items
        selected = self._active["answers"][q_idx] == opt_i
        if selected:
            fill, outline = Color.ACCENT, Color.ACCENT
            text_fill = letter_fill = "#FFFFFF"
        elif hover:
            fill, outline, text_fill = Color.HOVER_BG, Color.BORDER, Color.TEXT_PRIMARY
            letter_fill = Color.TEXT_SECONDARY
        else:
            fill, outline, text_fill = Color.INPUT_BG, Color.BORDER, Color.TEXT_PRIMARY
            letter_fill = Color.TEXT_MUTED
        try:
            cv = self.quiz_list.canvas
            cv.itemconfig(rid, fill=fill, outline=outline)
            cv.itemconfig(tid, fill=text_fill)
            cv.itemconfig(lid, fill=letter_fill)
        except Exception:
            pass

    def _hover_option(self, q_idx, opt_i, entering):
        self._style_option(q_idx, opt_i, hover=entering)
        try:
            self.quiz_list.canvas.config(cursor="hand2" if entering else "")
        except Exception:
            pass

    def _select_option(self, q_index, opt_index):
        if self._active is None:
            return
        answers = self._active["answers"]
        # Clicking the already-selected option again deselects it, leaving
        # the question unanswered (lets the user reconsider before submit).
        if answers[q_index] == opt_index:
            answers[q_index] = None
        else:
            answers[q_index] = opt_index
        for i in range(len(self._active["questions"][q_index]["options"])):
            self._style_option(q_index, i)
        answered = sum(1 for a in answers if a is not None)
        try:
            self.answered_label.configure(text=f"{answered} / {len(answers)} answered")
        except Exception:
            pass
        try:
            self.progress_bar.set(answered / max(len(answers), 1))
        except Exception:
            pass

    def _tick_clock(self):
        self._clock_timer = None
        if not self._quiz_in_progress or self._active is None:
            return
        elapsed = int(time.monotonic() - self._active["start_time"])
        try:
            self.clock_label.configure(text=_fmt_secs(elapsed))
        except Exception:
            return
        self._clock_timer = self.after(1000, self._tick_clock)

    def _cancel_quiz(self):
        dlg = StyledConfirmDialog(
            self.app, "Cancel Quiz",
            "Discard this quiz? Your answers will not be saved.",
            confirm_text="Discard", danger=True
        )
        self.app.wait_window(dlg)
        if not getattr(dlg, "result", False):
            return
        self._teardown_active_quiz()
        self.show_setup()

    def _teardown_active_quiz(self):
        for attr in ("_build_timer", "_clock_timer"):
            timer = getattr(self, attr, None)
            if timer is not None:
                try:
                    self.after_cancel(timer)
                except Exception:
                    pass
                setattr(self, attr, None)
        self._build_queue = []
        self._quiz_in_progress = False
        self._active = None
        self._option_items = {}
        if self.quiz_frame is not None:
            self.quiz_frame.destroy()
            self.quiz_frame = None
        self.quiz_list = None

    # ==================================================================
    # SUBMIT & RESULTS SECTION
    # ==================================================================

    def _submit_quiz(self):
        if self._active is None:
            return
        questions = self._active["questions"]
        answers = self._active["answers"]
        unanswered = sum(1 for a in answers if a is None)
        if unanswered:
            dlg = StyledConfirmDialog(
                self.app, "Submit Quiz",
                f"{unanswered} question{'s are' if unanswered != 1 else ' is'} "
                "unanswered and will be marked incorrect.\nSubmit anyway?",
                confirm_text="Submit"
            )
            self.app.wait_window(dlg)
            if not getattr(dlg, "result", False):
                return

        time_taken = int(time.monotonic() - self._active["start_time"])
        meta = dict(self._active["meta"])
        rows = []
        score = 0
        for i, q in enumerate(questions):
            chosen = answers[i]
            is_correct = chosen == q["correct_index"]
            if is_correct:
                score += 1
            rows.append(
                {
                    "word": q["word"],
                    "question_type": q["question_type"],
                    "question": q["question"],
                    "options": q["options"],
                    "correct_index": q["correct_index"],
                    "chosen_index": chosen,
                    "is_correct": is_correct,
                    "explanation": q.get("explanation", ""),
                }
            )
        meta["score"] = score
        meta["num_questions"] = len(questions)
        meta["percentage"] = round(score * 100.0 / len(questions), 1)
        meta["time_taken_secs"] = time_taken
        meta.setdefault("created_at", time.strftime("%Y-%m-%d %H:%M:%S"))

        try:
            meta["id"] = quiz_db.save_quiz_attempt(meta, rows)
        except Exception:
            meta["id"] = None  # losing history beats losing the results screen

        self._teardown_active_quiz()
        self._results_source = "quiz"
        self._show_results({"meta": meta, "questions": rows})

    @staticmethod
    def _pct_color(pct):
        if pct >= 80:
            return Color.SUCCESS
        if pct >= 50:
            return Color.STAR
        return Color.DANGER

    def _show_results(self, detail):
        """Renders results from an attempt-detail dict, so a freshly finished
        quiz and a history 'Open' share the exact same code path."""
        if self.results_frame is not None:
            self.results_frame.destroy()
            self.results_frame = None
            self.results_list = None

        meta = detail["meta"]
        questions = detail["questions"]
        total = int(meta.get("num_questions") or len(questions) or 1)
        correct = int(meta.get("score") or 0)
        incorrect = total - correct
        pct = float(meta.get("percentage") or 0.0)

        frame = ctk.CTkFrame(self.body, fg_color="transparent")
        self.results_frame = frame

        # Everything scrollable is drawn on ONE canvas -- zero embedded
        # widgets, so long review lists scroll as smoothly as the word list.
        self._results_detail = {
            "meta": meta, "questions": questions, "total": total,
            "correct": correct, "incorrect": incorrect, "pct": pct,
        }
        self.results_list = _CanvasList(frame, Color.APP_BG)
        self.results_list.pack(fill="both", expand=True, padx=45, pady=(0, 12))
        self.results_list.set_renderer(self._render_results)

        # ---- Footer actions (outside the scroll area) ----
        footer = ctk.CTkFrame(frame, fg_color="transparent")
        footer.pack(fill="x", padx=45, pady=(0, 25))
        ctk.CTkButton(
            footer, text="New Quiz", width=160, height=44, corner_radius=8,
            fg_color=Color.ACCENT, hover_color=Color.ACCENT_HOVER,
            font=Font.base(14, "bold"), command=self.show_setup
        ).pack(side="right")
        ctk.CTkButton(
            footer, text="View History", width=150, height=44, corner_radius=8,
            fg_color="transparent", hover_color=Color.HOVER_BG,
            border_width=1, border_color=Color.BORDER,
            text_color=Color.TEXT_SECONDARY, font=Font.base(14),
            command=self.show_history
        ).pack(side="right", padx=(0, 12))

        self._show_section("results")

    def _render_results(self, cv, width):
        d = self._results_detail
        if not d:
            return 0
        meta, questions = d["meta"], d["questions"]
        pct = d["pct"]
        cw = max(width - 4, 400)
        pad = 28

        # ---- Summary card: score ring | divider | aligned stats grid ----
        ring_r = 52
        ring_cx = pad + ring_r
        ring_cy = 26 + ring_r
        ring_color = Color.ACCENT
        cv.create_oval(ring_cx - ring_r, ring_cy - ring_r,
                       ring_cx + ring_r, ring_cy + ring_r,
                       outline=Color.INPUT_BG, width=9)
        if pct > 0:
            extent = -359.9 if pct >= 100 else -max(3.6 * pct, 2.0)
            cv.create_arc(ring_cx - ring_r, ring_cy - ring_r,
                          ring_cx + ring_r, ring_cy + ring_r,
                          start=90, extent=extent, style="arc",
                          outline=ring_color, width=9)
        cv.create_text(ring_cx, ring_cy, text=f"{pct:.0f}%",
                       font=Font.base(26, "bold"), fill=ring_color,
                       anchor="center")
        ring_bottom = ring_cy + ring_r

        div_x = ring_cx + ring_r + 36
        grid_x = div_x + 32
        avail = max(cw - grid_x - pad, 200)
        n_cols = max(2, min(4, int(avail // 150)))
        col_w = avail / n_cols
        cells = [
            ("SCORE", f"{d['correct']}/{d['total']}"),
            ("CORRECT", str(d["correct"])),
            ("INCORRECT", str(d["incorrect"])),
            ("TIME", _fmt_secs(meta.get("time_taken_secs"))),
            ("PROVIDER", str(meta.get("provider_name") or "—")),
            ("SOURCE", str(meta.get("word_source_label") or "—")),
            ("TYPE", str(meta.get("question_type") or "—")),
            ("DATE", str(meta.get("created_at") or "—")),
        ]
        row_h = 50
        # Vertically center the stats grid against the score ring.
        n_rows = (len(cells) + n_cols - 1) // n_cols
        grid_h = (n_rows - 1) * row_h + 34
        gy = max(26, int((ring_bottom + 26 - grid_h) / 2))
        for i, (label, value) in enumerate(cells):
            cx = grid_x + (i % n_cols) * col_w
            cy = gy + (i // n_cols) * row_h
            cv.create_text(cx, cy, text=label, font=Font.base(10, "bold"),
                           fill=Color.TEXT_MUTED, anchor="nw")
            cv.create_text(cx, cy + 18, text=value, font=Font.base(13, "bold"),
                           fill=Color.TEXT_PRIMARY, anchor="nw")
        grid_bottom = gy + (n_rows - 1) * row_h + 40
        bottom = max(ring_bottom, grid_bottom) + 26
        cv.create_line(div_x, 24, div_x, bottom - 24, fill=Color.BORDER)
        card = self._rounded(cv, 0, 0, cw, bottom, 14, Color.CARD_BG,
                             outline=Color.BORDER)
        cv.tag_lower(card)
        y = bottom + 24

        # ---- Review of ALL questions (correct and incorrect) ----
        if questions:
            tid = cv.create_text(2, y, text="Review", font=Font.base(17, "bold"),
                                 fill=Color.TEXT_PRIMARY, anchor="nw")
            cv.create_text(cv.bbox(tid)[2] + 14, y + 6,
                           text=(f"{len(questions)} questions   ·   "
                                 f"{d['correct']} correct   ·   "
                                 f"{d['incorrect']} incorrect"),
                           font=Font.base(12), fill=Color.TEXT_MUTED,
                           anchor="nw")
            y = cv.bbox(tid)[3] + 14
            for idx, q in enumerate(questions, 1):
                y = self._draw_review_card(cv, q, cw, y, idx) + 14
        return y + 15

    def _draw_review_card(self, cv, q, cw, y, number=None):
        pad = 24
        wrap = cw - 2 * pad
        top = y
        iy = top + 22
        is_correct = bool(q.get("is_correct"))
        s_color = Color.SUCCESS if is_correct else Color.DANGER

        # Caption row: question number + type (left), status pill (right)
        cap = f"QUESTION {number}   ·   {str(q.get('question_type', '')).upper()}"
        cv.create_text(pad, iy, text=cap, font=Font.base(11, "bold"),
                       fill=Color.TEXT_MUTED, anchor="nw")
        bt = cv.create_text(cw - pad - 12, iy - 2,
                            text="✓  CORRECT" if is_correct else "✗  INCORRECT",
                            font=Font.base(10, "bold"), fill=s_color,
                            anchor="ne")
        bb = cv.bbox(bt)
        pill = self._rounded(cv, bb[0] - 12, bb[1] - 6, bb[2] + 12, bb[3] + 6,
                             10, Color.INPUT_BG, outline=Color.BORDER)
        cv.tag_lower(pill, bt)

        iy += 30
        tid = cv.create_text(pad, iy, text=q["word"], font=Font.base(17, "bold"),
                             fill=Color.TEXT_PRIMARY, anchor="nw", width=wrap)
        iy = cv.bbox(tid)[3] + 8
        tid = cv.create_text(pad, iy, text=q["question"], font=Font.base(14),
                             fill=Color.TEXT_SECONDARY, anchor="nw", width=wrap)
        iy = cv.bbox(tid)[3] + 18

        options = q.get("options") or []
        chosen = q.get("chosen_index")
        if chosen is not None and 0 <= int(chosen) < len(options):
            your_answer = options[int(chosen)]
        else:
            your_answer = "Not answered"
        correct_answer = ""
        ci = q.get("correct_index")
        if ci is not None and 0 <= int(ci) < len(options):
            correct_answer = options[int(ci)]

        tid = cv.create_text(pad, iy, text="YOUR ANSWER",
                             font=Font.base(10, "bold"), fill=Color.TEXT_MUTED,
                             anchor="nw")
        iy = cv.bbox(tid)[3] + 4
        tid = cv.create_text(pad, iy, text=your_answer, font=Font.base(14),
                             fill=s_color, anchor="nw", width=wrap)
        iy = cv.bbox(tid)[3] + 14
        tid = cv.create_text(pad, iy, text="CORRECT ANSWER",
                             font=Font.base(10, "bold"), fill=Color.TEXT_MUTED,
                             anchor="nw")
        iy = cv.bbox(tid)[3] + 4
        tid = cv.create_text(pad, iy, text=correct_answer,
                             font=Font.base(14, "bold"), fill=Color.SUCCESS,
                             anchor="nw", width=wrap)
        iy = cv.bbox(tid)[3]

        explanation = (q.get("explanation") or "").strip()
        if explanation:
            iy += 16
            cv.create_line(pad, iy, cw - pad, iy, fill=Color.BORDER)
            tid = cv.create_text(pad, iy + 14, text=explanation,
                                 font=Font.base(13, "italic"),
                                 fill=Color.TEXT_SECONDARY, anchor="nw",
                                 width=wrap)
            iy = cv.bbox(tid)[3]

        card = self._rounded(cv, 0, top, cw, iy + 22, 14, Color.CARD_BG,
                             outline=Color.BORDER)
        cv.tag_lower(card)
        # Left accent strip: green for correct, red for incorrect, so the
        # review list can be scanned at a glance.
        self._rounded(cv, 0, top + 16, 4, iy + 22 - 16, 2, s_color)
        return iy + 22

    # ==================================================================
    # HISTORY SECTION (paginated: fast even with an extensive history)
    # ==================================================================

    def _build_history_view(self):
        frame = ctk.CTkFrame(self.body, fg_color="transparent")

        bar = ctk.CTkFrame(frame, fg_color="transparent")
        bar.pack(fill="x", padx=45, pady=(0, 14))
        self.history_count_label = ctk.CTkLabel(
            bar, text="", font=Font.base(13), text_color=Color.TEXT_MUTED
        )
        self.history_count_label.pack(side="left")
        self.clear_history_btn = ctk.CTkButton(
            bar, text="Delete All", width=120, height=38, corner_radius=8,
            fg_color="transparent", hover_color=Color.HOVER_BG,
            border_width=1, border_color=Color.DANGER,
            text_color=Color.DANGER, font=Font.base(13, "bold"),
            command=self._clear_history
        )
        self.clear_history_btn.pack(side="right")

        self.history_list = _CanvasList(frame, Color.APP_BG)
        self.history_list.pack(fill="both", expand=True, padx=45, pady=(0, 25))
        return frame

    def _refresh_history(self):
        if self.history_frame is None:
            self.history_frame = self._build_history_view()
        self._history_offset = 0
        self._history_rows = []
        self._history_total = 0
        self._fetch_history_page()
        self.history_list.set_renderer(self._render_history)

    def _append_history_rows(self):
        self._fetch_history_page()
        self.history_list.rerender()

    def _fetch_history_page(self):
        try:
            total = quiz_db.count_quiz_attempts()
            rows = quiz_db.get_quiz_history(
                limit=HISTORY_PAGE_SIZE, offset=self._history_offset
            )
        except Exception:
            total, rows = 0, []
        self._history_total = total
        self._history_rows.extend(rows)
        self._history_offset += len(rows)
        self.history_count_label.configure(
            text=f"{total} attempt{'s' if total != 1 else ''}"
        )
        if total:
            if not self.clear_history_btn.winfo_ismapped():
                self.clear_history_btn.pack(side="right")
            self.clear_history_btn.configure(state="normal")
        else:
            self.clear_history_btn.pack_forget()

    def _render_history(self, cv, width):
        cw = max(width - 4, 400)
        if self._history_total == 0:
            box_h = 170
            self._rounded(cv, 0, 0, cw, box_h, 14, Color.CARD_BG,
                          outline=Color.BORDER)
            cv.create_text(cw / 2, box_h / 2 - 16, text="No quizzes yet",
                           font=Font.base(16, "bold"), fill=Color.TEXT_PRIMARY,
                           anchor="center")
            cv.create_text(cw / 2, box_h / 2 + 14,
                           text="Take a quiz and your attempts will show up here.",
                           font=Font.base(13), fill=Color.TEXT_MUTED,
                           anchor="center")
            return box_h
        y = 0
        for row in self._history_rows:
            y = self._draw_history_row(cv, row, cw, y) + 12
        if self._history_offset < self._history_total:
            y = self._draw_canvas_button(
                cv, cw / 2 - 75, y + 6, 150, 40, "Load More", Color.APP_BG,
                Color.TEXT_SECONDARY, "loadmore",
                lambda e: self._append_history_rows(),
                outline=Color.BORDER, hover_fill=Color.HOVER_BG,
            ) + 10
        return y + 15

    def _draw_history_row(self, cv, row, cw, y):
        top = y
        pad = 32
        h = 118
        aid = row.get("id")
        row_tag = f"row_{aid}"

        # Buttons occupy the right side; content must stay clear of them.
        btn_w, btn_h, btn_gap = 96, 40, 12
        btn_left = cw - pad - 2 * btn_w - btn_gap

        # ---- Primary line: big score + accuracy (e.g. "8/10  • 80%") ----
        pct = float(row.get("percentage") or 0.0)
        sid = cv.create_text(pad, top + 26,
                             text=f"{row.get('score', 0)}/{row.get('num_questions', 0)}",
                             font=Font.base(20, "bold"), fill=Color.TEXT_PRIMARY,
                             anchor="nw", tags=(row_tag,))
        cv.create_text(cv.bbox(sid)[2] + 12, top + 26,
                       text=f"• {pct:.0f}%",
                       font=Font.base(20, "bold"), fill=Color.ACCENT,
                       anchor="nw", tags=(row_tag,))

        # ---- Secondary line: muted date/duration + metadata chips ----
        # Positioned from the score's measured bbox so the two lines can
        # never overlap regardless of platform font rendering.
        cy = cv.bbox(sid)[3] + 22
        did = cv.create_text(pad, cy,
                             text=(f"{row.get('created_at', '')}   ·   "
                                   f"{_fmt_secs(row.get('time_taken_secs'))}"),
                             font=Font.base(12), fill=Color.TEXT_MUTED,
                             anchor="w", tags=(row_tag,))
        cx = cv.bbox(did)[2] + 18
        for chip in (row.get("provider_name"), row.get("word_source_label"),
                     row.get("question_type")):
            chip = str(chip or "").strip()
            if not chip:
                continue
            tid = cv.create_text(cx + 11, cy, text=chip,
                                 font=Font.base(10, "bold"),
                                 fill=Color.TEXT_SECONDARY, anchor="w",
                                 tags=(row_tag,))
            tb = cv.bbox(tid)
            if tb[2] + 15 > btn_left - 16:
                cv.delete(tid)  # never collide with the action buttons
                break
            rid = self._rounded(cv, cx, cy - 12, tb[2] + 11, cy + 12, 9,
                                Color.INPUT_BG, outline=Color.BORDER,
                                tags=(row_tag,))
            cv.tag_lower(rid, tid)
            cx = tb[2] + 11 + 8

        # ---- Card background: whole row is hoverable + clickable ----
        # Left accent strip in the app's blue (matches the Open button).
        strip = self._rounded(cv, 0, top + 18, 4, top + h - 18, 2,
                              Color.ACCENT, tags=(row_tag,))
        card = self._rounded(cv, 0, top, cw, top + h, 14, Color.CARD_BG,
                             outline=Color.BORDER, tags=(row_tag,))
        cv.tag_lower(card)
        cv.tag_raise(strip, card)
        cv.tag_bind(row_tag, "<Button-1>",
                    lambda e, a=aid: self._open_attempt(a))
        cv.tag_bind(row_tag, "<Enter>",
                    lambda e, c=card: (cv.itemconfig(c, fill=Color.HOVER_BG),
                                       cv.config(cursor="hand2")))
        cv.tag_bind(row_tag, "<Leave>",
                    lambda e, c=card: (cv.itemconfig(c, fill=Color.CARD_BG),
                                       cv.config(cursor="")))

        # ---- Action buttons: vertically centered, consistent sizing ----
        btn_y = top + (h - btn_h) / 2
        self._draw_canvas_button(
            cv, cw - pad - btn_w, btn_y, btn_w, btn_h, "Open",
            Color.ACCENT, "#FFFFFF", f"open_{aid}",
            lambda e, a=aid: self._open_attempt(a),
            hover_fill=Color.ACCENT_HOVER, bold=True,
        )
        # Secondary danger button: the original subtle style, with a red
        # border for button affordance without demanding attention.
        self._draw_canvas_button(
            cv, btn_left, btn_y, btn_w, btn_h, "Delete",
            Color.INPUT_BG, Color.DANGER, f"del_{aid}",
            lambda e, a=aid: self._delete_attempt(a),
            outline=Color.DANGER, hover_fill=Color.HOVER_BG,
        )
        return top + h

    def _open_attempt(self, attempt_id):
        try:
            detail = quiz_db.get_quiz_attempt_detail(attempt_id)
        except Exception:
            detail = None
        if detail is None:
            StyledConfirmDialog(
                self.app, "Not Found",
                "This quiz attempt could not be loaded. It may have been deleted.",
                confirm_text="OK"
            ).wait_window()
            self._refresh_history()
            return
        self._results_source = "history"
        self._show_results(detail)

    def _delete_attempt(self, attempt_id):
        dlg = StyledConfirmDialog(
            self.app, "Delete Quiz",
            "Delete this quiz attempt permanently?",
            confirm_text="Delete", danger=True
        )
        self.app.wait_window(dlg)
        if not getattr(dlg, "result", False):
            return
        try:
            quiz_db.delete_quiz_attempt(attempt_id)
        except Exception:
            pass
        self._refresh_history()

    def _clear_history(self):
        dlg = StyledConfirmDialog(
            self.app, "Delete All History",
            "Delete ALL quiz history permanently? This cannot be undone.",
            confirm_text="Delete All", danger=True
        )
        self.app.wait_window(dlg)
        if not getattr(dlg, "result", False):
            return
        try:
            quiz_db.clear_quiz_history()
        except Exception:
            pass
        self._refresh_history()
