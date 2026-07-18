import os
import sys
import ctypes
import math
import threading
from PIL import Image

# =======================================================================
# MODULE 1: SYSTEM & HIGH-DPI FIX
# =======================================================================
if sys.platform == 'win32':
    try:
        ctypes.windll.shcore.SetProcessDpiAwareness(1)
    except Exception:
        pass

import tkinter as tk
import customtkinter as ctk
from customtkinter import filedialog

from api.gemini import test_connection as _test_gemini_connection, fetch_word_details as _fetch_word_details
from database.db_manager import (
    init_db, save_word_to_db, get_all_words_dictionaries, 
    update_single_field, delete_word, check_word_exists,
    get_setting, save_setting, get_all_volumes, create_volume,
    rename_volume, delete_volume
)
from utils.export_manager import export_to_docx, import_from_docx

# =======================================================================
# MODULE 2: CONSTANTS, TOKENS & CONFIGURATIONS
# =======================================================================
class Color:
    SURFACE_0 = "#05070A"  
    SURFACE_1 = "#0B0E14"  
    SURFACE_2 = "#121722"  
    SURFACE_3 = "#1A2133"  
    GLASS_BORDER = "#2A364F" 
    TEXT_PRIMARY = "#F8FAFC"
    TEXT_SECONDARY = "#94A3B8"
    TEXT_MUTED = "#7C8BA1"     
    ACCENT = "#38BDF8"     
    ACCENT_HOVER = "#0EA5E9"
    LOGO_BLUE = "#3B82F6" 
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
# MODULE 3: CUSTOM DIALOGS
# =======================================================================
class StyledConfirmDialog(ctk.CTkToplevel):
    def __init__(self, master, title, message, confirm_text="Confirm", danger=False):
        super().__init__(master)
        self.title("Action Required")
        self.geometry("450x220")
        self.result = False
        self.transient(master)
        self.grab_set()
        self.configure(fg_color=Color.SURFACE_2)
        if os.path.exists(resource_path("vocab_icon.ico")): self.after(200, lambda: self.iconbitmap(resource_path("vocab_icon.ico")))
        
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
        self.title("Input Prompt")
        self.geometry("400x200")
        self.result = None
        self.transient(master)
        self.grab_set()
        self.configure(fg_color=Color.SURFACE_2)
        if os.path.exists(resource_path("vocab_icon.ico")): self.after(200, lambda: self.iconbitmap(resource_path("vocab_icon.ico")))
        
        ctk.CTkLabel(self, text=title, font=Font.base(15, "bold"), text_color=Color.TEXT_PRIMARY).pack(pady=(25, 15), padx=25, anchor="w")
        self.entry = ctk.CTkEntry(self, placeholder_text=placeholder, font=Font.base(13), fg_color=Color.SURFACE_1, border_color=Color.GLASS_BORDER, width=350)
        master.apply_focus_ring(self.entry)
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

class DuplicateDialog(ctk.CTkToplevel):
    def __init__(self, master, word):
        super().__init__(master)
        self.title("Duplicate Detected")
        self.geometry("500x200")
        self.result = "cancel"
        self.transient(master)
        self.grab_set()
        self.configure(fg_color=Color.SURFACE_2)
        if os.path.exists(resource_path("vocab_icon.ico")): self.after(200, lambda: self.iconbitmap(resource_path("vocab_icon.ico")))
        
        ctk.CTkLabel(self, text=f"'{word.capitalize()}' is already in your notebook.", font=Font.base(15, "bold"), text_color=Color.TEXT_PRIMARY).pack(pady=(30, 25))
        btn_frame = ctk.CTkFrame(self, fg_color="transparent")
        btn_frame.pack(fill="x", padx=20)
        ctk.CTkButton(btn_frame, text="Open Entry", fg_color=Color.ACCENT, hover_color=Color.ACCENT_HOVER, text_color="#000000", command=lambda: self.set_result("open")).pack(side="left", padx=5, expand=True)
        ctk.CTkButton(btn_frame, text="Replace AI Data", fg_color=Color.DANGER, hover_color="#DC2626", text_color="#FFFFFF", command=lambda: self.set_result("replace")).pack(side="left", padx=5, expand=True)
        ctk.CTkButton(btn_frame, text="Cancel", fg_color=Color.SURFACE_3, hover_color=Color.GLASS_BORDER, text_color=Color.TEXT_PRIMARY, command=lambda: self.set_result("cancel")).pack(side="left", padx=5, expand=True)
        
    def set_result(self, res):
        self.result = res
        self.destroy()

class ExportSelectionDialog(ctk.CTkToplevel):
    def __init__(self, master, current_vol_id, all_volumes):
        super().__init__(master)
        self.title("Export Notebook")
        self.geometry("450x260")
        self.result = None
        self.transient(master)
        self.grab_set()
        self.configure(fg_color=Color.SURFACE_2)
        if os.path.exists(resource_path("vocab_icon.ico")): self.after(200, lambda: self.iconbitmap(resource_path("vocab_icon.ico")))
        
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
        if os.path.exists(resource_path("vocab_icon.ico")): self.after(200, lambda: self.iconbitmap(resource_path("vocab_icon.ico")))
        
        ctk.CTkLabel(self, text=f"'{word.capitalize()}' already exists. What should we do?", font=Font.base(15, "bold"), text_color=Color.TEXT_PRIMARY).pack(pady=(20, 25))
        btn_frame = ctk.CTkFrame(self, fg_color="transparent")
        btn_frame.pack(fill="x", padx=15)
        ctk.CTkButton(btn_frame, text="Replace", fg_color=Color.DANGER, hover_color="#DC2626", text_color="#FFFFFF", command=lambda: self.set_result("replace")).pack(side="left", padx=5, expand=True)
        ctk.CTkButton(btn_frame, text="Skip", fg_color=Color.SURFACE_3, hover_color=Color.GLASS_BORDER, text_color=Color.TEXT_PRIMARY, command=lambda: self.set_result("skip")).pack(side="left", padx=5, expand=True)
        ctk.CTkButton(btn_frame, text="Replace All", fg_color=Color.DANGER, hover_color="#DC2626", text_color="#FFFFFF", command=lambda: self.set_result("replace_all")).pack(side="left", padx=5, expand=True)
        ctk.CTkButton(btn_frame, text="Skip All", fg_color=Color.SURFACE_3, hover_color=Color.GLASS_BORDER, text_color=Color.TEXT_PRIMARY, command=lambda: self.set_result("skip_all")).pack(side="left", padx=5, expand=True)
        
    def set_result(self, res):
        self.result = res
        self.destroy()

