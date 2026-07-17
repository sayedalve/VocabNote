import os
import sys
import ctypes

# =======================================================================
# HIGH-DPI FIX
# =======================================================================
if sys.platform == 'win32':
    try:
        ctypes.windll.shcore.SetProcessDpiAwareness(1)
    except Exception:
        pass

import tkinter as tk
import customtkinter as ctk
import threading
import traceback

from api.gemini import test_connection as _test_gemini_connection, fetch_word_details as _fetch_word_details

from database.db_manager import (
    init_db, save_word_to_db, get_all_words_dictionaries, 
    update_single_field, delete_word, check_word_exists,
    get_setting, save_setting, get_all_volumes, create_volume,
    rename_volume, delete_volume
)
from utils.export_manager import export_to_docx, import_from_docx
from customtkinter import filedialog

# =======================================================================
# DESIGN TOKENS (Glassmorphic Midnight Blue Theme)
# =======================================================================
class Color:
    SURFACE_0 = "#05070A"  
    SURFACE_1 = "#0B0E14"  
    SURFACE_2 = "#121722"  
    SURFACE_3 = "#1A2133"  
    GLASS_BORDER = "#2A364F" 
    TEXT_PRIMARY = "#F8FAFC"
    TEXT_SECONDARY = "#94A3B8"
    TEXT_MUTED = "#475569"
    ACCENT = "#38BDF8"     
    ACCENT_HOVER = "#0EA5E9"
    SUCCESS = "#10B981"
    WARNING = "#F59E0B"
    DANGER = "#EF4444"
    HIGHLIGHT = "#FCD34D"

class Font:
    @staticmethod
    def base(size, weight="normal"):
        return ("Segoe UI", size, weight)
    
    @staticmethod
    def bangla(size, weight="normal"):
        return ("Kalpurush", size, weight)

def resource_path(relative_path):
    try:
        base_path = sys._MEIPASS
    except Exception:
        base_path = os.path.abspath(".")
    return os.path.join(base_path, relative_path)

ctk.set_appearance_mode("dark")

# =======================================================================
# CUSTOM DIALOGS 
# =======================================================================
class StyledConfirmDialog(ctk.CTkToplevel):
    def __init__(self, master, title, message, confirm_text="Confirm", danger=False):
        super().__init__(master)
        self.title("")
        self.geometry("450x220")
        self.result = False
        self.transient(master)
        self.grab_set()
        self.configure(fg_color=Color.SURFACE_2)
        
        ctk.CTkLabel(self, text=title, font=Font.base(16, "bold"), text_color=Color.TEXT_PRIMARY).pack(pady=(25, 10), padx=25, anchor="w")
        ctk.CTkLabel(self, text=message, font=Font.base(13), text_color=Color.TEXT_SECONDARY, wraplength=400, justify="left").pack(padx=25, anchor="w")
        
        btn_frame = ctk.CTkFrame(self, fg_color="transparent")
        btn_frame.pack(fill="x", padx=25, pady=(30, 20), side="bottom")
        
        cancel_btn = ctk.CTkButton(btn_frame, text="Cancel", fg_color=Color.SURFACE_3, hover_color=Color.GLASS_BORDER, text_color=Color.TEXT_PRIMARY, command=self._cancel, width=100)
        cancel_btn.pack(side="right", padx=(10, 0))
        
        action_color = Color.DANGER if danger else Color.ACCENT
        action_hover = "#DC2626" if danger else Color.ACCENT_HOVER
        action_text = "#FFFFFF" if danger else "#000000"
        action_btn = ctk.CTkButton(btn_frame, text=confirm_text, fg_color=action_color, hover_color=action_hover, text_color=action_text, font=Font.base(12, "bold"), command=self._confirm, width=100)
        action_btn.pack(side="right")

    def _confirm(self):
        self.result = True
        self.destroy()

    def _cancel(self):
        self.result = False
        self.destroy()

class StyledInputDialog(ctk.CTkToplevel):
    def __init__(self, master, title, placeholder=""):
        super().__init__(master)
        self.title("")
        self.geometry("400x200")
        self.result = None
        self.transient(master)
        self.grab_set()
        self.configure(fg_color=Color.SURFACE_2)
        
        ctk.CTkLabel(self, text=title, font=Font.base(15, "bold"), text_color=Color.TEXT_PRIMARY).pack(pady=(25, 15), padx=25, anchor="w")
        self.entry = ctk.CTkEntry(self, placeholder_text=placeholder, font=Font.base(13), fg_color=Color.SURFACE_1, border_color=Color.GLASS_BORDER, width=350)
        self.entry.pack(padx=25)
        self.entry.focus_set()
        
        btn_frame = ctk.CTkFrame(self, fg_color="transparent")
        btn_frame.pack(fill="x", padx=25, pady=(20, 20), side="bottom")
        
        ctk.CTkButton(btn_frame, text="Cancel", fg_color=Color.SURFACE_3, hover_color=Color.GLASS_BORDER, text_color=Color.TEXT_PRIMARY, command=self.destroy, width=90).pack(side="right", padx=(10, 0))
        ctk.CTkButton(btn_frame, text="Save", fg_color=Color.ACCENT, hover_color=Color.ACCENT_HOVER, text_color="#000000", font=Font.base(12, "bold"), command=self._confirm, width=90).pack(side="right")
        self.bind("<Return>", lambda e: self._confirm())

    def _confirm(self):
        self.result = self.entry.get()
        self.destroy()

class ExportSelectionDialog(ctk.CTkToplevel):
    def __init__(self, master, current_vol_id, all_volumes):
        super().__init__(master)
        self.title("Export Notebook")
        self.geometry("450x500")
        self.result = None
        self.transient(master)
        self.grab_set()
        self.configure(fg_color=Color.SURFACE_2)
        
        self.export_type = tk.StringVar(value="current")
        ctk.CTkLabel(self, text="Select Export Scope", font=Font.base(16, "bold"), text_color=Color.TEXT_PRIMARY).pack(pady=(25, 15))
        
        rb_frame = ctk.CTkFrame(self, fg_color="transparent")
        rb_frame.pack(fill="x", padx=40)
        ctk.CTkRadioButton(rb_frame, text="Active Volume Only", variable=self.export_type, value="current", font=Font.base(13), text_color=Color.TEXT_PRIMARY, fg_color=Color.ACCENT).pack(anchor="w", pady=8)
        ctk.CTkRadioButton(rb_frame, text="Entire Notebook", variable=self.export_type, value="all", font=Font.base(13), text_color=Color.TEXT_PRIMARY, fg_color=Color.ACCENT).pack(anchor="w", pady=8)
        
        btn_frame = ctk.CTkFrame(self, fg_color="transparent")
        btn_frame.pack(fill="x", padx=40, pady=20, side="bottom")
        ctk.CTkButton(btn_frame, text="Export", fg_color=Color.ACCENT, hover_color=Color.ACCENT_HOVER, text_color="#000000", height=32, font=Font.base(13, "bold"), command=self.confirm).pack(side="left", expand=True, padx=5)
        ctk.CTkButton(btn_frame, text="Cancel", fg_color=Color.SURFACE_3, hover_color=Color.GLASS_BORDER, text_color=Color.TEXT_PRIMARY, height=32, font=Font.base(13), command=self.destroy).pack(side="left", expand=True, padx=5)
            
    def confirm(self):
        self.result = {'type': self.export_type.get()}
        self.destroy()

