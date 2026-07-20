import os
import sys
import ctypes
import math
import threading
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

try:
    from PIL import ImageTk
    HAS_IMAGETK = True
except ImportError:
    HAS_IMAGETK = False


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
            self.tw.destroy()
            self.tw = None
        elif self.tw:
            self._fade_out(self.tw.attributes("-alpha"))
            
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
        self.grab_set()
        self.configure(fg_color=Color.CARD_BG)
        
        icon_path = resource_path("vocab_icon.ico")
        if os.path.exists(icon_path):
            self.after(200, lambda: self.iconbitmap(icon_path))


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
            text_color=Color.TEXT_PRIMARY, font=Font.base(13), corner_radius=6, height=36,
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
        
        btn_frame = ctk.CTkFrame(self, fg_color="transparent")
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
        self.result = "skip"
        
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
            text_color=Color.TEXT_PRIMARY, font=Font.base(13), corner_radius=6, height=36,
            border_width=1, border_color=Color.BORDER, command=lambda: self.set_result("skip")
        ).pack(side="left", padx=5, expand=True, fill="x")
                      
        ctk.CTkButton(
            btn_frame, text="Replace All", fg_color=Color.DANGER, hover_color=Color.DANGER, 
            text_color="#FFFFFF", font=Font.base(13, "bold"), corner_radius=6, height=36,
            command=lambda: self.set_result("replace_all")
        ).pack(side="left", padx=5, expand=True, fill="x")
                      
        ctk.CTkButton(
            btn_frame, text="Skip All", fg_color="transparent", hover_color=Color.HOVER_BG, 
            text_color=Color.TEXT_PRIMARY, font=Font.base(13), corner_radius=6, height=36,
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
        target_size = self._z(icon_size)
        
        # Uses global app cache. Zero disk reads or Lanczos resizing during standard renders.
        self.icon_edit = self.app.get_icon("edit", target_size)
        self.icon_edit_hover = self.app.get_icon("edit_hover", target_size)
        self.icon_refresh = self.app.get_icon("refresh", target_size)
        self.icon_refresh_hover = self.app.get_icon("refresh_hover", target_size)
        self.icon_delete = self.app.get_icon("delete", target_size)
        self.icon_delete_hover = self.app.get_icon("delete_hover", target_size)

    def _line_metrics(self, font_tuple):
        """Uses App-level font cache. Zero tkfont object instantiations after first draw."""
        if font_tuple not in self.app.font_metrics_cache:
            tkf = tkfont.Font(root=self.canvas, font=font_tuple)
            m = tkf.metrics()
            self.app.font_metrics_cache[font_tuple] = (m['ascent'], m['descent'], m['linespace'])
        return self.app.font_metrics_cache[font_tuple]

    def _text_width(self, text, font_tuple):
        """Uses App-level font object cache. Eliminates canvas draw/destroy ops for measuring tags."""
        if font_tuple not in self.app.font_obj_cache:
            self.app.font_obj_cache[font_tuple] = tkfont.Font(root=self.canvas, font=font_tuple)
        return self.app.font_obj_cache[font_tuple].measure(text)

    def _z(self, val):
        """Pure math mapping. Zero lag."""
        return int(val * self._z_factor)

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
        fs = max(4, self._z(font_val))

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
            
            # Optimized memory-only width mapping (Zero UI thread canvas allocations)
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

                self.canvas.tag_bind(ptag, "<Enter>", on_enter)
                self.canvas.tag_bind(ptag, "<Leave>", on_leave)
                self.canvas.tag_bind(ptag, "<Button-1>", on_click)
                
            curr_x += tw + self._z(4)

        return curr_y + row_h

    def _draw_prop_row(self, label, key, w_data, x1, curr_y, max_x, is_edit, custom_font="Segoe UI", is_tag_list=False, safe_word=None, callbacks=None):
        value = w_data.get(key, "") or ""
        if not is_edit and not value: 
            return curr_y 

        card_tag = f"card_{safe_word}"
        
        font_size_key = f"{key.replace('_meaning', '').replace('_sentence', '')}_size"
        scaled_font_size = max(4, self._z(self.app.font_sizes.get(font_size_key, 12)))
        label_font = Font.base(scaled_font_size, "bold")
        
        label_x = x1 + self._z(25)
        self.canvas.create_text(
            label_x, curr_y, text=label, font=label_font, 
            fill=Color.TEXT_SECONDARY, anchor="nw", tags=card_tag
        )

        val_x = x1 + self._z(160)
        val_w = max(100, max_x - val_x - self._z(25))
        user_gap = max(0, self._z(self.app.spacings.get(f"{key}_gap", 0)))
        
        if is_edit:
            if is_tag_list or key == 'notes':
                widget = ctk.CTkTextbox(
                    self.canvas, width=val_w, height=self._z(70), 
                    fg_color=Color.INPUT_BG, text_color=Color.TEXT_PRIMARY, 
                    font=Font.base(scaled_font_size), border_width=1, 
                    border_color=Color.BORDER, corner_radius=6
                )
                widget.insert("1.0", value)
                self.canvas.create_window(val_x, curr_y, anchor="nw", window=widget)
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
                widget.insert(0, value)
                self.canvas.create_window(val_x, curr_y, anchor="nw", window=widget)
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
                x_left + (hit_w//2), y_center, text=fallback_char, font=Font.base(max(4, self._z(22))), 
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

            self.canvas.tag_bind(action_tag, "<Button-1>", on_click)
            self.canvas.tag_bind(action_tag, "<Enter>", on_enter)
            self.canvas.tag_bind(action_tag, "<Leave>", on_leave)

        return x_left - self._z(4)

    def _draw_text_action(self, x_right, y_center, text, default_color, hover_color, command, word, safe_word):
        temp = self.canvas.create_text(0, -10000, text=text, font=Font.base(max(4, self._z(14)), "bold"))
        bbox = self.canvas.bbox(temp)
        self.canvas.delete(temp)
        tw = (bbox[2] - bbox[0]) if bbox else self._z(40)

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
            x_left + tw//2, y_center, text=text, font=Font.base(max(4, self._z(14)), "bold"), 
            fill="#FFFFFF" if default_color != Color.TEXT_SECONDARY else Color.TEXT_PRIMARY, 
            tags=(action_tag, card_tag, "clickable")
        )

        if command:
            self.canvas.tag_bind(action_tag, "<Button-1>", lambda e: command(word))
            self.canvas.tag_bind(action_tag, "<Enter>", lambda e: [self.canvas.itemconfig(bg_id, fill=hover_color), self.canvas.config(cursor="hand2")])
            self.canvas.tag_bind(action_tag, "<Leave>", lambda e: [self.canvas.itemconfig(bg_id, fill=default_color if default_color != Color.TEXT_SECONDARY else ""), self.canvas.config(cursor="")])

        return x_left - pad_x - self._z(8)

    def draw_card(self, y_start, w_data, width, is_edit, is_selected=False, callbacks=None):
        if callbacks is None:
            callbacks = {}
            
        word = w_data['word']
        safe_word = "".join(c if c.isalnum() else "_" for c in word)
        
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
            self.canvas.tag_bind(star_id, "<Button-1>", lambda e, w=word: callbacks['fav'](w))
            self.canvas.tag_bind(star_id, "<Enter>", lambda e: self.canvas.config(cursor="hand2"))
            self.canvas.tag_bind(star_id, "<Leave>", lambda e: self.canvas.config(cursor=""))

        title_size = max(4, self._z(self.app.font_sizes.get('title_size', 20)))
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
            ipa_font = Font.base(max(4, self._z(13)), "italic")
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
            pos_font = Font.base(max(4, self._z(12)), "bold")
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

        title_gap = max(0, self.app.spacings.get('title_gap', 44))
        curr_y = header_y_center + self._z(title_gap)
        
        props = [
            ("Meaning", 'meaning', "Segoe UI", False),
            ("Bangla", 'bangla_meaning', "Kalpurush", False),
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

        curr_y += self._z(max(0, self.app.spacings.get('card_padding_bottom', 8)))

        if curr_y < y_start + self._z(130):
            curr_y = y_start + self._z(130)

        self._update_round_rect(bg_id, x1, y_start, x2, curr_y, radius=corner_rad)
        self.list_view.card_bboxes[safe_word] = (x1, y_start, x2, curr_y)
        
        return bg_id, bg_id, curr_y


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
        self.card_y_positions = {}
        self.card_bg_ids = {}
        self.card_highlight_ids = {}
        self.card_action_ids = {}
        self._resize_timer = None
        
        self.selected_index = -1 
        self.card_bboxes = {}
        self._hover_timer = None
        self._current_hover = None
        
        self.canvas_bg = Color.CARD_BG if is_preview else Color.APP_BG
        self.canvas = tk.Canvas(self, bg=self.canvas_bg, highlightthickness=0)
        
        self.scrollbar_y = ctk.CTkScrollbar(
            self, width=12, command=self.canvas.yview, 
            fg_color="transparent", button_color=Color.BORDER, 
            button_hover_color=Color.TEXT_MUTED
        )
        self.canvas.configure(yscrollcommand=self.scrollbar_y.set)
        self.canvas.pack(side="left", fill="both", expand=True)
        
        if not self.is_preview:
            self.scrollbar_y.pack(side="right", fill="y", padx=(0, 4))
            
        self.canvas.bind("<Configure>", self._on_configure)
        self._poll_hovers()

    def _on_configure(self, event):
        if self._resize_timer: 
            self.after_cancel(self._resize_timer)
        self._resize_timer = self.after(150, self.render)
        
    def _poll_hovers(self):
        if not self.winfo_exists() or not self.canvas.winfo_exists() or self.is_preview:
            return
            
        if not self.canvas.winfo_viewable():
            self._hover_timer = self.after(100, self._poll_hovers)
            return
            
        px, py = self.winfo_pointerxy()
        cx = self.canvas.winfo_rootx()
        cy = self.canvas.winfo_rooty()
        cw = self.canvas.winfo_width()
        ch = self.canvas.winfo_height()
        
        if cx <= px <= cx + cw and cy <= py <= cy + ch:
            x = px - cx + self.canvas.canvasx(0)
            y = py - cy + self.canvas.canvasy(0)
            
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
        else:
            if self._current_hover:
                self._hide_card_actions(self._current_hover)
                self._current_hover = None
                
        self._hover_timer = self.after(100, self._poll_hovers)

    def _show_card_actions(self, safe_word):
        for item_id in self.card_action_ids.get(safe_word, []):
            if self.canvas.itemcget(item_id, "state") == "hidden":
                self.canvas.itemconfig(item_id, state="normal")

    def _hide_card_actions(self, safe_word):
        if safe_word == self.editing_word: return
        for item_id in self.card_action_ids.get(safe_word, []):
            if self.canvas.itemcget(item_id, "state") == "normal":
                self.canvas.itemconfig(item_id, state="hidden")

    def set_words(self, words, keep_selection=False):
        self.words = words
        self.editing_word = None
        if not keep_selection:
            self.selected_index = -1
        self.render()

    def render(self):
        self.canvas.delete("all")   
        
        for widget in self.edit_widgets.values(): 
            widget.destroy()
            
        self.edit_widgets.clear()
        self.card_y_positions.clear()
        self.card_bg_ids.clear()
        self.card_highlight_ids.clear()
        self.card_action_ids.clear()
        self.card_bboxes.clear()
        
        visible_width = self.canvas.winfo_width()
        if visible_width < 100: 
            return 
        
        render_width = visible_width

        if not self.words:
            if not self.is_preview:
                self._draw_empty_state(visible_width, self.canvas.winfo_height())
            return

        y_offset = int(10 * self.app.zoom_factor * self.preview_scale)
        
        # Determine global coordinate scaling strictly once per pass to skip OS queries entirely
        try:
            dpi_scale = ctk.ScalingTracker.get_window_dpi_scaling(self.app)
        except Exception:
            dpi_scale = 1.0
        z_factor = self.app.zoom_factor * dpi_scale * self.preview_scale
        
        painter = CardRenderer(self, self.app, self.canvas, self.edit_widgets, z_factor)
        
        if self.is_preview:
            callbacks = {}
        else:
            callbacks = {
                'save': self.action_save, 
                'cancel': lambda w: self.app.cancel_edit(),
                'delete': self.action_delete, 
                'refresh': self.action_refresh,
                'edit': self.action_edit, 
                'fav': self.action_fav, 
                'toggle_tag': self._toggle_important
            }

        for idx, w_data in enumerate(self.words):
            self.card_y_positions[w_data['word']] = y_offset
            is_edit = (self.editing_word == w_data['word'])
            is_selected = (not self.is_preview) and (idx == self.selected_index)
            
            bg_id, hl_id, y_offset = painter.draw_card(y_offset, w_data, render_width, is_edit, is_selected, callbacks)
            y_offset += int(25 * z_factor) 
            self.card_bg_ids[w_data['word']] = bg_id
            self.card_highlight_ids[w_data['word']] = hl_id
            
        self.canvas.configure(scrollregion=(0, 0, render_width, max(self.canvas.winfo_height(), y_offset)))

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
                
        self.render()

    def action_delete(self, word):
        dlg = StyledConfirmDialog(self.app, "Delete Word", f"Permanently delete '{word.capitalize()}'?", danger=True)
        self.wait_window(dlg)
        if dlg.result and delete_word(word): 
            self.app.load_words()

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
            for field in ['meaning', 'bangla_meaning', 'english_definition', 'ipa', 'part_of_speech', 'example_sentence', 'synonyms', 'antonyms']:
                if field in data: 
                    update_single_field(word, field, data[field])
            self.app.notebook_page.status_label.configure(text=f"Refreshed '{word}'!", text_color=Color.SUCCESS)
            self.app.load_words(scroll_to=word.lower(), flash=False)
        else:
            StyledConfirmDialog(self.app, "Refresh Failed", api_msg, confirm_text="OK", danger=True).wait_window()
            self.app.notebook_page.status_label.configure(text="", text_color=Color.TEXT_MUTED)

    def action_edit(self, word):
        self.editing_word = word
        self.render()

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
            self.render()

    def scroll_to_word(self, target_word, flash=False, update_index=False):
        target_lower = target_word.lower()
        
        if update_index:
            for idx, w in enumerate(self.words):
                if w['word'].lower() == target_lower:
                    self.set_selected_index(idx)
                    self.update_idletasks()
                    break 

        actual_key = None
        for k in self.card_y_positions.keys():
            if k.lower() == target_lower:
                actual_key = k
                break
                
        if actual_key:
            # We strictly calculate the unscaled Y offset using the local z-factor internally. 
            target_y = self.card_y_positions.get(actual_key, 0)
            sr = self.canvas.cget("scrollregion")
            if sr:
                try:
                    sr_tuple = tuple(map(float, sr.split()))
                    if len(sr_tuple) == 4 and sr_tuple[3] > 0:
                        fraction = max(0.0, (target_y - int(25 * self.app.zoom_factor)) / sr_tuple[3])
                        self.canvas.yview_moveto(fraction)
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
        self._db_timer = None
        
        self.current_tab = None
        
        # --- HEADER ---
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

        # --- MAIN SPLIT CONTAINER ---
        self.split_container = ctk.CTkFrame(self, fg_color="transparent")
        self.split_container.pack(fill="both", expand=True, padx=45, pady=(0, 45))
        
        self.split_container.grid_columnconfigure(0, weight=1) 
        self.split_container.grid_columnconfigure(1, weight=1)
        self.split_container.grid_rowconfigure(0, weight=1)
        
        # --- LEFT COLUMN (Controls & Tabs) ---
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
        
        self.frames["spacing"] = self._build_layout_tab(self.controls_container, self.app.spacings, 0, 100, "px", [
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

        # --- RIGHT COLUMN (Pinned Preview) ---
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

        for t_id, btn in self.nav_buttons.items():
            is_active = (t_id == tab_id)
            btn.configure(
                fg_color=Color.CARD_BG if is_active else "transparent", 
                text_color=Color.TEXT_PRIMARY if is_active else Color.TEXT_SECONDARY,
                border_width=1 if is_active else 0,
                border_color=Color.BORDER if is_active else Color.APP_BG
            )
        
        if tab_id == "api":
            self.right_col.grid_remove()
            self.left_col.grid(columnspan=2, padx=0)
        else:
            self.left_col.grid(columnspan=1, padx=(0, 20))
            self.right_col.grid()
            if self.preview_list._resize_timer:
                self.preview_list.after_cancel(self.preview_list._resize_timer)
                self.preview_list._resize_timer = None
            self.preview_list.render()

        if self.current_tab:
            self.frames[self.current_tab].place_forget()
            
        self.frames[tab_id].tkraise()
        self.frames[tab_id].place(relx=0, rely=0, relwidth=1, relheight=1)
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
        
        saved_key = get_setting("gemini_api_key")
        if saved_key: 
            self.api_key_entry.insert(0, saved_key)
            self.api_key_entry.configure(show="•")
            
        self.api_key_entry.bind("<FocusIn>", lambda e: self.api_key_entry.configure(show=""))
        self.api_key_entry.bind("<FocusOut>", lambda e: self.api_key_entry.configure(show="•"))
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
                
                # Global UI Render Debounce: Strictly 1 render per screen refresh (16ms)
                if self._preview_timer:
                    self.after_cancel(self._preview_timer)
                    
                def apply_ui_change():
                    self.preview_list.render()
                    self.app._needs_notebook_refresh = True
                    self._preview_timer = None
                    
                self._preview_timer = self.after(16, apply_ui_change)
                
                # Global DB Write Debounce: Decoupled entirely from UI thread dragging
                if self._db_timer:
                    self.after_cancel(self._db_timer)
                    
                def apply_db_change(key_to_save=k, val_to_save=int_val):
                    save_setting(key_to_save, str(val_to_save))
                    self._db_timer = None
                        
                self._db_timer = self.after(500, apply_db_change)

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


# =======================================================================
# NOTEBOOK PAGE
# =======================================================================
class NotebookPage(ctk.CTkFrame):
    def __init__(self, master, app):
        super().__init__(master, fg_color=Color.APP_BG, corner_radius=0)
        self.app = app
        
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
        self.zoom_slider.bind("<ButtonRelease-1>", lambda e: save_setting("zoom_factor", str(self.app.zoom_factor)))
        
        self.zoom_label = ctk.CTkLabel(toolbar, text=f"{int(self.app.zoom_factor * 100)}%", font=Font.base(12, "bold"), text_color=Color.TEXT_PRIMARY)
        self.zoom_label.grid(row=0, column=7, padx=(0, 15))

        self.status_label = ctk.CTkLabel(self, text="", font=Font.base(13), text_color=Color.TEXT_SECONDARY, height=20)
        self.status_label.pack(anchor="w", padx=45, pady=(0, 0))
        
        self.word_list_frame = WordListView(self, self.app)
        self.word_list_frame.pack(side="top", fill="both", expand=True, padx=45, pady=(0, 10))

    def on_zoom_changed(self, v): 
        self.app.zoom_factor = v
        self.zoom_label.configure(text=f"{int(v * 100)}%")
        self.word_list_frame.render()


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
        init_db()
        self.raw_icons = {}
        self.icon_cache = {}
        self.font_metrics_cache = {}
        self.font_obj_cache = {}
        self._load_raw_icons()
        self.api_key = get_setting("gemini_api_key")
        self.tooltip_manager = TooltipManager(self)
        
        self._needs_notebook_refresh = False
        
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
        self.bind("<Up>", lambda e: None if self._typing_in_progress() else self.notebook_page.word_list_frame._on_up_arrow(e))
        self.bind("<Down>", lambda e: None if self._typing_in_progress() else self.notebook_page.word_list_frame._on_down_arrow(e))
        self.bind("<Return>", lambda e: None if self._typing_in_progress() else self.notebook_page.word_list_frame._on_enter_key(e))
        self.bind("<Delete>", lambda e: None if self._typing_in_progress() else self.notebook_page.word_list_frame._on_delete_key(e))
        
        self.view_all_words()
        self.refresh_volumes_dashboard()
        
        for e in ["<MouseWheel>", "<Button-4>", "<Button-5>"]: 
            self.bind_all(e, self._global_mousewheel)

    def _load_raw_icons(self):
        if HAS_IMAGETK:
            for name in ["edit", "edit_hover", "refresh", "refresh_hover", "delete", "delete_hover"]:
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
            return self.icon_cache[cache_key]
            
        raw_img = self.raw_icons.get(name)
        if raw_img:
            try:
                resized = raw_img.resize((size, size), Image.Resampling.LANCZOS)
                photo = ImageTk.PhotoImage(resized)
                self.icon_cache[cache_key] = photo
                return photo
            except Exception:
                pass
        return None

    def _global_mousewheel(self, event):
        self.tooltip_manager.hide(immediate=True)
        widget = self.winfo_containing(*self.winfo_pointerxy())
        if not widget:
            return
            
        if isinstance(widget, (tk.Text, ctk.CTkTextbox)) and str(widget.cget("state")) != "disabled":
            return
            
        if isinstance(widget, (tk.Scrollbar, ctk.CTkScrollbar)): 
            return
            
        widget_path = str(widget)
        for prefix, canvas in [
            (str(self.notebook_page.word_list_frame), self.notebook_page.word_list_frame.canvas), 
            (str(self.volumes_scroll), self.volumes_scroll._parent_canvas)
        ]:
            if widget_path.startswith(prefix): 
                direction = -1 if (getattr(event, 'num', 0) == 4 or getattr(event, 'delta', 0) > 0) else 1
                canvas.yview_scroll(direction, "units")
                break

    def apply_focus_ring(self, widget): 
        widget.bind("<FocusIn>", lambda e: widget.configure(border_color=Color.ACCENT))
        widget.bind("<FocusOut>", lambda e: widget.configure(border_color=Color.BORDER))

    def _typing_in_progress(self): 
        w = self.focus_get()
        return bool(w and isinstance(w, (tk.Entry, tk.Text, ctk.CTkEntry, ctk.CTkTextbox)) and str(w.cget("state")) != "disabled")

    def cancel_edit(self):
        if self.notebook_page.word_list_frame.editing_word: 
            self.notebook_page.word_list_frame.editing_word = None
            self.notebook_page.word_list_frame.render()

    def load_icon(self, filename, size=20):
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
            for idx, v in enumerate(vols):
                is_active = (v['id'] == self.current_volume_id and not self.show_favorites_only and self.notebook_page.winfo_ismapped())
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
        
        if self.current_volume_id is None or not any(v['id'] == self.current_volume_id for v in vols): 
            self.current_volume_id = vols[0]['id'] if vols else None
            
        if not vols: 
            ctk.CTkLabel(self.volumes_scroll, text="No volumes yet", text_color=Color.TEXT_MUTED, font=Font.base(13, "italic")).pack(pady=10)
            return
            
        for v in vols:
            is_active = (v['id'] == self.current_volume_id and not self.show_favorites_only and self.notebook_page.winfo_ismapped())
            
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
                
        api_key_to_use = self.api_key if self.settings_page.api_key_entry.get().strip() == "••••••••" else self.settings_page.api_key_entry.get().strip()
        if not api_key_to_use: 
            StyledConfirmDialog(self, "Missing Key", "Please add API Key in Settings.", confirm_text="OK").wait_window()
            return
            
        self.notebook_page.status_label.configure(text=f"Enriching '{word}'...", text_color=Color.ACCENT)
        self.update_idletasks()
        
        threading.Thread(target=lambda: self._fetch_and_add(word, api_key_to_use), daemon=True).start()

    def _fetch_and_add(self, word, api_key):
        try: 
            data, msg = _fetch_word_details(word, api_key, self.settings_page.get_current_provider_config())
            self.after(0, lambda: self._on_add_complete(word, data, msg))
        except Exception as e: 
            self.after(0, lambda: self._on_add_complete(word, None, f"Network failed: {str(e)}"))

    def _on_add_complete(self, word, data, api_msg):
        if data:
            if check_word_exists(word): 
                for f in ['meaning', 'bangla_meaning', 'english_definition', 'ipa', 'part_of_speech', 'example_sentence', 'synonyms', 'antonyms']:
                    if f in data: 
                        update_single_field(word, f, data[field])
            else: 
                save_word_to_db(word, data, self.current_volume_id)
                
            self.notebook_page.status_label.configure(text=f"'{word}' processed!", text_color=Color.SUCCESS)
            self.notebook_page.add_word_entry.delete(0, 'end')
            self._last_volumes_state = None 
            self.refresh_volumes_dashboard()
            self.load_words(scroll_to=word.lower(), flash=True)
            self.after(3000, lambda: self.notebook_page.status_label.configure(text=""))
        else: 
            self.notebook_page.status_label.configure(text=api_msg, text_color=Color.DANGER)

    def select_frame(self, name):
        """Instantly maps frames and bypasses heavy DB queries."""
        is_all_words = (name == "notebook" and not self.show_favorites_only and not self.current_volume_id)
        is_favorites = (name == "notebook" and self.show_favorites_only)
        is_settings = (name == "settings")
        
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
        
        if name == "notebook": 
            self.set_sidebar_target(280)
            self.settings_page.grid_forget()
            self.notebook_page.grid(row=0, column=1, sticky="nsew")
            
            if getattr(self, '_needs_notebook_refresh', False):
                self.after(0, self.notebook_page.word_list_frame.render)
                self._needs_notebook_refresh = False
                
            self.refresh_volumes_dashboard()
        else: 
            self.set_sidebar_target(0)
            self.notebook_page.grid_forget()
            self.settings_page.grid(row=0, column=1, sticky="nsew")

    def import_docx(self):
        file_path = filedialog.askopenfilename(filetypes=[("Word Document", "*.docx")])
        if not file_path: return
        
        success, result = import_from_docx(file_path)
        if not success or not result: 
            StyledConfirmDialog(self, "Error", result if not success else "No words found.", confirm_text="OK", danger=not success).wait_window()
            return
            
        replace_all = False
        skip_all = False
        import_count = 0
        skip_count = 0
        fail_count = 0
        
        for w_data in result:
            word = w_data['word']
            if check_word_exists(word):
                if not replace_all and not skip_all:
                    dlg = ImportDuplicateDialog(self, word)
                    self.wait_window(dlg)
                    
                    if dlg.result == "cancel": 
                        break
                    elif dlg.result == "replace_all": 
                        replace_all = True
                    elif dlg.result == "skip_all": 
                        skip_all = True
                    elif dlg.result == "replace": 
                        self._force_replace(word, w_data)
                        import_count += 1
                        continue
                    elif dlg.result == "skip": 
                        skip_count += 1
                        continue
                        
                if replace_all: 
                    self._force_replace(word, w_data)
                    import_count += 1
                elif skip_all: 
                    skip_count += 1
            else:
                if save_word_to_db(word, w_data, self.current_volume_id)[0]: 
                    update_single_field(word, 'notes', w_data.get('notes', ''))
                    import_count += 1
                else: 
                    fail_count += 1
                    
        StyledConfirmDialog(self, "Summary", f"Imported: {import_count}\nSkipped: {skip_count}\nFailed: {fail_count}", confirm_text="OK").wait_window()
        self._last_volumes_state = None
        self.refresh_volumes_dashboard()
        self.load_words()

    def _force_replace(self, word, data):
        for field in ['meaning', 'bangla_meaning', 'english_definition', 'ipa', 'part_of_speech', 'example_sentence', 'synonyms', 'antonyms', 'notes']:
            if field in data: 
                update_single_field(word, field, data[field])

    def export_docx(self):
        dlg = ExportSelectionDialog(self, self.current_volume_id, get_all_volumes())
        self.wait_window(dlg)
        if not dlg.result: 
            return
        
        if dlg.result['type'] == 'all':
            words = get_all_words_dictionaries(search_all=True, sort_order="ASC")
        else:
            words = get_all_words_dictionaries(volume_id=self.current_volume_id, sort_order="ASC")
            
        if not words: 
            StyledConfirmDialog(self, "Failed", "No words found.", confirm_text="OK", danger=True).wait_window()
            return
            
        path = filedialog.asksaveasfilename(defaultextension=".docx", filetypes=[("Word Document", "*.docx")])
        if path: 
            success, msg = export_to_docx(words, path)
            StyledConfirmDialog(self, "Success" if success else "Error", msg, confirm_text="OK", danger=not success).wait_window()


if __name__ == "__main__":
    app = VocabNoteApp()
    app.mainloop()