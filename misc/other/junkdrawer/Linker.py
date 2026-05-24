import tkinter as tk
from tkinter import ttk, filedialog, messagebox
import os
import sys
from pathlib import Path
import webbrowser

class AnimationHelper:
    """Animation helper class inspired by InterfaceDesign.cs"""
    
    @staticmethod
    def fade_in(widget, duration=300, steps=20):
        """Fade in animation"""
        current = 0.0
        increment = 1.0 / steps
        delay = duration // steps
        
        def animate():
            nonlocal current
            if current < 1.0:
                current += increment
                try:
                    widget.attributes('-alpha', min(current, 1.0))
                except:
                    pass
                widget.after(delay, animate)
        
        animate()
    
    @staticmethod
    def fade_out(widget, duration=300, steps=20, callback=None):
        """Fade out animation"""
        current = 1.0
        decrement = 1.0 / steps
        delay = duration // steps
        
        def animate():
            nonlocal current
            if current > 0.0:
                current -= decrement
                try:
                    widget.attributes('-alpha', max(current, 0.0))
                except:
                    pass
                widget.after(delay, animate)
            elif callback:
                callback()
        
        animate()
    
    @staticmethod
    def slide_in(widget, from_y, to_y, duration=200, steps=15):
        """Slide animation"""
        current_y = from_y
        increment = (to_y - from_y) / steps
        delay = duration // steps
        
        def animate():
            nonlocal current_y
            if abs(current_y - to_y) > abs(increment):
                current_y += increment
                widget.place(y=int(current_y))
                widget.after(delay, animate)
            else:
                widget.place(y=to_y)
        
        animate()
    
    @staticmethod
    def color_transition(widget, from_color, to_color, duration=150, property='bg'):
        """Color transition animation"""
        # Simple color transition (can be enhanced)
        try:
            if property == 'bg':
                widget.config(bg=to_color)
            elif property == 'fg':
                widget.config(fg=to_color)
        except:
            pass