class ImportDuplicateDialog(ctk.CTkToplevel):
    def __init__(self, master, word):
        super().__init__(master)
        self.title("Duplicate Found")
        self.geometry("600x200")
        self.result = "skip"
        self.transient(master)
        self.grab_set()
        self.configure(fg_color=Color.SURFACE_2)
        
        ctk.CTkLabel(self, text=f"'{word.capitalize()}' already exists. What should we do?", font=Font.base(15, "bold"), text_color=Color.TEXT_PRIMARY).pack(pady=(20, 25))
        btn_frame = ctk.CTkFrame(self, fg_color="transparent")
        btn_frame.pack(fill="x", padx=15)
        ctk.CTkButton(btn_frame, text="Replace", fg_color=Color.ACCENT, hover_color=Color.ACCENT_HOVER, text_color="#000000", command=lambda: self.set_result("replace")).pack(side="left", padx=5, expand=True)
        ctk.CTkButton(btn_frame, text="Skip", fg_color=Color.SURFACE_3, hover_color=Color.GLASS_BORDER, text_color=Color.TEXT_PRIMARY, command=lambda: self.set_result("skip")).pack(side="left", padx=5, expand=True)
        ctk.CTkButton(btn_frame, text="Replace All", fg_color=Color.DANGER, hover_color="#DC2626", text_color="#FFFFFF", command=lambda: self.set_result("replace_all")).pack(side="left", padx=5, expand=True)
        ctk.CTkButton(btn_frame, text="Skip All", fg_color=Color.SURFACE_3, hover_color=Color.GLASS_BORDER, text_color=Color.TEXT_PRIMARY, command=lambda: self.set_result("skip_all")).pack(side="left", padx=5, expand=True)
        
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
        self.configure(fg_color=Color.SURFACE_2)
        
        ctk.CTkLabel(self, text=f"'{word.capitalize()}' is already in your notebook.", font=Font.base(15, "bold"), text_color=Color.TEXT_PRIMARY).pack(pady=(30, 25))
        btn_frame = ctk.CTkFrame(self, fg_color="transparent")
        btn_frame.pack(fill="x", padx=20)
        ctk.CTkButton(btn_frame, text="Open Entry", fg_color=Color.ACCENT, hover_color=Color.ACCENT_HOVER, text_color="#000000", command=lambda: self.set_result("open")).pack(side="left", padx=5, expand=True)
        ctk.CTkButton(btn_frame, text="Replace AI Data", fg_color=Color.DANGER, hover_color="#DC2626", text_color="#FFFFFF", command=lambda: self.set_result("replace")).pack(side="left", padx=5, expand=True)
        ctk.CTkButton(btn_frame, text="Cancel", fg_color=Color.SURFACE_3, hover_color=Color.GLASS_BORDER, text_color=Color.TEXT_PRIMARY, command=lambda: self.set_result("cancel")).pack(side="left", padx=5, expand=True)
        
    def set_result(self, res):
        self.result = res
        self.destroy()

