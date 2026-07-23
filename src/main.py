import os
import sys
import ctypes
import math
import threading
import hashlib
import bisect
import collections
import io
from PIL import Image
import tkinter as tk
import tkinter.font as tkfont
import customtkinter as ctk
from customtkinter import filedialog

# =======================================================================
# MODULE 1: SYSTEM & HIGH-DPI FIX
# =======================================================================
if sys.platform == 'win32':
    try:
        # Enable High-DPI awareness for crisp text rendering on Windows
        ctypes.windll.shcore.SetProcessDpiAwareness(1)
    except Exception:
        pass

# Ensure these imports point to your existing project structure
from api.gemini import test_connection as _test_gemini_connection, fetch_word_details as _fetch_word_details
from database.db_manager import (
    init_db, save_word_to_db, get_all_words_dictionaries, 
    update_single_field, delete_word, check_word_exists,
    get_setting, save_setting, get_all_volumes, create_volume,
    rename_volume, delete_volume
)
from utils.export_manager import export_to_docx, import_from_docx
from utils.tts_manager import TTSManager
from utils.provider_keys import get_provider_key, save_provider_key, migrate_legacy_key

try:
    from PIL import ImageTk
    HAS_IMAGETK = True
except ImportError:
    HAS_IMAGETK = False

# Optional SVG icon support: if cairosvg is installed and an assets/<name>.svg
# exists, it is rasterized at the exact pixel size needed (crisp at any zoom
# and DPI). Falls back to the existing PNG pipeline otherwise.
try:
    import cairosvg
    HAS_SVG = True
except Exception:
    HAS_SVG = False


# =======================================================================
# MODULE 2: PREMIUM DESKTOP THEME SYSTEM
# =======================================================================
class Color:
    APP_BG = "#16171B"          
    SIDEBAR_BG = "#121318"      
    CARD_BG = "#21232A"         
    INPUT_BG = "#0D0E11"        
    HOVER_BG = "#2D303B"        
    
    BORDER = "#323642"          
    
    TEXT_PRIMARY = "#FFFFFF"    
    TEXT_SECONDARY = "#9CA3AF"  
    TEXT_MUTED = "#6B7280"      
    
    ACCENT = "#1877F2"          
    ACCENT_HOVER = "#166FE5"    
    
    STAR = "#F59E0B"            
    SUCCESS = "#10B981"
    DANGER = "#EF4444"


class Font:
    _BANGLA_FAMILY = "Kalpurush"
    
    @staticmethod
    def _init_bangla(root=None):
        candidates = ["Kalpurush", "Noto Sans Bengali", "Vrinda", "SolaimanLipi"]
        try:
            available = set(tkfont.families(root))
            for c in candidates:
                if c in available:
                    Font._BANGLA_FAMILY = c
                    return
        except Exception:
            pass
        Font._BANGLA_FAMILY = "Kalpurush"
    
    @staticmethod
    def base(size, weight="normal"):
        return ("Segoe UI", size, weight)
    
    @staticmethod
    def bangla(size, weight="normal"):
        return (Font._BANGLA_FAMILY, size, weight)


def resource_path(relative_path):
    try:
        base_path = sys._MEIPASS
    except Exception:
        base_path = os.path.dirname(os.path.abspath(__file__))
    candidate = os.path.join(base_path, relative_path)
    if os.path.exists(candidate):
        return candidate
    # Fall back to the launch directory so assets are still found when the
    # app is started from the project folder (the original lookup behavior).
    cwd_candidate = os.path.join(os.path.abspath("."), relative_path)
    if os.path.exists(cwd_candidate):
        return cwd_candidate
    return candidate


ctk.set_appearance_mode("dark")


# =======================================================================
# MODULE 3: PREMIUM UI UTILITIES (Tooltips & Dialogs)
# =======================================================================
class TooltipManager:
    """Manages premium, fading tooltips perfectly anchored to items."""
    def __init__(self, app):
        self.app = app
        self.tw = None
        self._fade_in_after = None
        self._fade_out_after = None
    
    def show(self, text, screen_x, screen_y, icon_h):
        self.hide(immediate=True)
        self.tw = tk.Toplevel(self.app)
        self.tw.wm_overrideredirect(True)
        self.tw.wm_attributes("-alpha", 0.0)
        self.tw.wm_attributes("-topmost", True)
        
        self.tw.configure(bg=Color.BORDER)
        inner = tk.Frame(self.tw, bg="#21232A")
        inner.pack(fill="both", expand=True, padx=1, pady=1)
        lbl = tk.Label(inner, text=text, bg="#21232A", fg="#FFFFFF", font=Font.base(11, "bold"), padx=12, pady=5)
        lbl.pack()
        
        self.tw.update_idletasks()
        tw = self.tw.winfo_reqwidth()
        th = self.tw.winfo_reqheight()
        
        x = screen_x - tw // 2
        y = screen_y - th - 8
        
        sw = self.app.winfo_screenwidth()
        if x < 5: x = 5
        if x + tw > sw - 5: x = sw - tw - 5
        
        if y < 5:
            y = screen_y + icon_h + 8
            
        self.tw.geometry(f"+{int(x)}+{int(y)}")
        self._fade_in(0.0)
        
    def _fade_in(self, alpha):
        if not self.tw or not self.tw.winfo_exists(): return
        alpha += 0.25
        if alpha >= 1.0:
            self.tw.wm_attributes("-alpha", 1.0)
            self._fade_in_after = None
        else:
            self.tw.wm_attributes("-alpha", alpha)
            self._fade_in_after = self.app.after(15, self._fade_in, alpha)
            
    def hide(self, immediate=False):
        if self._fade_in_after:
            self.app.after_cancel(self._fade_in_after)
            self._fade_in_after = None
        if self._fade_out_after:
            self.app.after_cancel(self._fade_out_after)
            self._fade_out_after = None
            
        if immediate and self.tw:
            try:
                self.tw.destroy()
            except Exception:
                pass
            self.tw = None
        elif self.tw:
            # The tooltip toplevel can be destroyed externally (e.g. app
            # teardown) between scheduling and this call; guard the Tcl
            # attribute read so <Leave> handlers can never raise TclError.
            try:
                if self.tw.winfo_exists():
                    self._fade_out(self.tw.attributes("-alpha"))
                else:
                    self.tw = None
            except Exception:
                self.tw = None
            
    def _fade_out(self, alpha):
        if not self.tw or not self.tw.winfo_exists(): return
        alpha -= 0.3
        if alpha <= 0.0:
            self.tw.destroy()
            self.tw = None
        else:
            self.tw.wm_attributes("-alpha", alpha)
            self._fade_out_after = self.app.after(15, self._fade_out, alpha)


class BaseDialog(ctk.CTkToplevel):
    def __init__(self, master, title, width, height):
        super().__init__(master)
        self.title(title)
        self.geometry(f"{width}x{height}")
        self.transient(master)
        # grab_set() raises TclError on some platforms/window managers when
        # the toplevel is not viewable yet; retry once it is mapped instead
        # of crashing the dialog-open path.
        try:
            self.grab_set()
        except Exception:
            self.after(50, self._retry_grab)
        self.configure(fg_color=Color.CARD_BG)
        
        icon_path = resource_path("vocab_icon.ico")
        if os.path.exists(icon_path):
            self.after(200, lambda: self.iconbitmap(icon_path) if self.winfo_exists() else None)

    def _retry_grab(self):
        try:
            if self.winfo_exists():
                self.grab_set()
        except Exception:
            pass


class StyledConfirmDialog(BaseDialog):
    def __init__(self, master, title, message, confirm_text="Confirm", danger=False):
        super().__init__(master, title, 450, 220)
        self.result = False
        
        content = ctk.CTkFrame(self, fg_color="transparent")
        content.pack(fill="both", expand=True, padx=30, pady=30)
        
        ctk.CTkLabel(content, text=title, font=Font.base(18, "bold"), text_color=Color.TEXT_PRIMARY).pack(anchor="w", pady=(0, 10))
        ctk.CTkLabel(content, text=message, font=Font.base(14), text_color=Color.TEXT_SECONDARY, wraplength=390, justify="left").pack(anchor="w")
        
        btn_frame = ctk.CTkFrame(self, fg_color="transparent")
        btn_frame.pack(fill="x", side="bottom", padx=30, pady=25)
        
        action_color = Color.DANGER if danger else Color.ACCENT
        
        ctk.CTkButton(
            btn_frame, text=confirm_text, fg_color=action_color, hover_color=action_color, 
            text_color="#FFFFFF", font=Font.base(13, "bold"), corner_radius=6, 
            command=self._confirm, width=110, height=36
        ).pack(side="right", padx=(10, 0))
        
        ctk.CTkButton(
            btn_frame, text="Cancel", fg_color="transparent", hover_color=Color.HOVER_BG, 
            text_color=Color.TEXT_PRIMARY, font=Font.base(13), corner_radius=6, 
            border_width=1, border_color=Color.BORDER, command=self._cancel, width=90, height=36
        ).pack(side="right")

    def _confirm(self):
        self.result = True
        self.destroy()

    def _cancel(self):
        self.result = False
        self.destroy()


class StyledInputDialog(BaseDialog):
    def __init__(self, master, title, placeholder=""):
        super().__init__(master, title, 420, 210)
        self.result = None
        
        content = ctk.CTkFrame(self, fg_color="transparent")
        content.pack(fill="both", expand=True, padx=30, pady=30)
        
        ctk.CTkLabel(content, text=title, font=Font.base(16, "bold"), text_color=Color.TEXT_PRIMARY).pack(anchor="w", pady=(0, 15))
        
        self.entry = ctk.CTkEntry(
            content, placeholder_text=placeholder, font=Font.base(14), fg_color=Color.INPUT_BG, 
            border_color=Color.BORDER, border_width=1, corner_radius=6, height=40, width=360
        )
        master.apply_focus_ring(self.entry)
        self.entry.pack(anchor="w")
        self.entry.focus_set()
        
        btn_frame = ctk.CTkFrame(self, fg_color="transparent")
        btn_frame.pack(fill="x", side="bottom", padx=30, pady=25)
        
        ctk.CTkButton(
            btn_frame, text="Save", fg_color=Color.ACCENT, hover_color=Color.ACCENT_HOVER, 
            text_color="#FFFFFF", font=Font.base(13, "bold"), corner_radius=6, 
            command=self._confirm, width=100, height=36
        ).pack(side="right", padx=(10, 0))
        
        ctk.CTkButton(
            btn_frame, text="Cancel", fg_color="transparent", hover_color=Color.HOVER_BG, 
            text_color=Color.TEXT_PRIMARY, font=Font.base(13), corner_radius=6, 
            border_width=1, border_color=Color.BORDER, command=self.destroy, width=90, height=36
        ).pack(side="right")
        
        self.bind("<Return>", lambda e: self._confirm())

    def _confirm(self):
        self.result = self.entry.get()
        self.destroy()


class DuplicateDialog(BaseDialog):
    def __init__(self, master, word):
        super().__init__(master, "Duplicate Detected", 500, 200)
        self.result = "cancel"
        
        content = ctk.CTkFrame(self, fg_color="transparent")
        content.pack(fill="both", expand=True, padx=30, pady=30)
        
        msg = f"The word '{word.capitalize()}' is already in your notebook."
        ctk.CTkLabel(content, text=msg, font=Font.base(15, "bold"), text_color=Color.TEXT_PRIMARY).pack(pady=(5, 20))
        
        btn_frame = ctk.CTkFrame(content, fg_color="transparent")
        btn_frame.pack(fill="x", pady=10)
        
        ctk.CTkButton(
            btn_frame, text="Open Entry", fg_color=Color.ACCENT, hover_color=Color.ACCENT_HOVER, 
            text_color="#FFFFFF", font=Font.base(13, "bold"), corner_radius=6, height=36,
            command=lambda: self.set_result("open")
        ).pack(side="left", padx=(0, 10), expand=True, fill="x")
                      
        ctk.CTkButton(
            btn_frame, text="Replace", fg_color="transparent", hover_color=Color.HOVER_BG, 
            text_color=Color.DANGER, font=Font.base(13, "bold"), corner_radius=6, height=36,
            border_width=1, border_color=Color.DANGER, command=lambda: self.set_result("replace")
        ).pack(side="left", padx=(0, 10), expand=True, fill="x")
                      
        ctk.CTkButton(
            btn_frame, text="Cancel", fg_color="transparent", hover_color=Color.HOVER_BG, 
            text_color=Color.TEXT_PRIMARY, font=Font.base(13, "bold"), corner_radius=6, height=36,
            border_width=1, border_color=Color.BORDER, command=lambda: self.set_result("cancel")
        ).pack(side="left", expand=True, fill="x")
        
    def set_result(self, res):
        self.result = res
        self.destroy()


class ExportSelectionDialog(BaseDialog):
    def __init__(self, master, current_vol_id, all_volumes):
        super().__init__(master, "Export Notebook", 440, 260)
        self.result = None
        self.export_type = tk.StringVar(value="current")
        
        content = ctk.CTkFrame(self, fg_color="transparent")
        content.pack(fill="both", expand=True, padx=35, pady=30)
        
        ctk.CTkLabel(content, text="Select Export Scope", font=Font.base(16, "bold"), text_color=Color.TEXT_PRIMARY).pack(anchor="w", pady=(0, 15))
        
        rb_frame = ctk.CTkFrame(content, fg_color="transparent")
        rb_frame.pack(fill="x")
        
        ctk.CTkRadioButton(
            rb_frame, text="Active Volume Only", variable=self.export_type, value="current", 
            font=Font.base(14), text_color=Color.TEXT_PRIMARY, fg_color=Color.ACCENT, 
            hover_color=Color.ACCENT_HOVER, border_color=Color.BORDER
        ).pack(anchor="w", pady=10)
                           
        ctk.CTkRadioButton(
            rb_frame, text="Entire Notebook", variable=self.export_type, value="all", 
            font=Font.base(14), text_color=Color.TEXT_PRIMARY, fg_color=Color.ACCENT, 
            hover_color=Color.ACCENT_HOVER, border_color=Color.BORDER
        ).pack(anchor="w", pady=10)
        
        btn_frame = ctk.CTkFrame(content, fg_color="transparent")
        btn_frame.pack(fill="x", side="bottom", padx=35, pady=25)
        
        ctk.CTkButton(
            btn_frame, text="Export", fg_color=Color.ACCENT, hover_color=Color.ACCENT_HOVER, 
            text_color="#FFFFFF", font=Font.base(13, "bold"), corner_radius=6, height=36, command=self.confirm
        ).pack(side="right", padx=(10, 0))
        
        ctk.CTkButton(
            btn_frame, text="Cancel", fg_color="transparent", hover_color=Color.HOVER_BG, 
            text_color=Color.TEXT_PRIMARY, font=Font.base(13), corner_radius=6, height=36,
            border_width=1, border_color=Color.BORDER, command=self.destroy
        ).pack(side="right")
            
    def confirm(self):
        self.result = {'type': self.export_type.get()}
        self.destroy()


class ImportDuplicateDialog(BaseDialog):
    def __init__(self, master, word):
        super().__init__(master, "Duplicate Found", 600, 200)
        # Closing this dialog with the window's X button now aborts the rest
        # of the import: the "cancel" branch in _process_import_chunk was
        # previously unreachable, leaving large imports impossible to stop.
        self.result = "cancel"
        
        content = ctk.CTkFrame(self, fg_color="transparent")
        content.pack(fill="both", expand=True, padx=30, pady=30)
        
        ctk.CTkLabel(content, text=f"'{word.capitalize()}' already exists. Action?", font=Font.base(15, "bold"), text_color=Color.TEXT_PRIMARY).pack(pady=(0, 20))
                     
        btn_frame = ctk.CTkFrame(content, fg_color="transparent")
        btn_frame.pack(fill="x")
        
        ctk.CTkButton(
            btn_frame, text="Replace", fg_color="transparent", hover_color=Color.HOVER_BG, 
            text_color=Color.DANGER, font=Font.base(13, "bold"), corner_radius=6, height=36,
            border_width=1, border_color=Color.DANGER, command=lambda: self.set_result("replace")
        ).pack(side="left", padx=5, expand=True, fill="x")
                      
        ctk.CTkButton(
            btn_frame, text="Skip", fg_color="transparent", hover_color=Color.HOVER_BG, 
            text_color=Color.TEXT_PRIMARY, font=Font.base(13, "bold"), corner_radius=6, height=36,
            border_width=1, border_color=Color.BORDER, command=lambda: self.set_result("skip")
        ).pack(side="left", padx=5, expand=True, fill="x")
                      
        ctk.CTkButton(
            btn_frame, text="Replace All", fg_color=Color.DANGER, hover_color=Color.DANGER, 
            text_color="#FFFFFF", font=Font.base(13, "bold"), corner_radius=6, height=36,
            command=lambda: self.set_result("replace_all")
        ).pack(side="left", padx=5, expand=True, fill="x")
                      
        ctk.CTkButton(
            btn_frame, text="Skip All", fg_color="transparent", hover_color=Color.HOVER_BG, 
            text_color=Color.TEXT_PRIMARY, font=Font.base(13, "bold"), corner_radius=6, height=36,
            border_width=1, border_color=Color.BORDER, command=lambda: self.set_result("skip_all")
        ).pack(side="left", padx=5, expand=True, fill="x")
        
    def set_result(self, res):
        self.result = res
        self.destroy()