class MonacoEditor(tk.Frame):
    """Monaco Editor wrapper using embedded browser"""
    
    def __init__(self, parent, **kwargs):
        super().__init__(parent, **kwargs)
        self.config(bg='#262626')
        
        # For this implementation, we'll use a text widget styled like Monaco
        # In production, you'd use CEFPython or similar to embed the actual Monaco editor
        self.setup_editor()
        
    def setup_editor(self):
        """Setup Monaco-style editor"""
        # Line numbers frame
        self.line_frame = tk.Frame(self, bg='#1a1a1a', width=50)
        self.line_frame.pack(side=tk.LEFT, fill=tk.Y)
        
        self.line_numbers = tk.Text(
            self.line_frame,
            width=4,
            bg='#1a1a1a',
            fg='#7A7A7A',
            font=('JetBrains Mono', 13),
            bd=0,
            state=tk.DISABLED,
            cursor='arrow',
            selectbackground='#1a1a1a',
            selectforeground='#7A7A7A',
            highlightthickness=0
        )
        self.line_numbers.pack(fill=tk.BOTH, expand=True, padx=(10, 5), pady=(24, 0))
        
        # Editor frame
        editor_frame = tk.Frame(self, bg='#262626')
        editor_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        # Scrollbar
        scrollbar = tk.Scrollbar(editor_frame, bg='#1a1a1a', troughcolor='#262626')
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        # Main editor
        self.editor = tk.Text(
            editor_frame,
            bg='#262626',
            fg='#C3CCDB',
            insertbackground='#7AA2F7',
            font=('JetBrains Mono', 11),
            bd=0,
            wrap=tk.NONE,
            undo=True,
            maxundo=-1,
            selectbackground='#404040',
            selectforeground='#D5D5D5',
            insertwidth=3,
            highlightthickness=0,
            yscrollcommand=scrollbar.set
        )
        self.editor.pack(fill=tk.BOTH, expand=True, pady=(24, 0), padx=(10, 5))
        scrollbar.config(command=self.editor.yview)
        
        # Configure syntax highlighting tags
        self.configure_syntax_tags()
        
        # Initial content
        self.editor.insert('1.0', '''--[[ v1 ]]--''')
        
        # Bind events
        self.editor.bind('<KeyRelease>', self.on_text_change)
        self.editor.bind('<Button-1>', lambda e: self.update_line_numbers())
        self.editor.bind('<MouseWheel>', self.sync_scroll)
        
        self.update_line_numbers()
        self.apply_syntax_highlighting()
    
    def configure_syntax_tags(self):
        """Configure Monaco-style syntax highlighting"""
        # PDark theme colors
        self.editor.tag_config('keyword', foreground='#BB9AF7', font=('JetBrains Mono', 10, 'bold'))
        self.editor.tag_config('string', foreground='#9ECE6A')
        self.editor.tag_config('comment', foreground='#666666', font=('JetBrains Mono', 10, 'italic'))
        self.editor.tag_config('number', foreground='#FF9E64')
        self.editor.tag_config('function', foreground='#7AA2F7')
        self.editor.tag_config('builtin', foreground='#0DB9D7')
        self.editor.tag_config('operator', foreground='#89DDFF')
        self.editor.tag_config('variable', foreground='#E0AF68')
        self.editor.tag_config('property', foreground='#7DCFFF')
        self.editor.tag_config('self', foreground='#F7768E')
    
    def sync_scroll(self, event):
        """Sync scrolling between editor and line numbers"""
        self.line_numbers.yview_moveto(self.editor.yview()[0])
        return "break"
    
    def on_text_change(self, event=None):
        """Handle text changes"""
        self.update_line_numbers()
        self.apply_syntax_highlighting()
    
    def update_line_numbers(self):
        """Update line numbers"""
        line_count = int(self.editor.index('end-1c').split('.')[0])
        line_numbers_text = '\n'.join(str(i) for i in range(1, line_count + 1))
        
        self.line_numbers.config(state=tk.NORMAL)
        self.line_numbers.delete('1.0', tk.END)
        self.line_numbers.insert('1.0', line_numbers_text)
        self.line_numbers.config(state=tk.DISABLED)
    
    def apply_syntax_highlighting(self):
        """Apply basic syntax highlighting"""
        content = self.editor.get('1.0', tk.END)
        
        # Remove existing tags
        for tag in ['keyword', 'string', 'comment', 'number', 'function', 'builtin', 'operator']:
            self.editor.tag_remove(tag, '1.0', tk.END)
        
        # Keywords
        keywords = ['local', 'function', 'end', 'if', 'then', 'else', 'elseif', 'for', 'while', 
                   'do', 'repeat', 'until', 'return', 'break', 'in', 'and', 'or', 'not']
        for keyword in keywords:
            start = '1.0'
            while True:
                pos = self.editor.search(r'\m' + keyword + r'\M', start, tk.END, regexp=True)
                if not pos:
                    break
                end = f"{pos}+{len(keyword)}c"
                self.editor.tag_add('keyword', pos, end)
                start = end
        
        # Builtins
        builtins = ['print', 'warn', 'game', 'workspace', 'Instance', 'Vector3', 'Color3', 
                   'UDim2', 'pcall', 'loadstring', 'require', 'spawn', 'wait']
        for builtin in builtins:
            start = '1.0'
            while True:
                pos = self.editor.search(r'\m' + builtin + r'\M', start, tk.END, regexp=True)
                if not pos:
                    break
                end = f"{pos}+{len(builtin)}c"
                self.editor.tag_add('builtin', pos, end)
                start = end
        
        # Comments
        lines = content.split('\n')
        for i, line in enumerate(lines, 1):
            if '--' in line:
                comment_start = line.index('--')
                start_pos = f"{i}.{comment_start}"
                end_pos = f"{i}.end"
                self.editor.tag_add('comment', start_pos, end_pos)
        
        # Strings
        import re
        for match in re.finditer(r'(["\'])(?:(?=(\\?))\2.)*?\1', content):
            start_idx = self.editor.index(f"1.0+{match.start()}c")
            end_idx = self.editor.index(f"1.0+{match.end()}c")
            self.editor.tag_add('string', start_idx, end_idx)
        
        # Numbers
        for match in re.finditer(r'\b\d+\.?\d*\b', content):
            start_idx = self.editor.index(f"1.0+{match.start()}c")
            end_idx = self.editor.index(f"1.0+{match.end()}c")
            self.editor.tag_add('number', start_idx, end_idx)
    
    def get_text(self):
        """Get editor text"""
        return self.editor.get('1.0', tk.END).strip()
    
    def set_text(self, text):
        """Set editor text"""
        self.editor.delete('1.0', tk.END)
        self.editor.insert('1.0', text)
        self.update_line_numbers()
        self.apply_syntax_highlighting()
    
    def clear(self):
        """Clear editor"""
        self.editor.delete('1.0', tk.END)
        self.update_line_numbers()