# =======================================================================
# CANVAS ENGINE (REFACTORED with corrected label spacing)
# =======================================================================
class WordListView(ctk.CTkFrame):
    def __init__(self, master, app):
        super().__init__(master, fg_color=Color.SURFACE_0, corner_radius=0)
        self.app = app
        self.words = []
        
        self.editing_word = None
        self.edit_widgets = {}
        
        self.card_y_positions = {}
        self.card_bg_ids = {}
        self._resize_timer = None
        
        self.canvas = tk.Canvas(self, bg=Color.SURFACE_0, highlightthickness=0)
        
        self.scrollbar = ctk.CTkScrollbar(
            self, 
            width=12, 
            command=self.canvas.yview, 
            fg_color="transparent", 
            button_color=Color.SURFACE_3, 
            button_hover_color=Color.GLASS_BORDER
        )
        self.canvas.configure(yscrollcommand=self.scrollbar.set)
        
        self.canvas.pack(side="left", fill="both", expand=True)
        self.scrollbar.pack(side="right", fill="y", padx=(0, 2))
        
        self.canvas.bind("<Configure>", self._on_configure)
        self.canvas.bind("<Enter>", self._bind_mouse)
        self.canvas.bind("<Leave>", self._unbind_mouse)

    def _on_configure(self, event):
        if self._resize_timer:
            self.after_cancel(self._resize_timer)
        self._resize_timer = self.after(100, self.render)

    def _bind_mouse(self, event):
        self.canvas.bind_all("<MouseWheel>", self._on_mousewheel)
        self.canvas.bind_all("<Button-4>", self._on_mousewheel)
        self.canvas.bind_all("<Button-5>", self._on_mousewheel)

    def _unbind_mouse(self, event):
        self.canvas.unbind_all("<MouseWheel>")
        self.canvas.unbind_all("<Button-4>")
        self.canvas.unbind_all("<Button-5>")

    def _on_mousewheel(self, event):
        if event.num == 4 or event.delta > 0: self.canvas.yview_scroll(-1, "units")
        elif event.num == 5 or event.delta < 0: self.canvas.yview_scroll(1, "units")

    def scroll_to_word(self, target_word, flash=False):
        target_lower = target_word.lower()
        actual_key = next((k for k in self.card_y_positions.keys() if k.lower() == target_lower), None)
                
        if actual_key:
            target_y = self.card_y_positions.get(actual_key, 0)
            sr = self.canvas.cget("scrollregion")
            if sr:
                try:
                    sr_tuple = tuple(map(float, sr.split()))
                    if len(sr_tuple) == 4 and sr_tuple[3] > 0:
                        fraction = max(0.0, (target_y - self._z(10)) / sr_tuple[3])
                        self.canvas.yview_moveto(fraction)
                except ValueError: pass
            
            if flash:
                bg_id = self.card_bg_ids.get(actual_key)
                if bg_id:
                    orig_color = Color.SURFACE_2
                    flash_color = Color.SURFACE_3 
                    def flash_cycle(step):
                        try:
                            if step % 2 == 0: self.canvas.itemconfig(bg_id, fill=flash_color)
                            else: self.canvas.itemconfig(bg_id, fill=orig_color)
                            if step < 3: self.after(300, lambda: flash_cycle(step + 1))
                        except Exception: pass 
                    flash_cycle(0)

    def _z(self, val):
        try:
            dpi_scale = ctk.ScalingTracker.get_window_dpi_scaling(self.app)
        except Exception:
            dpi_scale = 1.0
        return max(1, int(val * self.app.zoom_factor * dpi_scale))

    def set_words(self, words):
        self.words = words
        self.editing_word = None
        self.render()

    def render(self):
        self.canvas.delete("all")
        for w in self.edit_widgets.values(): w.destroy()
        self.edit_widgets.clear()
        self.card_y_positions.clear()
        self.card_bg_ids.clear()
        
        width = self.canvas.winfo_width()
        if width < 100: return 
        
        if not self.words:
            self._draw_empty_state(width, self.canvas.winfo_height())
            return

        y_offset = self._z(15)
        for w_data in self.words:
            self.card_y_positions[w_data['word']] = y_offset
            bg_id, y_offset = self._draw_card(y_offset, w_data, width)
            self.card_bg_ids[w_data['word']] = bg_id
            y_offset += self._z(15) 
            
        # Hard limits scrolling strictly to the exact bounds of the content.
        visible_height = self.canvas.winfo_height()
        self.canvas.configure(scrollregion=(0, 0, width, max(visible_height, y_offset)))

    def _draw_empty_state(self, w, h):
        msg = "No words found. Enter a word above to get started."
        if self.app.search_entry.get().strip(): msg = "No words match your search."
        elif self.app.show_favorites_only: msg = "No favorites yet. Star some words!"
        self.canvas.create_text(w//2, max(150, h//3), text=msg, font=Font.base(self._z(12)), fill=Color.TEXT_MUTED, justify="center")

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

    def _draw_interactive_tags(self, start_x, start_y, max_w, items_str, important_str, word, field_key):
        curr_x, curr_y = start_x, start_y
        line_height = self._z(20) 
        items = [s.strip() for s in items_str.split(',') if s.strip()]
        important_items = set(s.strip().lower() for s in important_str.split(',') if s.strip())

        if not items: return start_y

        for i, item in enumerate(items):
            is_imp = item.lower() in important_items
            color = Color.ACCENT if is_imp else Color.TEXT_PRIMARY
            font_choice = Font.base(self._z(11), "bold" if is_imp else "normal")
            
            display_text = item + ("," if i < len(items) - 1 else "")
            
            temp_id = self.canvas.create_text(0, -10000, text=display_text, font=font_choice)
            bbox = self.canvas.bbox(temp_id)
            self.canvas.delete(temp_id)
            item_w = (bbox[2] - bbox[0]) if bbox else self._z(len(display_text) * 7)
            
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
            curr_x += item_w + self._z(5)

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
        if not found: imp_list.append(item_val)
        new_str = ", ".join(imp_list)
        update_single_field(word, f"important_{field_key}", new_str)
        
        for w in self.words:
            if w['word'] == word:
                w[f"important_{field_key}"] = new_str
                break
        self.render()

    def _draw_text_action(self, x_right, y_center, text, default_color, hover_color, command, word, tag_group, hover_trigger_tag):
        temp = self.canvas.create_text(0, -10000, text=text, font=Font.base(self._z(10), "bold"))
        bbox = self.canvas.bbox(temp)
        self.canvas.delete(temp)
        tw = (bbox[2] - bbox[0]) if bbox else self._z(30)

        x_left = x_right - tw
        btn_tag = f"action_{text}_{word}"
        
        pad = self._z(5)
        self.canvas.create_rectangle(x_left-pad, y_center-pad, x_right+pad, y_center+pad, fill="", outline="", tags=(btn_tag, tag_group, hover_trigger_tag, "clickable"))
        text_id = self.canvas.create_text(x_left + tw//2, y_center, text=text, font=Font.base(self._z(10), "bold"), fill=default_color, tags=(btn_tag, tag_group, hover_trigger_tag, "clickable"))

        def on_click(e, cmd=command, w=word): cmd(w)
        def on_enter(e, tid=text_id, hc=hover_color):
            self.canvas.itemconfig(tid, fill=hc)
            self.canvas.config(cursor="hand2")
        def on_leave(e, tid=text_id, dc=default_color):
            self.canvas.itemconfig(tid, fill=dc)
            self.canvas.config(cursor="")

        self.canvas.tag_bind(btn_tag, "<Button-1>", on_click)
        self.canvas.tag_bind(btn_tag, "<Enter>", on_enter)
        self.canvas.tag_bind(btn_tag, "<Leave>", on_leave)

        return x_left - self._z(12) 

    # ----- UPDATED METHOD (user's corrected version) -----
    def _draw_prop_row(self, label, key, w_data, x1, curr_y, max_x, is_edit, custom_font="Segoe UI", is_tag_list=False, val_font_size=11):
        value = w_data.get(key, "") or ""
        if not is_edit and not value: return curr_y 

        # The X-coordinate where the label text begins
        label_x = x1 + self._z(15)
        
        # FIX: Increased val_x from 95 to 125.
        # This allocates a much wider, guaranteed invisible column for the bold labels, 
        # ensuring even the longest labels (like "Synonyms") never overlap the values.
        val_x = x1 + self._z(125) 
        
        # Calculate remaining width to wrap long text properly before hitting the right edge
        val_w = max(self._z(80), max_x - val_x - self._z(15))

        # Draw the Label
        self.canvas.create_text(label_x, curr_y, text=label, font=Font.base(self._z(10), "bold"), fill=Color.TEXT_SECONDARY, anchor="nw")

        # Draw the Value (Entry/Textbox if editing, static text/interactive tags if viewing)
        if is_edit:
            if is_tag_list or key == 'notes':
                widget = ctk.CTkTextbox(self.canvas, width=val_w, height=self._z(45), fg_color=Color.SURFACE_3, text_color=Color.TEXT_PRIMARY, font=Font.base(self._z(11)), border_width=1, border_color=Color.GLASS_BORDER)
                widget.insert("1.0", value)
                self.canvas.create_window(val_x, curr_y, anchor="nw", window=widget)
                self.edit_widgets[f"{w_data['word']}_{key}"] = widget
                return curr_y + self._z(55)
            else:
                widget = ctk.CTkEntry(self.canvas, width=val_w, fg_color=Color.SURFACE_3, text_color=Color.TEXT_PRIMARY, font=(custom_font, self._z(11)), border_width=1, border_color=Color.GLASS_BORDER)
                widget.insert(0, value)
                self.canvas.create_window(val_x, curr_y, anchor="nw", window=widget)
                self.edit_widgets[f"{w_data['word']}_{key}"] = widget
                return curr_y + self._z(30)
        else:
            if is_tag_list:
                imp_key = w_data.get(f'important_{key}', "") or ""
                return self._draw_interactive_tags(val_x, curr_y, val_w, value, imp_key, w_data['word'], key) + self._z(10)
            else:
                text_id = self.canvas.create_text(val_x, curr_y, text=value, font=(custom_font, self._z(val_font_size)), fill=Color.TEXT_PRIMARY, anchor="nw", width=val_w)
                bbox = self.canvas.bbox(text_id)
                return (bbox[3] if bbox else curr_y + self._z(15)) + self._z(12)

    def _draw_card(self, y_start, w_data, width):
        word = w_data['word']
        is_edit = (self.editing_word == word)
        
        x1 = self._z(20)
        x2 = max(x1 + self._z(250), width - self._z(20))
        
        card_tag = f"card_{word}"
        corner_rad = self._z(10)
        
        # Directly assign unique polygon IDs to prevent TclError
        rim_id = self._create_round_rect(x1, y_start, x2, y_start+self._z(60), radius=corner_rad, fill=Color.GLASS_BORDER, outline="", tags=card_tag)
        bg_id = self._create_round_rect(x1+1, y_start+1, x2-1, y_start+self._z(60)-1, radius=corner_rad, fill=Color.SURFACE_2, outline="", tags=card_tag)
        
        curr_y = y_start + self._z(15) 
        
        # --- Header Section ---
        is_fav = bool(w_data.get('is_favorite', 0))
        fav_color = Color.HIGHLIGHT if is_fav else Color.TEXT_MUTED
        
        star_id = self.canvas.create_text(x1 + self._z(15), curr_y, text="★" if is_fav else "☆", font=Font.base(self._z(14)), fill=fav_color, anchor="nw", tags=(card_tag, "clickable"))
        self.canvas.tag_bind(star_id, "<Button-1>", lambda e, w=word: self.action_fav(w))
        self.canvas.tag_bind(star_id, "<Enter>", lambda e, tid=star_id: self.canvas.itemconfig(tid, fill=Color.ACCENT) or self.canvas.config(cursor="hand2"))
        self.canvas.tag_bind(star_id, "<Leave>", lambda e, tid=star_id: self.canvas.itemconfig(tid, fill=fav_color) or self.canvas.config(cursor=""))

        title_x = x1 + self._z(35)
        title_id = self.canvas.create_text(title_x, curr_y - self._z(2), text=word.capitalize(), font=Font.base(self._z(16), "bold"), fill=Color.TEXT_PRIMARY, anchor="nw", tags=card_tag)
        
        title_bbox = self.canvas.bbox(title_id)
        current_x = (title_bbox[2] + self._z(10)) if title_bbox else title_x + self._z(80)

        ipa = w_data.get('ipa', '').strip()
        if ipa:
            ipa_id = self.canvas.create_text(current_x, curr_y + self._z(2), text=f"/{ipa}/", font=Font.base(self._z(10), "italic"), fill=Color.TEXT_MUTED, anchor="nw", tags=card_tag)
            ipa_bbox = self.canvas.bbox(ipa_id)
            current_x = (ipa_bbox[2] + self._z(10)) if ipa_bbox else current_x + self._z(50)

        pos = w_data.get('part_of_speech', '').strip()
        if pos:
            self.canvas.create_text(current_x, curr_y + self._z(2), text=f"•  {pos}", font=Font.base(self._z(10)), fill=Color.ACCENT, anchor="nw", tags=card_tag)

        # --- Hidden Action Bar ---
        actions_tag = f"actions_{word}"
        btn_x = x2 - self._z(15)
        action_y = curr_y + self._z(8)
        
        if is_edit:
            btn_x = self._draw_text_action(btn_x, action_y, "Save", Color.SUCCESS, Color.SUCCESS, self.action_save, word, actions_tag, card_tag)
            btn_x = self._draw_text_action(btn_x, action_y, "Cancel", Color.TEXT_SECONDARY, Color.TEXT_PRIMARY, lambda w: self.app.cancel_edit(), word, actions_tag, card_tag)
        else:
            btn_x = self._draw_text_action(btn_x, action_y, "Delete", Color.TEXT_SECONDARY, Color.DANGER, self.action_delete, word, actions_tag, card_tag)
            btn_x = self._draw_text_action(btn_x, action_y, "Refresh", Color.TEXT_SECONDARY, Color.ACCENT, self.action_refresh, word, actions_tag, card_tag)
            btn_x = self._draw_text_action(btn_x, action_y, "Edit", Color.TEXT_SECONDARY, Color.TEXT_PRIMARY, self.action_edit, word, actions_tag, card_tag)
            self.canvas.itemconfig(actions_tag, state="hidden")

        self.canvas.tag_bind(card_tag, "<Enter>", lambda e: self.canvas.itemconfig(actions_tag, state="normal"))
        self.canvas.tag_bind(card_tag, "<Leave>", lambda e: self.canvas.itemconfig(actions_tag, state="hidden"))

        # --- Body Grid Section ---
        curr_y += self._z(35)
        
        curr_y = self._draw_prop_row("Meaning", 'meaning', w_data, x1, curr_y, x2, is_edit)
        curr_y = self._draw_prop_row("Bangla", 'bangla_meaning', w_data, x1, curr_y, x2, is_edit, custom_font="Kalpurush", val_font_size=12)
        curr_y = self._draw_prop_row("Example", 'example_sentence', w_data, x1, curr_y, x2, is_edit)
        
        curr_y += self._z(4)
        curr_y = self._draw_prop_row("Synonyms", 'synonyms', w_data, x1, curr_y, x2, is_edit, is_tag_list=True)
        curr_y = self._draw_prop_row("Antonyms", 'antonyms', w_data, x1, curr_y, x2, is_edit, is_tag_list=True)
        
        curr_y += self._z(4) 
        curr_y = self._draw_prop_row("Notes", 'notes', w_data, x1, curr_y, x2, is_edit)

        # Use the specific IDs assigned above
        self._update_round_rect(bg_id, x1+1, y_start+1, x2-1, curr_y + self._z(15)-1, radius=corner_rad)
        self._update_round_rect(rim_id, x1, y_start, x2, curr_y + self._z(15), radius=corner_rad)
        
        return bg_id, curr_y + self._z(15)

    # --- Event Actions ---
    def action_delete(self, word):
        dlg = StyledConfirmDialog(self.app, "Delete Word", f"Permanently delete '{word.capitalize()}'?", danger=True)
        self.wait_window(dlg)
        if dlg.result:
            if delete_word(word):
                self.app.load_words()

    def action_refresh(self, word):
        raw_key = self.app.api_key_entry.get().strip()
        api_key = self.app.api_key if raw_key == "••••••••" else raw_key
        if not api_key:
            dlg = StyledConfirmDialog(self.app, "Missing API Key", "Please enter your API Key in Settings first.", confirm_text="OK")
            self.wait_window(dlg)
            return
            
        self.app.status_label.configure(text=f"Refreshing '{word}'...", text_color=Color.ACCENT)
        
        def fetch_task():
            try:
                data, api_msg = _fetch_word_details(word, api_key, self.app.get_current_provider_config())
                self.app.after(0, lambda: self._on_refresh_done(word, data, api_msg))
            except Exception as e:
                self.app.after(0, lambda: self._on_refresh_done(word, None, f"Network Crash: {str(e)}"))
            
        threading.Thread(target=fetch_task, daemon=True).start()

    def _on_refresh_done(self, word, data, api_msg):
        if data:
            for field in ['meaning', 'bangla_meaning', 'english_definition', 'ipa', 'part_of_speech', 'example_sentence', 'synonyms', 'antonyms', 'exam_history']:
                if field in data: update_single_field(word, field, data[field])
            self.app.status_label.configure(text=f"Refreshed '{word}'!", text_color=Color.SUCCESS)
            self.app.load_words(scroll_to=word.lower(), flash=False)
        else:
            dlg = StyledConfirmDialog(self.app, "Refresh Failed", api_msg, confirm_text="OK", danger=True)
            self.wait_window(dlg)
            self.app.status_label.configure(text="", text_color=Color.TEXT_MUTED)

    def action_edit(self, word):
        self.editing_word = word
        self.render()

    def action_save(self, word):
        updates = {
            'meaning': self.edit_widgets.get(f"{word}_meaning").get().strip() if f"{word}_meaning" in self.edit_widgets else "",
            'bangla_meaning': self.edit_widgets.get(f"{word}_bangla_meaning").get().strip() if f"{word}_bangla_meaning" in self.edit_widgets else "",
            'example_sentence': self.edit_widgets.get(f"{word}_example_sentence").get().strip() if f"{word}_example_sentence" in self.edit_widgets else "",
            'synonyms': self.edit_widgets.get(f"{word}_synonyms").get("1.0", "end-1c").strip() if f"{word}_synonyms" in self.edit_widgets else "",
            'antonyms': self.edit_widgets.get(f"{word}_antonyms").get("1.0", "end-1c").strip() if f"{word}_antonyms" in self.edit_widgets else "",
        }
        if f"{word}_notes" in self.edit_widgets:
            updates['notes'] = self.edit_widgets.get(f"{word}_notes").get("1.0", "end-1c").strip()
            
        for field, new_value in updates.items(): update_single_field(word, field, new_value)
            
        self.editing_word = None
        self.app.load_words(scroll_to=word.lower(), flash=False)

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

# =======================================================================
# MAIN APPLICATION
# =======================================================================
class VocabNoteApp(ctk.CTk):
    
    API_PRESETS = {
        "Google AI Studio": {"url": "https://generativelanguage.googleapis.com/v1beta/models", "model": "gemini-3.1-flash-lite", "type": "google"},
        "Agent Router": {"url": "https://agentrouter.org/v1", "model": "claude-opus-4-8", "type": "openai_compatible"},
        "Groq": {"url": "https://api.groq.com/openai/v1", "model": "llama3-8b-8192", "type": "openai_compatible"},
        "Mistral AI": {"url": "https://api.mistral.ai/v1", "model": "mistral-small-latest", "type": "openai_compatible"},
        "GitHub Models": {"url": "https://models.inference.ai.azure.com", "model": "gpt-4o", "type": "openai_compatible"},
        "OpenRouter": {"url": "https://openrouter.ai/api/v1", "model": "google/gemini-2.5-flash:free", "type": "openai_compatible"},
        "Hugging Face": {"url": "https://api-inference.huggingface.co/v1", "model": "meta-llama/Meta-Llama-3-8B-Instruct", "type": "openai_compatible"},
        "Cohere": {"url": "https://api.cohere.com/v1", "model": "command-r", "type": "openai_compatible"},
        "Cloudflare Workers": {"url": "https://api.cloudflare.com/client/v4/accounts/YOUR_ACCOUNT_ID/ai/v1", "model": "@cf/meta/llama-3-8b-instruct", "type": "openai_compatible"},
        "Custom API Server": {"url": "https://api.example.com/v1", "model": "gpt-4", "type": "openai_compatible"}
    }
    
    def __init__(self):
        super().__init__()
        init_db()
        
        self.api_key = get_setting("gemini_api_key")
        
        # Zoom Logic – default 1.0 replaces previous 0.6
        try:
            saved_zoom = float(get_setting("zoom_factor") or 1.0)
            if saved_zoom <= 0.7:
                self.zoom_factor = 1.0
            else:
                self.zoom_factor = saved_zoom
        except ValueError: 
            self.zoom_factor = 1.0
            
        self.current_volume_id = None
        self.show_favorites_only = False
        self.volume_buttons = []

        self.title("VocabNote")
        if os.path.exists(resource_path("vocab_icon.ico")): self.iconbitmap(resource_path("vocab_icon.ico"))
            
        self.geometry("1200x800")
        self.configure(fg_color=Color.SURFACE_0)
        self.grid_columnconfigure(1, weight=1)
        self.grid_rowconfigure(0, weight=1)

        self.setup_sidebar()
        self.setup_notebook_page()
        self.setup_settings_page()
        self.setup_shortcuts() 

        self.view_all_words()
        self.refresh_volumes_dashboard()
        self.load_words()

    def setup_shortcuts(self):
        self.bind("<Control-f>", lambda e: self.search_entry.focus_set())
        self.bind("<Control-n>", lambda e: self.add_word_entry.focus_set())
        self.bind("<Escape>", lambda e: self.cancel_edit())

    def cancel_edit(self):
        if self.word_list_frame.editing_word:
            self.word_list_frame.editing_word = None
            self.word_list_frame.render()

    def setup_sidebar(self):
        self.sidebar = ctk.CTkFrame(self, width=260, fg_color=Color.SURFACE_1, corner_radius=0)
        self.sidebar.grid(row=0, column=0, sticky="nsew")
        self.sidebar.grid_rowconfigure(4, weight=1)

        ctk.CTkLabel(self.sidebar, text="VocabNote", font=Font.base(20, "bold"), text_color=Color.TEXT_PRIMARY).grid(row=0, column=0, padx=25, pady=(35, 20), sticky="w")

        self.btn_notebook = ctk.CTkButton(self.sidebar, text="All Words", fg_color=Color.SURFACE_3, hover_color=Color.GLASS_BORDER, text_color=Color.TEXT_PRIMARY, font=Font.base(13, "bold"), anchor="w", command=self.view_all_words)
        self.btn_notebook.grid(row=1, column=0, padx=15, pady=2, sticky="ew")

        self.btn_favorites = ctk.CTkButton(self.sidebar, text="Favorites", fg_color="transparent", hover_color=Color.SURFACE_3, text_color=Color.TEXT_SECONDARY, font=Font.base(13, "bold"), anchor="w", command=self.view_favorites)
        self.btn_favorites.grid(row=2, column=0, padx=15, pady=2, sticky="ew")

        nav_header = ctk.CTkFrame(self.sidebar, fg_color="transparent")
        nav_header.grid(row=3, column=0, padx=25, pady=(30, 10), sticky="ew")
        ctk.CTkLabel(nav_header, text="VOLUMES", font=Font.base(11, "bold"), text_color=Color.TEXT_MUTED).pack(side="left")
        ctk.CTkButton(nav_header, text="+", width=24, height=24, fg_color="transparent", hover_color=Color.SURFACE_3, text_color=Color.ACCENT, command=self.add_volume_ui).pack(side="right")

        self.volumes_scroll = ctk.CTkScrollableFrame(self.sidebar, fg_color="transparent", width=230)
        self.volumes_scroll.grid(row=4, column=0, padx=5, sticky="nsew")

        ctk.CTkButton(self.sidebar, text="Settings", fg_color="transparent", hover_color=Color.SURFACE_3, text_color=Color.TEXT_SECONDARY, font=Font.base(13), anchor="w", command=lambda: self.select_frame("settings")).grid(row=6, column=0, padx=15, pady=(20, 5), sticky="ew")
        ctk.CTkButton(self.sidebar, text="Export as DOCX", fg_color="transparent", hover_color=Color.SURFACE_3, text_color=Color.TEXT_SECONDARY, font=Font.base(13), anchor="w", command=self.export_docx).grid(row=7, column=0, padx=15, pady=5, sticky="ew")
        ctk.CTkButton(self.sidebar, text="Import from DOCX", fg_color="transparent", hover_color=Color.SURFACE_3, text_color=Color.TEXT_SECONDARY, font=Font.base(13), anchor="w", command=self.import_docx).grid(row=8, column=0, padx=15, pady=(5, 30), sticky="ew")

    def setup_notebook_page(self):
        self.notebook_frame = ctk.CTkFrame(self, fg_color=Color.SURFACE_0, corner_radius=0)
        
        self.header_container = tk.Frame(self.notebook_frame, bg=Color.SURFACE_0)
        self.header_container.pack(fill="x", padx=40, pady=(35, 10))

        row1 = tk.Frame(self.header_container, bg=Color.SURFACE_0)
        row1.pack(fill="x", pady=(0, 25))
        
        self.header_title = ctk.CTkLabel(row1, text="My Notebook", font=Font.base(24, "bold"), text_color=Color.TEXT_PRIMARY)
        self.header_title.pack(side="left")

        self.zoom_slider = ctk.CTkSlider(row1, from_=0.7, to=1.5, width=120, command=self.on_zoom_changed, button_color=Color.ACCENT, button_hover_color=Color.ACCENT_HOVER)
        self.zoom_slider.set(self.zoom_factor)
        self.zoom_slider.pack(side="right", padx=(10, 0))
        self.zoom_slider.bind("<ButtonRelease-1>", lambda e: save_setting("zoom_factor", str(self.zoom_factor)))
        ctk.CTkLabel(row1, text="Zoom", font=Font.base(11, "bold"), text_color=Color.TEXT_MUTED).pack(side="right")
        
        self.sort_dropdown = ctk.CTkOptionMenu(row1, values=["Sort A-Z", "Sort Z-A"], width=120, height=32, fg_color=Color.SURFACE_1, button_color=Color.SURFACE_1, button_hover_color=Color.SURFACE_3, font=Font.base(12), command=lambda _: self.load_words())
        self.sort_dropdown.pack(side="right", padx=15)

        row2 = tk.Frame(self.header_container, bg=Color.SURFACE_0)
        row2.pack(fill="x")

        self.add_word_entry = ctk.CTkEntry(row2, placeholder_text="Enter word to add/enrich...", width=260, height=34, font=Font.base(13), fg_color=Color.SURFACE_1, border_width=1, border_color=Color.GLASS_BORDER)
        self.add_word_entry.pack(side="left", padx=(0, 10))
        self.add_word_entry.bind("<Return>", lambda e: self.add_new_word())
        
        ctk.CTkButton(row2, text="Enrich Word", width=110, height=34, fg_color=Color.ACCENT, hover_color=Color.ACCENT_HOVER, text_color="#000000", font=Font.base(13, "bold"), command=self.add_new_word).pack(side="left")

        self.search_all_var = tk.BooleanVar(value=True)
        self.cb_search_all = ctk.CTkCheckBox(row2, text="Search All Volumes", variable=self.search_all_var, font=Font.base(11), text_color=Color.TEXT_MUTED, fg_color=Color.ACCENT, hover_color=Color.ACCENT_HOVER, border_color=Color.GLASS_BORDER, command=lambda: self.load_words())
        self.cb_search_all.pack(side="right", padx=(15, 0))

        self.search_entry = ctk.CTkEntry(row2, placeholder_text="Search notebook...", width=220, height=34, font=Font.base(13), fg_color=Color.SURFACE_1, border_width=1, border_color=Color.GLASS_BORDER)
        self.search_entry.pack(side="right")
        self.search_entry.bind("<KeyRelease>", lambda e: self.load_words())

        self.status_label = ctk.CTkLabel(self.notebook_frame, text="", font=Font.base(12), text_color=Color.TEXT_MUTED, height=20)
        self.status_label.pack(anchor="w", padx=40, pady=(0, 6))

        self.word_list_frame = WordListView(self.notebook_frame, self)
        self.word_list_frame.pack(side="top", fill="both", expand=True, padx=40, pady=(0, 10))

    def on_zoom_changed(self, value):
        self.zoom_factor = value
        self.word_list_frame.render()

    def setup_settings_page(self):
        self.settings_frame = ctk.CTkFrame(self, fg_color=Color.SURFACE_0, corner_radius=0)
        
        card = ctk.CTkFrame(self.settings_frame, fg_color=Color.SURFACE_1, corner_radius=16, border_width=1, border_color=Color.GLASS_BORDER)
        card.pack(fill="x", padx=50, pady=50)
        
        ctk.CTkLabel(card, text="API Settings", font=Font.base(24, "bold"), text_color=Color.TEXT_PRIMARY).pack(anchor="w", padx=40, pady=(40, 30))
        
        ctk.CTkLabel(card, text="Select AI Platform", font=Font.base(12, "bold"), text_color=Color.TEXT_MUTED).pack(anchor="w", padx=40)
        self.provider_var = tk.StringVar(value=get_setting("api_provider_name") or "Google AI Studio")
        self.provider_dropdown = ctk.CTkOptionMenu(card, variable=self.provider_var, values=list(self.API_PRESETS.keys()), width=300, fg_color=Color.SURFACE_2, button_color=Color.SURFACE_2, button_hover_color=Color.SURFACE_3, font=Font.base(13), command=self.on_provider_change)
        self.provider_dropdown.pack(anchor="w", padx=40, pady=(0, 20))

        ctk.CTkLabel(card, text="Base URL", font=Font.base(12, "bold"), text_color=Color.TEXT_MUTED).pack(anchor="w", padx=40)
        self.url_entry = ctk.CTkEntry(card, width=500, font=Font.base(13), fg_color=Color.SURFACE_2, border_color=Color.GLASS_BORDER)
        self.url_entry.insert(0, get_setting("api_base_url") or self.API_PRESETS["Google AI Studio"]["url"])
        self.url_entry.pack(anchor="w", padx=40, pady=(0, 20))

        ctk.CTkLabel(card, text="Model Name", font=Font.base(12, "bold"), text_color=Color.TEXT_MUTED).pack(anchor="w", padx=40)
        self.model_entry = ctk.CTkEntry(card, width=500, font=Font.base(13), fg_color=Color.SURFACE_2, border_color=Color.GLASS_BORDER)
        self.model_entry.insert(0, get_setting("api_model") or self.API_PRESETS["Google AI Studio"]["model"])
        self.model_entry.pack(anchor="w", padx=40, pady=(0, 20))
        
        ctk.CTkLabel(card, text="API Key", font=Font.base(12, "bold"), text_color=Color.TEXT_MUTED).pack(anchor="w", padx=40)
        self.api_key_entry = ctk.CTkEntry(card, width=500, font=Font.base(13), fg_color=Color.SURFACE_2, border_color=Color.GLASS_BORDER)
        saved_key = get_setting("gemini_api_key")
        if saved_key: 
            self.api_key_entry.insert(0, saved_key)
            self.api_key_entry.configure(show="•")
        self.api_key_entry.bind("<FocusIn>", lambda e: self.api_key_entry.configure(show=""))
        self.api_key_entry.bind("<FocusOut>", lambda e: self.api_key_entry.configure(show="•"))
        self.api_key_entry.pack(anchor="w", padx=40, pady=(0, 30))

        btn_frame = ctk.CTkFrame(card, fg_color="transparent")
        btn_frame.pack(anchor="w", padx=40, pady=(0, 40))
        
        ctk.CTkButton(btn_frame, text="Save Configurations", width=170, height=34, fg_color=Color.ACCENT, hover_color=Color.ACCENT_HOVER, text_color="#000000", font=Font.base(13, "bold"), command=self.save_api_settings).pack(side="left", padx=(0, 15))
        self.test_btn = ctk.CTkButton(btn_frame, text="Test Connection", width=150, height=34, fg_color=Color.SURFACE_3, hover_color=Color.GLASS_BORDER, text_color=Color.TEXT_PRIMARY, font=Font.base(13), command=self.run_api_test)
        self.test_btn.pack(side="left")
        
        self.settings_status = ctk.CTkLabel(btn_frame, text="", font=Font.base(13), text_color=Color.TEXT_MUTED)
        self.settings_status.pack(side="left", padx=20)

    def on_provider_change(self, choice):
        preset = self.API_PRESETS.get(choice)
        if preset:
            self.url_entry.delete(0, 'end')
            self.url_entry.insert(0, preset["url"])
            self.model_entry.delete(0, 'end')
            self.model_entry.insert(0, preset["model"])

    def get_current_provider_config(self):
        return {
            "type": self.API_PRESETS.get(self.provider_var.get(), {}).get("type", "openai_compatible"),
            "base_url": self.url_entry.get().strip(),
            "model": self.model_entry.get().strip()
        }

    def save_api_settings(self):
        save_setting("api_provider_name", self.provider_var.get())
        save_setting("api_model", self.model_entry.get().strip())
        save_setting("api_base_url", self.url_entry.get().strip())
        save_setting("gemini_api_key", self.api_key_entry.get().strip())
        self.api_key = self.api_key_entry.get().strip()
        self.settings_status.configure(text="Saved securely!", text_color=Color.SUCCESS)

    def run_api_test(self):
        self.settings_status.configure(text="Testing...", text_color=Color.ACCENT)
        self.test_btn.configure(state="disabled")
        self.update()
        test_config = self.get_current_provider_config()
        api_key_to_test = self.api_key_entry.get().strip()
        
        def background_task():
            is_success, msg = _test_gemini_connection(api_key_to_test, test_config)
            self.after(0, lambda: self.settings_status.configure(text=msg, text_color=Color.SUCCESS if is_success else Color.DANGER))
            self.after(0, lambda: self.test_btn.configure(state="normal"))
            
        threading.Thread(target=background_task, daemon=True).start()

    def refresh_volumes_dashboard(self):
        vols = get_all_volumes()
        
        for btn in self.volume_buttons: btn.destroy()
        self.volume_buttons.clear()
        
        if self.current_volume_id is None or not any(v['id'] == self.current_volume_id for v in vols):
            self.current_volume_id = vols[0]['id'] if vols else None

        for v in vols:
            is_active = (v['id'] == self.current_volume_id and not self.show_favorites_only and self.notebook_frame.winfo_ismapped())
            bg_color = Color.SURFACE_3 if is_active else "transparent"
            text_color = Color.ACCENT if is_active else Color.TEXT_SECONDARY
            font_w = "bold" if is_active else "normal"
            
            btn = ctk.CTkButton(self.volumes_scroll, text=f"{v['name']} ({v['word_count']})", fg_color=bg_color, hover_color=Color.SURFACE_3, text_color=text_color, font=Font.base(13, font_w), anchor="w", command=lambda vid=v['id']: self.on_volume_selected(vid))
            btn.pack(fill="x", padx=10, pady=2)
            
            btn.bind("<Button-3>", lambda e, v_id=v['id']: self.on_volume_rclick(e, v_id)) 
            
            self.volume_buttons.append(btn)

    def on_volume_rclick(self, event, vid):
        menu = tk.Menu(self, tearoff=0, bg=Color.SURFACE_1, fg=Color.TEXT_PRIMARY, activebackground=Color.SURFACE_3, activeforeground=Color.TEXT_PRIMARY, borderwidth=1, relief="solid", font=Font.base(11))
        menu.add_command(label="Rename Volume", command=lambda: self.rename_volume_ui(vid))
        menu.add_command(label="Delete Volume", command=lambda: self.delete_volume_ui(vid))
        try:
            menu.tk_popup(event.x_root, event.y_root)
        finally:
            menu.grab_release()

    def on_volume_selected(self, vid):
        self.current_volume_id = vid
        self.show_favorites_only = False
        self.select_frame("notebook")

    def view_all_words(self):
        self.show_favorites_only = False
        self.current_volume_id = None 
        self.select_frame("notebook")

    def view_favorites(self):
        self.show_favorites_only = True
        self.select_frame("notebook")

    def add_volume_ui(self):
        dlg = StyledInputDialog(self, "Create Volume", placeholder="Enter new volume name")
        self.wait_window(dlg)
        if dlg.result and dlg.result.strip():
            create_volume(dlg.result.strip())
            self.refresh_volumes_dashboard()

    def rename_volume_ui(self, vid=None):
        target_vid = vid or self.current_volume_id
        if not target_vid: return
        dlg = StyledInputDialog(self, "Rename Volume", placeholder="Enter new name")
        self.wait_window(dlg)
        if dlg.result and dlg.result.strip():
            rename_volume(target_vid, dlg.result.strip())
            self.refresh_volumes_dashboard()
            self.load_words()

    def delete_volume_ui(self, vid=None):
        target_vid = vid or self.current_volume_id
        if not target_vid: return
        dlg = StyledConfirmDialog(self, "Delete Volume", "Are you sure you want to delete this volume and all its words permanently?", danger=True)
        self.wait_window(dlg)
        if dlg.result:
            success, msg = delete_volume(target_vid)
            if success:
                if self.current_volume_id == target_vid: self.current_volume_id = None
                self.refresh_volumes_dashboard()
                self.load_words()
            else:
                StyledConfirmDialog(self, "Error", msg, confirm_text="OK").wait_window()

    def load_words(self, scroll_to=None, flash=False):
        if self.show_favorites_only:
            self.header_title.configure(text="Favorites")
        elif self.current_volume_id:
            vols = get_all_volumes()
            v_name = next((v['name'] for v in vols if v['id'] == self.current_volume_id), "Volume")
            self.header_title.configure(text=v_name)
        else:
            self.header_title.configure(text="All Words")

        all_words = get_all_words_dictionaries(
            search_query=self.search_entry.get().strip(), 
            sort_order="DESC" if "Z-A" in self.sort_dropdown.get() else "ASC", 
            volume_id=self.current_volume_id if not self.show_favorites_only else None, 
            search_all=self.search_all_var.get(),
            favorites_only=self.show_favorites_only
        )

        self.word_list_frame.set_words(all_words)
        
        if scroll_to: self.after(50, lambda: self.word_list_frame.scroll_to_word(scroll_to, flash=flash))
        else:
            try: self.word_list_frame.canvas.yview_moveto(0)
            except Exception: pass

    def add_new_word(self):
        word = self.add_word_entry.get().strip()
        if not word: return

        if check_word_exists(word):
            dialog = DuplicateDialog(self, word)
            self.wait_window(dialog)
            if dialog.result == "cancel": return
            elif dialog.result == "open":
                self.search_entry.delete(0, 'end')
                self.search_all_var.set(True) 
                self.load_words(scroll_to=word.lower(), flash=True)
                self.add_word_entry.delete(0, 'end')
                return

        raw_key = self.api_key_entry.get().strip()
        api_key_to_use = self.api_key if raw_key == "••••••••" else raw_key
        if not api_key_to_use:
            StyledConfirmDialog(self, "Missing API Key", "Please add your API Key in Settings first.", confirm_text="OK").wait_window()
            return

        self.status_label.configure(text=f"Enriching '{word}' via AI...", text_color=Color.ACCENT)
        self.update_idletasks()

        def fetch_task():
            try:
                data, api_msg = _fetch_word_details(word, api_key_to_use, self.get_current_provider_config())
                self.after(0, lambda: self._on_add_fetched(word, data, api_msg))
            except Exception as e:
                self.after(0, lambda: self._on_add_fetched(word, None, f"Network failed: {str(e)}"))
            
        threading.Thread(target=fetch_task, daemon=True).start()

    def _on_add_fetched(self, word, data, api_msg):
        if data:
            if check_word_exists(word): 
                for field in ['meaning', 'bangla_meaning', 'english_definition', 'ipa', 'part_of_speech', 'example_sentence', 'synonyms', 'antonyms', 'exam_history']:
                    if field in data: update_single_field(word, field, data[field])
                self.status_label.configure(text=f"'{word}' updated with fresh AI data!", text_color=Color.SUCCESS)
            else:
                save_word_to_db(word, data, current_vol_id=self.current_volume_id)
                self.status_label.configure(text=f"'{word}' added successfully!", text_color=Color.SUCCESS)
            
            self.add_word_entry.delete(0, 'end')
            self.search_entry.delete(0, 'end')
            self.refresh_volumes_dashboard() 
            self.load_words(scroll_to=word.lower(), flash=True)
            self.after(4000, lambda: self.status_label.configure(text=""))
        else:
            self.status_label.configure(text=api_msg, text_color=Color.DANGER)

    def select_frame(self, name):
        self.notebook_frame.grid_forget()
        self.settings_frame.grid_forget()
        
        self.btn_notebook.configure(
            fg_color=Color.SURFACE_3 if name == "notebook" and not self.show_favorites_only and not self.current_volume_id else "transparent",
            text_color=Color.ACCENT if name == "notebook" and not self.show_favorites_only and not self.current_volume_id else Color.TEXT_SECONDARY
        )
        self.btn_favorites.configure(
            fg_color=Color.SURFACE_3 if name == "notebook" and self.show_favorites_only else "transparent",
            text_color=Color.ACCENT if name == "notebook" and self.show_favorites_only else Color.TEXT_SECONDARY
        )
        
        if name == "notebook":
            self.notebook_frame.grid(row=0, column=1, sticky="nsew")
            self.refresh_volumes_dashboard()
            self.load_words()
        else:
            self.settings_frame.grid(row=0, column=1, sticky="nsew")
            self.refresh_volumes_dashboard()

    def import_docx(self):
        file_path = filedialog.askopenfilename(filetypes=[("Word Document", "*.docx")])
        if not file_path: return
        success, result = import_from_docx(file_path)
        if not success:
            StyledConfirmDialog(self, "Import Error", result, confirm_text="OK", danger=True).wait_window()
            return
            
        words_to_import = result
        if not words_to_import:
            StyledConfirmDialog(self, "Import", "No recognizable vocabulary items found.", confirm_text="OK").wait_window()
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
                    
        StyledConfirmDialog(self, "Import Summary", f"Imported: {imported_count} words\nSkipped: {skipped_count} duplicates\nFailed: {failed_count}", confirm_text="OK").wait_window()
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
            
        if not words:
            StyledConfirmDialog(self, "Export Failed", "No words found to export.", confirm_text="OK", danger=True).wait_window()
            return
            
        file_path = filedialog.asksaveasfilename(defaultextension=".docx", filetypes=[("Word Document", "*.docx")])
        if file_path:
            success, msg = export_to_docx(words, file_path)
            dlg = StyledConfirmDialog(self, "Success" if success else "Error", msg, confirm_text="OK", danger=not success)
            dlg.wait_window()

if __name__ == "__main__":
    app = VocabNoteApp()
    app.mainloop()