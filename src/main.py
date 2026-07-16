import tkinter as tk
import sys
import os
import customtkinter as ctk
from tkinter import messagebox
import re
import threading
from api.gemini import test_gemini_connection, fetch_word_details
from database.db_manager import (
    init_db, save_word_to_db, get_all_words_dictionaries, 
    update_single_field, delete_word, check_word_exists,
    get_setting, save_setting, get_all_volumes, create_volume,
    rename_volume, delete_volume
)
from utils.export_manager import export_to_docx, import_from_docx
from customtkinter import filedialog

# --- Premium Design System ---
BG_MAIN = "#0E0E10"
BG_SIDEBAR = "#18181B"
BG_CARD = "#27272A"
TEXT_PRIMARY = "#FAFAFA"
TEXT_MUTED = "#A1A1AA"
ACCENT = "#2563EB"
ACCENT_HOVER = "#1D4ED8"
HIGHLIGHT_COLOR = "#FBBF24"



def resource_path(relative_path):
    """ Get absolute path to resource, works for dev and for PyInstaller """
    try:
        base_path = sys._MEIPASS
    except Exception:
        base_path = os.path.abspath(".")
    return os.path.join(base_path, relative_path)

ctk.set_appearance_mode("dark")

class ExportSelectionDialog(ctk.CTkToplevel):
    def __init__(self, master, current_vol_id, all_volumes):
        super().__init__(master)
        self.title("Export Notebook to DOCX")
        self.geometry("450x500")
        self.result = None
        self.transient(master)
        self.grab_set()
        self.configure(fg_color=BG_CARD)
        
        self.export_type = tk.StringVar(value="current")
        ctk.CTkLabel(self, text="Select Export Scope", font=("Segoe UI", 18, "bold"), text_color=TEXT_PRIMARY).pack(pady=(25, 15))
        
        rb_frame = ctk.CTkFrame(self, fg_color=BG_CARD)
        rb_frame.pack(fill="x", padx=40)
        ctk.CTkRadioButton(rb_frame, text="Active Volume Only", variable=self.export_type, value="current", font=("Segoe UI", 14), command=self.toggle_custom).pack(anchor="w", pady=8)
        ctk.CTkRadioButton(rb_frame, text="Entire Notebook", variable=self.export_type, value="all", font=("Segoe UI", 14), command=self.toggle_custom).pack(anchor="w", pady=8)
        ctk.CTkRadioButton(rb_frame, text="Specific Volumes", variable=self.export_type, value="custom", font=("Segoe UI", 14), command=self.toggle_custom).pack(anchor="w", pady=8)
        
        self.custom_frame = ctk.CTkScrollableFrame(self, fg_color=BG_MAIN, height=150, corner_radius=8)
        self.custom_frame.pack(fill="x", padx=40, pady=(15, 10))
        
        self.vol_vars = {}
        for vol in all_volumes:
            var = tk.BooleanVar(value=(vol['id'] == current_vol_id))
            ctk.CTkCheckBox(self.custom_frame, text=f"{vol['name']} ({vol['word_count']} words)", font=("Segoe UI", 13), variable=var).pack(anchor="w", pady=5, padx=10)
            self.vol_vars[vol['id']] = var
            
        self.toggle_custom()
        btn_frame = ctk.CTkFrame(self, fg_color=BG_CARD)
        btn_frame.pack(fill="x", padx=40, pady=20)
        ctk.CTkButton(btn_frame, text="Export", fg_color=ACCENT, hover_color=ACCENT_HOVER, height=36, font=("Segoe UI", 14, "bold"), command=self.confirm).pack(side="left", expand=True, padx=5)
        ctk.CTkButton(btn_frame, text="Cancel", fg_color="#3F3F46", hover_color="#52525B", height=36, font=("Segoe UI", 14), command=self.destroy).pack(side="left", expand=True, padx=5)
        
    def toggle_custom(self):
        state = "normal" if self.export_type.get() == "custom" else "disabled"
        for child in self.custom_frame.winfo_children(): child.configure(state=state)
            
    def confirm(self):
        t = self.export_type.get()
        if t == "custom":
            selected = [vid for vid, var in self.vol_vars.items() if var.get()]
            if not selected:
                messagebox.showwarning("Warning", "Please select at least one volume.")
                return
            self.result = {'type': 'custom', 'volumes': selected}
        else: self.result = {'type': t}
        self.destroy()

class ImportDuplicateDialog(ctk.CTkToplevel):
    def __init__(self, master, word):
        super().__init__(master)
        self.title("Duplicate Found")
        self.geometry("600x200")
        self.result = "skip"
        self.transient(master)
        self.grab_set()
        self.configure(fg_color=BG_CARD)
        
        ctk.CTkLabel(self, text=f"'{word.capitalize()}' already exists. What should we do?", font=("Segoe UI", 16, "bold"), text_color=TEXT_PRIMARY).pack(pady=(20, 25))
        btn_frame = ctk.CTkFrame(self, fg_color=BG_CARD)
        btn_frame.pack(fill="x", padx=15)
        ctk.CTkButton(btn_frame, text="Replace", fg_color=ACCENT, hover_color=ACCENT_HOVER, command=lambda: self.set_result("replace")).pack(side="left", padx=5, expand=True)
        ctk.CTkButton(btn_frame, text="Skip", fg_color="#3F3F46", hover_color="#52525B", command=lambda: self.set_result("skip")).pack(side="left", padx=5, expand=True)
        ctk.CTkButton(btn_frame, text="Replace All", fg_color="#991B1B", hover_color="#7F1D1D", command=lambda: self.set_result("replace_all")).pack(side="left", padx=5, expand=True)
        ctk.CTkButton(btn_frame, text="Skip All", fg_color="#3F3F46", hover_color="#52525B", command=lambda: self.set_result("skip_all")).pack(side="left", padx=5, expand=True)
        
    def set_result(self, res):
        self.result = res
        self.destroy()