class SynapseXUI:
    """Enhanced Synapse X UI with animations and Monaco editor"""
    
    def __init__(self, root):
        self.root = root
        self.root.title("Synapse X")
        self.root.geometry("820x550")
        self.root.configure(bg='#1a1a1a')
        
        # Remove default window decorations
        self.root.overrideredirect(True)
        
        # Window state
        self.is_minimized = False
        self.is_attached = False
        
        # Colors (PDark theme)
        self.colors = {
            'bg_deep': '#16161a',
            'bg_mid': '#1e1e23',
            'bg_panel': '#1a1a1f',
            'bg_editor': '#262626',
            'bg_btn': '#26262d',
            'bg_btn_hov': '#34343e',
            'stroke_outer': '#3c3c4b',
            'stroke_inner': '#2d2d3a',
            'stroke_btn': '#373744',
            'stroke_accent': '#5050b4',
            'text_main': '#dcdce6',
            'text_dim': '#828296',
            'text_tab': '#c8c8d7',
            'icon_tint': '#b4b4c8',
            'close_hov': '#b43232',
            'attach_on': '#32b450',
            'accent_blue': '#7AA2F7',
            'accent_purple': '#BB9AF7'
        }
        
        # Animation helper
        self.animator = AnimationHelper()
        
        # Set icon if available
        icon_path = '/mnt/user-data/uploads/synapse_white.ico'
        if os.path.exists(icon_path):
            try:
                self.root.iconbitmap(icon_path)
            except:
                pass
        
        self.setup_ui()
        self.bind_events()
        self.enable_dragging()
        
        # Fade in on start
        self.root.attributes('-alpha', 0.0)
        self.root.after(100, lambda: self.animator.fade_in(self.root, duration=400))
    
    def setup_ui(self):
        """Setup the main UI"""
        # Main container
        self.main_frame = tk.Frame(
            self.root,
            bg=self.colors['bg_deep'],
            highlightbackground=self.colors['stroke_outer'],
            highlightthickness=1
        )
        self.main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Title bar
        self.create_title_bar()
        
        # Accent line
        accent_line = tk.Frame(self.main_frame, bg=self.colors['accent_purple'], height=2)
        accent_line.pack(fill=tk.X)
        
        # Tab bar
        self.create_tab_bar()
        
        # Editor container with Monaco
        self.monaco_editor = MonacoEditor(self.main_frame)
        self.monaco_editor.pack(fill=tk.BOTH, expand=True, padx=1, pady=0)
        
        # Toolbar
        self.create_toolbar()
    
    def create_title_bar(self):
        """Create custom title bar"""
        title_bar = tk.Frame(self.main_frame, bg=self.colors['bg_mid'], height=32)
        title_bar.pack(fill=tk.X)
        title_bar.pack_propagate(False)
        
        # Title with icon
        title_container = tk.Frame(title_bar, bg=self.colors['bg_mid'])
        title_container.pack(side=tk.LEFT, padx=10)
        
        # Title text
        title_label = tk.Label(
            title_container,
            text="⚡ Synapse X",
            bg=self.colors['bg_mid'],
            fg=self.colors['text_main'],
            font=('Segoe UI', 11, 'bold')
        )
        title_label.pack(side=tk.LEFT)
        
        # Window controls
        controls_frame = tk.Frame(title_bar, bg=self.colors['bg_mid'])
        controls_frame.pack(side=tk.RIGHT, padx=5)
        
        # Minimize button
        self.min_btn = tk.Button(
            controls_frame,
            text="─",
            bg=self.colors['bg_mid'],
            fg=self.colors['text_dim'],
            font=('Segoe UI', 10),
            bd=0,
            width=3,
            height=1,
            cursor='hand2',
            command=self.toggle_minimize
        )
        self.min_btn.pack(side=tk.LEFT, padx=2)
        self.bind_hover(self.min_btn, self.colors['bg_btn_hov'])
        
        # Close button
        self.close_btn = tk.Button(
            controls_frame,
            text="✕",
            bg=self.colors['bg_mid'],
            fg=self.colors['text_dim'],
            font=('Segoe UI', 10),
            bd=0,
            width=3,
            height=1,
            cursor='hand2',
            command=self.close_window
        )
        self.close_btn.pack(side=tk.LEFT, padx=2)
        self.bind_hover(self.close_btn, self.colors['close_hov'])
        
        self.title_bar = title_bar
    
    def create_tab_bar(self):
        """Create tab bar"""
        tab_bar = tk.Frame(self.main_frame, bg=self.colors['bg_panel'], height=28)
        tab_bar.pack(fill=tk.X)
        tab_bar.pack_propagate(False)
        
        # Active tab
        active_tab = tk.Frame(
            tab_bar,
            bg=self.colors['bg_editor'],
            highlightbackground=self.colors['stroke_inner'],
            highlightthickness=1
        )
        active_tab.pack(side=tk.LEFT, fill=tk.Y, padx=(5, 0))
        
        tab_label = tk.Label(
            active_tab,
            text="Script 1",
            bg=self.colors['bg_editor'],
            fg=self.colors['text_tab'],
            font=('Segoe UI', 9)
        )
        tab_label.pack(side=tk.LEFT, padx=10, pady=3)
        
        tab_close = tk.Label(
            active_tab,
            text="✕",
            bg=self.colors['bg_editor'],
            fg=self.colors['text_dim'],
            font=('Segoe UI', 8),
            cursor='hand2'
        )
        tab_close.pack(side=tk.LEFT, padx=(0, 8), pady=3)
        tab_close.bind('<Button-1>', lambda e: self.monaco_editor.clear())
        self.bind_hover(tab_close, self.colors['close_hov'], property='fg')
        
        # New tab button
        new_tab = tk.Label(
            tab_bar,
            text="+",
            bg=self.colors['bg_panel'],
            fg=self.colors['text_dim'],
            font=('Segoe UI', 12, 'bold'),
            cursor='hand2',
            padx=8,
            pady=2
        )
        new_tab.pack(side=tk.LEFT, padx=5)
        new_tab.bind('<Button-1>', lambda e: self.new_tab())
        self.bind_hover(new_tab, self.colors['bg_btn_hov'])
    
    def create_toolbar(self):
        """Create bottom toolbar"""
        toolbar = tk.Frame(
            self.main_frame,
            bg=self.colors['bg_mid'],
            height=40,
            highlightbackground=self.colors['stroke_inner'],
            highlightthickness=1
        )
        toolbar.pack(fill=tk.X, side=tk.BOTTOM)
        toolbar.pack_propagate(False)
        
        buttons_config = [
            ('Execute', self.execute_code, self.colors['accent_purple'], True),
            ('Clear', self.clear_editor, self.colors['stroke_btn'], False),
            ('Open File', self.open_file, self.colors['stroke_btn'], False),
            ('Execute File', self.execute_file, self.colors['stroke_btn'], False),
            ('Save File', self.save_file, self.colors['stroke_btn'], False),
            ('Options', self.options, self.colors['stroke_btn'], False),
            ('Attach', self.attach, self.colors['stroke_btn'], False),
            ('Script Hub', self.script_hub, self.colors['stroke_btn'], False)
        ]
        
        x_pos = 10
        self.buttons = {}
        
        for text, command, accent, is_primary in buttons_config:
            btn = tk.Button(
                toolbar,
                text=text,
                bg=self.colors['bg_btn'],
                fg=self.colors['text_main'],
                font=('Segoe UI', 9),
                bd=0,
                cursor='hand2',
                command=command,
                relief=tk.FLAT,
                highlightbackground=accent,
                highlightthickness=1 if is_primary else 0
            )
            btn.place(x=x_pos, y=8, width=90, height=24)
            self.bind_hover(btn, self.colors['bg_btn_hov'])
            self.buttons[text] = btn
            x_pos += 95
    
    def bind_hover(self, widget, hover_color, property='bg'):
        """Bind hover effects"""
        original_color = widget.cget(property)
        
        def on_enter(e):
            self.animator.color_transition(widget, original_color, hover_color, property=property)
        
        def on_leave(e):
            self.animator.color_transition(widget, hover_color, original_color, property=property)
        
        widget.bind('<Enter>', on_enter)
        widget.bind('<Leave>', on_leave)
    
    def enable_dragging(self):
        """Enable window dragging"""
        self.drag_data = {'x': 0, 'y': 0}
        
        def start_drag(event):
            self.drag_data['x'] = event.x
            self.drag_data['y'] = event.y
        
        def do_drag(event):
            x = self.root.winfo_x() + (event.x - self.drag_data['x'])
            y = self.root.winfo_y() + (event.y - self.drag_data['y'])
            self.root.geometry(f"+{x}+{y}")
        
        self.title_bar.bind('<Button-1>', start_drag)
        self.title_bar.bind('<B1-Motion>', do_drag)
    
    def bind_events(self):
        """Bind keyboard shortcuts"""
        self.root.bind('<Control-o>', lambda e: self.open_file())
        self.root.bind('<Control-s>', lambda e: self.save_file())
        self.root.bind('<Control-e>', lambda e: self.execute_code())
        self.root.bind('<Control-l>', lambda e: self.clear_editor())
        self.root.bind('<F5>', lambda e: self.execute_code())
    
    def toggle_minimize(self):
        """Toggle minimize state"""
        if not self.is_minimized:
            # Minimize
            self.monaco_editor.pack_forget()
            self.root.geometry(f"820x32")
            self.is_minimized = True
        else:
            # Restore
            self.monaco_editor.pack(fill=tk.BOTH, expand=True, padx=1, pady=0)
            self.root.geometry("820x550")
            self.is_minimized = False
    
    def close_window(self):
        """Close window with fade out"""
        def destroy():
            self.root.destroy()
        
        self.animator.fade_out(self.root, duration=200, callback=destroy)
    
    def execute_code(self):
        """Execute code"""
        code = self.monaco_editor.get_text()
        if code and code.strip():
            print(f"\n{'='*50}")
            print("[Synapse X] Executing Script...")
            print(f"{'='*50}\n")
            print(code)
            print(f"\n{'='*50}")
            # Flash execute button
            original_bg = self.buttons['Execute'].cget('bg')
            self.buttons['Execute'].config(bg=self.colors['accent_blue'])
            self.root.after(100, lambda: self.buttons['Execute'].config(bg=original_bg))
        else:
            print("[Synapse X] No code to execute")
    
    def clear_editor(self):
        """Clear editor"""
        self.monaco_editor.clear()
        print("[Synapse X] Editor cleared")
    
    def open_file(self):
        """Open file"""
        filename = filedialog.askopenfilename(
            title="Open Script",
            filetypes=[
                ("Lua files", "*.lua"),
                ("Text files", "*.txt"),
                ("All files", "*.*")
            ]
        )
        if filename:
            try:
                with open(filename, 'r', encoding='utf-8') as f:
                    content = f.read()
                self.monaco_editor.set_text(content)
                print(f"[Synapse X] Opened: {filename}")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to open file:\n{str(e)}")
    
    def execute_file(self):
        """Execute file"""
        filename = filedialog.askopenfilename(
            title="Execute Script",
            filetypes=[("Lua files", "*.lua"), ("All files", "*.*")]
        )
        if filename:
            try:
                with open(filename, 'r', encoding='utf-8') as f:
                    code = f.read()
                print(f"\n{'='*50}")
                print(f"[Synapse X] Executing File: {filename}")
                print(f"{'='*50}\n")
                print(code)
                print(f"\n{'='*50}")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to execute file:\n{str(e)}")
    
    def save_file(self):
        """Save file"""
        filename = filedialog.asksaveasfilename(
            title="Save Script",
            defaultextension=".lua",
            filetypes=[
                ("Lua files", "*.lua"),
                ("Text files", "*.txt"),
                ("All files", "*.*")
            ]
        )
        if filename:
            try:
                with open(filename, 'w', encoding='utf-8') as f:
                    f.write(self.monaco_editor.get_text())
                print(f"[Synapse X] Saved to: {filename}")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to save file:\n{str(e)}")
    
    def options(self):
        """Show options"""
        print("[Synapse X] Options menu (Not implemented)")
        messagebox.showinfo("Options", "Options menu coming soon!")
    
    def attach(self):
        """Attach to Roblox"""
        self.is_attached = not self.is_attached
        if self.is_attached:
            self.buttons['Attach'].config(
                highlightbackground=self.colors['attach_on'],
                highlightthickness=2
            )
            print("[Synapse X] ✓ Attached to Roblox")
        else:
            self.buttons['Attach'].config(highlightthickness=0)
            print("[Synapse X] ✗ Detached from Roblox")
    
    def script_hub(self):
        """Open script hub"""
        print("[Synapse X] Opening Script Hub...")
        messagebox.showinfo("Script Hub", "Script Hub coming soon!")
    
    def new_tab(self):
        """Create new tab"""
        self.monaco_editor.clear()
        print("[Synapse X] New tab created")


def main():
    root = tk.Tk()
    app = SynapseXUI(root)
    
    # Center window
    root.update_idletasks()
    width = root.winfo_width()
    height = root.winfo_height()
    x = (root.winfo_screenwidth() // 2) - (width // 2)
    y = (root.winfo_screenheight() // 2) - (height // 2)
    root.geometry(f'{width}x{height}+{x}+{y}')
    
    root.mainloop()


if __name__ == "__main__":
    main()