# =======================================================================
# MODULE 4: UNIFIED CANVAS RENDER ENGINE (Inline Layout)
# =======================================================================
class CardRenderer:
    def __init__(self, list_view, app, canvas, edit_widgets_dict, z_factor):
        self.list_view = list_view
        self.app = app
        self.canvas = canvas
        self.edit_widgets = edit_widgets_dict
        
        # Eliminates hundreds of DPI OS calls by using pre-evaluated multiplier
        self._z_factor = z_factor
        
        icon_size = 28 
        target_size = self._qz(icon_size)
        
        # Uses global app cache. Zero disk reads or Lanczos resizing during standard renders.
        self.icon_edit = self.app.get_icon("edit", target_size)
        self.icon_edit_hover = self.app.get_icon("edit_hover", target_size)
        self.icon_refresh = self.app.get_icon("refresh", target_size)
        self.icon_refresh_hover = self.app.get_icon("refresh_hover", target_size)
        self.icon_delete = self.app.get_icon("delete", target_size)
        self.icon_delete_hover = self.app.get_icon("delete_hover", target_size)
        self.icon_mic = self.app.get_icon("mic", target_size)
        self.icon_mic_hover = self.app.get_icon("mic_hover", target_size)

    def _bind_tag(self, safe_word, tag_or_id, seq, func):
        """Registers a canvas binding and records its Tcl command id so the
        list view can release it when the card's items are deleted. tag_bind
        never deregisters the previous command when a tag is rebound, so
        without this bookkeeping every card redraw leaks a command + closure."""
        funcid = self.canvas.tag_bind(tag_or_id, seq, func)
        self.list_view._tag_bind_ids.setdefault(safe_word, []).append((tag_or_id, seq, funcid))
        return funcid

    def _line_metrics(self, font_tuple):
        """Uses App-level font cache (LRU-bounded). Zero tkfont object instantiations after first draw."""
        cache = self.app.font_metrics_cache
        if font_tuple in cache:
            cache.move_to_end(font_tuple)
            return cache[font_tuple]
        tkf = tkfont.Font(root=self.canvas, font=font_tuple)
        m = tkf.metrics()
        cache[font_tuple] = (m['ascent'], m['descent'], m['linespace'])
        if len(cache) > 48:
            try:
                cache.popitem(last=False)
            except Exception:
                pass
        return cache[font_tuple]

    def _text_width(self, text, font_tuple):
        """Uses App-level font object cache (LRU-bounded). Eliminates canvas draw/destroy ops for measuring tags."""
        cache = self.app.font_obj_cache
        if font_tuple in cache:
            cache.move_to_end(font_tuple)
        else:
            cache[font_tuple] = tkfont.Font(root=self.canvas, font=font_tuple)
            if len(cache) > 48:
                try:
                    cache.popitem(last=False)
                except Exception:
                    pass
        return cache[font_tuple].measure(text)

    def _wrapped_line_count(self, text, font_tuple, wrap_w):
        # Estimate how many visual lines Tk wraps `text` into at pixel width
        # `wrap_w`, mirroring Tk's greedy word-break so this pre-layout estimate
        # matches the height _draw_prop_row actually produces (measured via
        # canvas.bbox). Uses the shared LRU font-width cache, so it stays cheap.
        if not text or wrap_w <= 0:
            return 1
        space_w = self._text_width(" ", font_tuple)
        total = 0
        for para in text.split("\n"):
            # Fast path: a single measure call resolves the common case of a
            # paragraph that fits on one visual line, skipping the per-chunk
            # loop (and its many Tcl round-trips). This is what keeps full
            # relayouts affordable on large notebooks.
            if self._text_width(para, font_tuple) <= wrap_w:
                total += 1
                continue
            line_w = 0
            lines = 1
            for chunk in para.split(" "):
                cw = self._text_width(chunk, font_tuple)
                add = cw if line_w == 0 else space_w + cw
                if line_w != 0 and line_w + add > wrap_w:
                    lines += 1
                    line_w = cw
                else:
                    line_w += add
                if line_w > wrap_w and cw > wrap_w:
                    extra = int(math.ceil(cw / wrap_w)) - 1
                    if extra > 0:
                        lines += extra
                        line_w = cw - extra * wrap_w
                        if line_w < 0:
                            line_w = 0
            total += lines
        return max(1, total)

    def _z(self, val):
        """Pure math mapping. Zero lag."""
        return int(val * self._z_factor)

    def _qz(self, val):
        """Quantized zoom for font sizes — collapses drag-intermediate sizes into 2px buckets."""
        q = int(val * self._z_factor)
        return max(4, (q // 2) * 2)

    def _create_round_rect(self, x1, y1, x2, y2, radius, **kwargs):
        r = max(1, radius)
        points = [
            x1+r, y1, x1+r, y1, x2-r, y1, x2-r, y1, 
            x2, y1, x2, y1+r, x2, y1+r, x2, y2-r, 
            x2, y2-r, x2, y2, x2-r, y2, x2-r, y2, 
            x1+r, y2, x1+r, y2, x1, y2, x1, y2-r, 
            x1, y2-r, x1, y1+r, x1, y1+r, x1, y1
        ]
        return self.canvas.create_polygon(points, smooth=True, **kwargs)

    def _update_round_rect(self, item_id, x1, y1, x2, y2, radius):
        r = max(1, radius)
        points = [
            x1+r, y1, x1+r, y1, x2-r, y1, x2-r, y1, 
            x2, y1, x2, y1+r, x2, y1+r, x2, y2-r, 
            x2, y2-r, x2, y2, x2-r, y2, x2-r, y2, 
            x1+r, y2, x1+r, y2, x1, y2, x1, y2-r, 
            x1, y2-r, x1, y1+r, x1, y1+r, x1, y1
        ]
        self.canvas.coords(item_id, *points)

    def _draw_star(self, cx, cy, r_out, r_in, filled, color, tags):
        points = []
        for i in range(10):
            r = r_out if i % 2 == 0 else r_in
            angle = math.radians(i * 36 - 90)
            x = cx + r * math.cos(angle)
            y = cy + r * math.sin(angle)
            points.extend([x, y])
        return self.canvas.create_polygon(points, fill=color if filled else "", outline=color, width=1.5, tags=tags)

    def _draw_inline_tags(self, start_x, start_y, max_w, items_str, important_str, word, field_key, safe_word, font_size_key, callbacks):
        curr_x = start_x
        curr_y = start_y
        
        items = [s.strip() for s in items_str.split(',') if s.strip()]
        important_items = set(s.strip().lower() for s in important_str.split(',') if s.strip())

        if not items: 
            return start_y

        card_tag = f"card_{safe_word}"
        font_val = self.app.font_sizes.get(font_size_key, 12)
        fs = self._qz(font_val)

        font_norm = Font.base(fs, "normal")
        font_bold = Font.base(fs, "bold")
        _, _, line_height = self._line_metrics(font_norm)
        
        pad_y = self._z(2)
        row_h = line_height + (pad_y * 2)

        for i, item in enumerate(items):
            is_imp = item.lower() in important_items
            suffix = "" if i == len(items) - 1 else ", "
            
            text_color = Color.ACCENT if is_imp else Color.TEXT_SECONDARY
            active_font = font_bold if is_imp else font_norm
            disp = item + suffix
            
            tw = self._text_width(disp, active_font)
            
            if curr_x + tw > start_x + max_w and curr_x != start_x:
                curr_x = start_x
                curr_y += row_h
                
            ptag = f"tag_{safe_word}_{field_key}_{i}"
            
            t_id = self.canvas.create_text(
                curr_x, curr_y + pad_y, text=disp, font=active_font, 
                fill=text_color, anchor="nw", tags=(card_tag, ptag, "clickable")
            )
            
            if callbacks and callbacks.get('toggle_tag'):
                def on_enter(e, t=t_id):
                    self.canvas.itemconfig(t, fill=Color.TEXT_PRIMARY)
                    self.canvas.config(cursor="hand2")
                    
                def on_leave(e, t=t_id, orig=text_color):
                    self.canvas.itemconfig(t, fill=orig)
                    self.canvas.config(cursor="")
                    
                def on_click(e, w=word, k=field_key, val=item, ci=important_str):
                    callbacks['toggle_tag'](w, k, val, ci)

                self._bind_tag(safe_word, ptag, "<Enter>", on_enter)
                self._bind_tag(safe_word, ptag, "<Leave>", on_leave)
                self._bind_tag(safe_word, ptag, "<Button-1>", on_click)
                
            curr_x += tw + self._z(4)

        return curr_y + row_h

    def _draw_prop_row(self, label, key, w_data, x1, curr_y, max_x, is_edit, custom_font="Segoe UI", is_tag_list=False, safe_word=None, callbacks=None):
        value = w_data.get(key, "") or ""
        if not is_edit and not value: 
            return curr_y 

        card_tag = f"card_{safe_word}"
        
        font_size_key = f"{key.replace('_meaning', '').replace('_sentence', '')}_size"
        scaled_font_size = self._qz(self.app.font_sizes.get(font_size_key, 12))
        label_font = Font.base(scaled_font_size, "bold")
        
        label_x = x1 + self._z(25)
        self.canvas.create_text(
            label_x, curr_y, text=label, font=label_font, 
            fill=Color.TEXT_SECONDARY, anchor="nw", tags=card_tag
        )

        val_x = x1 + self._z(160)
        val_w = max(100, max_x - val_x - self._z(25))
        # Negative gaps are allowed (slider goes down to -20 px) to pull the
        # following row closer; draw and height-estimation paths share this.
        user_gap = self._z(self.app.spacings.get(f"{key}_gap", 0))
        
        if is_edit:
            if is_tag_list or key == 'notes':
                widget = ctk.CTkTextbox(
                    self.canvas, width=val_w, height=self._z(70), 
                    fg_color=Color.INPUT_BG, text_color=Color.TEXT_PRIMARY, 
                    font=Font.base(scaled_font_size), border_width=1, 
                    border_color=Color.BORDER, corner_radius=6
                )
                draft_val = self.list_view._edit_draft.get(f"{w_data['word']}_{key}")
                widget.insert("1.0", value if draft_val is None else draft_val)
                self.canvas.create_window(val_x, curr_y, anchor="nw", window=widget, tags=card_tag)
                self.edit_widgets[f"{w_data['word']}_{key}"] = widget
                return curr_y + self._z(70) + user_gap
            else:
                widget = ctk.CTkEntry(
                    self.canvas, width=val_w, fg_color=Color.INPUT_BG, 
                    text_color=Color.TEXT_PRIMARY, font=(custom_font, scaled_font_size), 
                    border_width=1, border_color=Color.BORDER, height=self._z(36),
                    corner_radius=6
                )
                self.app.apply_focus_ring(widget)
                draft_val = self.list_view._edit_draft.get(f"{w_data['word']}_{key}")
                widget.insert(0, value if draft_val is None else draft_val)
                self.canvas.create_window(val_x, curr_y, anchor="nw", window=widget, tags=card_tag)
                self.edit_widgets[f"{w_data['word']}_{key}"] = widget
                return curr_y + self._z(36) + user_gap
        else:
            if is_tag_list:
                imp_key = w_data.get(f'important_{key}', "") or ""
                actual_h = self._draw_inline_tags(
                    val_x, curr_y, val_w, value, imp_key, w_data['word'], 
                    key, safe_word, font_size_key, callbacks or {}
                )
                row_h = max(self._z(24), actual_h - curr_y)
                return curr_y + row_h + user_gap
            else:
                font_tuple = Font.base(scaled_font_size) if custom_font == "Segoe UI" else (custom_font, scaled_font_size)
                _, _, line_height = self._line_metrics(font_tuple)
                
                t_id = self.canvas.create_text(
                    val_x, curr_y, text=value, font=font_tuple, width=val_w, 
                    fill=Color.TEXT_SECONDARY, anchor="nw", tags=card_tag
                )
                bbox = self.canvas.bbox(t_id)
                actual_h = (bbox[3] - bbox[1]) if bbox else line_height
                
                row_h = max(self._z(24), actual_h)
                return curr_y + row_h + user_gap

    def _draw_icon_action(self, x_right, y_center, icon_img, icon_hover_img, fallback_char, tooltip_text, command, word, safe_word):
        hit_w = self._z(34)
        hit_h = self._z(32)
        x_left = x_right - hit_w
        
        action_tag = f"action_{fallback_char}_{safe_word}"
        card_tag = f"card_{safe_word}"
        
        bg_id = self._create_round_rect(
            x_left, y_center - hit_h//2, x_left + hit_w, y_center + hit_h//2, 
            radius=self._z(6), fill="", outline="", tags=(action_tag, card_tag, "clickable")
        )
        
        if icon_img:
            item_id = self.canvas.create_image(
                x_left + (hit_w//2), y_center, image=icon_img, 
                tags=(action_tag, card_tag, "clickable"), state="hidden"
            )
        else:
            item_id = self.canvas.create_text(
                x_left + (hit_w//2), y_center, text=fallback_char, font=Font.base(self._qz(22)), 
                fill=Color.TEXT_SECONDARY, tags=(action_tag, card_tag, "clickable"), state="hidden"
            )

        if safe_word not in self.list_view.card_action_ids:
            self.list_view.card_action_ids[safe_word] = []
        self.list_view.card_action_ids[safe_word].extend([item_id, bg_id])

        if command:
            def on_click(e, cmd=command, w=word): 
                self.app.tooltip_manager.hide(immediate=True)
                cmd(w)
                
            def on_enter(e, i_id=item_id, h_img=icon_hover_img, b_id=bg_id, has_img=bool(icon_img)):
                self.canvas.itemconfig(b_id, fill=Color.HOVER_BG)
                
                if has_img and h_img:
                    self.canvas.itemconfig(i_id, image=h_img)
                elif not has_img:
                    self.canvas.itemconfig(i_id, fill=Color.ACCENT)
                
                self.canvas.config(cursor="hand2")
                
                coords = self.canvas.coords(b_id)
                if coords:
                    cx_canvas = (coords[0] + coords[2]) / 2
                    top_y_canvas = coords[1]
                    icon_h = coords[3] - coords[1]
                    
                    screen_x = self.canvas.winfo_rootx() + int(cx_canvas - self.canvas.canvasx(0))
                    screen_y = self.canvas.winfo_rooty() + int(top_y_canvas - self.canvas.canvasy(0))
                    
                    self.app.tooltip_manager.show(tooltip_text, screen_x, screen_y, icon_h)
                
            def on_leave(e, i_id=item_id, n_img=icon_img, b_id=bg_id, has_img=bool(icon_img)):
                self.canvas.itemconfig(b_id, fill="")
                
                if has_img and n_img:
                    self.canvas.itemconfig(i_id, image=n_img)
                elif not has_img:
                    self.canvas.itemconfig(i_id, fill=Color.TEXT_SECONDARY)
                    
                self.canvas.config(cursor="")
                self.app.tooltip_manager.hide()

            self._bind_tag(safe_word, action_tag, "<Button-1>", on_click)
            self._bind_tag(safe_word, action_tag, "<Enter>", on_enter)
            self._bind_tag(safe_word, action_tag, "<Leave>", on_leave)

        return x_left - self._z(4)

    def _draw_text_action(self, x_right, y_center, text, default_color, hover_color, command, word, safe_word):
        font_tuple = Font.base(self._qz(14), "bold")
        tw = self._text_width(text, font_tuple)

        x_left = x_right - tw
        action_tag = f"action_{text}_{safe_word}"
        card_tag = f"card_{safe_word}"
        pad_x, pad_y = self._z(14), self._z(10)

        bg_id = self._create_round_rect(
            x_left - pad_x, y_center - pad_y, x_right + pad_x, y_center + pad_y, 
            radius=self._z(8), fill=default_color if default_color != Color.TEXT_SECONDARY else "", 
            outline="", tags=(action_tag, card_tag, "clickable")
        )
        
        text_id = self.canvas.create_text(
            x_left + tw//2, y_center, text=text, font=font_tuple, 
            fill="#FFFFFF" if default_color != Color.TEXT_SECONDARY else Color.TEXT_PRIMARY, 
            tags=(action_tag, card_tag, "clickable")
        )

        if command:
            self._bind_tag(safe_word, action_tag, "<Button-1>", lambda e: command(word))
            self._bind_tag(safe_word, action_tag, "<Enter>", lambda e: [self.canvas.itemconfig(bg_id, fill=hover_color), self.canvas.config(cursor="hand2")])
            self._bind_tag(safe_word, action_tag, "<Leave>", lambda e: [self.canvas.itemconfig(bg_id, fill=default_color if default_color != Color.TEXT_SECONDARY else ""), self.canvas.config(cursor="")])

        return x_left - pad_x - self._z(8)

    def draw_card(self, y_start, w_data, width, is_edit, is_selected=False, callbacks=None):
        if callbacks is None:
            callbacks = {}
            
        word = w_data['word']
        safe_word = hashlib.md5(word.lower().encode()).hexdigest()[:12]
        
        x1 = self._z(30)
        x2 = max(x1 + self._z(300), width - self._z(30))
        
        card_tag = f"card_{safe_word}"
        corner_rad = self._z(8) 
        
        hl_color = Color.ACCENT if is_selected else Color.BORDER
        hl_width = 2 if is_selected else 1
        
        bg_id = self._create_round_rect(
            x1, y_start, x2, y_start+self._z(80), 
            radius=corner_rad, fill=Color.CARD_BG, 
            outline=hl_color, width=hl_width, tags=card_tag
        )
        
        header_y_center = y_start + self._z(40) 
        
        is_fav = bool(w_data.get('is_favorite', 0))
        fav_color = Color.STAR if is_fav else Color.BORDER
        star_id = self._draw_star(x1 + self._z(25), header_y_center, self._z(10), self._z(4), is_fav, fav_color, (card_tag, "clickable"))
        
        if callbacks.get('fav'):
            self._bind_tag(safe_word, star_id, "<Button-1>", lambda e, w=word: callbacks['fav'](w))
            self._bind_tag(safe_word, star_id, "<Enter>", lambda e: self.canvas.config(cursor="hand2"))
            self._bind_tag(safe_word, star_id, "<Leave>", lambda e: self.canvas.config(cursor=""))

        title_size = self._qz(self.app.font_sizes.get('title_size', 20))
        title_font = Font.base(title_size, "bold")
        title_id = self.canvas.create_text(
            x1 + self._z(55), header_y_center, text=word.capitalize(), 
            font=title_font, fill=Color.TEXT_PRIMARY, anchor="w", tags=card_tag
        )
        
        title_bbox = self.canvas.bbox(title_id)
        if title_bbox:
            current_x = title_bbox[2] + self._z(16)
        else:
            current_x = x1 + self._z(120)

        ipa = w_data.get('ipa', '').strip()
        if ipa:
            ipa_font = Font.base(self._qz(13), "italic")
            ipa_id = self.canvas.create_text(
                current_x, header_y_center, text=f"/{ipa}/", 
                font=ipa_font, fill=Color.TEXT_SECONDARY, anchor="w", tags=card_tag
            )
            ipa_bbox = self.canvas.bbox(ipa_id)
            if ipa_bbox:
                current_x = ipa_bbox[2] + self._z(16)
            else:
                current_x = current_x + self._z(70)

        pos = w_data.get('part_of_speech', '').strip()
        if pos:
            pos_font = Font.base(self._qz(12), "bold")
            self.canvas.create_text(
                current_x, header_y_center, text=pos.lower(), 
                font=pos_font, fill=Color.ACCENT, anchor="w", tags=card_tag
            )

        btn_x = x2 - self._z(20)
        
        if is_edit:
            self.list_view.card_action_ids[safe_word] = []
            btn_x = self._draw_text_action(btn_x, header_y_center, "Save", Color.SUCCESS, Color.SUCCESS, callbacks.get('save'), word, safe_word)
            btn_x = self._draw_text_action(btn_x, header_y_center, "Cancel", Color.TEXT_SECONDARY, Color.HOVER_BG, callbacks.get('cancel'), word, safe_word)
        elif not self.list_view.is_preview:
            btn_x = self._draw_icon_action(btn_x, header_y_center, self.icon_delete, self.icon_delete_hover, "🗑", "Delete", callbacks.get('delete'), word, safe_word)
            btn_x = self._draw_icon_action(btn_x, header_y_center, self.icon_refresh, self.icon_refresh_hover, "↻", "Refresh", callbacks.get('refresh'), word, safe_word)
            btn_x = self._draw_icon_action(btn_x, header_y_center, self.icon_edit, self.icon_edit_hover, "✎", "Edit", callbacks.get('edit'), word, safe_word)
            btn_x = self._draw_icon_action(btn_x, header_y_center, self.icon_mic, self.icon_mic_hover, "🔊", "Pronounce", callbacks.get('pronounce'), word, safe_word)

        title_gap = self.app.spacings.get('title_gap', 44)
        curr_y = header_y_center + self._z(title_gap)
        
        props = [
            ("Meaning", 'meaning', "Segoe UI", False),
            ("Bangla", 'bangla_meaning', Font._BANGLA_FAMILY, False),
            ("Example", 'example_sentence', "Segoe UI", False),
            ("Synonyms", 'synonyms', "Segoe UI", True),
            ("Antonyms", 'antonyms', "Segoe UI", True),
            ("Notes", 'notes', "Segoe UI", False)
        ]

        for label, key, font_name, is_tag in props:
            val = w_data.get(key, "") or ""
            if is_edit or val:
                curr_y = self._draw_prop_row(
                    label, key, w_data, x1, curr_y, x2, is_edit, 
                    custom_font=font_name, is_tag_list=is_tag, 
                    safe_word=safe_word, callbacks=callbacks
                )

        curr_y += self._z(self.app.spacings.get('card_padding_bottom', 8))

        if curr_y < y_start + self._z(130):
            curr_y = y_start + self._z(130)

        self._update_round_rect(bg_id, x1, y_start, x2, curr_y, radius=corner_rad)
        self.list_view.card_bboxes[safe_word] = (x1, y_start, x2, curr_y)
        
        return bg_id, bg_id, curr_y

    def compute_card_height(self, y_start, w_data, width, is_edit):
        word = w_data['word']
        
        x1 = self._z(30)
        x2 = max(x1 + self._z(300), width - self._z(30))
        
        header_y_center = y_start + self._z(40) 
        title_gap = self.app.spacings.get('title_gap', 44)
        curr_y = header_y_center + self._z(title_gap)
        
        props = [
            ("Meaning", 'meaning', "Segoe UI", False),
            ("Bangla", 'bangla_meaning', Font._BANGLA_FAMILY, False),
            ("Example", 'example_sentence', "Segoe UI", False),
            ("Synonyms", 'synonyms', "Segoe UI", True),
            ("Antonyms", 'antonyms', "Segoe UI", True),
            ("Notes", 'notes', "Segoe UI", False)
        ]

        for label, key, font_name, is_tag in props:
            value = w_data.get(key, "") or ""
            if is_edit or value:
                curr_y = self._calc_prop_row_height(key, w_data, x1, curr_y, x2, is_edit, custom_font=font_name, is_tag_list=is_tag)

        curr_y += self._z(self.app.spacings.get('card_padding_bottom', 8))

        if curr_y < y_start + self._z(130):
            curr_y = y_start + self._z(130)

        return curr_y

    def _calc_prop_row_height(self, key, w_data, x1, curr_y, max_x, is_edit, custom_font="Segoe UI", is_tag_list=False):
        value = w_data.get(key, "") or ""
        if not is_edit and not value: 
            return curr_y 

        font_size_key = f"{key.replace('_meaning', '').replace('_sentence', '')}_size"
        scaled_font_size = self._qz(self.app.font_sizes.get(font_size_key, 12))
        
        val_x = x1 + self._z(160)
        val_w = max(100, max_x - val_x - self._z(25))
        # Negative gaps are allowed (slider goes down to -20 px) to pull the
        # following row closer; draw and height-estimation paths share this.
        user_gap = self._z(self.app.spacings.get(f"{key}_gap", 0))
        
        if is_edit:
            if is_tag_list or key == 'notes':
                return curr_y + self._z(70) + user_gap
            else:
                return curr_y + self._z(36) + user_gap
        else:
            if is_tag_list:
                items_str = value
                items = [s.strip() for s in items_str.split(',') if s.strip()]
                imp_str = w_data.get(f"important_{key}", "") or ""
                important_items = set(s.strip().lower() for s in imp_str.split(',') if s.strip())

                if not items: 
                    return curr_y + user_gap

                font_val = self.app.font_sizes.get(font_size_key, 12)
                fs = self._qz(font_val)
                font_norm = Font.base(fs, "normal")
                font_bold = Font.base(fs, "bold")
                _, _, line_height = self._line_metrics(font_norm)
                pad_y = self._z(2)
                row_h = line_height + (pad_y * 2)

                curr_x = val_x
                rows = 1
                for i, item in enumerate(items):
                    suffix = "" if i == len(items) - 1 else ", "
                    active_font = font_bold if item.lower() in important_items else font_norm
                    disp = item + suffix
                    tw = self._text_width(disp, active_font)
                    
                    if curr_x + tw > val_x + val_w and curr_x != val_x:
                        curr_x = val_x
                        rows += 1
                    curr_x += tw + self._z(4)

                actual_h = (rows * row_h)
                row_h_final = max(self._z(24), actual_h)
                return curr_y + row_h_final + user_gap
            else:
                font_tuple = Font.base(scaled_font_size) if custom_font == "Segoe UI" else (custom_font, scaled_font_size)
                _, _, line_height = self._line_metrics(font_tuple)
                
                lines = self._wrapped_line_count(value, font_tuple, val_w)
                actual_h = lines * line_height
                
                row_h = max(self._z(24), actual_h)
                return curr_y + row_h + user_gap


# =======================================================================
# MODULE 5: PAGE LAYOUTS (List Rendering Engine)
# =======================================================================
class WordListView(ctk.CTkFrame):
    def __init__(self, master, app, is_preview=False):
        super().__init__(master, fg_color="transparent", corner_radius=0)
        self.app = app
        self.is_preview = is_preview
        
        self.preview_scale = 1.0 
        
        self.words = []
        self.editing_word = None
        self.edit_widgets = {}
        self._edit_draft = {} 
        
        self.card_y_positions = {}
        self.card_bg_ids = {}
        self.card_highlight_ids = {}
        self.card_action_ids = {}
        self._resize_timer = None
        # Startup-glitch fix: explicit layout validity. _update_viewport()
        # may only draw once _compute_layout() has produced offsets/heights
        # for the CURRENT word list at the CURRENT geometry. Set True only
        # by a successful _compute_layout(); cleared whenever the word list
        # changes or usable geometry is lost.
        self._layout_valid = False
        # True once render() has completed with usable geometry. Used by
        # _on_configure to render the first valid frame immediately instead
        # of waiting out the resize debounce.
        self._has_rendered = False
        self._last_render_size = (0, 0)
        self._awaiting_first_visible_configure = False
        
        self.row_heights = {}
        self.row_offsets = {}
        self.visible_words = set()
        self._height_cache = {}
        self._height_cache_sig = None
        # Last exact layout: (z_factor, width, {content_key: height},
        # layout_version). Lets live zoom scale heights arithmetically
        # instead of re-measuring text on every slider tick.
        self._exact_layout_snapshot = None
        self._layout_is_approx = False
        # H1: chunked background height-measurement pass for very large lists.
        self._bg_measure_timer = None
        self._estimated_words = set()
        self._ordered_words = []
        self._ordered_tops = []
        self._ordered_bottoms = []
        
        self.selected_index = -1 
        self.card_bboxes = {}
        self._current_hover = None
        self._word_index = {}
        self._tag_bind_ids = {}

        self._cached_z_factor = 1.0
        
        self.canvas_bg = Color.CARD_BG if is_preview else Color.APP_BG
        self.canvas = tk.Canvas(self, bg=self.canvas_bg, highlightthickness=0)
        
        self.scrollbar_y = ctk.CTkScrollbar(
            self, width=12, command=self._scroll_command, 
            fg_color="transparent", button_color=Color.BORDER, 
            button_hover_color=Color.TEXT_MUTED
        )
        self.canvas.configure(yscrollcommand=self.scrollbar_y.set)
        self.canvas.pack(side="left", fill="both", expand=True)
        
        if not self.is_preview:
            self.scrollbar_y.pack(side="right", fill="y", padx=(0, 4))
            
        self.canvas.bind("<Configure>", self._on_configure)
        self.canvas.bind("<Motion>", self._on_canvas_motion)
        self.canvas.bind("<Leave>", self._on_canvas_leave)

    def _scroll_command(self, *args):
        self.canvas.yview(*args)
        self._update_viewport()

    def _on_canvas_motion(self, event):
        if self.is_preview: return
        x = self.canvas.canvasx(event.x)
        y = self.canvas.canvasy(event.y)
        
        hovered_word = None
        for safe_word, bbox in self.card_bboxes.items():
            if bbox[1] <= y <= bbox[3] and bbox[0] <= x <= bbox[2]:
                hovered_word = safe_word
                break
                
        if hovered_word != self._current_hover:
            if self._current_hover:
                self._hide_card_actions(self._current_hover)
            self._current_hover = hovered_word
            if hovered_word:
                self._show_card_actions(hovered_word)

    def _on_canvas_leave(self, event):
        if self._current_hover:
            self._hide_card_actions(self._current_hover)
            self._current_hover = None

    def _on_configure(self, event):
        if self._resize_timer:
            self.after_cancel(self._resize_timer)
            self._resize_timer = None
        if self._awaiting_first_visible_configure:
            self._awaiting_first_visible_configure = False
            if self._has_rendered:
                self._last_render_size = (event.width, event.height)
            return
        if not self._has_rendered and event.width >= 100:
            # First usable geometry (startup / first mapping): render
            # immediately instead of debouncing, so no unrendered or stale
            # frame is ever visible. Later resizes use the debounce below.
            self.render()
            return
        if self._has_rendered and (event.width, event.height) == self._last_render_size:
            # Pure move / no-op configure: geometry is unchanged since the
            # last completed render (e.g. the map event right after startup,
            # or a window move), so a full re-render would be redundant.
            return
        self._resize_timer = self.after(150, self.render)
        
    def _show_card_actions(self, safe_word):
        for item_id in self.card_action_ids.get(safe_word, []):
            if self.canvas.itemcget(item_id, "state") == "hidden":
                self.canvas.itemconfig(item_id, state="normal")

    def _hide_card_actions(self, safe_word):
        for item_id in self.card_action_ids.get(safe_word, []):
            if self.canvas.itemcget(item_id, "state") == "normal":
                self.canvas.itemconfig(item_id, state="hidden")

    def _release_card_bindings(self, safe_word):
        """Frees the Tcl command objects registered via _bind_tag for one card.
        Called whenever the card's canvas items are deleted."""
        for tag, seq, funcid in self._tag_bind_ids.pop(safe_word, []):
            try:
                self.canvas.deletecommand(funcid)
            except Exception:
                pass
            try:
                self.canvas.tag_unbind(tag, seq)
            except Exception:
                pass

    def _sync_hover_actions(self):
        """Re-applies hover visibility to whatever card is currently under the
        cursor. Needed because redrawing a card (save/cancel/refresh/fav/tag
        toggle) creates new canvas items that start hidden — if the mouse never
        left the card, _on_canvas_motion's == check skips re-showing them."""
        if self.is_preview:
            return
        try:
            px, py = self.winfo_pointerxy()
            if self.winfo_containing(px, py) is not self.canvas:
                return
            x = self.canvas.canvasx(px - self.canvas.winfo_rootx())
            y = self.canvas.canvasy(py - self.canvas.winfo_rooty())
        except Exception:
            return

        hovered = None
        for safe_word, bbox in self.card_bboxes.items():
            if bbox[1] <= y <= bbox[3] and bbox[0] <= x <= bbox[2]:
                hovered = safe_word
                break

        if self._current_hover and self._current_hover != hovered:
            self._hide_card_actions(self._current_hover)
        self._current_hover = hovered
        if hovered:
            self._show_card_actions(hovered)

    def _compute_z_factor(self):
        try:
            dpi_scale = ctk.ScalingTracker.get_window_dpi_scaling(self.app)
        except Exception:
            dpi_scale = 1.0
        return self.app.zoom_factor * dpi_scale * self.preview_scale

    def set_words(self, words, keep_selection=False):
        self.words = words
        # The previous layout described the old list; nothing may be drawn
        # until _compute_layout() succeeds for this one.
        self._layout_valid = False
        self.editing_word = None
        self._edit_draft.clear()
        if not keep_selection:
            self.selected_index = -1
        self.render()

    def _height_cache_key(self, w_data, is_edit):
        # Everything that affects a card's rendered height. Card height is
        # independent of vertical position and of is_favorite (the star never
        # changes height), so those are intentionally excluded.
        return (
            w_data.get('word', ''),
            1 if is_edit else 0,
            w_data.get('meaning', '') or '',
            w_data.get('bangla_meaning', '') or '',
            w_data.get('example_sentence', '') or '',
            w_data.get('synonyms', '') or '',
            w_data.get('antonyms', '') or '',
            w_data.get('notes', '') or '',
            w_data.get('important_synonyms', '') or '',
            w_data.get('important_antonyms', '') or '',
        )

    def _compute_layout(self, approx=False):
        visible_width = self.canvas.winfo_width()
        if visible_width < 100:
            self._layout_valid = False
            return
        
        self._cached_z_factor = self._compute_z_factor()
        painter = CardRenderer(self, self.app, self.canvas, self.edit_widgets, self._cached_z_factor)
        
        y_offset = int(10 * self.app.zoom_factor * self.preview_scale)
        self.row_offsets = {}
        self.row_heights = {}
        
        # C1: reuse memoized per-card heights while the layout signature
        # (width, zoom factor, spacing/typography version) is unchanged, so
        # repeated relayouts (search keystrokes, tab switches) skip the
        # per-field text measurement for unchanged cards. Height is measured
        # once at y_start=0 and offset arithmetically, matching the previous
        # compute_card_height(y_offset, ...) result exactly.
        z = self._cached_z_factor
        sig = (visible_width, round(z, 4), getattr(self.app, 'layout_version', 0))
        if getattr(self, '_height_cache_sig', None) != sig:
            self._height_cache.clear()
            self._height_cache_sig = sig
        cache = self._height_cache
        gap = int(25 * z)

        # Real-time zoom (approx=True): while the SCALE slider is dragged,
        # card heights are scaled arithmetically from the last exact layout
        # instead of re-measuring every word's text. Re-measuring the whole
        # notebook is what made live zooming heavy: each new zoom value
        # invalidates the height cache, so every tick paid the full text-
        # measurement cost. The debounced exact relayout that follows the
        # drag re-measures for real, so the resting layout stays pixel-
        # identical to the original renderer.
        snap = self._exact_layout_snapshot
        scale = None
        if approx and snap and snap[0] > 0 and snap[1] == visible_width and snap[3] == sig[2]:
            scale = z / snap[0]
        snap_heights = snap[2] if scale is not None else None
        new_snapshot = None if scale is not None else {}
        self._layout_is_approx = scale is not None

        # H1: viewport-first measurement. A fresh layout signature (first
        # load, resize, zoom, spacing change) used to re-measure every card's
        # text synchronously before the UI could respond -- O(n) Tcl work at
        # 5,000-20,000 words. Cards near the viewport (plus a fixed budget of
        # others) are still measured exactly, so small and medium lists
        # behave exactly as before. Cards far off-screen beyond the budget
        # start from an estimated height and are replaced with real
        # measurements by a chunked background pass (_bg_measure_step) that
        # keeps the viewport visually anchored while correcting offsets.
        self._cancel_bg_measure()
        self._estimated_words = set()
        sync_budget = 300
        est_h = None
        view_top = self.canvas.canvasy(0)
        view_h = max(1, self.canvas.winfo_height())
        near_lo = view_top - 2 * view_h
        near_hi = view_top + 3 * view_h

        for idx, w_data in enumerate(self.words):
            word = w_data['word']
            self.row_offsets[word] = y_offset
            is_edit = (self.editing_word == word)
            ckey = self._height_cache_key(w_data, is_edit)
            card_h = cache.get(ckey)
            if card_h is None and snap_heights is not None:
                snap_h = snap_heights.get(ckey)
                if snap_h is not None:
                    card_h = max(1, int(snap_h * scale))
            if card_h is None:
                if sync_budget > 0 or (near_lo <= y_offset <= near_hi):
                    card_h = painter.compute_card_height(0, w_data, visible_width, is_edit)
                    cache[ckey] = card_h
                    sync_budget -= 1
                else:
                    if est_h is None:
                        est_h = self._estimate_card_height()
                    card_h = est_h
                    self._estimated_words.add(word)
            if new_snapshot is not None:
                new_snapshot[ckey] = card_h
            bottom = y_offset + card_h
            self.row_heights[word] = bottom
            y_offset = bottom + gap
        if new_snapshot is not None:
            self._exact_layout_snapshot = (z, visible_width, new_snapshot, sig[2])
        if self._estimated_words:
            self._bg_measure_timer = self.after(50, self._bg_measure_step)
        # C2: ordered parallel arrays enable bisect-based viewport slicing
        # instead of an O(n) scan from the top of the list on every scroll.
        self._ordered_words = [w['word'] for w in self.words]
        self._ordered_tops = [self.row_offsets[w] for w in self._ordered_words]
        self._ordered_bottoms = [self.row_heights[w] for w in self._ordered_words]
        self._word_index = {w: i for i, w in enumerate(self._ordered_words)}

        self.canvas.configure(scrollregion=(0, 0, visible_width, max(self.canvas.winfo_height(), y_offset)))
        # Offsets/heights and ordered arrays now match self.words at this
        # width/zoom: drawing is safe.
        self._layout_valid = True

    def _cancel_bg_measure(self):
        if getattr(self, '_bg_measure_timer', None):
            try:
                self.after_cancel(self._bg_measure_timer)
            except Exception:
                pass
        self._bg_measure_timer = None

    def _estimate_card_height(self):
        """H1: best-available average card height for far off-screen cards
        that the background pass will measure for real. Any error is corrected
        by _bg_measure_step (and, for drawn cards, _apply_height_correction),
        so it only ever affects scrollbar proportions temporarily."""
        cache = self._height_cache
        if cache:
            return max(1, int(sum(cache.values()) / len(cache)))
        snap = self._exact_layout_snapshot
        if snap and snap[0] > 0 and snap[2]:
            ratio = self._cached_z_factor / snap[0]
            vals = snap[2].values()
            return max(1, int((sum(vals) / len(vals)) * ratio))
        return max(1, int(160 * self._cached_z_factor))

    def _bg_measure_step(self):
        """H1: replaces estimated card heights with real measurements in
        small after()-scheduled chunks so huge notebooks never pay a full
        O(n) text-measurement pass in one frame. Offsets shift exactly the
        way _apply_height_correction always shifted them, and the viewport
        stays visually anchored on the same card."""
        self._bg_measure_timer = None
        if not self.words or not self._estimated_words:
            return
        try:
            if not self.winfo_exists():
                return
        except Exception:
            return
        visible_width = self.canvas.winfo_width()
        sig = (visible_width, round(self._cached_z_factor, 4), getattr(self.app, 'layout_version', 0))
        if sig != self._height_cache_sig:
            # A resize/zoom/spacing change is in flight; the next exact
            # _compute_layout re-owns all remaining estimates.
            return
        painter = CardRenderer(self, self.app, self.canvas, self.edit_widgets, self._cached_z_factor)
        cache = self._height_cache
        measured = 0
        for w_data in self.words:
            word = w_data['word']
            if word not in self._estimated_words:
                continue
            is_edit = (self.editing_word == word)
            ckey = self._height_cache_key(w_data, is_edit)
            if ckey not in cache:
                cache[ckey] = painter.compute_card_height(0, w_data, visible_width, is_edit)
            self._estimated_words.discard(word)
            measured += 1
            if measured >= 40:
                break
        if measured == 0:
            # Every remaining entry refers to a word no longer in the list.
            self._estimated_words.clear()
            return
        self._relayout_from_cache(visible_width)
        if self._estimated_words:
            self._bg_measure_timer = self.after(30, self._bg_measure_step)

    def _relayout_from_cache(self, visible_width):
        """H1: recomputes all row offsets from cached (or still-estimated)
        heights -- pure arithmetic, no text measurement -- then moves already
        drawn cards by their offset delta and re-anchors the scroll position
        so nothing visibly jumps."""
        z = self._cached_z_factor
        gap = int(25 * z)
        cache = self._height_cache
        old_offsets = self.row_offsets
        old_heights = self.row_heights

        view_top = self.canvas.canvasy(0)
        anchor_word = None
        anchor_old = 0
        i = bisect.bisect_right(self._ordered_bottoms, view_top)
        if 0 <= i < len(self._ordered_words):
            anchor_word = self._ordered_words[i]
            anchor_old = old_offsets.get(anchor_word, 0)

        snap = self._exact_layout_snapshot
        snap_dict = snap[2] if (snap and abs(snap[0] - z) < 1e-9) else None
        y_offset = int(10 * self.app.zoom_factor * self.preview_scale)
        new_offsets = {}
        new_heights = {}
        for w_data in self.words:
            word = w_data['word']
            is_edit = (self.editing_word == word)
            ckey = self._height_cache_key(w_data, is_edit)
            card_h = cache.get(ckey)
            if card_h is None:
                # Still estimated: keep the current estimate unchanged.
                card_h = old_heights.get(word, 0) - old_offsets.get(word, 0)
                if card_h <= 0:
                    card_h = self._estimate_card_height()
            elif snap_dict is not None:
                snap_dict[ckey] = card_h
            new_offsets[word] = y_offset
            bottom = y_offset + card_h
            new_heights[word] = bottom
            y_offset = bottom + gap

        self.row_offsets = new_offsets
        self.row_heights = new_heights
        self._ordered_words = [w['word'] for w in self.words]
        self._ordered_tops = [new_offsets[w] for w in self._ordered_words]
        self._ordered_bottoms = [new_heights[w] for w in self._ordered_words]
        self._word_index = {w: i for i, w in enumerate(self._ordered_words)}

        total = max(self.canvas.winfo_height(), y_offset)
        self.canvas.configure(scrollregion=(0, 0, visible_width, total))

        # Move already-drawn cards whose offset shifted (same mechanics as
        # _apply_height_correction) instead of redrawing them.
        for word, bg_id in list(self.card_bg_ids.items()):
            old_y = old_offsets.get(word)
            new_y = new_offsets.get(word)
            if old_y is None or new_y is None:
                continue
            delta = new_y - old_y
            if delta and self.canvas.type(bg_id):
                sw = hashlib.md5(word.lower().encode()).hexdigest()[:12]
                self.canvas.move(f"card_{sw}", 0, delta)
                if word in self.card_y_positions:
                    self.card_y_positions[word] += delta
                bbox = self.card_bboxes.get(sw)
                if bbox:
                    self.card_bboxes[sw] = (bbox[0], bbox[1] + delta, bbox[2], bbox[3] + delta)

        if anchor_word is not None:
            anchor_new = new_offsets.get(anchor_word)
            if anchor_new is not None and anchor_new != anchor_old and total > 0:
                try:
                    self.canvas.yview_moveto(max(0.0, (view_top + (anchor_new - anchor_old)) / total))
                except Exception:
                    pass
        self._update_viewport()

    def _invalidate_card(self, word):
        """Force a card to be fully redrawn (not just moved) — needed when its
        own content/edit-state changed, e.g. entering/exiting edit, favorite
        toggle, tag toggle."""
        safe_word = hashlib.md5(word.lower().encode()).hexdigest()[:12]
        self.canvas.delete(f"card_{safe_word}")
        self._release_card_bindings(safe_word)
        self.card_bg_ids.pop(word, None)
        self.card_highlight_ids.pop(word, None)
        self.card_action_ids.pop(safe_word, None)
        self.card_bboxes.pop(safe_word, None)
        self.card_y_positions.pop(word, None)
        self.visible_words.discard(word)

        prefix = f"{word}_"
        for k in list(self.edit_widgets.keys()):
            if k.startswith(prefix):
                try:
                    self.edit_widgets[k].destroy()
                except Exception:
                    pass
                del self.edit_widgets[k]

    def _reflow_single(self, changed_word):
        """Recompute height for ONE card and shift everything after it by the
        delta — avoids re-measuring text for the whole list on every action."""
        visible_width = self.canvas.winfo_width()
        if visible_width < 100:
            return
        if changed_word not in self.row_offsets:
            self._compute_layout()
            return
        idx = self._word_index.get(changed_word)
        if idx is None or idx >= len(self.words) or self.words[idx]['word'] != changed_word:
            self._compute_layout()
            return
        w_data = self.words[idx]

        self._cached_z_factor = self._compute_z_factor()
        painter = CardRenderer(self, self.app, self.canvas, self.edit_widgets, self._cached_z_factor)

        y_start = self.row_offsets[changed_word]
        old_bottom = self.row_heights.get(changed_word, y_start)
        is_edit = (self.editing_word == changed_word)
        new_bottom = painter.compute_card_height(y_start, w_data, visible_width, is_edit)
        delta = new_bottom - old_bottom
        self.row_heights[changed_word] = new_bottom

        if delta:
            for w in self.words[idx + 1:]:
                wd = w['word']
                self.row_offsets[wd] = self.row_offsets.get(wd, 0) + delta
                self.row_heights[wd] = self.row_heights.get(wd, 0) + delta

        gap = int(25 * self._cached_z_factor)
        last_bottom = self.row_heights.get(self.words[-1]['word'], new_bottom) if self.words else new_bottom
        self.canvas.configure(scrollregion=(0, 0, visible_width, max(self.canvas.winfo_height(), last_bottom + gap)))

        # Rebuild ordered arrays (C2) so the bisect viewport stays correct
        # after offsets were shifted by the reflow delta.
        self._ordered_words = [w['word'] for w in self.words]
        self._ordered_tops = [self.row_offsets.get(w, 0) for w in self._ordered_words]
        self._ordered_bottoms = [self.row_heights.get(w, 0) for w in self._ordered_words]
        self._word_index = {w: i for i, w in enumerate(self._ordered_words)}

    def _update_viewport(self):
        if not self.words:
            return
        if not self._layout_valid:
            # Hard precondition: without a computed layout for the current
            # word list (row offsets/heights, ordered arrays, z-factor),
            # drawing here would stack every card at y=0 on an unsized
            # canvas -- the startup glitch. All call sites are covered by
            # this single guard.
            return
            
        top = self.canvas.canvasy(0)
        bottom = top + self.canvas.winfo_height()
        viewport_h = bottom - top
        top -= viewport_h * 1.5
        bottom += viewport_h * 1.5

        words_to_draw = []
        
        tops = self._ordered_tops
        bottoms = self._ordered_bottoms
        if tops and len(tops) == len(self.words) and len(bottoms) == len(self.words):
            start_i = bisect.bisect_left(bottoms, top)
            end_i = bisect.bisect_right(tops, bottom)
            for i in range(start_i, end_i):
                words_to_draw.append(self.words[i])
        else:
            for w_data in self.words:
                word = w_data['word']
                y_start = self.row_offsets.get(word, 0)
                y_end = self.row_heights.get(word, 0)
                if y_end < top:
                    continue
                if y_start > bottom:
                    break
                words_to_draw.append(w_data)

        new_visible = set(w['word'] for w in words_to_draw)
        words_to_remove = self.visible_words - new_visible
        
        for word in words_to_remove:
            safe_word = hashlib.md5(word.lower().encode()).hexdigest()[:12]
            self.canvas.delete(f"card_{safe_word}")
            self._release_card_bindings(safe_word)
            prefix = f"{word}_"
            for wk in list(self.edit_widgets.keys()):
                if wk.startswith(prefix):
                    widget = self.edit_widgets[wk]
                    try:
                        if "text" in str(type(widget)).lower():
                            self._edit_draft[wk] = widget.get("1.0", "end-1c")
                        else:
                            self._edit_draft[wk] = widget.get()
                    except Exception:
                        pass
                    try:
                        widget.destroy()
                    except Exception:
                        pass
                    del self.edit_widgets[wk]
            self.card_bg_ids.pop(word, None)
            self.card_highlight_ids.pop(word, None)
            self.card_action_ids.pop(safe_word, None)
            self.card_bboxes.pop(safe_word, None)
            self.card_y_positions.pop(word, None)
            
        self.visible_words = new_visible

        if self.is_preview:
            callbacks = {}
        else:
            callbacks = {
                'save': self.action_save, 
                'cancel': lambda w: self.app.cancel_edit(),
                'delete': self.action_delete, 
                'refresh': self.action_refresh,
                'edit': self.action_edit,
                'pronounce': self.action_pronounce,
                'fav': self.action_fav, 
                'toggle_tag': self._toggle_important
            }

        painter = CardRenderer(self, self.app, self.canvas, self.edit_widgets, self._cached_z_factor)
        
        for w_data in words_to_draw:
            word = w_data['word']
            safe_word = hashlib.md5(word.lower().encode()).hexdigest()[:12]
            
            if word in self.card_bg_ids and self.canvas.type(self.card_bg_ids[word]):
                new_y = self.row_offsets.get(word, 0)
                old_y = self.card_y_positions.get(word)
                if old_y is not None and new_y != old_y:
                    delta = new_y - old_y
                    self.canvas.move(f"card_{safe_word}", 0, delta)
                    self.card_y_positions[word] = new_y
                    bbox = self.card_bboxes.get(safe_word)
                    if bbox:
                        self.card_bboxes[safe_word] = (bbox[0], bbox[1] + delta, bbox[2], bbox[3] + delta)
                continue
                
            y_start = self.row_offsets.get(word, 0)
            idx = self._word_index.get(word, -1)
            is_edit = (self.editing_word == word)
            is_selected = (not self.is_preview) and (idx == self.selected_index)
            
            self.card_y_positions[word] = y_start
            bg_id, hl_id, y_end = painter.draw_card(y_start, w_data, self.canvas.winfo_width(), is_edit, is_selected, callbacks)
            
            self.card_bg_ids[word] = bg_id
            self.card_highlight_ids[word] = hl_id

            # Reconcile the estimated layout height with the height the card
            # actually rendered at, but ONLY when the card would genuinely
            # collide with the one below it (the mismatch consumes the whole
            # inter-card gap). Routine measurement slack is tolerated exactly
            # as the app always did. This keeps zoom drags fast: the zoom-
            # invalidated height cache no longer triggers O(n) offset shifts
            # and card moves for ordinary slack on every slider tick.
            expected_bottom = self.row_heights.get(word)
            if expected_bottom is not None and not self._layout_is_approx:
                gap = int(25 * self._cached_z_factor)
                if y_end - expected_bottom >= gap:
                    self._apply_height_correction(word, w_data, is_edit, y_end)

        self._sync_hover_actions()

    def _apply_height_correction(self, word, w_data, is_edit, actual_bottom):
        """Shifts every card below `word` by the difference between its
        estimated height and the height it actually rendered at, and stores
        the real height in the cache so this runs at most once per card per
        layout signature. Prevents card overlap when the wrap estimator and
        Tk's renderer disagree."""
        idx = self._word_index.get(word)
        old_bottom = self.row_heights.get(word)
        if idx is None or old_bottom is None:
            return
        delta = actual_bottom - old_bottom
        if not delta:
            return

        self.row_heights[word] = actual_bottom
        y_start = self.row_offsets.get(word, 0)
        self._height_cache[self._height_cache_key(w_data, is_edit)] = actual_bottom - y_start
        # Keep the exact-layout snapshot (used for real-time zoom scaling)
        # in sync with the corrected height.
        snap = self._exact_layout_snapshot
        if snap and abs(snap[0] - self._cached_z_factor) < 1e-9:
            snap[2][self._height_cache_key(w_data, is_edit)] = actual_bottom - y_start

        for w in self.words[idx + 1:]:
            wd = w['word']
            if wd in self.row_offsets:
                self.row_offsets[wd] += delta
            if wd in self.row_heights:
                self.row_heights[wd] += delta
            # Cards already drawn are moved in place so they stay in sync
            # without a full redraw.
            if wd in self.card_bg_ids and self.canvas.type(self.card_bg_ids[wd]):
                sw = hashlib.md5(wd.lower().encode()).hexdigest()[:12]
                self.canvas.move(f"card_{sw}", 0, delta)
                if wd in self.card_y_positions:
                    self.card_y_positions[wd] += delta
                bbox = self.card_bboxes.get(sw)
                if bbox:
                    self.card_bboxes[sw] = (bbox[0], bbox[1] + delta, bbox[2], bbox[3] + delta)

        self._ordered_tops = [self.row_offsets.get(w, 0) for w in self._ordered_words]
        self._ordered_bottoms = [self.row_heights.get(w, 0) for w in self._ordered_words]

        if self.words:
            gap = int(25 * self._cached_z_factor)
            last_bottom = self.row_heights.get(self.words[-1]['word'], actual_bottom)
            self.canvas.configure(scrollregion=(0, 0, self.canvas.winfo_width(), max(self.canvas.winfo_height(), last_bottom + gap)))

    def _flash_card(self, word):
        """Briefly highlights a card outline after a scroll-to. load_words
        has always threaded a `flash` flag through to scroll_to_word for
        newly added / opened duplicate words, but it was never acted on."""
        bg_id = self.card_bg_ids.get(word)
        if not bg_id or not self.canvas.type(bg_id):
            return
        try:
            self.canvas.itemconfig(bg_id, outline=Color.ACCENT, width=2)
        except Exception:
            return

        def restore(w=word, item=bg_id):
            try:
                if not self.winfo_exists():
                    return
                if self.card_bg_ids.get(w) != item or not self.canvas.type(item):
                    return
                idx = self._word_index.get(w, -1)
                is_selected = (not self.is_preview) and (idx == self.selected_index)
                self.canvas.itemconfig(
                    item,
                    outline=Color.ACCENT if is_selected else Color.BORDER,
                    width=2 if is_selected else 1
                )
            except Exception:
                pass

        self.after(900, restore)

    def render(self, fast_zoom=False):
        if self.editing_word and self.edit_widgets:
            for k, widget in self.edit_widgets.items():
                if k.startswith(f"{self.editing_word}_"):
                    try:
                        if "text" in str(type(widget)).lower():
                            self._edit_draft[k] = widget.get("1.0", "end-1c")
                        else:
                            self._edit_draft[k] = widget.get()
                    except Exception:
                        pass
                        
        self.canvas.delete("all")
        for sw in list(self._tag_bind_ids.keys()):
            self._release_card_bindings(sw)

        for widget in self.edit_widgets.values():
            try:
                widget.destroy()
            except Exception:
                pass
            
        self.edit_widgets.clear()
        self.card_y_positions.clear()
        self.card_bg_ids.clear()
        self.card_highlight_ids.clear()
        self.card_action_ids.clear()
        self.card_bboxes.clear()
        self.visible_words.clear()
        
        visible_width = self.canvas.winfo_width()
        if visible_width < 100: 
            # The canvas was just cleared but has no usable geometry yet;
            # any previously computed layout no longer matches the screen.
            self._layout_valid = False
            return 
        
        self._has_rendered = True
        self._last_render_size = (visible_width, self.canvas.winfo_height())

        if not self.words:
            self._layout_valid = False
            if not self.is_preview:
                self._draw_empty_state(visible_width, self.canvas.winfo_height())
            return

        self._compute_layout(approx=fast_zoom)
        self._update_viewport()

    def set_selected_index(self, new_idx):
        if not self.words or new_idx < 0 or new_idx >= len(self.words): 
            return
        
        if self.selected_index != -1:
            old_word = self.words[self.selected_index]['word']
            old_hl_id = self.card_highlight_ids.get(old_word)
            if old_hl_id: 
                self.canvas.itemconfig(old_hl_id, outline=Color.BORDER, width=1)
            
        self.selected_index = new_idx
        new_word = self.words[self.selected_index]['word']
        new_hl_id = self.card_highlight_ids.get(new_word)
        if new_hl_id: 
            self.canvas.itemconfig(new_hl_id, outline=Color.ACCENT, width=2)
        
        self.scroll_to_word(new_word)

    def _on_up_arrow(self, event):
        if not self.words: 
            return
        if self.selected_index == -1: 
            self.set_selected_index(len(self.words) - 1)
        else: 
            self.set_selected_index(max(0, self.selected_index - 1))

    def _on_down_arrow(self, event):
        if not self.words: 
            return
        if self.selected_index == -1: 
            self.set_selected_index(0)
        else: 
            self.set_selected_index(min(len(self.words) - 1, self.selected_index + 1))

    def _on_enter_key(self, event):
        if self.selected_index != -1 and not self.is_preview and not self.editing_word:
            self.action_edit(self.words[self.selected_index]['word'])

    def _on_delete_key(self, event):
        if self.selected_index != -1 and not self.is_preview and not self.editing_word:
            self.action_delete(self.words[self.selected_index]['word'])

    def _draw_empty_state(self, w, h):
        msg = "No words found. Add a word above to get started."
        if self.app.notebook_page.search_entry.get().strip(): 
            msg = "No words match your search."
        elif self.app.show_favorites_only: 
            msg = "No favorites yet. Star some words!"
            
        self.canvas.create_text(
            w//2, max(150, h//3), text=msg, 
            font=Font.base(14), fill=Color.TEXT_MUTED, justify="center"
        )

    def _toggle_important(self, word, field_key, item_val, current_important_str):
        imp_list = []
        for s in current_important_str.split(','):
            if s.strip():
                imp_list.append(s.strip())
                
        item_lower = item_val.lower()
        
        is_present = False
        for imp in imp_list:
            if imp.lower() == item_lower:
                is_present = True
                break
                
        if is_present:
            imp_list = [imp for imp in imp_list if imp.lower() != item_lower]
        else:
            imp_list.append(item_val)
            
        new_str = ", ".join(imp_list)
        update_single_field(word, f"important_{field_key}", new_str)
        
        for w in self.words:
            if w['word'] == word:
                w[f"important_{field_key}"] = new_str
                break
        
        self._reflow_single(word)
        self._invalidate_card(word)
        self._update_viewport()

    def action_delete(self, word):
        dlg = StyledConfirmDialog(self.app, "Delete Word", f"Permanently delete '{word.capitalize()}'?", danger=True)
        self.wait_window(dlg)
        if dlg.result and delete_word(word): 
            self.app.load_words()

    def action_refresh(self, word):
        raw_key = self.app.settings_page.api_key_entry.get().strip()
        api_key = raw_key if raw_key else self.app.api_key
        if not api_key:
            StyledConfirmDialog(self.app, "Missing API Key", "Please enter your API Key in Settings first.", confirm_text="OK").wait_window()
            return
            
        # Shares the same pending namespace as add_new_word so an add and a
        # refresh of the same word can never run concurrently and interleave
        # their per-field DB writes.
        pend_key = word.lower()
        if pend_key in self.app._pending_words:
            return
        self.app._pending_words.add(pend_key)
        # M2: watchdog so a hung request cannot leave this word un-refreshable
        # forever. A late reply is still applied by _on_refresh_done.
        self.app.after(60000, lambda: self.app._release_stuck_request(pend_key, f"Refreshing '{word}' timed out."))
        self.app.notebook_page.status_label.configure(text=f"Refreshing '{word}'...", text_color=Color.ACCENT)
        provider_config = self.app.settings_page.get_current_provider_config()
        threading.Thread(target=lambda: self._fetch_refresh(word, api_key, provider_config), daemon=True).start()

    def _fetch_refresh(self, word, api_key, provider_config):
        try:
            data, msg = _fetch_word_details(word, api_key, provider_config)
        except Exception as e:
            data, msg = None, f"Crash: {str(e)}"
        try:
            self.app.after(0, lambda: self._on_refresh_done(word, data, msg))
        except Exception:
            # The app was closed while the request was in flight; scheduling
            # on a destroyed root raises and there is nothing left to update.
            pass

    def _on_refresh_done(self, word, data, api_msg):
        self.app._pending_words.discard(word.lower())
        if data:
            for field in ['meaning', 'bangla_meaning', 'english_definition', 'ipa', 'part_of_speech', 'example_sentence', 'synonyms', 'antonyms']:
                if field in data: 
                    update_single_field(word, field, data[field])
            self.app.notebook_page.status_label.configure(text=f"Refreshed '{word}'!", text_color=Color.SUCCESS)
            self.app.load_words(scroll_to=word.lower(), flash=False)
        else:
            StyledConfirmDialog(self.app, "Refresh Failed", api_msg, confirm_text="OK", danger=True).wait_window()
            self.app.notebook_page.status_label.configure(text="", text_color=Color.TEXT_MUTED)

    def action_edit(self, word):
        prev_editing = self.editing_word
        self.editing_word = word
        self._edit_draft.clear()
        if prev_editing and prev_editing != word:
            self._reflow_single(prev_editing)
            self._invalidate_card(prev_editing)
        self._reflow_single(word)
        self._invalidate_card(word)
        self._update_viewport()

    def cancel_editing(self):
        if not self.editing_word:
            return
        prev = self.editing_word
        self.editing_word = None
        self._edit_draft.clear()
        self._reflow_single(prev)
        self._invalidate_card(prev)
        self._update_viewport()
        # Belt-and-suspenders: _update_viewport() already calls this at its
        # tail, but on the Cancel path the canvas items for the just-redrawn
        # card may not be fully realized when that tail call runs (Tk queues
        # the geometry work). Flushing pending idle tasks then re-syncing
        # guarantees the new action icons exist before we try to show them,
        # so hover state restores correctly even though no <Motion> event
        # fires (the mouse never left the card).
        try:
            self.canvas.update_idletasks()
        except Exception:
            pass
        self._sync_hover_actions()

    def action_pronounce(self, word):
        self.app.tts_manager.speak(word)

    def action_save(self, word):
        updates = {}
        for k in ['meaning', 'bangla_meaning', 'example_sentence', 'synonyms', 'antonyms', 'notes']:
            if f"{word}_{k}" in self.edit_widgets:
                widget = self.edit_widgets[f"{word}_{k}"]
                if "text" in str(type(widget)).lower():
                    updates[k] = widget.get("1.0", "end-1c").strip()
                else:
                    updates[k] = widget.get().strip()
                    
        for field, new_value in updates.items(): 
            update_single_field(word, field, new_value)
            
        self.editing_word = None
        self._edit_draft.clear()
        self.app.load_words(scroll_to=word.lower(), flash=False)

    def action_fav(self, word):
        w_data = None
        for w in self.words:
            if w['word'] == word:
                w_data = w
                break
                
        if not w_data: 
            return
            
        is_fav = not bool(w_data.get('is_favorite', 0))
        update_single_field(word, 'is_favorite', 1 if is_fav else 0)
        
        if not is_fav and self.app.show_favorites_only: 
            self.app.load_words()
        else:
            w_data['is_favorite'] = 1 if is_fav else 0
            self._reflow_single(word)
            self._invalidate_card(word)
            self._update_viewport()

    def scroll_to_word(self, target_word, flash=False, update_index=False):
        target_lower = target_word.lower()
        
        if update_index:
            for idx, w in enumerate(self.words):
                if w['word'].lower() == target_lower:
                    self.set_selected_index(idx)
                    self.update_idletasks()
                    break 

        actual_key = None
        for k in self.row_offsets.keys():
            if k.lower() == target_lower:
                actual_key = k
                break
                
        if actual_key:
            target_y = self.row_offsets.get(actual_key, 0)
            sr = self.canvas.cget("scrollregion")
            if sr:
                try:
                    sr_tuple = tuple(map(float, sr.split()))
                    if len(sr_tuple) == 4 and sr_tuple[3] > 0:
                        fraction = max(0.0, (target_y - int(25 * self._cached_z_factor)) / sr_tuple[3])
                        self.canvas.yview_moveto(fraction)
                        self._update_viewport()
                        if flash:
                            self._flash_card(actual_key)
                except ValueError: 
                    pass


# =======================================================================
# SETTINGS PAGE (Side-by-Side Unified Split Layout)
# =======================================================================
class SettingsPage(ctk.CTkFrame):
    def __init__(self, master, app):
        super().__init__(master, fg_color=Color.APP_BG, corner_radius=0)
        self.app = app
        self.sliders = {}
        self.slider_labels = {}
        self._preview_timer = None
        self._tab_place_timer = None
        self._db_timers = {}
        self._pending_setting_saves = {}
        
        self.current_tab = None
        
        self.header_frame = ctk.CTkFrame(self, fg_color="transparent")
        self.header_frame.pack(fill="x", padx=45, pady=(45, 10))
        
        self.btn_back = ctk.CTkButton(
            self.header_frame, text="← Back", font=Font.base(14, "bold"),
            fg_color="transparent", hover_color=Color.HOVER_BG,
            text_color=Color.TEXT_SECONDARY, width=60, height=36,
            command=lambda: self.app.select_frame("notebook")
        )
        self.btn_back.pack(side="left", padx=(0, 20))
        
        ctk.CTkLabel(self.header_frame, text="Settings Dashboard", font=Font.base(26, "bold"), text_color=Color.TEXT_PRIMARY).pack(side="left")

        self.split_container = ctk.CTkFrame(self, fg_color="transparent")
        self.split_container.pack(fill="both", expand=True, padx=45, pady=(0, 45))
        
        self.split_container.grid_columnconfigure(0, weight=1) 
        self.split_container.grid_columnconfigure(1, weight=1)
        self.split_container.grid_rowconfigure(0, weight=1)
        
        self.left_col = ctk.CTkFrame(self.split_container, fg_color="transparent")
        self.left_col.grid(row=0, column=0, sticky="nsew", padx=(0, 20))

        self.tabs_container = ctk.CTkFrame(self.left_col, fg_color="transparent")
        self.tabs_container.pack(fill="x", pady=(0, 20))
        
        self.nav_buttons = {}
        self.btn_api = self._create_nav_btn(self.tabs_container, "API Settings", "api")
        self.btn_api.pack(side="left", padx=(0, 10))
        self.btn_space = self._create_nav_btn(self.tabs_container, "Spacing", "spacing")
        self.btn_space.pack(side="left", padx=(0, 10))
        self.btn_font = self._create_nav_btn(self.tabs_container, "Typography", "fonts")
        self.btn_font.pack(side="left")
        
        self.controls_container = ctk.CTkFrame(self.left_col, fg_color=Color.CARD_BG, corner_radius=12, border_width=1, border_color=Color.BORDER)
        self.controls_container.pack(fill="both", expand=True)
        
        self.frames = {}
        self.frames["api"] = self._build_api_tab(self.controls_container)
        
        self.frames["spacing"] = self._build_layout_tab(self.controls_container, self.app.spacings, -20, 100, "px", [
            ("Gap after Title", "title_gap"), ("Gap after Meaning", "meaning_gap"), 
            ("Gap after Bangla", "bangla_meaning_gap"), ("Gap after Example", "example_sentence_gap"), 
            ("Gap after Synonyms", "synonyms_gap"), ("Gap after Antonyms", "antonyms_gap"), 
            ("Gap after Notes", "notes_gap"), ("Bottom Card Padding", "card_padding_bottom")
        ])
        
        self.frames["fonts"] = self._build_layout_tab(self.controls_container, self.app.font_sizes, 8, 36, "pt", [
            ("Title Size", "title_size"), ("Meaning Size", "meaning_size"), 
            ("Bangla Size", "bangla_size"), ("Example Size", "example_size"), 
            ("Synonyms Size", "synonyms_size"), ("Antonyms Size", "antonyms_size"), 
            ("Notes Size", "notes_size")
        ])

        for frame in self.frames.values():
            frame.place_forget()

        self.right_col = ctk.CTkFrame(self.split_container, fg_color="transparent")
        self.right_col.grid(row=0, column=1, sticky="nsew", padx=(20, 0))

        self.preview_header = ctk.CTkFrame(self.right_col, fg_color="transparent")
        self.preview_header.pack(fill="x", pady=(0, 10))
        ctk.CTkLabel(self.preview_header, text="Live Layout Preview", font=Font.base(14, "bold"), text_color=Color.TEXT_SECONDARY).pack(side="left")
        
        self.btn_reset = ctk.CTkButton(
            self.preview_header, text="↺ Reset Defaults", font=Font.base(12, "bold"), 
            fg_color="transparent", hover_color=Color.HOVER_BG, 
            text_color=Color.TEXT_PRIMARY, border_width=1, border_color=Color.BORDER,
            height=30, width=120, command=self.reset_layout_defaults
        )
        self.btn_reset.pack(side="right")

        self.preview_stage = ctk.CTkFrame(self.right_col, fg_color=Color.APP_BG, corner_radius=12, border_width=1, border_color=Color.BORDER)
        self.preview_stage.pack(fill="both", expand=True)
        
        self.preview_list = WordListView(self.preview_stage, self.app, is_preview=True)
        self.preview_list.pack(fill="both", expand=True, padx=20, pady=20) 
        
        sample_word = {
            'word': 'abject', 'ipa': 'ab-jekt', 'part_of_speech': 'adjective',
            'meaning': 'Extremely bad or hopeless',
            'bangla_meaning': 'অধম, শোচনীয়, হীন',
            'example_sentence': 'They live in abject poverty, struggling to afford basic necessities.',
            'synonyms': 'miserable, wretched, hopeless',
            'antonyms': 'proud, commendable, exalted',
            'is_favorite': 1
        }
        self.preview_list.set_words([sample_word])
        
        self.switch_tab("api")

    def reset_layout_defaults(self):
        self.app.layout_version += 1
        for k, default_val in self.app.DEFAULT_SPACINGS.items():
            self.app.spacings[k] = default_val
            if k in self.sliders:
                self.sliders[k].set(default_val)
                self.slider_labels[k].configure(text=f"{int(default_val)} px")
                
        for k, default_val in self.app.DEFAULT_FONTS.items():
            self.app.font_sizes[k] = default_val
            if k in self.sliders:
                self.sliders[k].set(default_val)
                self.slider_labels[k].configure(text=f"{int(default_val)} pt")
                
        self.app.zoom_factor = 0.8
        if hasattr(self.app, 'notebook_page'):
            self.app.notebook_page.zoom_slider.set(0.8)
            self.app.notebook_page.zoom_label.configure(text="80%")
            
        def apply_db():
            for sk, sval in self.app.spacings.items(): save_setting(sk, str(sval))
            for sk, sval in self.app.font_sizes.items(): save_setting(sk, str(sval))
            save_setting("zoom_factor", "0.8")
            self._pending_setting_saves.clear()

        for sk, sval in self.app.spacings.items(): self._pending_setting_saves[sk] = sval
        for sk, sval in self.app.font_sizes.items(): self._pending_setting_saves[sk] = sval
        self._pending_setting_saves["zoom_factor"] = "0.8"
        self.after(50, apply_db)
                
        orig_color = self.btn_reset.cget("fg_color")
        orig_text_color = self.btn_reset.cget("text_color")
        self.btn_reset.configure(text="Restored!", fg_color=Color.SUCCESS, border_width=0, text_color="#FFFFFF")
        
        self.after(1500, lambda: self.btn_reset.configure(
            text="↺ Reset Defaults", fg_color=orig_color, border_width=1, text_color=orig_text_color
        ))

        self.preview_list.render()
        self.app._needs_notebook_refresh = True

    def _create_nav_btn(self, parent, text, tab_id):
        btn = ctk.CTkButton(
            parent, text=text, font=Font.base(13, "bold"), fg_color="transparent", 
            hover_color=Color.HOVER_BG, text_color=Color.TEXT_SECONDARY, 
            corner_radius=6, height=36, command=lambda: self.switch_tab(tab_id)
        )
        self.nav_buttons[tab_id] = btn
        return btn

    def switch_tab(self, tab_id):
        if self.current_tab == tab_id:
            return

        # Restyle only the two nav buttons whose active state changes;
        # reconfiguring all of them forces needless re-renders.
        for t_id in (self.current_tab, tab_id):
            if t_id is None:
                continue
            btn = self.nav_buttons[t_id]
            is_active = (t_id == tab_id)
            btn.configure(
                fg_color=Color.CARD_BG if is_active else "transparent", 
                text_color=Color.TEXT_PRIMARY if is_active else Color.TEXT_SECONDARY,
                border_width=1 if is_active else 0,
                border_color=Color.BORDER if is_active else Color.APP_BG
            )
        
        # Hide the outgoing tab BEFORE the column layout changes, so its
        # widgets are never resized just to be hidden a moment later, and
        # each hidden tab keeps the geometry of its own layout.
        if self.current_tab:
            self.frames[self.current_tab].place_forget()

        if self._tab_place_timer:
            self.after_cancel(self._tab_place_timer)
            self._tab_place_timer = None

        # Does this switch change the column layout (full <-> split)?
        crossing = (tab_id == "api") != (self.current_tab == "api")
        width_before = self.controls_container.winfo_width()

        if tab_id == "api":
            self.right_col.grid_remove()
            self.left_col.grid(columnspan=2, padx=0)
        else:
            self.left_col.grid(columnspan=1, padx=(0, 20))
            self.right_col.grid()
            # Render the preview once the grid reflow has settled instead
            # of synchronously mid-switch: rendering here would measure a
            # stale canvas width, and the canvas <Configure> debounce would
            # render a second time 150ms later.
            def _render_preview():
                try:
                    if not self.preview_list.winfo_exists():
                        return
                    if self.preview_list._resize_timer:
                        self.preview_list.after_cancel(self.preview_list._resize_timer)
                        self.preview_list._resize_timer = None
                    self.preview_list.render()
                except Exception:
                    pass
            self.after_idle(_render_preview)

        # Map the incoming tab only once the controls container has reached
        # its FINAL size for this column layout. Profiling showed that Tk
        # relayouts propagate in generations (grid -> column -> container),
        # so placing the tab after a single idle tick still sized it against
        # the outgoing width first and the final width a moment later --
        # every widget in the tab was rendered TWICE per switch (measured
        # at 200-350ms, with CTkOptionMenu alone costing ~120ms per draw).
        # Waiting until the container width actually changes means the tab
        # is re-placed at exactly the size it already has, so its widgets
        # are not re-rendered at all -- the same reason Typography <->
        # Spacing switches were always smooth.
        def _place_tab():
            self._tab_place_timer = None
            try:
                frame = self.frames[tab_id]
                frame.tkraise()
                frame.place(relx=0, rely=0, relwidth=1, relheight=1)
            except Exception:
                pass

        if not crossing or not self.controls_container.winfo_ismapped():
            # Same column layout as the outgoing tab (or not on screen
            # yet): the container size is already final, place directly.
            _place_tab()
        else:
            attempts = [0]
            def _wait_for_final_width():
                self._tab_place_timer = None
                try:
                    if not self.controls_container.winfo_exists():
                        return
                    width_now = self.controls_container.winfo_width()
                except Exception:
                    return
                attempts[0] += 1
                if (width_now > 100 and width_now != width_before) or attempts[0] >= 40:
                    _place_tab()
                else:
                    self._tab_place_timer = self.after(10, _wait_for_final_width)
            self._tab_place_timer = self.after_idle(_wait_for_final_width)
        self.current_tab = tab_id

    def _build_api_tab(self, parent):
        frame = ctk.CTkFrame(parent, fg_color="transparent", corner_radius=10)
        
        grid_container = ctk.CTkFrame(frame, fg_color="transparent")
        grid_container.pack(fill="x", padx=40, pady=40)
        grid_container.grid_columnconfigure(0, weight=1, uniform="col")
        grid_container.grid_columnconfigure(1, weight=1, uniform="col")
        
        p1 = ctk.CTkFrame(grid_container, fg_color="transparent")
        p1.grid(row=0, column=0, sticky="ew", padx=(0, 20), pady=(0, 30))
        ctk.CTkLabel(p1, text="Select AI Platform", font=Font.base(13, "bold"), text_color=Color.TEXT_SECONDARY).pack(anchor="w", pady=(0, 10))
        
        self.provider_var = tk.StringVar(value=get_setting("api_provider_name") or "Google AI Studio")
        provider_menu = ctk.CTkOptionMenu(
            p1, variable=self.provider_var, values=list(self.app.API_PRESETS.keys()), 
            fg_color=Color.INPUT_BG, button_color=Color.INPUT_BG, button_hover_color=Color.HOVER_BG, 
            font=Font.base(14), height=40, corner_radius=6, command=self._on_provider_change
        )
        provider_menu.pack(fill="x")

        p2 = ctk.CTkFrame(grid_container, fg_color="transparent")
        p2.grid(row=0, column=1, sticky="ew", padx=(20, 0), pady=(0, 30))
        ctk.CTkLabel(p2, text="Base URL", font=Font.base(13, "bold"), text_color=Color.TEXT_SECONDARY).pack(anchor="w", pady=(0, 10))
        
        self.url_entry = ctk.CTkEntry(p2, font=Font.base(14), height=40, fg_color=Color.INPUT_BG, border_color=Color.BORDER, corner_radius=6)
        self.app.apply_focus_ring(self.url_entry)
        self.url_entry.insert(0, get_setting("api_base_url") or self.app.API_PRESETS["Google AI Studio"]["url"])
        self.url_entry.pack(fill="x")

        p3 = ctk.CTkFrame(grid_container, fg_color="transparent")
        p3.grid(row=1, column=0, sticky="ew", padx=(0, 20), pady=(0, 25))
        ctk.CTkLabel(p3, text="Model Name", font=Font.base(13, "bold"), text_color=Color.TEXT_SECONDARY).pack(anchor="w", pady=(0, 10))
        
        self.model_entry = ctk.CTkEntry(p3, font=Font.base(14), height=40, fg_color=Color.INPUT_BG, border_color=Color.BORDER, corner_radius=6)
        self.app.apply_focus_ring(self.model_entry)
        self.model_entry.insert(0, get_setting("api_model") or self.app.API_PRESETS["Google AI Studio"]["model"])
        self.model_entry.pack(fill="x")
        
        p4 = ctk.CTkFrame(grid_container, fg_color="transparent")
        p4.grid(row=1, column=1, sticky="ew", padx=(20, 0), pady=(0, 25))
        ctk.CTkLabel(p4, text="API Key", font=Font.base(13, "bold"), text_color=Color.TEXT_SECONDARY).pack(anchor="w", pady=(0, 10))
        
        self.api_key_entry = ctk.CTkEntry(p4, font=Font.base(14), height=40, fg_color=Color.INPUT_BG, border_color=Color.BORDER, corner_radius=6)
        self.app.apply_focus_ring(self.api_key_entry)
        
        # Per-provider key storage: migrate the legacy shared key once,
        # then show the key saved for the currently selected provider.
        migrate_legacy_key(self.provider_var.get())
        saved_key = get_provider_key(self.provider_var.get()) or get_setting("gemini_api_key")
        if saved_key: 
            self.api_key_entry.insert(0, saved_key)
            self.api_key_entry.configure(show="•")
            
        self.api_key_entry.bind("<FocusIn>", lambda e: self.api_key_entry.configure(show=""), add="+")
        self.api_key_entry.bind("<FocusOut>", lambda e: self.api_key_entry.configure(show="•"), add="+")
        self.api_key_entry.pack(fill="x")

        btn_frame = ctk.CTkFrame(frame, fg_color="transparent")
        btn_frame.pack(fill="x", padx=40, pady=(0, 40))
        
        ctk.CTkButton(
            btn_frame, text="Save Config", width=150, height=40, corner_radius=6,
            fg_color=Color.ACCENT, hover_color=Color.ACCENT_HOVER, text_color="#FFFFFF", 
            font=Font.base(14, "bold"), command=self.save_api_settings
        ).pack(side="left", padx=(0, 15))
                      
        self.test_btn = ctk.CTkButton(
            btn_frame, text="Test Connection", width=160, height=40, corner_radius=6,
            fg_color="transparent", hover_color=Color.HOVER_BG, 
            text_color=Color.TEXT_PRIMARY, border_width=1, border_color=Color.BORDER,
            font=Font.base(14, "bold"), command=self.run_api_test
        )
        self.test_btn.pack(side="left")
        
        self.settings_status = ctk.CTkLabel(btn_frame, text="", font=Font.base(14), text_color=Color.TEXT_SECONDARY)
        self.settings_status.pack(side="left", padx=25)
        
        return frame

    def _build_layout_tab(self, parent, data_dict, min_val, max_val, unit, sliders_conf):
        frame = ctk.CTkFrame(parent, fg_color="transparent", corner_radius=10)
        
        grid_container = ctk.CTkFrame(frame, fg_color="transparent")
        grid_container.pack(fill="x", padx=30, pady=30)
        
        grid_container.grid_columnconfigure(0, weight=1, uniform="col")
        grid_container.grid_columnconfigure(1, weight=1, uniform="col")
        
        row_idx = 0
        col_idx = 0
        
        for label_text, key in sliders_conf:
            slider_wrapper = ctk.CTkFrame(
                grid_container, fg_color=Color.INPUT_BG, corner_radius=8,
                border_width=1, border_color=Color.BORDER
            )
            
            if col_idx == 0: pad_x = (0, 15)
            else: pad_x = (15, 0)
            
            slider_wrapper.grid(row=row_idx, column=col_idx, sticky="ew", padx=pad_x, pady=(0, 20))
            
            header = ctk.CTkFrame(slider_wrapper, fg_color="transparent")
            header.pack(fill="x", padx=15, pady=(10, 0))
            ctk.CTkLabel(header, text=label_text, font=Font.base(13, "bold"), text_color=Color.TEXT_PRIMARY).pack(side="left")
            val_label = ctk.CTkLabel(header, text=f"{int(data_dict[key])} {unit}", font=Font.base(13, "bold"), text_color=Color.ACCENT)
            val_label.pack(side="right")
            
            self.slider_labels[key] = val_label

            def on_slide(val, k=key, vl=val_label, d_dict=data_dict, suffix=unit):
                int_val = int(val)
                if d_dict[k] == int_val: return 
                
                vl.configure(text=f"{int_val} {suffix}")
                d_dict[k] = int_val
                self.app.layout_version += 1
                
                if self._preview_timer:
                    self.after_cancel(self._preview_timer)
                    
                def apply_ui_change():
                    self.preview_list.render()
                    self.app._needs_notebook_refresh = True
                    self._preview_timer = None
                    
                self._preview_timer = self.after(16, apply_ui_change)
                
                if k in self._db_timers and self._db_timers[k]:
                    self.after_cancel(self._db_timers[k])
                    
                def apply_db_change(key_to_save=k, val_to_save=int_val):
                    save_setting(key_to_save, str(val_to_save))
                    self._db_timers[key_to_save] = None
                    self._pending_setting_saves.pop(key_to_save, None)

                self._pending_setting_saves[k] = int_val
                self._db_timers[k] = self.after(500, apply_db_change)

            slider = ctk.CTkSlider(
                slider_wrapper, from_=min_val, to=max_val, command=on_slide, 
                button_color=Color.ACCENT, button_hover_color=Color.ACCENT_HOVER,
                progress_color=Color.ACCENT
            )
            slider.set(data_dict[key])
            slider.pack(fill="x", padx=15, pady=(8, 15))
            
            self.sliders[key] = slider
            
            col_idx += 1
            if col_idx > 1:
                col_idx = 0
                row_idx += 1
                
        return frame

    def _on_provider_change(self, choice):
        preset = self.app.API_PRESETS.get(choice)
        if preset:
            self.url_entry.delete(0, 'end')
            self.url_entry.insert(0, preset["url"])
            self.model_entry.delete(0, 'end')
            self.model_entry.insert(0, preset["model"])
        # Load the key saved for the newly selected provider so previously
        # entered keys never need retyping (the Quiz page relies on these
        # per-provider keys as well).
        stored_key = get_provider_key(choice)
        self.api_key_entry.delete(0, 'end')
        if stored_key:
            self.api_key_entry.insert(0, stored_key)
            self.api_key_entry.configure(show="•")
        else:
            self.api_key_entry.configure(show="")

    def get_current_provider_config(self):
        return {
            "type": self.app.API_PRESETS.get(self.provider_var.get(), {}).get("type", "openai_compatible"), 
            "base_url": self.url_entry.get().strip(), 
            "model": self.model_entry.get().strip()
        }

    def save_api_settings(self):
        save_setting("api_provider_name", self.provider_var.get())
        save_setting("api_model", self.model_entry.get().strip())
        save_setting("api_base_url", self.url_entry.get().strip())
        save_setting("gemini_api_key", self.api_key_entry.get().strip())
        # Permanently remember this key for the selected provider (the
        # legacy setting above is kept in sync for older code paths).
        save_provider_key(self.provider_var.get(), self.api_key_entry.get().strip())
        self.app.api_key = self.api_key_entry.get().strip()
        # The key is stored as plain text in the local settings DB, so the
        # label no longer claims secure storage.
        self.settings_status.configure(text="Settings saved!", text_color=Color.SUCCESS)

    def run_api_test(self):
        self.settings_status.configure(text="Testing...", text_color=Color.ACCENT)
        self.test_btn.configure(state="disabled")
        config = self.get_current_provider_config()
        api_key_to_test = self.api_key_entry.get().strip()
        # M2: if the request hangs, re-enable the Test button after 60s so
        # the page cannot be left permanently un-testable. The sequence token
        # keeps an old watchdog from touching a newer test run; a late real
        # result still overwrites the timeout message.
        self._api_test_seq = getattr(self, '_api_test_seq', 0) + 1
        seq = self._api_test_seq

        def watchdog(s=seq):
            try:
                if s == self._api_test_seq and str(self.test_btn.cget("state")) == "disabled":
                    self.test_btn.configure(state="normal")
                    self.settings_status.configure(text="Test timed out. Check your connection.", text_color=Color.DANGER)
            except Exception:
                pass
        self.after(60000, watchdog)
        
        def bg_task():
            try:
                success, msg = _test_gemini_connection(api_key_to_test, config)
            except Exception as e:
                success, msg = False, f"Crash: {str(e)}"
            try:
                self.after(0, lambda: self.settings_status.configure(text=msg, text_color=Color.SUCCESS if success else Color.DANGER))
                self.after(0, lambda: self.test_btn.configure(state="normal"))
            except Exception:
                # The settings page/app was destroyed while the test ran.
                pass
            
        threading.Thread(target=bg_task, daemon=True).start()


# =======================================================================
# NOTEBOOK PAGE
# =======================================================================
class NotebookPage(ctk.CTkFrame):
    def __init__(self, master, app):
        super().__init__(master, fg_color=Color.APP_BG, corner_radius=0)
        self.app = app
        self._zoom_timer = None
        self._fast_zoom_scheduled = False
        
        self.header_container = tk.Frame(self, bg=Color.APP_BG)
        self.header_container.pack(fill="x", padx=45, pady=(30, 15))

        row1 = tk.Frame(self.header_container, bg=Color.APP_BG)
        row1.pack(fill="x", pady=(0, 20))
        self.header_title = ctk.CTkLabel(row1, text="My Notebook", font=Font.base(28, "bold"), text_color=Color.TEXT_PRIMARY)
        self.header_title.pack(side="left")

        toolbar = ctk.CTkFrame(self.header_container, fg_color="transparent")
        toolbar.pack(fill="x")
        
        toolbar.grid_columnconfigure(0, weight=0) 
        toolbar.grid_columnconfigure(1, weight=1) 
        toolbar.grid_columnconfigure(2, weight=0) 
        toolbar.grid_columnconfigure(3, weight=0) 
        toolbar.grid_columnconfigure(4, weight=0) 
        toolbar.grid_columnconfigure(5, weight=0) 
        toolbar.grid_columnconfigure(6, weight=0) 
        toolbar.grid_columnconfigure(7, weight=0) 
        
        toolbar.grid_rowconfigure(0, weight=1)
        
        search_box = ctk.CTkFrame(toolbar, fg_color=Color.INPUT_BG, border_color=Color.BORDER, border_width=1, corner_radius=6)
        search_box.grid(row=0, column=0, sticky="w")
        
        self.search_entry = ctk.CTkEntry(
            search_box, placeholder_text="Search notebook...", width=220, height=36, 
            font=Font.base(14), fg_color="transparent", border_width=0, text_color=Color.TEXT_PRIMARY
        )
        self.search_entry.pack(side="left", padx=(10, 0), pady=0)
        
        self._search_timer = None
        def on_search_type(e):
            if self._search_timer: 
                self.after_cancel(self._search_timer)
            self._search_timer = self.after(300, self.app.load_words)
        self.search_entry.bind("<KeyRelease>", on_search_type)
        
        self.search_all_var = tk.BooleanVar(value=True)
        ctk.CTkCheckBox(
            search_box, text="Search all volumes", variable=self.search_all_var, font=Font.base(12), 
            text_color=Color.TEXT_SECONDARY, fg_color=Color.ACCENT, hover_color=Color.ACCENT_HOVER, 
            border_color=Color.BORDER, border_width=1, corner_radius=4,
            command=self.app.load_words, checkbox_width=20, checkbox_height=20
        ).pack(side="left", padx=(5, 10))

        tk.Frame(toolbar, bg=Color.APP_BG).grid(row=0, column=1, sticky="ew")

        self.add_word_entry = ctk.CTkEntry(
            toolbar, placeholder_text="Enter word to add...", width=200, height=36, 
            font=Font.base(14), fg_color=Color.INPUT_BG, border_width=1, 
            border_color=Color.BORDER, corner_radius=6
        )
        self.app.apply_focus_ring(self.add_word_entry)
        self.add_word_entry.grid(row=0, column=2, padx=(10, 10))
        self.add_word_entry.bind("<Return>", lambda e: self.app.add_new_word())
        
        add_btn = ctk.CTkButton(
            toolbar, text="+ New", width=90, height=36, corner_radius=6, 
            fg_color=Color.ACCENT, hover_color=Color.ACCENT_HOVER, text_color="#FFFFFF", 
            font=Font.base(13, "bold"), command=self.app.add_new_word
        )
        add_btn.grid(row=0, column=3, padx=(0, 10))
        
        tk.Frame(toolbar, bg=Color.BORDER, width=1, height=30).grid(row=0, column=4, padx=15)
        
        ctk.CTkLabel(toolbar, text="SCALE", font=Font.base(11, "bold"), text_color=Color.TEXT_MUTED).grid(row=0, column=5, padx=(5, 5))
        
        self.zoom_slider = ctk.CTkSlider(
            toolbar, from_=0.5, to=1.5, width=90, command=self.on_zoom_changed, 
            button_color=Color.ACCENT, button_hover_color=Color.ACCENT_HOVER, progress_color=Color.ACCENT
        )
        self.zoom_slider.set(self.app.zoom_factor)
        self.zoom_slider.grid(row=0, column=6, padx=(0, 10))
        self.zoom_slider.bind("<ButtonRelease-1>", lambda e: (save_setting("zoom_factor", str(self.app.zoom_factor)), setattr(self.app, "_zoom_dirty", False)))
        
        self.zoom_label = ctk.CTkLabel(toolbar, text=f"{int(self.app.zoom_factor * 100)}%", font=Font.base(12, "bold"), text_color=Color.TEXT_PRIMARY)
        self.zoom_label.grid(row=0, column=7, padx=(0, 15))

        self.status_label = ctk.CTkLabel(self, text="", font=Font.base(13), text_color=Color.TEXT_SECONDARY, height=20)
        self.status_label.pack(anchor="w", padx=45, pady=(0, 0))
        
        self.word_list_frame = WordListView(self, self.app)
        self.word_list_frame.pack(side="top", fill="both", expand=True, padx=45, pady=(0, 10))

    def on_zoom_changed(self, v):
        self.app.zoom_factor = v
        self.app._zoom_dirty = True
        self.zoom_label.configure(text=f"{int(v * 100)}%")
        if self._zoom_timer:
            self.after_cancel(self._zoom_timer)
        # Real-time preview while the slider is dragged: redraw right away
        # using card heights scaled from the last exact layout (no per-word
        # text measurement), throttled to ~30 fps. The debounced exact,
        # pixel-identical relayout below still runs once the drag pauses,
        # exactly as before.
        if not self._fast_zoom_scheduled:
            self._fast_zoom_scheduled = True
            def fast_zoom_render():
                self._fast_zoom_scheduled = False
                try:
                    if self.winfo_exists():
                        self.word_list_frame.render(fast_zoom=True)
                except Exception:
                    pass
            self.after(33, fast_zoom_render)
        def apply_zoom_render():
            self.word_list_frame.render()
            self._zoom_timer = None
        self._zoom_timer = self.after(150, apply_zoom_render)
# =======================================================================
# MAIN APPLICATION ROOT
# =======================================================================
class VocabNoteApp(ctk.CTk):
    
    API_PRESETS = {
        "Google AI Studio": {"url": "https://generativelanguage.googleapis.com/v1beta/models", "model": "gemini-3.1-flash-lite", "type": "google"},
        "Agent Router": {"url": "https://agentrouter.org/v1", "model": "claude-opus-4-8", "type": "openai_compatible"},
        "Groq": {"url": "https://api.groq.com/openai/v1", "model": "llama3-8b-8192", "type": "openai_compatible"},
        "Mistral AI": {"url": "https://api.mistral.ai/v1", "model": "mistral-small-latest", "type": "openai_compatible"},
        "GitHub Models": {"url": "https://models.inference.ai.azure.com", "model": "gpt-4o", "type": "openai_compatible"},
        "OpenRouter": {"url": "https://openrouter.ai/api/v1", "model": "google/gemini-2.5-flash:free", "type": "openai_compatible"},
        "Hugging Face": {"url": "https://api-inference.huggingface.co/v1", "model": "meta-llama/Meta-Llama-3-8B-Instruct", "type": "openai_compatible"}
    }
    
    def __init__(self):
        super().__init__()
        # First-frame-perfect startup: the window stays unmapped for the
        # whole of __init__ without any explicit withdraw() -- on Windows,
        # CTk itself keeps it withdrawn while applying the dark titlebar,
        # and on all platforms Tk maps the window only once the event loop
        # runs. IMPORTANT: never call self.withdraw() here. CTk's
        # overridden withdraw() would set
        # _withdraw_called_before_window_exists, which makes CTk.mainloop()
        # skip its startup deiconify() on Windows and leaves the app
        # permanently hidden. The first real render happens at the end of
        # __init__, while the window is still unmapped.
        Font._init_bangla(self)
        init_db()
        self._pending_words = set()
        self._import_in_progress = False
        self._export_in_progress = False
        self.layout_version = 0
        self.tts_manager = TTSManager()
        # Quiz feature: the page is built lazily on first open (open_quiz)
        # so it adds zero startup cost; the flag prevents duplicate generations.
        self.quiz_page = None
        self._quiz_generation_active = False
        self.raw_icons = {}
        self.svg_icons = {}
        self.icon_cache = collections.OrderedDict()
        self.font_metrics_cache = collections.OrderedDict()
        self.font_obj_cache = collections.OrderedDict()
        self._load_raw_icons()
        self.api_key = get_setting("gemini_api_key")
        self.tooltip_manager = TooltipManager(self)

        self._needs_notebook_refresh = False
        self._zoom_dirty = False
        
        try: 
            self.zoom_factor = max(0.5, float(get_setting("zoom_factor") or 0.8))
        except ValueError: 
            self.zoom_factor = 0.8
            
        self.DEFAULT_FONTS = {
            'title_size': 20, 'meaning_size': 12, 'bangla_size': 12, 
            'example_size': 12, 'synonyms_size': 12, 'antonyms_size': 12, 'notes_size': 12
        }
        self.DEFAULT_SPACINGS = {
            'title_gap': 44, 'meaning_gap': 0, 'bangla_meaning_gap': 0, 
            'example_sentence_gap': 0, 'synonyms_gap': 0, 'antonyms_gap': 12, 
            'notes_gap': 12, 'card_padding_bottom': 8
        }
        
        self.font_sizes = {k: int(get_setting(k) or v) for k, v in self.DEFAULT_FONTS.items()}
        self.spacings = {k: float(get_setting(k) or v) for k, v in self.DEFAULT_SPACINGS.items()}
        
        self.current_volume_id = None
        self.default_volume_id = None
        self.show_favorites_only = False
        self.volume_buttons = []
        self.volume_opts_buttons = []

        self.title("VocabNote")
        if os.path.exists(resource_path("vocab_icon.ico")): 
            self.iconbitmap(resource_path("vocab_icon.ico"))
            
        self.geometry("1300x900")
        self.minsize(1250, 750) 
        self.configure(fg_color=Color.APP_BG)
        
        self.grid_columnconfigure(1, weight=1)
        self.grid_rowconfigure(0, weight=1)

        self.setup_sidebar()
        self.notebook_page = NotebookPage(self, self)
        self.settings_page = SettingsPage(self, self)
        
        self.bind("<Control-f>", lambda e: self.notebook_page.search_entry.focus_set())
        self.bind("<Control-n>", lambda e: self.notebook_page.add_word_entry.focus_set())
        self.bind("<Escape>", lambda e: self.cancel_edit())
        self.bind("<Up>", lambda e: None if (self._typing_in_progress() or self._quiz_is_active()) else self.notebook_page.word_list_frame._on_up_arrow(e))
        self.bind("<Down>", lambda e: None if (self._typing_in_progress() or self._quiz_is_active()) else self.notebook_page.word_list_frame._on_down_arrow(e))
        self.bind("<Return>", lambda e: None if (self._typing_in_progress() or self._quiz_is_active()) else self.notebook_page.word_list_frame._on_enter_key(e))
        self.bind("<Delete>", lambda e: None if (self._typing_in_progress() or self._quiz_is_active()) else self.notebook_page.word_list_frame._on_delete_key(e))

        # One-time invisible warm-up of the Settings tab layouts shortly
        # after startup (see _prewarm_settings_tabs).
        self.after(600, self._prewarm_settings_tabs)
        
        self.view_all_words()
        self.refresh_volumes_dashboard()
        
        for e in ["<MouseWheel>", "<Button-4>", "<Button-5>"]: 
            self.bind_all(e, self._global_mousewheel)

        self.protocol("WM_DELETE_WINDOW", self._on_close)

        # Visibility guarantee: the window must always become visible
        # shortly after mainloop() starts, no matter what happens in the
        # first render below or inside CTk's own startup logic.
        # after_idle fires right after CTk.mainloop() has finished its
        # titlebar/deiconify preamble; the 1s check is a second line of
        # defense for pathological cases.
        self.after_idle(self._ensure_window_visible)
        self.after(1000, self._ensure_window_visible)

        # Perform the first real render while the window is still unmapped:
        # update_idletasks() finalizes widget geometry (the canvas gets its
        # real width) without mapping the window, so render() lays out and
        # draws the cards exactly as they will appear on screen. The user's
        # first visible frame is therefore the finished one -- no
        # intermediate rendering state is ever presented. The window itself
        # is shown by CTk.mainloop()'s normal startup deiconify().
        try:
            self.update_idletasks()
            self.notebook_page.word_list_frame.render()
            self.notebook_page.word_list_frame._awaiting_first_visible_configure = True
        except Exception:
            # Never let a failed first render abort or hide the app; the
            # <Configure> fast path in WordListView repairs the content on
            # first mapping.
            pass

    def _ensure_window_visible(self):
        # Safety net against the app staying invisible: CTk.mainloop()
        # skips its startup deiconify() if withdraw()/iconify() was called
        # before the window first existed, and its titlebar-color routine
        # withdraws the window temporarily. If anything ever leaves the
        # window withdrawn after startup, show it.
        try:
            if self.state() == "withdrawn":
                self.deiconify()
        except Exception:
            pass

    def _load_raw_icons(self):
        if HAS_IMAGETK:
            for name in ["edit", "edit_hover", "refresh", "refresh_hover", "delete", "delete_hover", "mic", "mic_hover"]:
                if HAS_SVG:
                    svg_path = resource_path(f"assets/{name}.svg")
                    if os.path.exists(svg_path):
                        self.svg_icons[name] = svg_path
                        continue
                path = resource_path(f"assets/{name}.png")
                if os.path.exists(path):
                    try:
                        self.raw_icons[name] = Image.open(path)
                    except Exception:
                        pass

    def get_icon(self, name, size):
        if not HAS_IMAGETK: return None
        size = max(1, int(size)) 
        cache_key = (name, size)
        
        if cache_key in self.icon_cache:
            self.icon_cache.move_to_end(cache_key)
            return self.icon_cache[cache_key]
            
        svg_path = self.svg_icons.get(name)
        if svg_path:
            try:
                png_bytes = cairosvg.svg2png(url=svg_path, output_width=size, output_height=size)
                photo = ImageTk.PhotoImage(Image.open(io.BytesIO(png_bytes)))
                self.icon_cache[cache_key] = photo
                if len(self.icon_cache) > 256:
                    try:
                        self.icon_cache.popitem(last=False)
                    except Exception:
                        pass
                return photo
            except Exception:
                pass

        raw_img = self.raw_icons.get(name)
        if raw_img:
            try:
                resized = raw_img.resize((size, size), Image.Resampling.LANCZOS)
                photo = ImageTk.PhotoImage(resized)
                self.icon_cache[cache_key] = photo
                if len(self.icon_cache) > 256:
                    try:
                        self.icon_cache.popitem(last=False)
                    except Exception:
                        pass
                return photo
            except Exception:
                pass
        return None

    def _on_close(self):
        # Best-effort teardown of pending after() timers and the tooltip so the
        # process exits cleanly without stray callback tracebacks on shutdown.
        try:
            self.tooltip_manager.hide(immediate=True)
        except Exception:
            pass
        nb = getattr(self, 'notebook_page', None)
        wl = getattr(nb, 'word_list_frame', None)
        sp = getattr(self, 'settings_page', None)
        qp = getattr(self, 'quiz_page', None)
        for owner, attr in [(nb, '_zoom_timer'), (nb, '_search_timer'),
                            (wl, '_resize_timer'), (wl, '_bg_measure_timer'),
                            (sp, '_preview_timer'), (sp, '_tab_place_timer'),
                            (qp, '_build_timer'), (qp, '_clock_timer')]:
            if owner is None:
                continue
            try:
                tid = getattr(owner, attr, None)
                if tid:
                    self.after_cancel(tid)
            except Exception:
                pass
        try:
            if sp is not None:
                for tid in list(getattr(sp, '_db_timers', {}).values()):
                    if tid:
                        self.after_cancel(tid)
        except Exception:
            pass
        # Flush debounced setting writes that were cancelled above so a quick
        # slider-change-then-close doesn't silently lose the new values.
        try:
            if sp is not None:
                for sk, sval in list(getattr(sp, '_pending_setting_saves', {}).items()):
                    try:
                        save_setting(sk, str(sval))
                    except Exception:
                        pass
        except Exception:
            pass
        try:
            if getattr(self, '_zoom_dirty', False):
                save_setting("zoom_factor", str(self.zoom_factor))
        except Exception:
            pass
        try:
            self.destroy()
        except Exception:
            pass

    def _global_mousewheel(self, event):
        self.tooltip_manager.hide(immediate=True)
        widget = self.winfo_containing(*self.winfo_pointerxy())
        if not widget:
            return
            
        if isinstance(widget, (tk.Text, ctk.CTkTextbox, ctk.CTkEntry)) and str(widget.cget("state")) != "disabled":
            return
            
        if isinstance(widget, (tk.Scrollbar, ctk.CTkScrollbar)): 
            return
            
        widget_path = str(widget)
        scroll_targets = [
            (str(self.notebook_page.word_list_frame), self.notebook_page.word_list_frame.canvas), 
            (str(self.volumes_scroll), self.volumes_scroll._parent_canvas)
        ]
        if self.quiz_page is not None:
            scroll_targets.extend(self.quiz_page.get_scroll_targets())
        for prefix, canvas in scroll_targets:
            if widget_path.startswith(prefix): 
                direction = -1 if (getattr(event, 'num', 0) == 4 or getattr(event, 'delta', 0) > 0) else 1
                canvas.yview_scroll(direction, "units")
                if canvas == self.notebook_page.word_list_frame.canvas:
                    self.notebook_page.word_list_frame._update_viewport()
                break

    def apply_focus_ring(self, widget): 
        # L2: additive bindings so a focus ring can never silently replace
        # another <FocusIn>/<FocusOut> handler bound to the same widget.
        widget.bind("<FocusIn>", lambda e: widget.configure(border_color=Color.ACCENT), add="+")
        widget.bind("<FocusOut>", lambda e: widget.configure(border_color=Color.BORDER), add="+")

    def _typing_in_progress(self): 
        w = self.focus_get()
        if bool(w and isinstance(w, (tk.Entry, tk.Text, ctk.CTkEntry, ctk.CTkTextbox)) and str(w.cget("state")) != "disabled"):
            return True
        if self.notebook_page.word_list_frame.editing_word:
            return True
        return False

    def cancel_edit(self):
        self.notebook_page.word_list_frame.cancel_editing()

    def load_icon(self, filename, size=20):
        if HAS_SVG:
            try:
                base_name = os.path.splitext(filename)[0]
                svg_path = resource_path(f"assets/{base_name}.svg")
                if os.path.exists(svg_path):
                    # Render at 2x so the icon stays crisp on HiDPI displays.
                    png_bytes = cairosvg.svg2png(url=svg_path, output_width=size * 2, output_height=size * 2)
                    img = Image.open(io.BytesIO(png_bytes))
                    return ctk.CTkImage(light_image=img, dark_image=img, size=(size, size))
            except Exception:
                pass
        try:
            return ctk.CTkImage(
                light_image=Image.open(resource_path(f"assets/{filename}")),
                dark_image=Image.open(resource_path(f"assets/{filename}")),
                size=(size, size)
            )
        except Exception:
            return None

    def setup_sidebar(self):
        self.sidebar_container = ctk.CTkFrame(self, width=280, fg_color=Color.SIDEBAR_BG, corner_radius=0)
        self.sidebar_container.grid(row=0, column=0, sticky="nsew")
        self.sidebar_container.pack_propagate(False)
        
        ctk.CTkFrame(self.sidebar_container, width=1, fg_color=Color.BORDER, corner_radius=0).pack(side="right", fill="y")

        icon_notebook = self.load_icon("all_words.png", 18)
        icon_favorites = self.load_icon("favorites.png", 18)
        icon_settings = self.load_icon("settings.png", 18)
        icon_export = self.load_icon("export.png", 18)
        icon_import = self.load_icon("import.png", 18)

        self.sidebar_top = ctk.CTkFrame(self.sidebar_container, fg_color="transparent")
        self.sidebar_top.pack(fill="x", side="top")
        
        header_box = ctk.CTkFrame(self.sidebar_top, fg_color="transparent")
        header_box.pack(fill="x", padx=25, pady=(45, 30))
        ctk.CTkLabel(header_box, text="Vocab", font=Font.base(22, "bold"), text_color=Color.TEXT_PRIMARY).pack(side="left")
        ctk.CTkLabel(header_box, text="Note", font=Font.base(22, "bold"), text_color=Color.ACCENT).pack(side="left")

        self.btn_notebook = ctk.CTkButton(
            self.sidebar_top, text="  All Words", image=icon_notebook, compound="left",
            fg_color=Color.ACCENT, hover_color=Color.ACCENT_HOVER, text_color="#FFFFFF", 
            font=Font.base(14, "bold"), anchor="w", corner_radius=6, height=44, 
            command=self.view_all_words
        )
        self.btn_notebook.pack(fill="x", padx=15, pady=(0, 2))
        
        self.btn_favorites = ctk.CTkButton(
            self.sidebar_top, text="  Favorites", image=icon_favorites, compound="left",
            fg_color="transparent", hover_color=Color.HOVER_BG, text_color=Color.TEXT_SECONDARY, 
            font=Font.base(14, "bold"), anchor="w", corner_radius=6, height=44, 
            command=self.view_favorites
        )
        self.btn_favorites.pack(fill="x", padx=15, pady=2)

        self.sidebar_bottom = ctk.CTkFrame(self.sidebar_container, fg_color="transparent")
        self.sidebar_bottom.pack(fill="x", side="bottom", pady=(0, 20))
        
        self.btn_settings = ctk.CTkButton(
            self.sidebar_bottom, text="  Settings", image=icon_settings, compound="left",
            fg_color="transparent", hover_color=Color.HOVER_BG, text_color=Color.TEXT_SECONDARY, 
            font=Font.base(14, "bold"), anchor="w", corner_radius=6, height=44, 
            command=lambda: self.select_frame("settings")
        )
        self.btn_settings.pack(fill="x", padx=15, pady=2)
        
        self.btn_export = ctk.CTkButton(
            self.sidebar_bottom, text="  Export as DOCX", image=icon_export, compound="left",
            fg_color="transparent", hover_color=Color.HOVER_BG, text_color=Color.TEXT_SECONDARY, 
            font=Font.base(14, "bold"), anchor="w", corner_radius=6, height=44, 
            command=self.export_docx
        )
        self.btn_export.pack(fill="x", padx=15, pady=2)
        
        self.btn_import = ctk.CTkButton(
            self.sidebar_bottom, text="  Import from DOCX", image=icon_import, compound="left",
            fg_color="transparent", hover_color=Color.HOVER_BG, text_color=Color.TEXT_SECONDARY, 
            font=Font.base(14, "bold"), anchor="w", corner_radius=6, height=44, 
            command=self.import_docx
        )
        self.btn_import.pack(fill="x", padx=15, pady=2)

        self.sidebar_middle = ctk.CTkFrame(self.sidebar_container, fg_color="transparent")
        self.sidebar_middle.pack(fill="both", expand=True, side="top")
        
        nav_header = ctk.CTkFrame(self.sidebar_middle, fg_color="transparent")
        nav_header.pack(fill="x", padx=25, pady=(30, 10))
        ctk.CTkLabel(nav_header, text="VOLUMES", font=Font.base(12, "bold"), text_color=Color.TEXT_MUTED).pack(side="left")
        ctk.CTkButton(
            nav_header, text="+", width=28, height=28, corner_radius=4, 
            fg_color="transparent", hover_color=Color.HOVER_BG, text_color=Color.TEXT_PRIMARY, 
            font=Font.base(14, "bold"), command=self.add_volume_ui
        ).pack(side="right")

        # ---- Quiz section (anchored directly below Volumes) ----
        # Packed with side="bottom" BEFORE the volumes scroll so the packer
        # reserves this section's space first; otherwise the expanding
        # volumes list consumes the whole cavity and these buttons get
        # clipped to zero height on shorter windows.
        icon_quiz = self.load_icon("quiz.png", 18)
        icon_quiz_history = self.load_icon("quiz_history.png", 18)

        quiz_header = ctk.CTkFrame(self.sidebar_middle, fg_color="transparent")
        ctk.CTkLabel(quiz_header, text="QUIZ", font=Font.base(12, "bold"), text_color=Color.TEXT_MUTED).pack(side="left")

        self.btn_quiz = ctk.CTkButton(
            self.sidebar_middle, text="  Take Quiz", image=icon_quiz, compound="left",
            fg_color="transparent", hover_color=Color.HOVER_BG, text_color=Color.TEXT_SECONDARY, 
            font=Font.base(14, "bold"), anchor="w", corner_radius=6, height=44, 
            command=lambda: self.open_quiz("setup")
        )

        self.btn_quiz_history = ctk.CTkButton(
            self.sidebar_middle, text="  Quiz History", image=icon_quiz_history, compound="left",
            fg_color="transparent", hover_color=Color.HOVER_BG, text_color=Color.TEXT_SECONDARY, 
            font=Font.base(14, "bold"), anchor="w", corner_radius=6, height=44, 
            command=lambda: self.open_quiz("history")
        )

        # side="bottom" stacks upward, so pack in reverse visual order.
        self.btn_quiz_history.pack(side="bottom", fill="x", padx=15, pady=(2, 12))
        self.btn_quiz.pack(side="bottom", fill="x", padx=15, pady=(0, 2))
        quiz_header.pack(side="bottom", fill="x", padx=25, pady=(10, 10))

        self.volumes_scroll = ctk.CTkScrollableFrame(self.sidebar_middle, fg_color="transparent")
        self.volumes_scroll.pack(fill="both", expand=True, pady=(0, 10))

    def set_sidebar_target(self, target_width):
        """Instant visibility toggle completely bypasses recursive geometry recalculations."""
        if target_width == 0:
            self.sidebar_container.grid_remove()
        else:
            self.sidebar_container.grid()

    def refresh_volumes_dashboard(self):
        """Heavily optimized dashboard updater. Caches widget states to avoid devastating UI thread destruction loops."""
        vols = get_all_volumes()
        current_state = [(v['id'], v['name'], v['word_count']) for v in vols]
        
        if getattr(self, '_last_volumes_state', None) == current_state and len(self.volume_buttons) == len(vols):
            # M3: restyle only buttons whose active state actually changed.
            # CTk widgets redraw on every configure() call even when nothing
            # changed, so unconditionally restyling every volume made each
            # sidebar navigation O(volumes) in redraws.
            states = getattr(self, '_volume_btn_states', None)
            if states is None:
                states = self._volume_btn_states = {}
            for idx, v in enumerate(vols):
                is_active = (v['id'] == self.current_volume_id and not self.show_favorites_only and self.notebook_page.winfo_ismapped())
                if states.get(idx) == is_active:
                    continue
                states[idx] = is_active
                btn = self.volume_buttons[idx]
                btn.configure(
                    fg_color=Color.ACCENT if is_active else "transparent", 
                    text_color="#FFFFFF" if is_active else Color.TEXT_SECONDARY,
                    font=Font.base(14, "bold" if is_active else "normal")
                )
                opts_btn = self.volume_opts_buttons[idx]
                opts_btn.configure(
                    hover_color=Color.ACCENT_HOVER if is_active else Color.HOVER_BG,
                    text_color="#FFFFFF" if is_active else Color.TEXT_SECONDARY
                )
            return

        self._last_volumes_state = current_state
        
        for child in self.volumes_scroll.winfo_children(): 
            child.destroy()
            
        self.volume_buttons.clear()
        self.volume_opts_buttons = []
        # M3: per-index active-state memo used by the fast path above.
        self._volume_btn_states = {}
        
        self.default_volume_id = vols[0]['id'] if vols else None
        if self.current_volume_id is not None and not any(v['id'] == self.current_volume_id for v in vols):
            self.current_volume_id = None
            
        if not vols: 
            ctk.CTkLabel(self.volumes_scroll, text="No volumes yet", text_color=Color.TEXT_MUTED, font=Font.base(13, "italic")).pack(pady=10)
            return
            
        for idx, v in enumerate(vols):
            is_active = (v['id'] == self.current_volume_id and not self.show_favorites_only and self.notebook_page.winfo_ismapped())
            self._volume_btn_states[idx] = is_active
            
            vol_frame = ctk.CTkFrame(self.volumes_scroll, fg_color="transparent", corner_radius=0)
            vol_frame.pack(fill="x", pady=0)
            
            btn = ctk.CTkButton(
                vol_frame, text=f"  {v['name']}  ({v['word_count']})", 
                fg_color=Color.ACCENT if is_active else "transparent", 
                hover_color=Color.ACCENT_HOVER if is_active else Color.HOVER_BG, 
                text_color="#FFFFFF" if is_active else Color.TEXT_SECONDARY, 
                font=Font.base(14, "bold" if is_active else "normal"), 
                anchor="w", height=44, corner_radius=6, 
                command=lambda vid=v['id']: self.on_volume_selected(vid)
            )
            btn.pack(side="left", expand=True, fill="x", padx=(15, 5), pady=2)
            btn.bind("<Button-3>", lambda e, v_id=v['id']: self.on_volume_rclick(e, v_id)) 
            
            opts = ctk.CTkButton(
                vol_frame, text="⋮", width=28, height=28,
                fg_color="transparent", 
                hover_color=Color.ACCENT_HOVER if is_active else Color.HOVER_BG, 
                text_color="#FFFFFF" if is_active else Color.TEXT_SECONDARY, 
                corner_radius=6, font=Font.base(16, "bold"), 
                command=lambda vid=v['id']: self.on_volume_rclick_inline(vid)
            )
            opts.pack(side="right", padx=(0, 15))
            
            self.volume_buttons.append(btn)
            self.volume_opts_buttons.append(opts)

    def on_volume_rclick_inline(self, vid):
        menu = tk.Menu(
            self, tearoff=0, bg=Color.CARD_BG, fg=Color.TEXT_PRIMARY, 
            activebackground=Color.HOVER_BG, activeforeground=Color.TEXT_PRIMARY, 
            borderwidth=1, relief="solid", font=Font.base(12)
        )
        menu.add_command(label="Rename Volume", command=lambda: self.rename_volume_ui(vid))
        menu.add_command(label="Delete Volume", command=lambda: self.delete_volume_ui(vid))
        x, y = self.winfo_pointerxy()
        menu.tk_popup(x, y)
        menu.grab_release()

    def on_volume_rclick(self, event, vid):
        menu = tk.Menu(
            self, tearoff=0, bg=Color.CARD_BG, fg=Color.TEXT_PRIMARY, 
            activebackground=Color.HOVER_BG, activeforeground=Color.TEXT_PRIMARY, 
            borderwidth=1, relief="solid", font=Font.base(12)
        )
        menu.add_command(label="Rename Volume", command=lambda: self.rename_volume_ui(vid))
        menu.add_command(label="Delete Volume", command=lambda: self.delete_volume_ui(vid))
        menu.tk_popup(event.x_root, event.y_root)
        menu.grab_release()

    def on_volume_selected(self, vid): 
        self.current_volume_id = vid
        self.show_favorites_only = False
        self.load_words()
        self.select_frame("notebook")

    def view_all_words(self): 
        self.show_favorites_only = False
        self.current_volume_id = None
        self.load_words()
        self.select_frame("notebook")

    def view_favorites(self): 
        self.show_favorites_only = True
        self.load_words()
        self.select_frame("notebook")

    def add_volume_ui(self):
        dlg = StyledInputDialog(self, "Create Volume", "Enter new volume name")
        self.wait_window(dlg)
        if dlg.result and dlg.result.strip(): 
            create_volume(dlg.result.strip())
            self.refresh_volumes_dashboard()

    def rename_volume_ui(self, vid=None):
        target_vid = vid or self.current_volume_id
        if not target_vid: return
        dlg = StyledInputDialog(self, "Rename Volume", "Enter new name")
        self.wait_window(dlg)
        if dlg.result and dlg.result.strip(): 
            rename_volume(target_vid, dlg.result.strip())
            self.refresh_volumes_dashboard()
            self.load_words()

    def delete_volume_ui(self, vid=None):
        target_vid = vid or self.current_volume_id
        if not target_vid: return
        dlg = StyledConfirmDialog(self, "Delete Volume", "Delete this volume and all its words permanently?", danger=True)
        self.wait_window(dlg)
        if dlg.result and delete_volume(target_vid)[0]: 
            self.current_volume_id = None if self.current_volume_id == target_vid else self.current_volume_id
            self.refresh_volumes_dashboard()
            self.load_words()

    def load_words(self, scroll_to=None, flash=False):
        if self.show_favorites_only:
            header_text = "Favorites"
        elif self.current_volume_id:
            header_text = next((v['name'] for v in get_all_volumes() if v['id'] == self.current_volume_id), "Volume")
        else:
            header_text = "All Words"
            
        self.notebook_page.header_title.configure(text=header_text)
        
        self.notebook_page.word_list_frame.set_words(
            get_all_words_dictionaries(
                search_query=self.notebook_page.search_entry.get().strip(), 
                sort_order="ASC", 
                volume_id=self.current_volume_id if not self.show_favorites_only else None, 
                search_all=self.notebook_page.search_all_var.get(), 
                favorites_only=self.show_favorites_only
            )
        )
        if scroll_to: 
            self.after(50, lambda: self.notebook_page.word_list_frame.scroll_to_word(scroll_to, flash=flash, update_index=not flash))
        else:
            try: 
                self.notebook_page.word_list_frame.canvas.yview_moveto(0)
                self.notebook_page.word_list_frame._update_viewport()
            except Exception: 
                pass

    def add_new_word(self):
        word = self.notebook_page.add_word_entry.get().strip()
        if not word: 
            return
        
        if check_word_exists(word):
            dialog = DuplicateDialog(self, word)
            self.wait_window(dialog)
            if dialog.result == "cancel": 
                return
            elif dialog.result == "open": 
                self.notebook_page.search_entry.delete(0, 'end')
                self.notebook_page.search_all_var.set(True)
                self.load_words(scroll_to=word.lower(), flash=True)
                self.notebook_page.add_word_entry.delete(0, 'end')
                return
                
        raw_key = self.settings_page.api_key_entry.get().strip()
        api_key_to_use = raw_key if raw_key else self.api_key
        
        if not api_key_to_use: 
            StyledConfirmDialog(self, "Missing Key", "Please add API Key in Settings.", confirm_text="OK").wait_window()
            return
            
        pend_key = word.lower()
        if pend_key in self._pending_words:
            return
        self._pending_words.add(pend_key)
        # M2: a hung network request must not lock this word out of
        # add/refresh forever (the pending flag was only ever cleared by the
        # completion callback). If nothing has completed after 60s, release
        # the slot and say so; a late reply is still applied normally by
        # _on_add_complete if it eventually arrives.
        self.after(60000, lambda: self._release_stuck_request(pend_key, f"'{word}' timed out. Please try again."))

        self.notebook_page.status_label.configure(text=f"Enriching '{word}'...", text_color=Color.ACCENT)
        self.update_idletasks()
        
        provider_config = self.settings_page.get_current_provider_config()
        # Capture the destination volume at request time so switching volumes
        # while the background fetch runs cannot re-route the new word.
        target_volume_id = self.current_volume_id if self.current_volume_id is not None else self.default_volume_id
        threading.Thread(target=lambda: self._fetch_and_add(word, api_key_to_use, provider_config, target_volume_id), daemon=True).start()

    def _fetch_and_add(self, word, api_key, provider_config, target_volume_id):
        try:
            data, msg = _fetch_word_details(word, api_key, provider_config)
        except Exception as e:
            data, msg = None, f"Network failed: {str(e)}"
        try:
            self.after(0, lambda: self._on_add_complete(word, data, msg, target_volume_id))
        except Exception:
            # The app was closed while the request was in flight.
            pass

    def _on_add_complete(self, word, data, api_msg, target_volume_id=None):
        self._pending_words.discard(word.lower())
        if data:
            if check_word_exists(word): 
                for f in ['meaning', 'bangla_meaning', 'english_definition', 'ipa', 'part_of_speech', 'example_sentence', 'synonyms', 'antonyms']:
                    if f in data: 
                        update_single_field(word, f, data[f])
            else: 
                if target_volume_id is None:
                    target_volume_id = self.current_volume_id if self.current_volume_id is not None else self.default_volume_id
                save_word_to_db(word, data, target_volume_id)
                
            self.notebook_page.status_label.configure(text=f"'{word}' processed!", text_color=Color.SUCCESS)
            # Only clear the entry if it still holds the submitted word, so a
            # different word the user typed during the background fetch is
            # never wiped out.
            if self.notebook_page.add_word_entry.get().strip().lower() == word.strip().lower():
                self.notebook_page.add_word_entry.delete(0, 'end')
            self._last_volumes_state = None 
            self.refresh_volumes_dashboard()
            self.load_words(scroll_to=word.lower(), flash=True)
            self.after(3000, lambda: self.notebook_page.status_label.configure(text=""))
        else: 
            self.notebook_page.status_label.configure(text=api_msg, text_color=Color.DANGER)

    def _release_stuck_request(self, pend_key, msg):
        """M2: releases a word whose network request never completed so the
        user can retry, instead of the word staying locked out forever."""
        if pend_key in self._pending_words:
            self._pending_words.discard(pend_key)
            try:
                self.notebook_page.status_label.configure(text=msg, text_color=Color.DANGER)
            except Exception:
                pass

    def select_frame(self, name):
        """Instantly maps frames and bypasses heavy DB queries."""
        is_all_words = (name == "notebook" and not self.show_favorites_only and not self.current_volume_id)
        is_favorites = (name == "notebook" and self.show_favorites_only)
        is_settings = (name == "settings")
        is_quiz = (name == "quiz")
        
        self.btn_notebook.configure(
            fg_color=Color.ACCENT if is_all_words else "transparent", 
            text_color="#FFFFFF" if is_all_words else Color.TEXT_SECONDARY
        )
        self.btn_favorites.configure(
            fg_color=Color.ACCENT if is_favorites else "transparent", 
            text_color="#FFFFFF" if is_favorites else Color.TEXT_SECONDARY
        )
        self.btn_settings.configure(
            fg_color=Color.CARD_BG if is_settings else "transparent", 
            text_color=Color.TEXT_PRIMARY if is_settings else Color.TEXT_SECONDARY
        )
        
        self._sync_quiz_nav(is_quiz)
        if name == "notebook": 
            self.set_sidebar_target(280)
            self.settings_page.grid_forget()
            if self.quiz_page is not None:
                self.quiz_page.grid_forget()
            self.notebook_page.grid(row=0, column=1, sticky="nsew")
            
            if getattr(self, '_needs_notebook_refresh', False):
                self.after(0, self.notebook_page.word_list_frame.render)
                self._needs_notebook_refresh = False
                
            self.refresh_volumes_dashboard()
        elif name == "quiz": 
            # Quiz lives beside the notebook, so the sidebar stays visible.
            self.set_sidebar_target(280)
            self.settings_page.grid_forget()
            self.notebook_page.grid_forget()
            self.quiz_page.grid(row=0, column=1, sticky="nsew")
            self.refresh_volumes_dashboard()
        else: 
            self.set_sidebar_target(0)
            self.notebook_page.grid_forget()
            if self.quiz_page is not None:
                self.quiz_page.grid_forget()
            # Clear a possibly in-progress invisible warm-up placement
            # before gridding (harmless no-op otherwise).
            self.settings_page.place_forget()
            self.settings_page.grid(row=0, column=1, sticky="nsew")

    def _quiz_is_active(self):
        """True while the Quiz page is the currently visible page."""
        qp = getattr(self, 'quiz_page', None)
        try:
            return bool(qp is not None and qp.winfo_ismapped())
        except Exception:
            return False

    def _sync_quiz_nav(self, is_quiz=None):
        """Restyles the two Quiz sidebar buttons (same active/inactive recipe
        as the other nav buttons); called from select_frame and whenever the
        quiz page switches between its internal sections."""
        if is_quiz is None:
            is_quiz = self._quiz_is_active()
        section = getattr(self.quiz_page, 'section', 'setup') if self.quiz_page is not None else 'setup'
        take_active = bool(is_quiz and section != "history")
        hist_active = bool(is_quiz and section == "history")
        self.btn_quiz.configure(
            fg_color=Color.ACCENT if take_active else "transparent", 
            text_color="#FFFFFF" if take_active else Color.TEXT_SECONDARY
        )
        self.btn_quiz_history.configure(
            fg_color=Color.ACCENT if hist_active else "transparent", 
            text_color="#FFFFFF" if hist_active else Color.TEXT_SECONDARY
        )

    def open_quiz(self, view="setup"):
        """Entry point for the Quiz feature. The page (and its DB tables) are
        created lazily on the first visit so the feature adds zero startup
        cost; afterwards navigation is instant map/forget like other pages."""
        if self.quiz_page is None:
            from quiz.quiz_page import init_ui, QuizPage
            init_ui(Color, Font, StyledConfirmDialog)
            self.quiz_page = QuizPage(self, self)
        if view == "history":
            self.quiz_page.show_history()
        else:
            self.quiz_page.show_setup()
        self.select_frame("quiz")

    def _prewarm_settings_tabs(self):
        """One-time, invisible warm-up of the Settings page layouts.

        Profiling showed the first visit to each Settings tab paid a
        one-time layout pass (~75-190ms of widget re-renders) because its
        widgets had never been sized at their real on-screen geometry.
        Crucially, the sidebar column is REMOVED while Settings is open,
        so the Settings page is wider than the notebook area -- the
        warm-up must therefore happen at that final width, not inside
        the notebook cell. This places the page at exactly the size it
        will have when really shown, lowered beneath the sidebar and the
        notebook page (never visible), visits each tab once, then tucks
        it away. Aborts immediately and silently if the user opens
        Settings mid-warm-up.
        """
        if getattr(self, '_settings_prewarmed', False):
            return
        self._settings_prewarmed = True
        sp = getattr(self, 'settings_page', None)
        nb = getattr(self, 'notebook_page', None)
        if sp is None or nb is None:
            return
        try:
            if not self.winfo_exists() or sp.winfo_ismapped() or not nb.winfo_ismapped():
                # Settings already open (or notebook not up): skip --
                # real usage will warm the layouts instead.
                return
            # Final Settings geometry: with the sidebar column removed,
            # the page spans from x=0 to the notebook's right edge.
            full_w = nb.winfo_x() + nb.winfo_width()
            full_h = nb.winfo_height()
            if full_w < 400 or full_h < 300:
                return
            sp.place(x=0, y=nb.winfo_y(), width=full_w, height=full_h)
            sp.lower()
        except Exception:
            return

        def hidden():
            # Warm-up is only allowed while the settings page sits mapped
            # UNDER the visible notebook page. Any other state means the
            # user navigated, so stop interfering immediately.
            try:
                return sp.winfo_ismapped() and nb.winfo_ismapped()
            except Exception:
                return False

        def visit_fonts():
            if not hidden(): return
            sp.switch_tab("fonts")
            self.after(450, visit_spacing)

        def visit_spacing():
            if not hidden(): return
            sp.switch_tab("spacing")
            self.after(450, back_to_api)

        def back_to_api():
            if not hidden(): return
            sp.switch_tab("api")
            self.after(450, tuck_away)

        def tuck_away():
            if not hidden(): return
            try:
                sp.place_forget()
            except Exception:
                pass

        self.after(150, visit_fonts)

    def import_docx(self):
        if getattr(self, '_import_in_progress', False) or getattr(self, '_export_in_progress', False):
            return
        file_path = filedialog.askopenfilename(filetypes=[("Word Document", "*.docx")])
        if not file_path: return
        
        # Parse the DOCX off the UI thread so a large file cannot freeze the
        # window. All DB writes stay on the UI thread (_process_import_chunk).
        self._import_in_progress = True
        self.notebook_page.status_label.configure(text="Reading file...", text_color=Color.ACCENT)
        
        def bg_parse(path=file_path):
            try:
                success, result = import_from_docx(path)
            except Exception as e:
                success, result = False, f"Import failed: {str(e)}"
            try:
                self.after(0, lambda: self._on_import_parsed(success, result))
            except Exception:
                # The app was closed while the file was being parsed.
                pass
                
        threading.Thread(target=bg_parse, daemon=True).start()

    def _on_import_parsed(self, success, result):
        if not success or not result: 
            self._import_in_progress = False
            self.notebook_page.status_label.configure(text="")
            StyledConfirmDialog(self, "Error", result if not success else "No words found.", confirm_text="OK", danger=not success).wait_window()
            return
            
        self._import_queue = result
        self._import_index = 0
        self._import_replace_all = False
        self._import_skip_all = False
        self._import_counts = {'imported': 0, 'skipped': 0, 'failed': 0}
        # The destination volume is captured once, so switching volumes while
        # chunks yield to the event loop cannot re-route remaining words.
        self._import_volume_id = self.current_volume_id if self.current_volume_id is not None else self.default_volume_id
        
        self.notebook_page.status_label.configure(text=f"Importing 0/{len(self._import_queue)}...", text_color=Color.ACCENT)
        self._process_import_chunk()

    def _process_import_chunk(self):
        if self._import_index >= len(self._import_queue):
            self._on_import_complete()
            return
            
        chunk_size = 50
        end_idx = min(self._import_index + chunk_size, len(self._import_queue))
        
        for i in range(self._import_index, end_idx):
            w_data = self._import_queue[i]
            word = w_data['word']
            
            if check_word_exists(word):
                if not self._import_replace_all and not self._import_skip_all:
                    dlg = ImportDuplicateDialog(self, word)
                    self.wait_window(dlg)
                    
                    if dlg.result == "cancel": 
                        self._import_index = len(self._import_queue) 
                        break
                    elif dlg.result == "replace_all": 
                        self._import_replace_all = True
                    elif dlg.result == "skip_all": 
                        self._import_skip_all = True
                    elif dlg.result == "replace": 
                        self._force_replace(word, w_data)
                        self._import_counts['imported'] += 1
                        continue
                    elif dlg.result == "skip": 
                        self._import_counts['skipped'] += 1
                        continue
                        
                if self._import_replace_all: 
                    self._force_replace(word, w_data)
                    self._import_counts['imported'] += 1
                elif self._import_skip_all: 
                    self._import_counts['skipped'] += 1
            else:
                if save_word_to_db(word, w_data, self._import_volume_id)[0]: 
                    # M1: skip the extra per-word write (and its commit) when
                    # there are no notes to store; save_word_to_db already
                    # created the row.
                    notes_val = w_data.get('notes', '')
                    if notes_val:
                        update_single_field(word, 'notes', notes_val)
                    self._import_counts['imported'] += 1
                else: 
                    self._import_counts['failed'] += 1
                    
        self._import_index = end_idx
        self.notebook_page.status_label.configure(text=f"Importing {self._import_index}/{len(self._import_queue)}...", text_color=Color.ACCENT)
        self.after(1, self._process_import_chunk)

    def _on_import_complete(self):
        self._import_in_progress = False
        import_count = self._import_counts['imported']
        skip_count = self._import_counts['skipped']
        fail_count = self._import_counts['failed']
        # L1: release the parsed import payload; it could hold thousands of
        # word dicts for the rest of the session otherwise.
        self._import_queue = []
        
        self.notebook_page.status_label.configure(text="")
        StyledConfirmDialog(self, "Summary", f"Imported: {import_count}\nSkipped: {skip_count}\nFailed: {fail_count}", confirm_text="OK").wait_window()
        self._last_volumes_state = None
        self.refresh_volumes_dashboard()
        self.load_words()

    def _force_replace(self, word, data):
        for field in ['meaning', 'bangla_meaning', 'english_definition', 'ipa', 'part_of_speech', 'example_sentence', 'synonyms', 'antonyms', 'notes']:
            if field in data: 
                update_single_field(word, field, data[field])

    def export_docx(self):
        if getattr(self, '_export_in_progress', False) or getattr(self, '_import_in_progress', False):
            return
        dlg = ExportSelectionDialog(self, self.current_volume_id, get_all_volumes())
        self.wait_window(dlg)
        if not dlg.result: 
            return
        
        if dlg.result['type'] == 'all':
            words = get_all_words_dictionaries(search_all=True, sort_order="ASC")
        else:
            target_volume = self.current_volume_id if self.current_volume_id is not None else self.default_volume_id
            words = get_all_words_dictionaries(volume_id=target_volume, sort_order="ASC")
            
        if not words: 
            StyledConfirmDialog(self, "Failed", "No words found.", confirm_text="OK", danger=True).wait_window()
            return
            
        path = filedialog.asksaveasfilename(defaultextension=".docx", filetypes=[("Word Document", "*.docx")])
        if not path: 
            return
            
        # Build the DOCX off the UI thread: document generation for large
        # notebooks takes long enough to freeze the window otherwise. All DB
        # reads already happened above, on the UI thread.
        self._export_in_progress = True
        self.notebook_page.status_label.configure(text="Exporting...", text_color=Color.ACCENT)
        
        def bg_export(words=words, path=path):
            try:
                success, msg = export_to_docx(words, path)
            except Exception as e:
                success, msg = False, f"Export failed: {str(e)}"
            try:
                self.after(0, lambda: self._on_export_complete(success, msg))
            except Exception:
                # The app was closed while the export ran.
                pass
                
        threading.Thread(target=bg_export, daemon=True).start()

    def _on_export_complete(self, success, msg):
        self._export_in_progress = False
        self.notebook_page.status_label.configure(text="")
        StyledConfirmDialog(self, "Success" if success else "Error", msg, confirm_text="OK", danger=not success).wait_window()


if __name__ == "__main__":
    app = VocabNoteApp()
    app.mainloop()