class DuplicateDialog(ctk.CTkToplevel):
    def __init__(self, master, word):
        super().__init__(master)
        self.title("Duplicate Detected")
        self.geometry("500x200")
        self.result = "cancel"
        self.transient(master)
        self.grab_set()
        self.configure(fg_color=BG_CARD)
        
        ctk.CTkLabel(self, text=f"'{word.capitalize()}' is already in your notebook.", font=("Segoe UI", 18, "bold"), text_color=TEXT_PRIMARY).pack(pady=(30, 25))
        btn_frame = ctk.CTkFrame(self, fg_color=BG_CARD)
        btn_frame.pack(fill="x", padx=20)
        ctk.CTkButton(btn_frame, text="Open Entry", fg_color=ACCENT, hover_color=ACCENT_HOVER, command=lambda: self.set_result("open")).pack(side="left", padx=5, expand=True)
        ctk.CTkButton(btn_frame, text="Replace AI Data", fg_color="#991B1B", hover_color="#7F1D1D", command=lambda: self.set_result("replace")).pack(side="left", padx=5, expand=True)
        ctk.CTkButton(btn_frame, text="Cancel", fg_color="#3F3F46", hover_color="#52525B", command=lambda: self.set_result("cancel")).pack(side="left", padx=5, expand=True)
        
    def set_result(self, res):
        self.result = res
        self.destroy()


# =========================================================================================
# THE DYNAMIC SCALING CANVAS ENGINE
# =========================================================================================