# =======================================================================
# MODULE 4: UNIFIED CANVAS RENDER ENGINE
# =======================================================================
class CardRenderer:
    def __init__(self, app, canvas, edit_widgets_dict):
        self.app = app
        self.canvas = canvas
        self.edit_widgets = edit_widgets_dict

    def _z(self, val):
        try:
            dpi_scale = ctk.ScalingTracker.get_window_dpi_scaling(self.app)
        except Exception:
            dpi_scale = 1.0
        return int(val * self.app.zoom_factor * dpi_scale)

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

    def _draw_interactive_tags(self, start_x, start_y, max_w, items_str, important_str, word, field_key, safe_word, font_size_key, callbacks):
        curr_x, curr_y = start_x, start_y
        items = [s.strip() for s in items_str.split(',') if s.strip()]
        important_items = set(s.strip().lower() for s in important_str.split(',') if s.strip())

        if not items: return start_y

        card_tag = f"card_{safe_word}"
        font_val = self.app.font_sizes.get(font_size_key, 12)
        
        line_height = self._z(font_val * 2.2)  
        text_height = self._z(font_val * 1.5) 
        max_bottom = curr_y + text_height 

        for i, item in enumerate(items):
            is_imp = item.lower() in important_items
            text_color = Color.ACCENT if is_imp else Color.TEXT_SECONDARY
            font_choice = Font.base(max(4, self._z(font_val)), "bold" if is_imp else "normal")
            
            display_text = item + ("," if i < len(items) - 1 else "")
            
            temp_id = self.canvas.create_text(0, -10000, text=display_text, font=font_choice)
            bbox = self.canvas.bbox(temp_id)
            self.canvas.delete(temp_id)
            tw = (bbox[2] - bbox[0]) if bbox else self._z(len(display_text) * 7)
            
            if curr_x + tw > start_x + max_w and curr_x != start_x:
                curr_x = start_x
                curr_y += line_height
                max_bottom = curr_y + text_height
                
            pill_tag = f"tag_{safe_word}_{field_key}_{i}"
            
            text_id = self.canvas.create_text(curr_x, curr_y, text=display_text, font=font_choice, fill=text_color, anchor="nw", tags=(card_tag, pill_tag, "clickable"))
            
            if callbacks and callbacks.get('toggle_tag'):
                def on_enter(e, tid=text_id):
                    self.canvas.itemconfig(tid, fill=Color.TEXT_PRIMARY)
                    self.canvas.config(cursor="hand2")
                def on_leave(e, tid=text_id, tc=text_color):
                    self.canvas.itemconfig(tid, fill=tc)
                    self.canvas.config(cursor="")
                def on_click(e, w=word, k=field_key, val=item, cur_imp=important_str):
                    callbacks['toggle_tag'](w, k, val, cur_imp)

                self.canvas.tag_bind(pill_tag, "<Enter>", on_enter)
                self.canvas.tag_bind(pill_tag, "<Leave>", on_leave)
                self.canvas.tag_bind(pill_tag, "<Button-1>", on_click)
            
            curr_x += tw + self._z(8)

        return max_bottom

    def _draw_prop_row(self, label, key, w_data, x1, curr_y, max_x, is_edit, custom_font="Segoe UI", is_tag_list=False, safe_word=None, callbacks=None):
        value = w_data.get(key, "") or ""
        if not is_edit and not value: return curr_y 

        label_x = x1 + self._z(15)
        val_x = x1 + self._z(135) 
        val_w = max(self._z(80), max_x - val_x - self._z(15))

        font_size_key = f"{key.replace('_meaning', '')}_size" if "meaning" in key else f"{key.replace('_sentence', '')}_size"
        val_font_size = self.app.font_sizes.get(font_size_key, 12)
        scaled_font_size = max(4, self._z(val_font_size))

        label_y_offset = self._z(2) if val_font_size >= 12 else 0
        self.canvas.create_text(label_x, curr_y + label_y_offset, text=label, font=Font.base(max(4, self._z(11)), "bold"), fill=Color.TEXT_SECONDARY, anchor="nw")

        user_gap = self._z(self.app.spacings.get(f"{key}_gap", 15))

        if is_edit:
            if is_tag_list or key == 'notes':
                widget = ctk.CTkTextbox(self.canvas, width=val_w, height=self._z(45), fg_color=Color.SURFACE_3, text_color=Color.TEXT_PRIMARY, font=Font.base(scaled_font_size), border_width=1, border_color=Color.GLASS_BORDER)
                widget.insert("1.0", value)
                self.canvas.create_window(val_x, curr_y, anchor="nw", window=widget)
                self.edit_widgets[f"{w_data['word']}_{key}"] = widget
                return curr_y + self._z(55) + user_gap
            else:
                widget = ctk.CTkEntry(self.canvas, width=val_w, fg_color=Color.SURFACE_3, text_color=Color.TEXT_PRIMARY, font=(custom_font, scaled_font_size), border_width=1, border_color=Color.GLASS_BORDER)
                self.app.apply_focus_ring(widget)
                widget.insert(0, value)
                self.canvas.create_window(val_x, curr_y, anchor="nw", window=widget)
                self.edit_widgets[f"{w_data['word']}_{key}"] = widget
                return curr_y + self._z(35) + user_gap
        else:
            if is_tag_list:
                imp_key = w_data.get(f'important_{key}', "") or ""
                new_y = self._draw_interactive_tags(val_x, curr_y, val_w, value, imp_key, w_data['word'], key, safe_word, font_size_key, callbacks or {})
                return new_y + user_gap
            else:
                font_tuple = Font.base(scaled_font_size) if custom_font == "Segoe UI" else (custom_font, scaled_font_size)
                
                temp_id = self.canvas.create_text(0, -10000, text=value, font=font_tuple, width=val_w, anchor="nw")
                bbox = self.canvas.bbox(temp_id)
                self.canvas.delete(temp_id)
                actual_h = (bbox[3] - bbox[1]) + 2 if bbox else self._z(val_font_size * 1.5)
                
                tb = tk.Text(self.canvas, bg=Color.SURFACE_2, fg=Color.TEXT_PRIMARY, font=font_tuple,
                             wrap="word", bd=0, highlightthickness=0, padx=0, pady=0,
                             selectbackground=Color.ACCENT, selectforeground="#000000")
                tb.insert("1.0", value)
                tb.configure(state="disabled")
                
                self.canvas.create_window(val_x, curr_y, anchor="nw", window=tb, width=val_w, height=actual_h)
                self.edit_widgets[f"display_{safe_word}_{key}"] = tb 
                
                return curr_y + actual_h + user_gap

    def _draw_text_action(self, x_right, y_center, text, default_color, hover_color, command, word, tag_group, hover_trigger_tag):
        temp = self.canvas.create_text(0, -10000, text=text, font=Font.base(max(4, self._z(11)), "bold"))
        bbox = self.canvas.bbox(temp)
        self.canvas.delete(temp)
        tw = (bbox[2] - bbox[0]) if bbox else self._z(30)

        x_left = x_right - tw
        safe_word = "".join(c if c.isalnum() else "_" for c in word)
        btn_tag = f"action_{text}_{safe_word}"
        
        pad_x = self._z(12)
        pad_y = self._z(8)

        bg_id = self._create_round_rect(x_left - pad_x, y_center - pad_y, x_right + pad_x, y_center + pad_y, radius=self._z(6), fill="", outline="", tags=(btn_tag, tag_group, hover_trigger_tag, "clickable"))
        text_id = self.canvas.create_text(x_left + tw//2, y_center, text=text, font=Font.base(max(4, self._z(11)), "bold"), fill=default_color, tags=(btn_tag, tag_group, hover_trigger_tag, "clickable"))

        if command:
            def on_click(e, cmd=command, w=word): cmd(w)
            def on_enter(e, tid=text_id, bid=bg_id, hc=hover_color):
                self.canvas.itemconfig(tid, fill=hc)
                self.canvas.itemconfig(bid, fill=Color.SURFACE_3)
                self.canvas.config(cursor="hand2")
            def on_leave(e, tid=text_id, bid=bg_id, dc=default_color):
                self.canvas.itemconfig(tid, fill=dc)
                self.canvas.itemconfig(bid, fill="")
                self.canvas.config(cursor="")

            self.canvas.tag_bind(btn_tag, "<Button-1>", on_click)
            self.canvas.tag_bind(btn_tag, "<Enter>", on_enter)
            self.canvas.tag_bind(btn_tag, "<Leave>", on_leave)

        return x_left - pad_x - self._z(10) 

    def draw_card(self, y_start, w_data, width, is_edit, is_selected=False, callbacks=None):
        callbacks = callbacks or {} 
        word = w_data['word']
        safe_word = "".join(c if c.isalnum() else "_" for c in word)
        
        x1 = self._z(20)
        x2 = max(x1 + self._z(250), width - self._z(20))
        
        card_tag = f"card_{safe_word}"
        corner_rad = self._z(12) 
        
        shadow1_id = self._create_round_rect(x1-2, y_start-1, x2+2, y_start+self._z(65)+2, radius=corner_rad+2, fill="#040508", outline="", tags=card_tag)
        shadow2_id = self._create_round_rect(x1-1, y_start, x2+1, y_start+self._z(65)+1, radius=corner_rad+1, fill="#07090D", outline="", tags=card_tag)
        
        hl_color = Color.ACCENT if is_selected else ""
        hl_width = 2 if is_selected else 0
        highlight_id = self._create_round_rect(x1-2, y_start-2, x2+2, y_start+self._z(65)+2, radius=corner_rad+2, fill="", outline=hl_color, width=hl_width, tags=card_tag)
        
        rim_id = self._create_round_rect(x1, y_start, x2, y_start+self._z(65), radius=corner_rad, fill=Color.GLASS_BORDER, outline="", tags=card_tag)
        bg_id = self._create_round_rect(x1+1, y_start+1, x2-1, y_start+self._z(65)-1, radius=corner_rad, fill=Color.SURFACE_2, outline="", tags=card_tag)
        
        curr_y = y_start + self._z(15) 
        
        is_fav = bool(w_data.get('is_favorite', 0))
        fav_color = Color.HIGHLIGHT if is_fav else Color.TEXT_MUTED
        
        star_cx = x1 + self._z(22)
        star_cy = curr_y + self._z(12)
        star_id = self._draw_star(star_cx, star_cy, self._z(8), self._z(3.5), is_fav, fav_color, (card_tag, "clickable"))
        
        if callbacks.get('fav'):
            self.canvas.tag_bind(star_id, "<Button-1>", lambda e, w=word: callbacks['fav'](w))
            self.canvas.tag_bind(star_id, "<Enter>", lambda e: self.canvas.config(cursor="hand2"))
            self.canvas.tag_bind(star_id, "<Leave>", lambda e: self.canvas.config(cursor=""))

        title_size = max(4, self._z(self.app.font_sizes.get('title_size', 18)))
        title_x = x1 + self._z(45)
        title_id = self.canvas.create_text(title_x, curr_y - self._z(2), text=word.capitalize(), font=Font.base(title_size, "bold"), fill=Color.TEXT_PRIMARY, anchor="nw", tags=card_tag)
        
        title_bbox = self.canvas.bbox(title_id)
        current_x = (title_bbox[2] + self._z(15)) if title_bbox else title_x + self._z(90)

        ipa = w_data.get('ipa', '').strip()
        if ipa:
            ipa_id = self.canvas.create_text(current_x, curr_y + self._z(4), text=f"/{ipa}/", font=Font.base(max(4, self._z(11)), "italic"), fill=Color.TEXT_MUTED, anchor="nw", tags=card_tag)
            ipa_bbox = self.canvas.bbox(ipa_id)
            current_x = (ipa_bbox[2] + self._z(15)) if ipa_bbox else current_x + self._z(60)

        pos = w_data.get('part_of_speech', '').strip()
        if pos:
            self.canvas.create_text(current_x, curr_y + self._z(4), text=f"•  {pos}", font=Font.base(max(4, self._z(12))), fill=Color.ACCENT, anchor="nw", tags=card_tag)

        actions_tag = f"actions_{safe_word}"
        btn_x = x2 - self._z(15)
        action_y = curr_y + self._z(12)
        
        if is_edit:
            btn_x = self._draw_text_action(btn_x, action_y, "Save", Color.SUCCESS, Color.SUCCESS, callbacks.get('save'), word, actions_tag, card_tag)
            btn_x = self._draw_text_action(btn_x, action_y, "Cancel", Color.TEXT_SECONDARY, Color.TEXT_PRIMARY, callbacks.get('cancel'), word, actions_tag, card_tag)
        else:
            btn_x = self._draw_text_action(btn_x, action_y, "Delete", Color.TEXT_MUTED, Color.DANGER, callbacks.get('delete'), word, actions_tag, card_tag)
            btn_x = self._draw_text_action(btn_x, action_y, "Refresh", Color.TEXT_MUTED, Color.ACCENT, callbacks.get('refresh'), word, actions_tag, card_tag)
            btn_x = self._draw_text_action(btn_x, action_y, "Edit", Color.TEXT_MUTED, Color.SUCCESS, callbacks.get('edit'), word, actions_tag, card_tag)

        curr_y += self._z(self.app.spacings.get('title_gap', 47))
        
        curr_y = self._draw_prop_row("Meaning", 'meaning', w_data, x1, curr_y, x2, is_edit, callbacks=callbacks)
        curr_y = self._draw_prop_row("Bangla", 'bangla_meaning', w_data, x1, curr_y, x2, is_edit, custom_font="Kalpurush", callbacks=callbacks)
        curr_y = self._draw_prop_row("Example", 'example_sentence', w_data, x1, curr_y, x2, is_edit, callbacks=callbacks)
        curr_y = self._draw_prop_row("Synonyms", 'synonyms', w_data, x1, curr_y, x2, is_edit, is_tag_list=True, safe_word=safe_word, callbacks=callbacks)
        curr_y = self._draw_prop_row("Antonyms", 'antonyms', w_data, x1, curr_y, x2, is_edit, is_tag_list=True, safe_word=safe_word, callbacks=callbacks)
        curr_y = self._draw_prop_row("Notes", 'notes', w_data, x1, curr_y, x2, is_edit, callbacks=callbacks)

        curr_y += self._z(self.app.spacings.get('card_padding_bottom', 20))

        if curr_y < y_start + self._z(80):
            curr_y = y_start + self._z(80)

        self._update_round_rect(shadow1_id, x1-2, y_start-1, x2+2, curr_y+2, radius=corner_rad+2)
        self._update_round_rect(shadow2_id, x1-1, y_start, x2+1, curr_y+1, radius=corner_rad+1)
        self._update_round_rect(highlight_id, x1-2, y_start-2, x2+2, curr_y+2, radius=corner_rad+2)
        self._update_round_rect(rim_id, x1, y_start, x2, curr_y, radius=corner_rad)
        self._update_round_rect(bg_id, x1+1, y_start+1, x2-1, curr_y - 1, radius=corner_rad)
        
        return bg_id, highlight_id, curr_y

# =======================================================================
# MODULE 5: PAGE LAYOUTS (Settings & Notebook Views)
# =======================================================================
class WordListView(ctk.CTkFrame):
    def __init__(self, master, app, is_preview=False):
        bg_color = Color.SURFACE_1 if is_preview else Color.SURFACE_0
        super().__init__(master, fg_color=bg_color, corner_radius=0)
        self.app = app
        self.is_preview = is_preview
        self.words = []
        self.editing_word = None
        self.edit_widgets = {}
        self.card_y_positions = {}
        self.card_bg_ids = {}
        self.card_highlight_ids = {}
        self._resize_timer = None
        
        self.selected_index = -1 
        
        self.canvas = tk.Canvas(self, bg=bg_color, highlightthickness=0)
        
        self.scrollbar_y = ctk.CTkScrollbar(self, width=12, command=self.canvas.yview, fg_color="transparent", button_color=Color.SURFACE_3, button_hover_color=Color.GLASS_BORDER)
        self.canvas.configure(yscrollcommand=self.scrollbar_y.set)

        self.canvas.pack(side="left", fill="both", expand=True)
        
        if not self.is_preview:
            self.scrollbar_y.pack(side="right", fill="y", padx=(0, 2))
            
        self.canvas.bind("<Configure>", self._on_configure)

    def _z(self, val): return int(val * self.app.zoom_factor)

    def _on_configure(self, event):
        if self._resize_timer: self.after_cancel(self._resize_timer)
        self._resize_timer = self.after(150, self.render)

    def set_words(self, words, keep_selection=False):
        self.words = words
        self.editing_word = None
        if not keep_selection:
            self.selected_index = -1
        self.render()

    def render(self):
        self.canvas.delete("all")   
        for w in self.edit_widgets.values(): w.destroy()
        self.edit_widgets.clear()
        self.card_y_positions.clear()
        self.card_bg_ids.clear()
        self.card_highlight_ids.clear()
        
        visible_width = self.canvas.winfo_width()
        if visible_width < 100: return 
        
        render_width = visible_width

        if not self.words:
            if not self.is_preview:
                self._draw_empty_state(visible_width, self.canvas.winfo_height())
            return

        y_offset = self._z(15)
        painter = CardRenderer(self.app, self.canvas, self.edit_widgets)
        
        if self.is_preview:
            callbacks = {}
        else:
            callbacks = {
                'save': self.action_save, 'cancel': lambda w: self.app.cancel_edit(),
                'delete': self.action_delete, 'refresh': self.action_refresh,
                'edit': self.action_edit, 'fav': self.action_fav, 'toggle_tag': self._toggle_important
            }

        for idx, w_data in enumerate(self.words):
            self.card_y_positions[w_data['word']] = y_offset
            is_edit = (self.editing_word == w_data['word'])
            is_selected = (not self.is_preview) and (idx == self.selected_index)
            
            bg_id, hl_id, y_offset = painter.draw_card(y_offset, w_data, render_width, is_edit, is_selected, callbacks)
            y_offset += self._z(15) 
            self.card_bg_ids[w_data['word']] = bg_id
            self.card_highlight_ids[w_data['word']] = hl_id
            
        self.canvas.configure(scrollregion=(0, 0, render_width, max(self.canvas.winfo_height(), y_offset)))
        
        if self.is_preview:
            target_height = y_offset + self._z(5)
            if abs(self.canvas.winfo_reqheight() - target_height) > 2:
                self.canvas.configure(height=target_height)
                self.configure(height=target_height)

    def set_selected_index(self, new_idx):
        if not self.words or new_idx < 0 or new_idx >= len(self.words): return
        
        if self.selected_index != -1:
            old_word = self.words[self.selected_index]['word']
            old_hl_id = self.card_highlight_ids.get(old_word)
            if old_hl_id: self.canvas.itemconfig(old_hl_id, outline="", width=0)
            
        self.selected_index = new_idx
        new_word = self.words[self.selected_index]['word']
        new_hl_id = self.card_highlight_ids.get(new_word)
        if new_hl_id: self.canvas.itemconfig(new_hl_id, outline=Color.ACCENT, width=2)
        
        self.scroll_to_word(new_word)

    def _on_up_arrow(self, event):
        if not self.words: return
        if self.selected_index == -1:
            self.set_selected_index(len(self.words) - 1)
        else:
            self.set_selected_index(max(0, self.selected_index - 1))

    def _on_down_arrow(self, event):
        if not self.words: return
        if self.selected_index == -1:
            self.set_selected_index(0)
        else:
            self.set_selected_index(min(len(self.words) - 1, self.selected_index + 1))

    def _on_enter_key(self, event):
        if self.selected_index != -1 and not self.is_preview and not self.editing_word:
            word = self.words[self.selected_index]['word']
            self.action_edit(word)

    def _on_delete_key(self, event):
        if self.selected_index != -1 and not self.is_preview and not self.editing_word:
            word = self.words[self.selected_index]['word']
            self.action_delete(word)

    def _draw_empty_state(self, w, h):
        msg = "No words found. Enter a word above to get started."
        if self.app.notebook_page.search_entry.get().strip(): msg = "No words match your search."
        elif self.app.show_favorites_only: msg = "No favorites yet. Star some words!"
        self.canvas.create_text(w//2, max(150, h//3), text=msg, font=Font.base(self._z(12)), fill=Color.TEXT_MUTED, justify="center")

    def _toggle_important(self, word, field_key, item_val, current_important_str):
        imp_list = [s.strip() for s in current_important_str.split(',') if s.strip()]
        item_lower = item_val.lower()
        if item_lower in (imp.lower() for imp in imp_list):
            imp_list = [imp for imp in imp_list if imp.lower() != item_lower]
        else:
            imp_list.append(item_val)
            
        new_str = ", ".join(imp_list)
        update_single_field(word, f"important_{field_key}", new_str)
        for w in self.words:
            if w['word'] == word:
                w[f"important_{field_key}"] = new_str
                break
        self.render()

    def action_delete(self, word):
        dlg = StyledConfirmDialog(self.app, "Delete Word", f"Permanently delete '{word.capitalize()}'?", danger=True)
        self.wait_window(dlg)
        if dlg.result and delete_word(word): self.app.load_words()

    def action_refresh(self, word):
        raw_key = self.app.settings_page.api_key_entry.get().strip()
        api_key = self.app.api_key if raw_key == "••••••••" else raw_key
        if not api_key:
            StyledConfirmDialog(self.app, "Missing API Key", "Please enter your API Key in Settings first.", confirm_text="OK").wait_window()
            return
            
        self.app.notebook_page.status_label.configure(text=f"Refreshing '{word}'...", text_color=Color.ACCENT)
        threading.Thread(target=lambda: self._fetch_refresh(word, api_key), daemon=True).start()

    def _fetch_refresh(self, word, api_key):
        try:
            data, msg = _fetch_word_details(word, api_key, self.app.settings_page.get_current_provider_config())
            self.app.after(0, lambda: self._on_refresh_done(word, data, msg))
        except Exception as e:
            self.app.after(0, lambda: self._on_refresh_done(word, None, f"Crash: {str(e)}"))

    def _on_refresh_done(self, word, data, api_msg):
        if data:
            for field in ['meaning', 'bangla_meaning', 'english_definition', 'ipa', 'part_of_speech', 'example_sentence', 'synonyms', 'antonyms', 'exam_history']:
                if field in data: update_single_field(word, field, data[field])
            self.app.notebook_page.status_label.configure(text=f"Refreshed '{word}'!", text_color=Color.SUCCESS)
            self.app.load_words(scroll_to=word.lower(), flash=False)
        else:
            StyledConfirmDialog(self.app, "Refresh Failed", api_msg, confirm_text="OK", danger=True).wait_window()
            self.app.notebook_page.status_label.configure(text="", text_color=Color.TEXT_MUTED)

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
        if f"{word}_notes" in self.edit_widgets: updates['notes'] = self.edit_widgets.get(f"{word}_notes").get("1.0", "end-1c").strip()
            
        for field, new_value in updates.items(): update_single_field(word, field, new_value)
        self.editing_word = None
        self.app.load_words(scroll_to=word.lower(), flash=False)

    def action_fav(self, word):
        w_data = next((w for w in self.words if w['word'] == word), None)
        if not w_data: return
        is_fav = not bool(w_data.get('is_favorite', 0))
        update_single_field(word, 'is_favorite', 1 if is_fav else 0)
        
        if not is_fav and self.app.show_favorites_only: self.app.load_words()
        else:
            w_data['is_favorite'] = 1 if is_fav else 0
            self.render()

    def scroll_to_word(self, target_word, flash=False, update_index=False):
        target_lower = target_word.lower()
        
        if update_index:
            for idx, w in enumerate(self.words):
                if w['word'].lower() == target_lower:
                    self.set_selected_index(idx)
                    return 

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
                    def flash_cycle(step):
                        try:
                            self.canvas.itemconfig(bg_id, fill=Color.SURFACE_3 if step % 2 == 0 else orig_color)
                            if step < 3: self.after(300, lambda: flash_cycle(step + 1))
                        except Exception: pass 
                    flash_cycle(0)

# =======================================================================
# MODULE 6: PAGE LAYOUTS (Settings & Notebook Views)
# =======================================================================
class SettingsPage(ctk.CTkFrame):
    def __init__(self, master, app):
        super().__init__(master, fg_color=Color.SURFACE_0, corner_radius=0)
        self.app = app
        self.sliders = {}
        self.slider_labels = {}
        
        self.canvas = tk.Canvas(self, bg=Color.SURFACE_0, highlightthickness=0)
        self.scrollbar = ctk.CTkScrollbar(self, width=12, command=self.canvas.yview, 
                                          fg_color="transparent", button_color=Color.SURFACE_3, 
                                          button_hover_color=Color.GLASS_BORDER)
        self.canvas.configure(yscrollcommand=self.scrollbar.set)
        
        self.canvas.pack(side="left", fill="both", expand=True)
        
        self.content_frame = ctk.CTkFrame(self.canvas, fg_color="transparent")
        self.canvas_window = self.canvas.create_window((0, 0), window=self.content_frame, anchor="nw")
        
        self.content_frame.bind("<Configure>", self._on_content_configure)
        self.canvas.bind("<Configure>", self._on_canvas_configure)
        
        self.content_frame.grid_columnconfigure(0, weight=1)
        
        self.header_frame = ctk.CTkFrame(self.content_frame, fg_color="transparent")
        self.header_frame.grid(row=0, column=0, sticky="ew", padx=40, pady=(35, 10))
        ctk.CTkLabel(self.header_frame, text="Settings Dashboard", font=Font.base(24, "bold"), text_color=Color.TEXT_PRIMARY).pack(side="left")
        
        self.preview_wrapper = ctk.CTkFrame(self.content_frame, fg_color="transparent")
        self.preview_wrapper.grid(row=1, column=0, sticky="ew", padx=40, pady=(0, 30))
        
        ctk.CTkLabel(self.preview_wrapper, text="Live Layout Preview", font=Font.base(14, "bold"), text_color=Color.TEXT_MUTED).pack(anchor="w", pady=(0, 10))
        
        self.preview_stage = ctk.CTkFrame(self.preview_wrapper, fg_color=Color.SURFACE_1, corner_radius=12, border_width=1, border_color=Color.GLASS_BORDER)
        self.preview_stage.pack(fill="x", expand=False)
        
        self.preview_list = WordListView(self.preview_stage, self.app, is_preview=True)
        self.preview_list.pack(fill="x", expand=False, padx=40, pady=40) 
        
        sample_word = {
            'word': 'abject', 'ipa': 'ab-jekt', 'part_of_speech': 'adjective',
            'meaning': 'Extremely bad or hopeless',
            'bangla_meaning': 'অধম, শোচনীয়, হীন',
            'example_sentence': 'They live in abject poverty, struggling to afford even the most basic necessities.',
            'synonyms': 'miserable, wretched, hopeless',
            'antonyms': 'proud, commendable, exalted',
            'notes': 'Often used with abstract nouns like poverty or failure.',
            'is_favorite': 1
        }
        self.preview_list.set_words([sample_word])
        
        self.nav_frame = ctk.CTkFrame(self.content_frame, fg_color="transparent")
        self.nav_frame.grid(row=2, column=0, sticky="ew", padx=40, pady=(0, 15))
        
        self.tabs_container = ctk.CTkFrame(self.nav_frame, fg_color="transparent")
        self.tabs_container.pack(side="left")
        
        self.nav_buttons = {}
        self.btn_api = self._create_nav_btn(self.tabs_container, "API Settings", "api")
        self.btn_api.pack(side="left", padx=(0, 8))
        self.btn_space = self._create_nav_btn(self.tabs_container, "Spacing", "spacing")
        self.btn_space.pack(side="left", padx=(0, 8))
        self.btn_font = self._create_nav_btn(self.tabs_container, "Typography", "fonts")
        self.btn_font.pack(side="left")

        self.btn_reset = ctk.CTkButton(self.nav_frame, text="↺ Reset Defaults", font=Font.base(11, "bold"), fg_color=Color.SURFACE_3, hover_color=Color.GLASS_BORDER, text_color=Color.TEXT_PRIMARY, height=28, width=110, command=self.reset_layout_defaults)

        self.controls_container = ctk.CTkFrame(self.content_frame, fg_color=Color.SURFACE_1, corner_radius=12, border_width=1, border_color=Color.GLASS_BORDER)
        self.controls_container.grid(row=3, column=0, sticky="ew", padx=40, pady=(0, 40))
        self.controls_container.grid_rowconfigure(0, weight=1)
        self.controls_container.grid_columnconfigure(0, weight=1)
        
        self.frames = {}
        self.frames["api"] = self._build_api_tab(self.controls_container)
        self.frames["spacing"] = self._build_layout_tab(self.controls_container, self.app.spacings, -150, 150, "px", [
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
            frame.grid(row=0, column=0, sticky="nsew", padx=2, pady=2)

        self.switch_tab("api")

    def _on_content_configure(self, event=None):
        self.canvas.configure(scrollregion=self.canvas.bbox("all"))
        self._check_scrollbar()

    def _on_canvas_configure(self, event=None):
        self.canvas.itemconfig(self.canvas_window, width=event.width)
        self._check_scrollbar()

    def _check_scrollbar(self):
        if self.content_frame.winfo_reqheight() > self.canvas.winfo_height():
            self.scrollbar.pack(side="right", fill="y", padx=(0, 2))
        else:
            self.scrollbar.pack_forget()

    def reset_layout_defaults(self):
        for k, default_val in self.app.DEFAULT_SPACINGS.items():
            self.app.spacings[k] = default_val
            save_setting(k, str(default_val))
            if k in self.sliders:
                self.sliders[k].set(default_val)
                self.slider_labels[k].configure(text=f"{int(default_val)} px")
                
        for k, default_val in self.app.DEFAULT_FONTS.items():
            self.app.font_sizes[k] = default_val
            save_setting(k, str(default_val))
            if k in self.sliders:
                self.sliders[k].set(default_val)
                self.slider_labels[k].configure(text=f"{int(default_val)} pt")
                
        orig_color = self.btn_reset.cget("fg_color")
        orig_text_color = self.btn_reset.cget("text_color")
        self.btn_reset.configure(text="Restored!", fg_color=Color.SUCCESS, text_color="#000000")
        self.after(1500, lambda: self.btn_reset.configure(text="↺ Reset Defaults", fg_color=orig_color, text_color=orig_text_color))

        self.preview_list.render()
        if hasattr(self.app, 'notebook_page') and self.app.notebook_page.winfo_ismapped():
            self.app.notebook_page.word_list_frame.render()

    def _create_nav_btn(self, parent, text, tab_id):
        btn = ctk.CTkButton(parent, text=text, font=Font.base(13, "bold"), fg_color="transparent", hover_color=Color.SURFACE_2, text_color=Color.TEXT_SECONDARY, corner_radius=6, height=32, command=lambda: self.switch_tab(tab_id))
        self.nav_buttons[tab_id] = btn
        return btn

    def switch_tab(self, tab_id):
        for t_id, btn in self.nav_buttons.items():
            is_active = (t_id == tab_id)
            btn.configure(fg_color=Color.SURFACE_3 if is_active else "transparent", text_color=Color.TEXT_PRIMARY if is_active else Color.TEXT_SECONDARY)
        
        self.frames[tab_id].tkraise()

        if tab_id == "api":
            self.preview_wrapper.grid_remove()
            self.btn_reset.pack_forget()
        else:
            self.preview_wrapper.grid(row=1, column=0, sticky="ew", padx=40, pady=(0, 30))
            self.btn_reset.pack(side="right")
            self.after(60, lambda: self.preview_list.render())
            
        self.after(100, self._check_scrollbar)

    def _build_api_tab(self, parent):
        frame = ctk.CTkFrame(parent, fg_color=Color.SURFACE_1, corner_radius=10)
        
        grid_container = ctk.CTkFrame(frame, fg_color="transparent")
        grid_container.pack(fill="x", padx=30, pady=30)
        grid_container.grid_columnconfigure(0, weight=1, uniform="col")
        grid_container.grid_columnconfigure(1, weight=1, uniform="col")
        
        p1 = ctk.CTkFrame(grid_container, fg_color="transparent")
        p1.grid(row=0, column=0, sticky="ew", padx=(0, 15), pady=(0, 25))
        ctk.CTkLabel(p1, text="Select AI Platform", font=Font.base(12, "bold"), text_color=Color.TEXT_MUTED).pack(anchor="w", pady=(0, 8))
        self.provider_var = tk.StringVar(value=get_setting("api_provider_name") or "Google AI Studio")
        provider_menu = ctk.CTkOptionMenu(p1, variable=self.provider_var, values=list(self.app.API_PRESETS.keys()), 
                                          fg_color=Color.SURFACE_2, button_color=Color.SURFACE_2, button_hover_color=Color.SURFACE_3, 
                                          font=Font.base(13), height=32, command=self._on_provider_change)
        provider_menu.pack(fill="x")

        p2 = ctk.CTkFrame(grid_container, fg_color="transparent")
        p2.grid(row=0, column=1, sticky="ew", padx=(15, 0), pady=(0, 25))
        ctk.CTkLabel(p2, text="Base URL", font=Font.base(12, "bold"), text_color=Color.TEXT_MUTED).pack(anchor="w", pady=(0, 8))
        self.url_entry = ctk.CTkEntry(p2, font=Font.base(13), height=32, fg_color=Color.SURFACE_2, border_color=Color.GLASS_BORDER)
        self.app.apply_focus_ring(self.url_entry)
        self.url_entry.insert(0, get_setting("api_base_url") or self.app.API_PRESETS["Google AI Studio"]["url"])
        self.url_entry.pack(fill="x")

        p3 = ctk.CTkFrame(grid_container, fg_color="transparent")
        p3.grid(row=1, column=0, sticky="ew", padx=(0, 15), pady=(0, 20))
        ctk.CTkLabel(p3, text="Model Name", font=Font.base(12, "bold"), text_color=Color.TEXT_MUTED).pack(anchor="w", pady=(0, 8))
        self.model_entry = ctk.CTkEntry(p3, font=Font.base(13), height=32, fg_color=Color.SURFACE_2, border_color=Color.GLASS_BORDER)
        self.app.apply_focus_ring(self.model_entry)
        self.model_entry.insert(0, get_setting("api_model") or self.app.API_PRESETS["Google AI Studio"]["model"])
        self.model_entry.pack(fill="x")
        
        p4 = ctk.CTkFrame(grid_container, fg_color="transparent")
        p4.grid(row=1, column=1, sticky="ew", padx=(15, 0), pady=(0, 20))
        ctk.CTkLabel(p4, text="API Key", font=Font.base(12, "bold"), text_color=Color.TEXT_MUTED).pack(anchor="w", pady=(0, 8))
        self.api_key_entry = ctk.CTkEntry(p4, font=Font.base(13), height=32, fg_color=Color.SURFACE_2, border_color=Color.GLASS_BORDER)
        self.app.apply_focus_ring(self.api_key_entry)
        saved_key = get_setting("gemini_api_key")
        if saved_key: 
            self.api_key_entry.insert(0, saved_key)
            self.api_key_entry.configure(show="•")
        self.api_key_entry.bind("<FocusIn>", lambda e: self.api_key_entry.configure(show=""))
        self.api_key_entry.bind("<FocusOut>", lambda e: self.api_key_entry.configure(show="•"))
        self.api_key_entry.pack(fill="x")

        btn_frame = ctk.CTkFrame(frame, fg_color="transparent")
        btn_frame.pack(fill="x", padx=30, pady=(0, 30))
        
        ctk.CTkButton(btn_frame, text="Save Config", width=140, height=36, fg_color=Color.ACCENT, hover_color=Color.ACCENT_HOVER, text_color="#000000", font=Font.base(13, "bold"), command=self.save_api_settings).pack(side="left", padx=(0, 15))
        self.test_btn = ctk.CTkButton(btn_frame, text="Test Connection", width=150, height=36, fg_color=Color.SURFACE_3, hover_color=Color.GLASS_BORDER, text_color=Color.TEXT_PRIMARY, font=Font.base(13), command=self.run_api_test)
        self.test_btn.pack(side="left")
        
        self.settings_status = ctk.CTkLabel(btn_frame, text="", font=Font.base(13), text_color=Color.TEXT_MUTED)
        self.settings_status.pack(side="left", padx=20)
        
        return frame

    def _build_layout_tab(self, parent, data_dict, min_val, max_val, unit, sliders_conf):
        frame = ctk.CTkFrame(parent, fg_color=Color.SURFACE_1, corner_radius=10)
        
        grid_container = ctk.CTkFrame(frame, fg_color="transparent")
        grid_container.pack(fill="x", padx=30, pady=30)
        grid_container.grid_columnconfigure(0, weight=1, uniform="col")
        grid_container.grid_columnconfigure(1, weight=1, uniform="col")
        
        timers = {}
        row_idx = 0
        col_idx = 0
        
        for label_text, key in sliders_conf:
            slider_wrapper = ctk.CTkFrame(grid_container, fg_color=Color.SURFACE_2, corner_radius=8)
            pad_x = (0, 15) if col_idx == 0 else (15, 0)
            slider_wrapper.grid(row=row_idx, column=col_idx, sticky="ew", padx=pad_x, pady=(0, 15))
            
            header = ctk.CTkFrame(slider_wrapper, fg_color="transparent")
            header.pack(fill="x", padx=15, pady=(12, 0))
            ctk.CTkLabel(header, text=label_text, font=Font.base(12, "bold"), text_color=Color.TEXT_PRIMARY).pack(side="left")
            val_label = ctk.CTkLabel(header, text=f"{int(data_dict[key])} {unit}", font=Font.base(12, "bold"), text_color=Color.ACCENT)
            val_label.pack(side="right")
            
            self.slider_labels[key] = val_label

            def on_slide(val, k=key, vl=val_label, d_dict=data_dict, suffix=unit):
                int_val = int(val)
                vl.configure(text=f"{int_val} {suffix}")
                d_dict[k] = int_val
                
                if k in timers: self.after_cancel(timers[k])
                def apply_change():
                    save_setting(k, str(int_val))
                    self.preview_list.render()
                    if hasattr(self.app, 'notebook_page') and self.app.notebook_page.winfo_ismapped():
                        self.app.notebook_page.word_list_frame.render()
                timers[k] = self.after(30, apply_change)

            slider = ctk.CTkSlider(slider_wrapper, from_=min_val, to=max_val, command=on_slide, button_color=Color.ACCENT, button_hover_color=Color.ACCENT_HOVER)
            slider.set(data_dict[key])
            slider.pack(fill="x", padx=15, pady=(8, 16))
            
            self.sliders[key] = slider
            
            col_idx += 1
            if col_idx > 1:
                col_idx = 0
                row_idx += 1
                
        return frame

    def _on_provider_change(self, choice):
        preset = self.app.API_PRESETS.get(choice)
        if preset:
            self.url_entry.delete(0, 'end'); self.url_entry.insert(0, preset["url"])
            self.model_entry.delete(0, 'end'); self.model_entry.insert(0, preset["model"])

    def get_current_provider_config(self):
        return {"type": self.app.API_PRESETS.get(self.provider_var.get(), {}).get("type", "openai_compatible"), "base_url": self.url_entry.get().strip(), "model": self.model_entry.get().strip()}

    def save_api_settings(self):
        save_setting("api_provider_name", self.provider_var.get())
        save_setting("api_model", self.model_entry.get().strip())
        save_setting("api_base_url", self.url_entry.get().strip())
        save_setting("gemini_api_key", self.api_key_entry.get().strip())
        self.app.api_key = self.api_key_entry.get().strip()
        self.settings_status.configure(text="Saved securely!", text_color=Color.SUCCESS)

    def run_api_test(self):
        self.settings_status.configure(text="Testing...", text_color=Color.ACCENT)
        self.test_btn.configure(state="disabled")
        config = self.get_current_provider_config()
        api_key_to_test = self.api_key_entry.get().strip()
        
        def bg_task():
            success, msg = _test_gemini_connection(api_key_to_test, config)
            self.after(0, lambda: self.settings_status.configure(text=msg, text_color=Color.SUCCESS if success else Color.DANGER))
            self.after(0, lambda: self.test_btn.configure(state="normal"))
            
        threading.Thread(target=bg_task, daemon=True).start()


class NotebookPage(ctk.CTkFrame):
    def __init__(self, master, app):
        super().__init__(master, fg_color=Color.SURFACE_0, corner_radius=0)
        self.app = app
        
        self.header_container = tk.Frame(self, bg=Color.SURFACE_0)
        self.header_container.pack(fill="x", padx=40, pady=(35, 10))

        row1 = tk.Frame(self.header_container, bg=Color.SURFACE_0)
        row1.pack(fill="x", pady=(0, 20))
        self.header_title = ctk.CTkLabel(row1, text="My Notebook", font=Font.base(24, "bold"), text_color=Color.TEXT_PRIMARY)
        self.header_title.pack(side="left")

        row2 = tk.Frame(self.header_container, bg=Color.SURFACE_0)
        row2.pack(fill="x")

        left_group = ctk.CTkFrame(row2, fg_color="transparent")
        left_group.pack(side="left")

        self.add_word_entry = ctk.CTkEntry(left_group, placeholder_text="Enter word to add...", width=260, height=36, font=Font.base(13), fg_color=Color.SURFACE_1, border_width=1, border_color=Color.GLASS_BORDER)
        self.app.apply_focus_ring(self.add_word_entry)
        self.add_word_entry.pack(side="left", padx=(0, 10))
        self.add_word_entry.bind("<Return>", lambda e: self.app.add_new_word())
        
        ctk.CTkButton(left_group, text="+ Add Word", width=110, height=36, fg_color=Color.ACCENT, hover_color=Color.ACCENT_HOVER, text_color="#000000", font=Font.base(13, "bold"), command=self.app.add_new_word).pack(side="left")

        spacer = tk.Frame(row2, bg=Color.SURFACE_0)
        spacer.pack(side="left", fill="x", expand=True, padx=10)

        search_group = ctk.CTkFrame(row2, fg_color=Color.SURFACE_1, corner_radius=12, border_width=1, border_color=Color.GLASS_BORDER)
        search_group.pack(side="left")

        self.search_entry = ctk.CTkEntry(search_group, placeholder_text="Search notebook...", width=160, height=36, font=Font.base(13), fg_color=Color.SURFACE_1, border_width=1, border_color=Color.SURFACE_1)
        self.search_entry.pack(side="left", padx=(15, 5), pady=2)
        self.search_entry.bind("<FocusIn>", lambda e: self.search_entry.configure(border_color=Color.ACCENT_HOVER))
        self.search_entry.bind("<FocusOut>", lambda e: self.search_entry.configure(border_color=Color.SURFACE_1))
        
        self._search_timer = None
        def on_search_type(e):
            if self._search_timer: self.after_cancel(self._search_timer)
            self._search_timer = self.after(300, self.app.load_words)
        self.search_entry.bind("<KeyRelease>", on_search_type)
        
        self.search_all_var = tk.BooleanVar(value=True)
        ctk.CTkCheckBox(search_group, text="Search all volumes", variable=self.search_all_var, font=Font.base(11), text_color=Color.TEXT_MUTED, fg_color=Color.ACCENT, hover_color=Color.ACCENT_HOVER, border_color=Color.GLASS_BORDER, command=lambda: self.app.load_words(), checkbox_width=18, checkbox_height=18).pack(side="left", padx=10)

        spacer2 = tk.Frame(row2, bg=Color.SURFACE_0, width=15)
        spacer2.pack(side="left")

        zoom_group = ctk.CTkFrame(row2, fg_color=Color.SURFACE_1, corner_radius=12, border_width=1, border_color=Color.GLASS_BORDER)
        zoom_group.pack(side="left")

        ctk.CTkLabel(zoom_group, text="SCALE", font=Font.base(10, "bold"), text_color=Color.TEXT_MUTED).pack(side="left", padx=(15, 5))
        self.zoom_slider = ctk.CTkSlider(zoom_group, from_=0.7, to=1.5, width=90, command=self.on_zoom_changed, button_color=Color.ACCENT, button_hover_color=Color.ACCENT_HOVER)
        self.zoom_slider.set(self.app.zoom_factor)
        self.zoom_slider.pack(side="left", padx=(0, 8), pady=11)
        self.zoom_slider.bind("<ButtonRelease-1>", lambda e: save_setting("zoom_factor", str(self.app.zoom_factor)))

        self.zoom_label = ctk.CTkLabel(zoom_group, text=f"{int(self.app.zoom_factor * 100)}%", font=Font.base(11, "bold"), text_color=Color.TEXT_SECONDARY)
        self.zoom_label.pack(side="left", padx=(0, 15))

        self.status_label = ctk.CTkLabel(self, text="", font=Font.base(12), text_color=Color.TEXT_MUTED, height=20)
        self.status_label.pack(anchor="w", padx=40, pady=(0, 6))

        self.word_list_frame = WordListView(self, self.app)
        self.word_list_frame.pack(side="top", fill="both", expand=True, padx=40, pady=(0, 10))

    def on_zoom_changed(self, value):
        self.app.zoom_factor = value
        self.zoom_label.configure(text=f"{int(value * 100)}%")
        self.word_list_frame.render()

# =======================================================================
# MODULE 7: MAIN APPLICATION CLASS
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
        init_db()
        
        self.api_key = get_setting("gemini_api_key")
        try:
            val = get_setting("zoom_factor")
            saved_zoom = float(val) if val is not None else 0.85
            self.zoom_factor = max(0.7, saved_zoom)
        except ValueError: self.zoom_factor = 0.85

        self.DEFAULT_SPACINGS = {
            'title_gap': 47, 'meaning_gap': 5, 'bangla_meaning_gap': -10, 
            'example_sentence_gap': -7, 'synonyms_gap': 11, 'antonyms_gap': 11,
            'notes_gap': 15, 'card_padding_bottom': 20
        }
        self.spacings = {k: float(get_setting(k) if get_setting(k) is not None else v) for k, v in self.DEFAULT_SPACINGS.items()}

        self.DEFAULT_FONTS = {
            'title_size': 18, 'meaning_size': 12, 'bangla_size': 12,
            'example_size': 12, 'synonyms_size': 12, 'antonyms_size': 12, 'notes_size': 12
        }
        self.font_sizes = {k: int(get_setting(k) if get_setting(k) is not None else v) for k, v in self.DEFAULT_FONTS.items()}
            
        self.current_volume_id = None
        self.show_favorites_only = False
        self.volume_buttons = []

        self.title("VocabNote")
        if os.path.exists(resource_path("vocab_icon.ico")): self.iconbitmap(resource_path("vocab_icon.ico"))
        self.geometry("1250x850")
        self.minsize(1050, 600)
        
        self.configure(fg_color=Color.SURFACE_0)
        self.grid_columnconfigure(1, weight=1)
        self.grid_rowconfigure(0, weight=1)

        self.setup_sidebar()
        
        self.notebook_page = NotebookPage(self, self)
        self.settings_page = SettingsPage(self, self)
        
        self.setup_shortcuts() 
        self.view_all_words()
        self.refresh_volumes_dashboard()

        self.bind_all("<MouseWheel>", self._global_mousewheel)
        self.bind_all("<Button-4>", self._global_mousewheel)
        self.bind_all("<Button-5>", self._global_mousewheel)

    def _global_mousewheel(self, event):
        x, y = self.winfo_pointerxy()
        widget = self.winfo_containing(x, y)
        if not widget: return

        if isinstance(widget, (tk.Text, ctk.CTkTextbox)):
            if str(widget.cget("state")) != "disabled":
                return
        elif isinstance(widget, (tk.Scrollbar, ctk.CTkScrollbar)):
            return
            
        widget_path = str(widget)
        if widget_path.startswith(str(self.settings_page)):
            if self.settings_page.scrollbar.winfo_ismapped():
                if event.num == 4 or event.delta > 0: self.settings_page.canvas.yview_scroll(-1, "units")
                elif event.num == 5 or event.delta < 0: self.settings_page.canvas.yview_scroll(1, "units")
        elif widget_path.startswith(str(self.notebook_page.word_list_frame)):
            if event.num == 4 or event.delta > 0: self.notebook_page.word_list_frame.canvas.yview_scroll(-1, "units")
            elif event.num == 5 or event.delta < 0: self.notebook_page.word_list_frame.canvas.yview_scroll(1, "units")
        elif widget_path.startswith(str(self.volumes_scroll)):
            if event.num == 4 or event.delta > 0: self.volumes_scroll._parent_canvas.yview_scroll(-1, "units")
            elif event.num == 5 or event.delta < 0: self.volumes_scroll._parent_canvas.yview_scroll(1, "units")

    def apply_focus_ring(self, widget):
        widget.bind("<FocusIn>", lambda e: widget.configure(border_color=Color.ACCENT))
        widget.bind("<FocusOut>", lambda e: widget.configure(border_color=Color.GLASS_BORDER))

    def _typing_in_progress(self):
        w = self.focus_get()
        if not w: return False
        if isinstance(w, (tk.Entry, tk.Text, ctk.CTkEntry, ctk.CTkTextbox)):
            if str(w.cget("state")) == "disabled":
                return False
            return True
        return False

    def setup_shortcuts(self):
        self.bind("<Control-f>", lambda e: self.notebook_page.search_entry.focus_set())
        self.bind("<Control-n>", lambda e: self.notebook_page.add_word_entry.focus_set())
        self.bind("<Escape>", lambda e: self.cancel_edit())
        
        self.bind("<Up>", lambda e: None if self._typing_in_progress() else self.notebook_page.word_list_frame._on_up_arrow(e))
        self.bind("<Down>", lambda e: None if self._typing_in_progress() else self.notebook_page.word_list_frame._on_down_arrow(e))
        self.bind("<Return>", lambda e: None if self._typing_in_progress() else self.notebook_page.word_list_frame._on_enter_key(e))
        self.bind("<Delete>", lambda e: None if self._typing_in_progress() else self.notebook_page.word_list_frame._on_delete_key(e))

    def cancel_edit(self):
        if self.notebook_page.word_list_frame.editing_word:
            self.notebook_page.word_list_frame.editing_word = None
            self.notebook_page.word_list_frame.render()

    def load_icon(self, filename, size=20):
        try:
            path = resource_path(f"assets/{filename}")
            if os.path.exists(path):
                img = Image.open(path)
                return ctk.CTkImage(light_image=img, dark_image=img, size=(size, size))
        except Exception:
            pass
        return None

    def setup_sidebar(self):
        PAD_SM = 8; PAD_MD = 16
        self.sidebar = ctk.CTkFrame(self, width=260, fg_color=Color.SURFACE_1, corner_radius=0)
        self.sidebar.grid(row=0, column=0, sticky="nsew")
        
        self.sidebar.grid_rowconfigure(5, weight=1)

        ctk.CTkLabel(self.sidebar, text="VocabNote", font=Font.base(26, "bold"), text_color=Color.LOGO_BLUE, anchor="center").grid(row=0, column=0, padx=PAD_MD, pady=(35, 20), sticky="ew")

        self.icon_notebook = self.load_icon("all_words.png", 18)
        self.icon_favorites = self.load_icon("favorites.png", 18)
        self.icon_settings = self.load_icon("settings.png", 18)
        self.icon_export = self.load_icon("export.png", 18)
        self.icon_import = self.load_icon("import.png", 18)

        self.btn_notebook = ctk.CTkButton(self.sidebar, text=" All Words", image=self.icon_notebook, border_width=1, border_color=Color.SURFACE_1, fg_color=Color.SURFACE_3, hover_color=Color.GLASS_BORDER, text_color=Color.TEXT_PRIMARY, font=Font.base(14, "bold"), anchor="w", command=self.view_all_words)
        self.btn_notebook.grid(row=1, column=0, padx=PAD_MD, pady=2, sticky="ew")

        self.btn_favorites = ctk.CTkButton(self.sidebar, text=" Favorites", image=self.icon_favorites, border_width=1, border_color=Color.SURFACE_1, fg_color="transparent", hover_color=Color.SURFACE_3, text_color=Color.TEXT_SECONDARY, font=Font.base(14, "bold"), anchor="w", command=self.view_favorites)
        self.btn_favorites.grid(row=2, column=0, padx=PAD_MD, pady=2, sticky="ew")

        nav_header = ctk.CTkFrame(self.sidebar, fg_color="transparent")
        nav_header.grid(row=3, column=0, padx=PAD_MD, pady=(30, 10), sticky="ew")
        ctk.CTkLabel(nav_header, text="VOLUMES", font=Font.base(11, "bold"), text_color=Color.TEXT_MUTED).pack(side="left")
        ctk.CTkButton(nav_header, text="+", width=24, height=24, fg_color="transparent", hover_color=Color.SURFACE_3, text_color=Color.ACCENT, command=self.add_volume_ui).pack(side="right")

        self.volumes_scroll = ctk.CTkScrollableFrame(self.sidebar, fg_color="transparent", width=230)
        self.volumes_scroll.grid(row=4, column=0, padx=(PAD_MD, PAD_SM), sticky="ew")

        spacer_row = ctk.CTkFrame(self.sidebar, fg_color="transparent")
        spacer_row.grid(row=5, column=0, sticky="nsew")

        self.btn_settings = ctk.CTkButton(self.sidebar, text=" Settings", image=self.icon_settings, fg_color="transparent", hover_color=Color.SURFACE_3, text_color=Color.TEXT_SECONDARY, font=Font.base(14), anchor="w", command=lambda: self.select_frame("settings"))
        self.btn_settings.grid(row=6, column=0, padx=PAD_MD, pady=(20, 5), sticky="ew")
        
        self.btn_export = ctk.CTkButton(self.sidebar, text=" Export as DOCX", image=self.icon_export, fg_color="transparent", hover_color=Color.SURFACE_3, text_color=Color.TEXT_SECONDARY, font=Font.base(14), anchor="w", command=self.export_docx)
        self.btn_export.grid(row=7, column=0, padx=PAD_MD, pady=5, sticky="ew")
        
        self.btn_import = ctk.CTkButton(self.sidebar, text=" Import from DOCX", image=self.icon_import, fg_color="transparent", hover_color=Color.SURFACE_3, text_color=Color.TEXT_SECONDARY, font=Font.base(14), anchor="w", command=self.import_docx)
        self.btn_import.grid(row=8, column=0, padx=PAD_MD, pady=(5, 30), sticky="ew")

    def flash_action_button(self, btn):
        orig_fg = btn.cget("fg_color"); orig_text = btn.cget("text_color")
        btn.configure(fg_color=Color.ACCENT, text_color="#000000")
        self.after(300, lambda: btn.configure(fg_color=orig_fg, text_color=orig_text))

    def refresh_volumes_dashboard(self):
        vols = get_all_volumes()
        for child in self.volumes_scroll.winfo_children(): child.destroy()
        self.volume_buttons.clear()
        
        if self.current_volume_id is None or not any(v['id'] == self.current_volume_id for v in vols):
            self.current_volume_id = vols[0]['id'] if vols else None
            
        if not vols:
            self.volumes_scroll.configure(height=40)
            empty_lbl = ctk.CTkLabel(self.volumes_scroll, text="No volumes yet", text_color=Color.TEXT_MUTED, font=Font.base(12, "italic"))
            empty_lbl.pack(pady=10)
            return

        req_height = min(350, len(vols) * 40)
        self.volumes_scroll.configure(height=max(40, req_height))

        for v in vols:
            is_active = (v['id'] == self.current_volume_id and not self.show_favorites_only and self.notebook_page.winfo_ismapped())
            bg_color = Color.SURFACE_3 if is_active else "transparent"
            text_color = Color.ACCENT if is_active else Color.TEXT_SECONDARY
            
            vol_frame = ctk.CTkFrame(self.volumes_scroll, fg_color=bg_color, border_width=1, border_color=Color.GLASS_BORDER if is_active else Color.SURFACE_1, corner_radius=6)
            vol_frame.pack(fill="x", padx=10, pady=2)
            
            btn = ctk.CTkButton(vol_frame, text=f"{v['name']} ({v['word_count']})", fg_color="transparent", hover_color=Color.SURFACE_3, text_color=text_color, font=Font.base(13, "bold" if is_active else "normal"), anchor="w", command=lambda vid=v['id']: self.on_volume_selected(vid))
            btn.pack(side="left", expand=True, fill="x")
            btn.bind("<Button-3>", lambda e, v_id=v['id']: self.on_volume_rclick(e, v_id)) 
            
            opts = ctk.CTkButton(vol_frame, text="⋮", width=24, fg_color="transparent", hover_color=Color.GLASS_BORDER, text_color=Color.TEXT_MUTED, font=Font.base(14, "bold"), command=lambda vid=v['id']: self.on_volume_rclick_inline(vid))
            opts.pack(side="right", padx=2)
            
            self.volume_buttons.append(btn)

    def on_volume_rclick_inline(self, vid):
        menu = tk.Menu(self, tearoff=0, bg=Color.SURFACE_1, fg=Color.TEXT_PRIMARY, activebackground=Color.SURFACE_3, activeforeground=Color.TEXT_PRIMARY, borderwidth=1, relief="solid", font=Font.base(11))
        menu.add_command(label="Rename Volume", command=lambda: self.rename_volume_ui(vid))
        menu.add_command(label="Delete Volume", command=lambda: self.delete_volume_ui(vid))
        
        x, y = self.winfo_pointerxy()
        try: menu.tk_popup(x, y)
        finally: menu.grab_release()

    def on_volume_rclick(self, event, vid):
        menu = tk.Menu(self, tearoff=0, bg=Color.SURFACE_1, fg=Color.TEXT_PRIMARY, activebackground=Color.SURFACE_3, activeforeground=Color.TEXT_PRIMARY, borderwidth=1, relief="solid", font=Font.base(11))
        menu.add_command(label="Rename Volume", command=lambda: self.rename_volume_ui(vid))
        menu.add_command(label="Delete Volume", command=lambda: self.delete_volume_ui(vid))
        try: menu.tk_popup(event.x_root, event.y_root)
        finally: menu.grab_release()

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
            if delete_volume(target_vid)[0]:
                if self.current_volume_id == target_vid: self.current_volume_id = None
                self.refresh_volumes_dashboard()
                self.load_words()

    def load_words(self, scroll_to=None, flash=False):
        if self.show_favorites_only: self.notebook_page.header_title.configure(text="Favorites")
        elif self.current_volume_id:
            v_name = next((v['name'] for v in get_all_volumes() if v['id'] == self.current_volume_id), "Volume")
            self.notebook_page.header_title.configure(text=v_name)
        else: self.notebook_page.header_title.configure(text="All Words")

        words = get_all_words_dictionaries(
            search_query=self.notebook_page.search_entry.get().strip(), 
            sort_order="ASC", 
            volume_id=self.current_volume_id if not self.show_favorites_only else None, 
            search_all=self.notebook_page.search_all_var.get(),
            favorites_only=self.show_favorites_only
        )
        self.notebook_page.word_list_frame.set_words(words)
        if scroll_to: self.after(50, lambda: self.notebook_page.word_list_frame.scroll_to_word(scroll_to, flash=flash, update_index=True))
        else:
            try: self.notebook_page.word_list_frame.canvas.yview_moveto(0)
            except Exception: pass

    def add_new_word(self):
        word = self.notebook_page.add_word_entry.get().strip()
        if not word: return

        if check_word_exists(word):
            dialog = DuplicateDialog(self, word)
            self.wait_window(dialog)
            if dialog.result == "cancel": return
            elif dialog.result == "open":
                self.notebook_page.search_entry.delete(0, 'end')
                self.notebook_page.search_all_var.set(True) 
                self.load_words(scroll_to=word.lower(), flash=True)
                self.notebook_page.add_word_entry.delete(0, 'end')
                return

        raw_key = self.settings_page.api_key_entry.get().strip()
        api_key_use = self.api_key if raw_key == "••••••••" else raw_key
        if not api_key_use:
            StyledConfirmDialog(self, "Missing API Key", "Please add your API Key in Settings first.", confirm_text="OK").wait_window()
            return

        self.notebook_page.status_label.configure(text=f"Enriching '{word}' via AI...", text_color=Color.ACCENT)
        self.update_idletasks()
        
        threading.Thread(target=lambda: self._fetch_add(word, api_key_use), daemon=True).start()

    def _fetch_add(self, word, api_key_use):
        try:
            data, msg = _fetch_word_details(word, api_key_use, self.settings_page.get_current_provider_config())
            self.after(0, lambda: self._on_add_fetched(word, data, msg))
        except Exception as e:
            self.after(0, lambda: self._on_add_fetched(word, None, f"Network failed: {str(e)}"))

    def _on_add_fetched(self, word, data, api_msg):
        if data:
            if check_word_exists(word): 
                for f in ['meaning', 'bangla_meaning', 'english_definition', 'ipa', 'part_of_speech', 'example_sentence', 'synonyms', 'antonyms', 'exam_history']:
                    if f in data: update_single_field(word, f, data[f])
            else: save_word_to_db(word, data, current_vol_id=self.current_volume_id)
            
            self.notebook_page.status_label.configure(text=f"'{word}' processed!", text_color=Color.SUCCESS)
            self.notebook_page.add_word_entry.delete(0, 'end')
            self.refresh_volumes_dashboard() 
            self.load_words(scroll_to=word.lower(), flash=True)
            self.after(3000, lambda: self.notebook_page.status_label.configure(text=""))
        else:
            self.notebook_page.status_label.configure(text=api_msg, text_color=Color.DANGER)

    def select_frame(self, name):
        self.notebook_page.grid_forget()
        self.settings_page.grid_forget()
        
        all_w_act = (name == "notebook" and not self.show_favorites_only and not self.current_volume_id)
        fav_act = (name == "notebook" and self.show_favorites_only)
        set_act = (name == "settings")
        
        self.btn_notebook.configure(fg_color=Color.SURFACE_3 if all_w_act else "transparent", text_color=Color.ACCENT if all_w_act else Color.TEXT_SECONDARY, border_color=Color.GLASS_BORDER if all_w_act else Color.SURFACE_1)
        self.btn_favorites.configure(fg_color=Color.SURFACE_3 if fav_act else "transparent", text_color=Color.ACCENT if fav_act else Color.TEXT_SECONDARY, border_color=Color.GLASS_BORDER if fav_act else Color.SURFACE_1)
        self.btn_settings.configure(fg_color=Color.SURFACE_3 if set_act else "transparent", text_color=Color.ACCENT if set_act else Color.TEXT_SECONDARY)
        
        if name == "notebook":
            self.notebook_page.grid(row=0, column=1, sticky="nsew")
            self.load_words()
        else:
            self.settings_page.grid(row=0, column=1, sticky="nsew")
        self.refresh_volumes_dashboard()

    def import_docx(self):
        self.flash_action_button(self.btn_import)
        file_path = filedialog.askopenfilename(filetypes=[("Word Document", "*.docx")])
        if not file_path: return
        success, result = import_from_docx(file_path)
        if not success or not result:
            StyledConfirmDialog(self, "Import Error", result if not success else "No words found.", confirm_text="OK", danger=not success).wait_window()
            return
            
        repl_all, skip_all, imp_c, skp_c, fail_c = False, False, 0, 0, 0
        for w_data in result:
            word = w_data['word']
            if check_word_exists(word):
                if not repl_all and not skip_all:
                    dlg = ImportDuplicateDialog(self, word)
                    self.wait_window(dlg)
                    if dlg.result == "cancel": break
                    elif dlg.result == "replace_all": repl_all = True
                    elif dlg.result == "skip_all": skip_all = True
                    elif dlg.result == "replace":
                        self._force_replace_word(word, w_data); imp_c += 1
                        continue
                    elif dlg.result == "skip":
                        skp_c += 1; continue
                if repl_all: self._force_replace_word(word, w_data); imp_c += 1
                elif skip_all: skp_c += 1
            else:
                if save_word_to_db(word, w_data, self.current_volume_id)[0]: update_single_field(word, 'notes', w_data.get('notes', '')); imp_c += 1
                else: fail_c += 1
                    
        StyledConfirmDialog(self, "Import Summary", f"Imported: {imp_c}\nSkipped: {skp_c}\nFailed: {fail_c}", confirm_text="OK").wait_window()
        self.refresh_volumes_dashboard(); self.load_words()

    def _force_replace_word(self, word, data):
        for f in ['meaning', 'bangla_meaning', 'english_definition', 'ipa', 'part_of_speech', 'example_sentence', 'synonyms', 'antonyms', 'notes', 'exam_history']:
            if f in data: update_single_field(word, f, data[f])

    def export_docx(self):
        self.flash_action_button(self.btn_export)
        dlg = ExportSelectionDialog(self, self.current_volume_id, get_all_volumes())
        self.wait_window(dlg)
        if not dlg.result: return
            
        words = get_all_words_dictionaries(search_all=True, sort_order="ASC") if dlg.result['type'] == 'all' else get_all_words_dictionaries(volume_id=self.current_volume_id, sort_order="ASC")
        if not words:
            StyledConfirmDialog(self, "Export Failed", "No words found to export.", confirm_text="OK", danger=True).wait_window()
            return
            
        path = filedialog.asksaveasfilename(defaultextension=".docx", filetypes=[("Word Document", "*.docx")])
        if path:
            success, msg = export_to_docx(words, path)
            StyledConfirmDialog(self, "Success" if success else "Error", msg, confirm_text="OK", danger=not success).wait_window()

if __name__ == "__main__":
    app = VocabNoteApp()
    app.mainloop()