class WordListView(ctk.CTkFrame):
    def __init__(self, master, app):
        super().__init__(master, fg_color=BG_MAIN, corner_radius=0)
        self.app = app
        self.words = []
        
        self.editing_word = None
        self.open_notes = set()
        self.edit_widgets = {}
        
        self.canvas = tk.Canvas(self, bg=BG_MAIN, highlightthickness=0)
        self.scrollbar = ctk.CTkScrollbar(self, command=self.canvas.yview)
        self.canvas.configure(yscrollcommand=self.scrollbar.set)
        
        self.canvas.pack(side="left", fill="both", expand=True)
        self.scrollbar.pack(side="right", fill="y")
        
        self.canvas.bind("<Configure>", lambda e: self.render())
        self.canvas.bind("<Enter>", self._bind_mouse)
        self.canvas.bind("<Leave>", self._unbind_mouse)

    def _bind_mouse(self, event):
        self.canvas.bind_all("<MouseWheel>", self._on_mousewheel)
        self.canvas.bind_all("<Button-4>", self._on_mousewheel)
        self.canvas.bind_all("<Button-5>", self._on_mousewheel)

    def _unbind_mouse(self, event):
        self.canvas.unbind_all("<MouseWheel>")
        self.canvas.unbind_all("<Button-4>")
        self.canvas.unbind_all("<Button-5>")

    def _on_mousewheel(self, event):
        if event.num == 4 or event.delta > 0:
            self.canvas.yview_scroll(-1, "units")
        elif event.num == 5 or event.delta < 0:
            self.canvas.yview_scroll(1, "units")

    def _z(self, val):
        return max(1, int(val * self.app.zoom_factor))

    def set_words(self, words):
        self.words = words
        self.editing_word = None
        self.render()

    def render(self):
        self.canvas.delete("all")
        for w in self.edit_widgets.values():
            w.destroy()
        self.edit_widgets.clear()
        
        width = self.canvas.winfo_width()
        if width < 100: return 
        
        y_offset = self._z(10)
        for w_data in self.words:
            y_offset = self._draw_card(y_offset, w_data, width)
            y_offset += self._z(25)
            
        self.canvas.configure(scrollregion=self.canvas.bbox("all"))

    # --- Graphics Primitives ---

    def _create_round_rect(self, x1, y1, x2, y2, radius, **kwargs):
        points = [
            x1+radius, y1, x1+radius, y1, x2-radius, y1, x2-radius, y1, 
            x2, y1, x2, y1+radius, x2, y1+radius, x2, y2-radius, 
            x2, y2-radius, x2, y2, x2-radius, y2, x2-radius, y2, 
            x1+radius, y2, x1+radius, y2, x1, y2, x1, y2-radius, 
            x1, y2-radius, x1, y1+radius, x1, y1+radius, x1, y1
        ]
        return self.canvas.create_polygon(points, smooth=True, **kwargs)

    def _update_round_rect(self, item_id, x1, y1, x2, y2, radius):
        points = [
            x1+radius, y1, x1+radius, y1, x2-radius, y1, x2-radius, y1, 
            x2, y1, x2, y1+radius, x2, y1+radius, x2, y2-radius, 
            x2, y2-radius, x2, y2, x2-radius, y2, x2-radius, y2, 
            x1+radius, y2, x1+radius, y2, x1, y2, x1, y2-radius, 
            x1, y2-radius, x1, y1+radius, x1, y1+radius, x1, y1
        ]
        self.canvas.coords(item_id, *points)

    def _draw_button(self, x_right, y_center, text, fg_color, text_color, hover_color, command, word, is_star=False):
        font_size = self._z(24) if is_star else self._z(13)
        temp = self.canvas.create_text(0, -100, text=text, font=("Segoe UI", font_size, "bold"))
        bbox = self.canvas.bbox(temp)
        self.canvas.delete(temp)
        tw = bbox[2] - bbox[0] if bbox else self._z(40)
        
        w = self._z(38) if is_star else tw + self._z(36)
        h = self._z(36)
        x_left = x_right - w
        y_top = y_center - h//2
        y_bot = y_center + h//2
        
        btn_tag = f"btn_{text}_{word}"
        
        rect_id = self._create_round_rect(x_left, y_top, x_right, y_bot, radius=self._z(18) if is_star else self._z(6), fill=fg_color, outline="", tags=(btn_tag, "clickable"))
        self.canvas.create_text(x_left + w//2, y_center, text=text, font=("Segoe UI", font_size, "bold" if not is_star else ""), fill=text_color, tags=(btn_tag, "clickable"))
        
        def on_click(e, cmd=command, w=word): cmd(w)
        def on_enter(e, r=rect_id, hc=hover_color):
            self.canvas.itemconfig(r, fill=hc)
            self.canvas.config(cursor="hand2")
        def on_leave(e, r=rect_id, fc=fg_color):
            self.canvas.itemconfig(r, fill=fc)
            self.canvas.config(cursor="")

        self.canvas.tag_bind(btn_tag, "<Button-1>", on_click)
        self.canvas.tag_bind(btn_tag, "<Enter>", on_enter)
        self.canvas.tag_bind(btn_tag, "<Leave>", on_leave)
        
        return x_left - self._z(12) 

    # --- Interactive Layout Engine ---

    def _draw_interactive_tags(self, start_x, start_y, max_w, items_str, important_str, word, field_key):
        curr_x = start_x
        curr_y = start_y
        line_height = self._z(28)

        items = [s.strip() for s in items_str.split(',') if s.strip()]
        important_items = set(s.strip().lower() for s in important_str.split(',') if s.strip())

        if not items:
            self.canvas.create_text(start_x, start_y, text=f"No {field_key} yet.", font=("Segoe UI", self._z(15)), fill=TEXT_MUTED, anchor="nw")
            return start_y + self._z(35)

        for i, item in enumerate(items):
            is_imp = item.lower() in important_items
            color = HIGHLIGHT_COLOR if is_imp else TEXT_PRIMARY
            font_weight = "bold" if is_imp else "normal"
            font_choice = ("Segoe UI", self._z(17), font_weight)
            
            display_text = item + ("," if i < len(items) - 1 else "")
            
            temp_id = self.canvas.create_text(0, -100, text=display_text, font=font_choice)
            bbox = self.canvas.bbox(temp_id)
            self.canvas.delete(temp_id)
            item_w = bbox[2] - bbox[0] if bbox else 0
            
            if curr_x + item_w > start_x + max_w and curr_x != start_x:
                curr_x = start_x
                curr_y += line_height
                
            text_id = self.canvas.create_text(curr_x, curr_y, text=display_text, font=font_choice, fill=color, anchor="nw", tags="clickable")
            
            def on_enter(e, tid=text_id, f=font_choice):
                self.canvas.itemconfig(tid, font=(f[0], f[1], f[2] + " underline" if f[2] else "underline"))
                self.canvas.config(cursor="hand2")
            def on_leave(e, tid=text_id, f=font_choice):
                self.canvas.itemconfig(tid, font=f)
                self.canvas.config(cursor="")
            def on_click(e, w=word, k=field_key, val=item, cur_imp=important_str):
                self._toggle_important(w, k, val, cur_imp)

            self.canvas.tag_bind(text_id, "<Enter>", on_enter)
            self.canvas.tag_bind(text_id, "<Leave>", on_leave)
            self.canvas.tag_bind(text_id, "<Button-1>", on_click)
            
            curr_x += item_w + self._z(6)

        return curr_y + line_height
        
    def _toggle_important(self, word, field_key, item_val, current_important_str):
        imp_list = [s.strip() for s in current_important_str.split(',') if s.strip()]
        item_lower = item_val.lower()
        
        found = False
        for i, imp in enumerate(imp_list):
            if imp.lower() == item_lower:
                imp_list.pop(i)
                found = True
                break
                
        if not found:
            imp_list.append(item_val)
            
        new_str = ", ".join(imp_list)
        update_single_field(word, f"important_{field_key}", new_str)
        
        for w in self.words:
            if w['word'] == word:
                w[f"important_{field_key}"] = new_str
                break
        self.render()

    def _draw_inline_properties(self, w_data, x1, x2, curr_y, is_edit):
        """Draws PRO, POS, and Meaning cleanly with word wrap support for large properties."""
        if is_edit:
            # Edit Mode leverages the perfectly stacked layout for reliability
            curr_y = self._draw_property_row("PRO", 'ipa', w_data, x1, x2, curr_y, True)
            curr_y = self._draw_property_row("POS", 'part_of_speech', w_data, x1, x2, curr_y, True)
            curr_y = self._draw_property_row("MEANING", 'meaning', w_data, x1, x2, curr_y, True)
            return curr_y
            
        start_x = x1 + self._z(20)
        max_x = x2 - self._z(20)
        
        line_x = start_x
        line_y = curr_y
        max_y = curr_y
        
        def add_item(lbl_text, val_text):
            nonlocal line_x, line_y, max_y
            
            # Predict if this component will breach the line boundary
            est_w = self._z(40) + self._z(len(val_text)*10)
            if lbl_text == "MEANING": est_w = self._z(150) # Force minimum space for Meaning
            
            if line_x + est_w > max_x and line_x != start_x:
                line_x = start_x
                line_y = max_y + self._z(10)
                
            id_lbl = self.canvas.create_text(line_x, line_y + self._z(2), text=lbl_text, font=("Segoe UI", self._z(12), "bold"), fill=TEXT_MUTED, anchor="nw")
            bbox_lbl = self.canvas.bbox(id_lbl)
            val_x = (bbox_lbl[2] if bbox_lbl else line_x + self._z(35)) + self._z(8)
            
            rem_w = max_x - val_x
            if rem_w < self._z(80): rem_w = max_x - start_x # Force full width if choked
            
            id_val = self.canvas.create_text(val_x, line_y, text=val_text if val_text else "—", font=("Segoe UI", self._z(15)), fill=TEXT_PRIMARY if val_text else TEXT_MUTED, anchor="nw", width=rem_w)
            bbox_val = self.canvas.bbox(id_val)
            
            line_x = (bbox_val[2] if bbox_val else val_x + self._z(50)) + self._z(20)
            item_bottom = (bbox_val[3] if bbox_val else line_y + self._z(24))
            
            if item_bottom > max_y:
                max_y = item_bottom
                
        add_item("PRO", w_data.get('ipa', "") or "")
        add_item("POS", w_data.get('part_of_speech', "") or "")
        add_item("MEANING", w_data.get('meaning', "") or "")
        
        return max_y + self._z(14)

    def _draw_property_row(self, label, key, w_data, x1, x2, curr_y, is_edit, custom_font="Segoe UI"):
        col1_x = x1 + self._z(140)
        col2_x = col1_x + self._z(25)
        value = w_data.get(key, "") or ""
        
        self.canvas.create_text(col1_x, curr_y + self._z(2), text=label.upper(), font=("Segoe UI", self._z(11), "bold"), fill=TEXT_MUTED, anchor="ne")
        
        if is_edit:
            widget = ctk.CTkEntry(self.canvas, width=x2 - col2_x - self._z(30), fg_color=BG_SIDEBAR, text_color=TEXT_PRIMARY, font=(custom_font, self._z(16) if custom_font != "Segoe UI" else self._z(17)), border_width=0, corner_radius=6)
            widget.insert(0, value)
            self.canvas.create_window(col2_x, curr_y - self._z(6), anchor="nw", window=widget) 
            self.edit_widgets[f"{w_data['word']}_{key}"] = widget
            return curr_y + self._z(35)
        else:
            display_text = value if value else "—"
            color = TEXT_PRIMARY if value else TEXT_MUTED
            text_id = self.canvas.create_text(col2_x, curr_y, text=display_text, font=(custom_font, self._z(16) if custom_font != "Segoe UI" else self._z(15)), fill=color, anchor="nw", width=x2 - col2_x - self._z(30))
            bbox = self.canvas.bbox(text_id)
            return (bbox[3] if bbox else curr_y + self._z(24)) + self._z(14)

    def _draw_panel(self, label, key, w_data, x, y, width, bg_color, is_edit):
        rect_id = self._create_round_rect(x, y, x + width, y + self._z(10), radius=self._z(8), fill=bg_color, outline="")
        self.canvas.create_text(x + self._z(25), y + self._z(15), text=label, font=("Segoe UI", self._z(11), "bold"), fill=TEXT_MUTED, anchor="nw")
        
        val_x = x + self._z(25)
        val_y = y + self._z(42)
        val_w = width - self._z(50)
        value = w_data.get(key, "") or ""
        important_value = w_data.get(f'important_{key}', "") or ""
        
        if is_edit:
            widget = ctk.CTkTextbox(self.canvas, width=val_w, height=self._z(65), fg_color=BG_SIDEBAR, text_color=TEXT_PRIMARY, font=("Segoe UI", self._z(15)), border_width=0, corner_radius=6)
            widget.insert("1.0", value)
            self.canvas.create_window(val_x, val_y, anchor="nw", window=widget)
            self.edit_widgets[f"{w_data['word']}_{key}"] = widget
            bottom_y = val_y + self._z(75)
        else:
            bottom_y = self._draw_interactive_tags(val_x, val_y, val_w, value, important_value, w_data['word'], key)
                
        self._update_round_rect(rect_id, x, y, x + width, bottom_y + self._z(15), radius=self._z(8))
        return bottom_y + self._z(15)

    # --- Main Assembly ---

    def _draw_card(self, y_start, w_data, width):
        word = w_data['word']
        is_edit = (self.editing_word == word)
        x1 = self._z(40)
        x2 = max(x1 + self._z(100), width - self._z(40))
        
        bg_id = self._create_round_rect(x1, y_start, x2, y_start+self._z(100), radius=self._z(12), fill=BG_CARD, outline="")
        curr_y = y_start + self._z(35)
        
        is_fav = bool(w_data.get('is_favorite', 0))
        fav_color = HIGHLIGHT_COLOR if is_fav else TEXT_MUTED
        btn_x = self._draw_button(x1 + self._z(45), curr_y, "★" if is_fav else "☆", BG_CARD, fav_color, "#3F3F46", self.action_fav, word, is_star=True)
        
        id_title = self.canvas.create_text(x1 + self._z(65), curr_y, text=word.capitalize(), font=("Segoe UI", self._z(28), "bold"), fill=TEXT_PRIMARY, anchor="w")
        bbox_title = self.canvas.bbox(id_title)
        
        # Reliable bounding box calculation to prevent Exam History merging
        if bbox_title:
            title_end_x = bbox_title[2] + self._z(15)
        else:
            # Fallback approximation for first render
            title_end_x = x1 + self._z(65) + self._z(len(word) * 18) + self._z(15)
        
        exam = w_data.get('exam_history', '').strip()
        if exam:
            self.canvas.create_text(title_end_x, curr_y + self._z(5), text=exam, font=("Segoe UI", self._z(14), "italic"), fill=TEXT_MUTED, anchor="w")

        btn_x = x2 - self._z(25)
        btn_x = self._draw_button(btn_x, curr_y, "Delete", "#7F1D1D", TEXT_PRIMARY, "#991B1B", self.action_delete, word)
        btn_x = self._draw_button(btn_x, curr_y, "Refresh AI", ACCENT, TEXT_PRIMARY, ACCENT_HOVER, self.action_refresh, word)
        
        if is_edit:
            btn_x = self._draw_button(btn_x, curr_y, "💾 Save", ACCENT, TEXT_PRIMARY, ACCENT_HOVER, self.action_save, word)
        else:
            btn_x = self._draw_button(btn_x, curr_y, "✎ Edit", "#3F3F46", TEXT_PRIMARY, "#52525B", self.action_edit, word)
            
        has_notes = bool(w_data.get('notes', '').strip())
        n_color = ACCENT if has_notes else BG_CARD
        self._draw_button(btn_x, curr_y, "📝 Notes", n_color, TEXT_PRIMARY, ACCENT_HOVER if has_notes else "#3F3F46", self.action_notes, word)
        
        curr_y += self._z(50)
        
        curr_y = self._draw_inline_properties(w_data, x1, x2, curr_y, is_edit)
        curr_y = self._draw_property_row("BANGLA", 'bangla_meaning', w_data, x1, x2, curr_y, is_edit, custom_font="Kalpurush")
        curr_y = self._draw_property_row("EXAMPLE", 'example_sentence', w_data, x1, x2, curr_y, is_edit)
        curr_y += self._z(10)
        
        panel_w = max(self._z(100), (x2 - x1 - self._z(50)) // 2)
        y_syn = self._draw_panel("SYNONYMS", 'synonyms', w_data, x1 + self._z(20), curr_y, panel_w, "#1C1C20", is_edit)
        y_ant = self._draw_panel("ANTONYMS", 'antonyms', w_data, x1 + self._z(30) + panel_w, curr_y, panel_w, "#191A21", is_edit)
        curr_y = max(y_syn, y_ant) + self._z(15) 
        
        if word in self.open_notes or is_edit:
            notes_rect = self._create_round_rect(x1 + self._z(20), curr_y, x2 - self._z(20), curr_y + self._z(10), radius=self._z(8), fill=BG_SIDEBAR, outline="")
            self.canvas.create_text(x1 + self._z(45), curr_y + self._z(15), text="PERSONAL NOTES", font=("Segoe UI", self._z(11), "bold"), fill=TEXT_MUTED, anchor="nw")
            
            val_x = x1 + self._z(45)
            val_y = curr_y + self._z(40)
            val_w = x2 - x1 - self._z(90)
            value = w_data.get('notes', "") or ""
            
            if is_edit:
                widget = ctk.CTkTextbox(self.canvas, width=val_w, height=self._z(65), fg_color=BG_CARD, text_color=TEXT_PRIMARY, font=("Segoe UI", self._z(15)), border_width=0, corner_radius=6)
                widget.insert("1.0", value)
                self.canvas.create_window(val_x, val_y, anchor="nw", window=widget)
                self.edit_widgets[f"{word}_notes"] = widget
                bottom_y = val_y + self._z(75)
            else:
                display_text = value if value else "No personal notes yet."
                color = TEXT_PRIMARY if value else TEXT_MUTED
                text_id = self.canvas.create_text(val_x, val_y, text=display_text, font=("Segoe UI", self._z(15)), fill=color, anchor="nw", width=val_w)
                bbox = self.canvas.bbox(text_id)
                bottom_y = (bbox[3] if bbox else val_y + self._z(25)) + self._z(20)
                
            self._update_round_rect(notes_rect, x1 + self._z(20), curr_y, x2 - self._z(20), bottom_y + self._z(10), radius=self._z(8))
            curr_y = bottom_y + self._z(10)
            
        self._update_round_rect(bg_id, x1, y_start, x2, curr_y + self._z(25), radius=self._z(12))
        return curr_y + self._z(25)

    # --- Event Actions ---

    def action_delete(self, word):
        if messagebox.askyesno("Delete Word", f"Are you sure you want to permanently delete '{word.capitalize()}'?"):
            if delete_word(word):
                self.app.load_words()

    def action_refresh(self, word):
        api_key = self.app.api_key if self.app.api_key else self.app.api_key_entry.get().strip()
        if not api_key or api_key == "••••••••":
            messagebox.showwarning("Missing API Key", "Please enter your API Key in Settings first.")
            return
            
        self.app.status_label.configure(text=f"Refreshing '{word}'...", text_color=HIGHLIGHT_COLOR)
        
        def fetch_task():
            try:
                data, api_msg = fetch_word_details(word, api_key)
                self.app.after(0, lambda: self._on_refresh_done(word, data, api_msg))
            except Exception as e:
                self.app.after(0, lambda: self._on_refresh_done(word, None, f"Network failed: {str(e)}"))
            
        threading.Thread(target=fetch_task, daemon=True).start()

    def _on_refresh_done(self, word, data, api_msg):
        if data:
            for field in ['meaning', 'bangla_meaning', 'english_definition', 'ipa', 'part_of_speech', 'example_sentence', 'synonyms', 'antonyms', 'exam_history']:
                if field in data: update_single_field(word, field, data[field])
            self.app.status_label.configure(text=f"Refreshed '{word}'!", text_color="#34D399")
            self.app.load_words()
        else:
            messagebox.showerror("Refresh Failed", api_msg)
            self.app.status_label.configure(text="", text_color=TEXT_MUTED)

    def action_edit(self, word):
        self.editing_word = word
        self.render()

    def action_save(self, word):
        updates = {
            'ipa': self.edit_widgets.get(f"{word}_ipa").get().strip() if f"{word}_ipa" in self.edit_widgets else "",
            'part_of_speech': self.edit_widgets.get(f"{word}_part_of_speech").get().strip() if f"{word}_part_of_speech" in self.edit_widgets else "",
            'meaning': self.edit_widgets.get(f"{word}_meaning").get().strip() if f"{word}_meaning" in self.edit_widgets else "",
            'bangla_meaning': self.edit_widgets.get(f"{word}_bangla_meaning").get().strip() if f"{word}_bangla_meaning" in self.edit_widgets else "",
            'example_sentence': self.edit_widgets.get(f"{word}_example_sentence").get().strip() if f"{word}_example_sentence" in self.edit_widgets else "",
            'synonyms': self.edit_widgets.get(f"{word}_synonyms").get("1.0", "end-1c").strip() if f"{word}_synonyms" in self.edit_widgets else "",
            'antonyms': self.edit_widgets.get(f"{word}_antonyms").get("1.0", "end-1c").strip() if f"{word}_antonyms" in self.edit_widgets else "",
        }
        if f"{word}_notes" in self.edit_widgets:
            updates['notes'] = self.edit_widgets.get(f"{word}_notes").get("1.0", "end-1c").strip()
            
        for field, new_value in updates.items():
            update_single_field(word, field, new_value)
            
        self.editing_word = None
        self.app.load_words()

    def action_notes(self, word):
        if word in self.open_notes:
            self.open_notes.remove(word)
        else:
            self.open_notes.add(word)
        self.render()
        
    def action_fav(self, word):
        w_data = next((w for w in self.words if w['word'] == word), None)
        if not w_data: return
        
        is_fav = not bool(w_data.get('is_favorite', 0))
        update_single_field(word, 'is_favorite', 1 if is_fav else 0)
        
        if not is_fav and self.app.show_favorites_only:
            self.app.load_words()
        else:
            w_data['is_favorite'] = 1 if is_fav else 0
            self.render()


# =========================================================================================

class VocabNoteApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        init_db()
        
        self.api_key = get_setting("gemini_api_key")
        
        saved_zoom = get_setting("zoom_factor")
        try:
            self.zoom_factor = float(saved_zoom) if saved_zoom else 1.0
        except ValueError:
            self.zoom_factor = 1.0
            
        self.current_volume_id = None
        self.vol_display_to_id = {}
        self.show_favorites_only = False

        self.title("VocabNote")
        self.iconbitmap(resource_path("vocab_icon.ico"))
        self.geometry("1200x800")
        self.configure(fg_color=BG_MAIN)
        self.grid_columnconfigure(1, weight=1)
        self.grid_rowconfigure(0, weight=1)

        self.setup_sidebar()
        self.setup_notebook_page()
        self.setup_settings_page()

        self.view_all_words()
        self.refresh_volumes_dashboard()
        self.load_words()

    def setup_sidebar(self):
        self.sidebar = ctk.CTkFrame(self, width=250, fg_color=BG_SIDEBAR, corner_radius=0)
        self.sidebar.grid(row=0, column=0, sticky="nsew")
        self.sidebar.grid_rowconfigure(6, weight=1)

        ctk.CTkLabel(self.sidebar, text="VocabNote", font=("Segoe UI", 24, "bold"), text_color=TEXT_PRIMARY).grid(row=0, column=0, padx=25, pady=(35, 30), sticky="w")

        self.btn_notebook = ctk.CTkButton(self.sidebar, text="📚 All Words", fg_color=BG_CARD, hover_color="#3F3F46", text_color=TEXT_PRIMARY, font=("Segoe UI", 15), anchor="w", command=self.view_all_words)
        self.btn_notebook.grid(row=1, column=0, padx=15, pady=(5, 2), sticky="ew")

        self.btn_favorites = ctk.CTkButton(self.sidebar, text="⭐ Favorites", fg_color=BG_SIDEBAR, hover_color="#3F3F46", text_color=TEXT_PRIMARY, font=("Segoe UI", 15), anchor="w", command=self.view_favorites)
        self.btn_favorites.grid(row=2, column=0, padx=15, pady=(2, 15), sticky="ew")

        self.btn_settings = ctk.CTkButton(self.sidebar, text="⚙ Settings", fg_color=BG_SIDEBAR, hover_color=BG_CARD, text_color=TEXT_PRIMARY, font=("Segoe UI", 15), anchor="w", command=lambda: self.select_frame("settings"))
        self.btn_settings.grid(row=3, column=0, padx=15, pady=5, sticky="ew")

        ctk.CTkLabel(self.sidebar, text="DATA MANAGEMENT", font=("Segoe UI", 11, "bold"), text_color=TEXT_MUTED).grid(row=7, column=0, padx=25, pady=(20, 10), sticky="w")
        ctk.CTkButton(self.sidebar, text="Export as DOCX", fg_color=ACCENT, hover_color=ACCENT_HOVER, font=("Segoe UI", 14), anchor="w", command=self.export_docx).grid(row=8, column=0, padx=15, pady=(0, 10), sticky="ew")
        ctk.CTkButton(self.sidebar, text="Import from DOCX", fg_color=BG_CARD, hover_color="#3F3F46", text_color=TEXT_PRIMARY, font=("Segoe UI", 14), anchor="w", command=self.import_docx).grid(row=9, column=0, padx=15, pady=(0, 30), sticky="ew")

    def setup_notebook_page(self):
        self.notebook_frame = ctk.CTkFrame(self, fg_color=BG_MAIN, corner_radius=0)
        
        self.header_container = tk.Frame(self.notebook_frame, bg=BG_MAIN)
        self.header_container.pack(fill="x", padx=40, pady=(25, 10))

        row1 = tk.Frame(self.header_container, bg=BG_MAIN)
        row1.pack(fill="x", pady=(0, 10))
        
        self.header = ctk.CTkLabel(row1, text="My Notebook", font=("Segoe UI", 28, "bold"), text_color=TEXT_PRIMARY)
        self.header.pack(side="left", padx=(0, 20))

        self.volume_dropdown = ctk.CTkOptionMenu(row1, width=170, height=32, fg_color=BG_CARD, button_color=BG_CARD, button_hover_color="#3F3F46", font=("Segoe UI", 13), command=self.on_volume_selection_changed)
        self.volume_dropdown.pack(side="left", padx=(0, 8))
        
        ctk.CTkButton(row1, text="+ New", width=60, height=32, fg_color=BG_CARD, hover_color="#3F3F46", font=("Segoe UI", 12, "bold"), text_color=TEXT_PRIMARY, command=self.add_volume_ui).pack(side="left", padx=3)
        ctk.CTkButton(row1, text="Rename", width=65, height=32, fg_color=BG_CARD, hover_color="#3F3F46", font=("Segoe UI", 12, "bold"), text_color=TEXT_PRIMARY, command=self.rename_volume_ui).pack(side="left", padx=3)
        ctk.CTkButton(row1, text="Delete", width=65, height=32, fg_color="#7F1D1D", hover_color="#991B1B", font=("Segoe UI", 12, "bold"), text_color=TEXT_PRIMARY, command=self.delete_volume_ui).pack(side="left", padx=3)

        self.sort_dropdown = ctk.CTkOptionMenu(row1, values=["Sort A-Z", "Sort Z-A"], width=120, height=32, fg_color=BG_CARD, button_color=BG_CARD, button_hover_color="#3F3F46", font=("Segoe UI", 13), command=lambda choice: self.load_words())
        self.sort_dropdown.pack(side="right")
        
        self.zoom_slider = ctk.CTkSlider(row1, from_=0.6, to=1.4, width=120, command=self.on_zoom_changed)
        self.zoom_slider.set(self.zoom_factor)
        self.zoom_slider.pack(side="right", padx=(10, 15))
        self.zoom_slider.bind("<ButtonRelease-1>", lambda e: save_setting("zoom_factor", str(self.zoom_factor)))
        
        ctk.CTkLabel(row1, text="Zoom", font=("Segoe UI", 12, "bold"), text_color=TEXT_MUTED).pack(side="right")

        row2 = tk.Frame(self.header_container, bg=BG_MAIN)
        row2.pack(fill="x")

        self.add_word_entry = ctk.CTkEntry(row2, placeholder_text="Enter a hard English word...", width=260, height=38, font=("Segoe UI", 14), fg_color=BG_CARD, border_width=1, border_color="#3F3F46")
        self.add_word_entry.pack(side="left", padx=(0, 10))
        # Fixed Enter Key Binding
        self.add_word_entry.bind("<Return>", lambda e: self.add_new_word())
        
        ctk.CTkButton(row2, text="Enrich Word", width=110, height=38, fg_color=ACCENT, hover_color=ACCENT_HOVER, font=("Segoe UI", 14, "bold"), command=self.add_new_word).pack(side="left")

        self.search_all_var = tk.BooleanVar(value=True)
        self.cb_search_all = ctk.CTkCheckBox(row2, text="Search All Volumes", variable=self.search_all_var, font=("Segoe UI", 12), text_color=TEXT_MUTED, fg_color=ACCENT, hover_color=ACCENT_HOVER, command=lambda: self.load_words())
        self.cb_search_all.pack(side="right", padx=(15, 0))

        self.search_entry = ctk.CTkEntry(row2, placeholder_text="Search...", width=220, height=38, font=("Segoe UI", 14), fg_color=BG_CARD, border_width=1, border_color="#3F3F46")
        self.search_entry.pack(side="right")
        self.search_entry.bind("<KeyRelease>", lambda e: self.load_words())

        self.status_label = ctk.CTkLabel(self.notebook_frame, text="", font=("Segoe UI", 13), text_color=TEXT_MUTED, height=20)
        self.status_label.pack(anchor="w", padx=40, pady=(0, 6))

        self.word_list_frame = WordListView(self.notebook_frame, self)
        self.word_list_frame.pack(side="top", fill="both", expand=True, padx=40, pady=(0, 10))

    def on_zoom_changed(self, value):
        self.zoom_factor = value
        self.word_list_frame.render()

    def setup_settings_page(self):
        self.settings_frame = ctk.CTkFrame(self, fg_color=BG_MAIN, corner_radius=0)
        ctk.CTkLabel(self.settings_frame, text="Settings", font=("Segoe UI", 34, "bold"), text_color=TEXT_PRIMARY).pack(anchor="w", padx=50, pady=(45, 30))
        ctk.CTkLabel(self.settings_frame, text="AI API Key (Gemini)", font=("Segoe UI", 15, "bold"), text_color=TEXT_PRIMARY).pack(anchor="w", padx=50, pady=(0, 8))
        
        self.api_key_entry = ctk.CTkEntry(self.settings_frame, placeholder_text="Paste API Key here...", width=450, height=42, font=("Segoe UI", 14), fg_color=BG_CARD, border_width=1, border_color="#3F3F46")
        if self.api_key: self.api_key_entry.insert(0, "••••••••")
        self.api_key_entry.bind("<FocusOut>", self.on_api_key_changed)
        self.api_key_entry.pack(anchor="w", padx=50, pady=(0, 20))
        
        ctk.CTkButton(self.settings_frame, text="Test Connection", width=160, height=42, fg_color=BG_CARD, hover_color="#3F3F46", text_color=TEXT_PRIMARY, font=("Segoe UI", 14), command=self.run_api_test).pack(anchor="w", padx=50)
        self.settings_status = ctk.CTkLabel(self.settings_frame, text="", font=("Segoe UI", 14), text_color=TEXT_MUTED)
        self.settings_status.pack(anchor="w", padx=50, pady=15)

    def on_api_key_changed(self, event):
        new_key = self.api_key_entry.get().strip()
        if new_key == "":
            save_setting("gemini_api_key", "")
            self.api_key = None
        elif new_key != "••••••••":
            save_setting("gemini_api_key", new_key)
            self.api_key = new_key
            self.api_key_entry.delete(0, 'end')
            self.api_key_entry.insert(0, "••••••••")

    def refresh_volumes_dashboard(self):
        vols = get_all_volumes()
        dropdown_strings = []
        self.vol_display_to_id.clear()
        
        for v in vols:
            display_str = f"{v['name']} ({v['word_count']} words)"
            dropdown_strings.append(display_str)
            self.vol_display_to_id[display_str] = v['id']
            
        self.volume_dropdown.configure(values=dropdown_strings)
        
        if self.current_volume_id is None or not any(v['id'] == self.current_volume_id for v in vols):
            self.current_volume_id = vols[0]['id']
            
        for display_str, v_id in self.vol_display_to_id.items():
            if v_id == self.current_volume_id:
                self.volume_dropdown.set(display_str)
                break

    def on_volume_selection_changed(self, choice):
        self.current_volume_id = self.vol_display_to_id.get(choice)
        self.load_words()

    def view_all_words(self):
        self.show_favorites_only = False
        self.btn_notebook.configure(fg_color=BG_CARD)
        self.btn_favorites.configure(fg_color=BG_SIDEBAR)
        self.select_frame("notebook")

    def view_favorites(self):
        self.show_favorites_only = True
        self.btn_notebook.configure(fg_color=BG_SIDEBAR)
        self.btn_favorites.configure(fg_color=BG_CARD)
        self.select_frame("notebook")

    def add_volume_ui(self):
        dialog = ctk.CTkInputDialog(text="Enter new volume name:", title="Create Volume")
        name = dialog.get_input()
        if name and name.strip():
            create_volume(name.strip())
            self.refresh_volumes_dashboard()

    def rename_volume_ui(self):
        dialog = ctk.CTkInputDialog(text="Enter new name for active volume:", title="Rename Volume")
        name = dialog.get_input()
        if name and name.strip():
            rename_volume(self.current_volume_id, name.strip())
            self.refresh_volumes_dashboard()

    def delete_volume_ui(self):
        if messagebox.askyesno("Delete Volume", "Are you sure you want to delete the active volume permanently?"):
            success, msg = delete_volume(self.current_volume_id)
            if success:
                self.current_volume_id = None
                self.refresh_volumes_dashboard()
                self.load_words()
            else:
                messagebox.showerror("Error", msg)

    def load_words(self):
        self.header.configure(text="Favorites" if self.show_favorites_only else "My Notebook")

        all_words = get_all_words_dictionaries(
            search_query=self.search_entry.get().strip(), 
            sort_order="DESC" if "Z-A" in self.sort_dropdown.get() else "ASC", 
            volume_id=self.current_volume_id, 
            search_all=self.search_all_var.get(),
            favorites_only=self.show_favorites_only
        )

        self.word_list_frame.set_words(all_words)
        
        try:
            self.word_list_frame.canvas.yview_moveto(0)
        except Exception:
            pass

    def add_new_word(self):
        word = self.add_word_entry.get().strip()
        if not word: return

        if check_word_exists(word):
            dialog = DuplicateDialog(self, word)
            self.wait_window(dialog)
            if dialog.result == "cancel": return
            elif dialog.result == "open":
                self.search_entry.delete(0, 'end')
                self.search_entry.insert(0, word)
                self.search_all_var.set(True) 
                self.load_words()
                self.add_word_entry.delete(0, 'end')
                return

        api_key_to_use = self.api_key if self.api_key else self.api_key_entry.get().strip()
        if not api_key_to_use or api_key_to_use == "••••••••":
            messagebox.showwarning("Missing API Key", "Please add your API Key in Settings first.")
            return

        self.status_label.configure(text=f"Asking AI about '{word}'...", text_color=HIGHLIGHT_COLOR)
        self.update()

        def fetch_task():
            try:
                data, api_msg = fetch_word_details(word, api_key_to_use)
                self.after(0, lambda: self._on_add_fetched(word, data, api_msg))
            except Exception as e:
                self.after(0, lambda: self._on_add_fetched(word, None, f"Network failed: {str(e)}"))
            
        threading.Thread(target=fetch_task, daemon=True).start()

    def _on_add_fetched(self, word, data, api_msg):
        if data:
            if check_word_exists(word): 
                for field in ['meaning', 'bangla_meaning', 'english_definition', 'ipa', 'part_of_speech', 'example_sentence', 'synonyms', 'antonyms', 'exam_history']:
                    if field in data: update_single_field(word, field, data[field])
                self.status_label.configure(text=f"'{word}' updated with fresh AI data!", text_color="#34D399")
            else:
                save_word_to_db(word, data, current_vol_id=self.current_volume_id)
                self.status_label.configure(text=f"'{word}' added successfully!", text_color="#34D399")
            
            self.add_word_entry.delete(0, 'end')
            self.search_entry.delete(0, 'end')
            self.refresh_volumes_dashboard() 
            self.load_words()
        else:
            self.status_label.configure(text=api_msg, text_color="#F87171")

    def select_frame(self, name):
        self.notebook_frame.grid_forget()
        self.settings_frame.grid_forget()
        self.btn_notebook.configure(fg_color=BG_SIDEBAR)
        self.btn_favorites.configure(fg_color=BG_SIDEBAR)
        self.btn_settings.configure(fg_color=BG_CARD if name == "settings" else BG_SIDEBAR)
        
        if name == "notebook":
            self.notebook_frame.grid(row=0, column=1, sticky="nsew")
            if self.show_favorites_only: self.btn_favorites.configure(fg_color=BG_CARD)
            else: self.btn_notebook.configure(fg_color=BG_CARD)
            self.refresh_volumes_dashboard()
            self.load_words()
        else:
            self.settings_frame.grid(row=0, column=1, sticky="nsew")

    def run_api_test(self):
        self.settings_status.configure(text="Testing connection...", text_color=HIGHLIGHT_COLOR)
        self.update()
        key_input = self.api_key_entry.get().strip()
        if key_input == "••••••••": key_input = self.api_key
        is_success, msg = test_gemini_connection(key_input)
        self.settings_status.configure(text=msg, text_color="#34D399" if is_success else "#F87171")

    def import_docx(self):
        file_path = filedialog.askopenfilename(filetypes=[("Word Document", "*.docx")])
        if not file_path: return
        success, result = import_from_docx(file_path)
        if not success:
            messagebox.showerror("Import Error", result)
            return
            
        words_to_import = result
        if not words_to_import:
            messagebox.showinfo("Import", "No recognizable vocabulary items found in the document.")
            return
            
        replace_duplicates, skip_duplicates, imported_count, skipped_count, failed_count = False, False, 0, 0, 0
        
        for w_data in words_to_import:
            word = w_data['word']
            if check_word_exists(word):
                if not replace_duplicates and not skip_duplicates:
                    dialog = ImportDuplicateDialog(self, word)
                    self.wait_window(dialog)
                    if dialog.result == "cancel": break
                    elif dialog.result == "replace_all": replace_duplicates = True
                    elif dialog.result == "skip_all": skip_duplicates = True
                    elif dialog.result == "replace":
                        self._force_replace_word(word, w_data)
                        imported_count += 1
                        continue
                    elif dialog.result == "skip":
                        skipped_count += 1
                        continue
                if replace_duplicates:
                    self._force_replace_word(word, w_data)
                    imported_count += 1
                elif skip_duplicates: skipped_count += 1
            else:
                success, _ = save_word_to_db(word, w_data, self.current_volume_id)
                if success:
                    update_single_field(word, 'notes', w_data.get('notes', ''))
                    imported_count += 1
                else: failed_count += 1
                    
        messagebox.showinfo("Import Summary", f"Imported: {imported_count} words\nSkipped: {skipped_count} duplicates\nFailed: {failed_count}")
        self.refresh_volumes_dashboard()
        self.load_words()

    def _force_replace_word(self, word, data):
        for field in ['meaning', 'bangla_meaning', 'english_definition', 'ipa', 'part_of_speech', 'example_sentence', 'synonyms', 'antonyms', 'notes', 'exam_history']:
            if field in data: update_single_field(word, field, data[field])

    def export_docx(self):
        vols = get_all_volumes()
        dialog = ExportSelectionDialog(self, self.current_volume_id, vols)
        self.wait_window(dialog)
        if not dialog.result: return
            
        words = []
        if dialog.result['type'] == 'all': words = get_all_words_dictionaries(search_all=True, sort_order="ASC")
        elif dialog.result['type'] == 'current': words = get_all_words_dictionaries(volume_id=self.current_volume_id, sort_order="ASC")
        elif dialog.result['type'] == 'custom': words = get_all_words_dictionaries(volume_id=dialog.result['volumes'], sort_order="ASC")
            
        if not words:
            messagebox.showwarning("Export Failed", "No words found to export.")
            return
            
        file_path = filedialog.asksaveasfilename(defaultextension=".docx", filetypes=[("Word Document", "*.docx")])
        if file_path:
            success, msg = export_to_docx(words, file_path)
            if success: messagebox.showinfo("Success", msg)
            else: messagebox.showerror("Error", msg)

if __name__ == "__main__":
    app = VocabNoteApp()
    app.mainloop()