import sys
import re
import subprocess
import tempfile
import os
import fnmatch
import random
import socket
import threading
import struct
import json

try:
    from flask import Flask as _Flask, request as _flask_request, jsonify as _flask_jsonify

    _FLASK_AVAILABLE = True
except ImportError:
    _FLASK_AVAILABLE = False

try:
    import pyfiglet as _pyfiglet
    _PYFIGLET_AVAILABLE = True
except ImportError:
    _PYFIGLET_AVAILABLE = False

from PyQt6.QtWidgets import (
    QApplication,
    QMainWindow,
    QTextEdit,
    QVBoxLayout,
    QHBoxLayout,
    QWidget,
    QPushButton,
    QLabel,
    QSplitter,
    QPlainTextEdit,
    QStatusBar,
    QFileDialog,
    QTreeWidget,
    QTreeWidgetItem,
    QTabWidget,
    QMessageBox,
    QDialog,
    QFormLayout,
    QComboBox,
    QSpinBox,
    QCheckBox,
    QMenu,
    QLineEdit,
    QRadioButton,
    QButtonGroup,
    QScrollBar,
)
from PyQt6.QtGui import (
    QFont,
    QColor,
    QTextCharFormat,
    QSyntaxHighlighter,
    QPainter,
    QTextFormat,
    QAction,
    QIcon,
    QTextDocument,
)
from PyQt6.QtCore import Qt, QRect, QSize, QDir, QUrl, QEventLoop, QProcess, QProcessEnvironment
from PyQt6.QtWebEngineWidgets import QWebEngineView
from PyQt6.QtWebEngineCore import QWebEngineSettings

from PyQt6.QtCore import QFileSystemWatcher, QTimer

# ── Centralised theme definitions ──────────────────────────────────────────────
THEMES = {
    "Light": {
        # General UI
        "app_bg": "#F2F2F3",
        "toolbar_bg": "#E8E8EA",
        "toolbar_border": "#D0D0D4",
        "btn_bg": "#FFFFFF",
        "btn_fg": "#1A1A1E",
        "btn_border_tl": "#FFFFFF",
        "btn_border_br": "#C0C0C6",
        "btn_border_out": "#C8C8CE",
        "btn_hover_bg": "#EAF2FF",
        "btn_hover_border": "#4A90D9",
        "btn_press_bg": "#D6E8FF",
        "tree_bg": "#FFFFFF",
        "tree_alt": "#F7F7F9",
        "tree_border": "#D0D0D4",
        "tree_sel_bg": "#4A90D9",
        "tree_sel_fg": "#FFFFFF",
        "tree_hover": "#EAF2FF",
        "tab_bg": "#E2E2E6",
        "tab_sel_bg": "#FFFFFF",
        "tab_hover_bg": "#ECECF0",
        "tab_border": "#C8C8CE",
        "tab_pane_bg": "#FFFFFF",
        "tab_pane_border": "#D0D0D4",
        "splitter_bg": "#D0D0D4",
        "explorer_hdr_bg": "#E8E8EA",
        "explorer_hdr_bd": "#D0D0D4",
        "label_fg": "#1A1A1E",
        "status_fg": "#555560",
        # Editor
        "editor_bg": "#FFFFFF",
        "editor_fg": "#1A1A1E",
        "editor_sel": "#B8D4F8",
        "lineno_bg": "#F0F0F3",
        "lineno_fg": "#9090A0",
        "curline_bg": "#EEF4FF",
        # Syntax
        "syn_keyword": "#0055BB",
        "syn_builtin": "#7700CC",
        "syn_roblox": "#007878",
        "syn_number": "#116611",
        "syn_string": "#CC2200",
        "syn_comment": "#448844",
        # Accent buttons — subtle tinted backgrounds
        "btn_settings": "#F0EAF8",
        "btn_format": "#EAF2FF",
        "btn_bridge": "#E8F8EE",
        "btn_obfuscate": "#FFF8E0",
        # accent color used for active indicators
        "accent": "#4A90D9",
    },
    "Dark": {
        # General UI — deep charcoal, not pure black
        "app_bg": "#16171A",
        "toolbar_bg": "#1E1F24",
        "toolbar_border": "#2A2B32",
        "btn_bg": "#26272E",
        "btn_fg": "#C8CAD4",
        "btn_border_tl": "#36373F",
        "btn_border_br": "#111216",
        "btn_border_out": "#2E2F38",
        "btn_hover_bg": "#1E3A5C",
        "btn_hover_border": "#4A90D9",
        "btn_press_bg": "#173050",
        "tree_bg": "#1E1F24",
        "tree_alt": "#22232A",
        "tree_border": "#2A2B32",
        "tree_sel_bg": "#1E3A5C",
        "tree_sel_fg": "#E0E4EE",
        "tree_hover": "#252630",
        "tab_bg": "#1E1F24",
        "tab_sel_bg": "#16171A",
        "tab_hover_bg": "#24252D",
        "tab_border": "#2A2B32",
        "tab_pane_bg": "#16171A",
        "tab_pane_border": "#2A2B32",
        "splitter_bg": "#2A2B32",
        "explorer_hdr_bg": "#1E1F24",
        "explorer_hdr_bd": "#2A2B32",
        "label_fg": "#C8CAD4",
        "status_fg": "#6E7080",
        # Editor
        "editor_bg": "#16171A",
        "editor_fg": "#C8CAD4",
        "editor_sel": "#1E3A5C",
        "lineno_bg": "#1E1F24",
        "lineno_fg": "#484A5A",
        "curline_bg": "#1E202A",
        # Syntax — refined palette
        "syn_keyword": "#6AB0F5",
        "syn_builtin": "#C792EA",
        "syn_roblox": "#4EC9B0",
        "syn_number": "#A8CC8C",
        "syn_string": "#F09070",
        "syn_comment": "#5A7A5A",
        # Accent buttons — very subtle tints
        "btn_settings": "#221830",
        "btn_format": "#101E30",
        "btn_bridge": "#0E2018",
        "btn_obfuscate": "#201800",
        # accent color
        "accent": "#4A90D9",
    },
}

_current_theme = "Dark"


def get_theme():
    return THEMES[_current_theme]


# --- Line Number Area Widget ---
class LineNumberArea(QWidget):
    def __init__(self, editor):
        super().__init__(editor)
        self.editor = editor

    def sizeHint(self):
        return QSize(self.editor.line_number_area_width(), 0)

    def paintEvent(self, event):
        self.editor.line_number_area_paint_event(event)


# --- Code Editor with Line Numbers ---
class CodeEditor(QPlainTextEdit):
    def __init__(self):
        super().__init__()
        self.line_number_area = LineNumberArea(self)

        self.blockCountChanged.connect(self.update_line_number_area_width)
        self.updateRequest.connect(self.update_line_number_area)
        self.cursorPositionChanged.connect(self.highlight_current_line)

        self.update_line_number_area_width(0)
        self.highlight_current_line()

        # Zoom level tracking
        self.zoom_level = 0
        self.base_font_size = 11

    def wheelEvent(self, event):
        """Handle zoom with Ctrl + scroll wheel."""
        if event.modifiers() == Qt.KeyboardModifier.ControlModifier:
            delta = event.angleDelta().y()
            if delta > 0:
                self.zoom_in()
            elif delta < 0:
                self.zoom_out()
            event.accept()
        else:
            super().wheelEvent(event)

    def zoom_in(self):
        """Increase font size."""
        if self.zoom_level < 10:
            self.zoom_level += 1
            self.update_font_size()

    def zoom_out(self):
        """Decrease font size."""
        if self.zoom_level > -5:
            self.zoom_level -= 1
            self.update_font_size()

    def reset_zoom(self):
        """Reset zoom to default."""
        self.zoom_level = 0
        self.update_font_size()

    def update_font_size(self):
        """Update the font size based on zoom level."""
        new_size = self.base_font_size + self.zoom_level
        font = self.font()
        font.setPointSize(new_size)
        self.setFont(font)
        self.update_line_number_area_width(0)

    def line_number_area_width(self):
        digits = len(str(max(1, self.blockCount())))
        space = 10 + self.fontMetrics().horizontalAdvance("9") * digits
        return space

    def update_line_number_area_width(self, _):
        self.setViewportMargins(self.line_number_area_width(), 0, 0, 0)

    def update_line_number_area(self, rect, dy):
        if dy:
            self.line_number_area.scroll(0, dy)
        else:
            self.line_number_area.update(0, rect.y(), self.line_number_area.width(), rect.height())

        if rect.contains(self.viewport().rect()):
            self.update_line_number_area_width(0)

    def resizeEvent(self, event):
        super().resizeEvent(event)
        cr = self.contentsRect()
        self.line_number_area.setGeometry(
            QRect(cr.left(), cr.top(), self.line_number_area_width(), cr.height())
        )

    def line_number_area_paint_event(self, event):
        t = get_theme()
        painter = QPainter(self.line_number_area)
        painter.fillRect(event.rect(), QColor(t["lineno_bg"]))

        block = self.firstVisibleBlock()
        block_number = block.blockNumber()
        top = self.blockBoundingGeometry(block).translated(self.contentOffset()).top()
        bottom = top + self.blockBoundingRect(block).height()

        while block.isValid() and top <= event.rect().bottom():
            if block.isVisible() and bottom >= event.rect().top():
                number = str(block_number + 1)
                painter.setPen(QColor(t["lineno_fg"]))
                painter.drawText(
                    0,
                    int(top),
                    self.line_number_area.width() - 5,
                    self.fontMetrics().height(),
                    Qt.AlignmentFlag.AlignRight,
                    number,
                )

            block = block.next()
            top = bottom
            bottom = top + self.blockBoundingRect(block).height()
            block_number += 1

    def highlight_current_line(self):
        extra_selections = []

        if not self.isReadOnly():
            selection = QTextEdit.ExtraSelection()
            line_color = QColor(get_theme()["curline_bg"])
            selection.format.setBackground(line_color)
            selection.format.setProperty(QTextFormat.Property.FullWidthSelection, True)
            selection.cursor = self.textCursor()
            selection.cursor.clearSelection()
            extra_selections.append(selection)

        self.setExtraSelections(extra_selections)


# --- Syntax Highlighting ---
class LuaSyntaxHighlighter(QSyntaxHighlighter):
    def __init__(self, parent):
        super().__init__(parent)
        self.highlighting_rules = []
        self._build_rules()

    def _build_rules(self):
        t = get_theme()
        self.highlighting_rules = []

        # --- Keywords ---
        keyword_format = QTextCharFormat()
        keyword_format.setForeground(QColor(t["syn_keyword"]))
        keyword_format.setFontWeight(700)
        keywords = [
            "and",
            "break",
            "do",
            "else",
            "elseif",
            "end",
            "false",
            "for",
            "function",
            "if",
            "in",
            "local",
            "nil",
            "not",
            "or",
            "repeat",
            "return",
            "then",
            "true",
            "until",
            "while",
        ]
        for kw in keywords:
            self.highlighting_rules.append((re.compile(r"\b" + kw + r"\b"), keyword_format))

        # --- Built-ins ---
        builtin_format = QTextCharFormat()
        builtin_format.setForeground(QColor(t["syn_builtin"]))
        builtins = [
            "print",
            "tostring",
            "tonumber",
            "type",
            "pairs",
            "ipairs",
            "unpack",
            "select",
            "next",
            "error",
            "assert",
            "pcall",
            "xpcall",
            "rawget",
            "rawset",
            "rawequal",
            "setmetatable",
            "getmetatable",
            "require",
            "loadstring",
            "load",
            "dofile",
            "collectgarbage",
            "table",
            "string",
            "math",
            "os",
            "io",
            "coroutine",
            "game",
            "workspace",
            "script",
            "task",
            "warn",
            "tick",
            "wait",
            "spawn",
            "delay",
        ]
        for b in builtins:
            self.highlighting_rules.append((re.compile(r"\b" + b + r"\b"), builtin_format))

        # --- Roblox services/objects ---
        roblox_format = QTextCharFormat()
        roblox_format.setForeground(QColor(t["syn_roblox"]))
        roblox_names = [
            "Instance",
            "Vector3",
            "Vector2",
            "CFrame",
            "Color3",
            "UDim2",
            "UDim",
            "TweenInfo",
            "Enum",
            "Drawing",
            "Players",
            "RunService",
            "UserInputService",
            "TweenService",
            "ReplicatedStorage",
            "ServerStorage",
            "Workspace",
            "HttpService",
            "CoreGui",
            "Lighting",
        ]
        for r in roblox_names:
            self.highlighting_rules.append((re.compile(r"\b" + r + r"\b"), roblox_format))

        # --- Numbers ---
        number_format = QTextCharFormat()
        number_format.setForeground(QColor(t["syn_number"]))
        self.highlighting_rules.append((re.compile(r"\b\d+(\.\d+)?\b"), number_format))

        # --- Strings ---
        self.string_format = QTextCharFormat()
        self.string_format.setForeground(QColor(t["syn_string"]))

        # --- Comments ---
        self.comment_format = QTextCharFormat()
        self.comment_format.setForeground(QColor(t["syn_comment"]))
        self.comment_format.setFontItalic(True)

        self.single_comment_re = re.compile(r"--(?!\[\[).*")
        self.ml_start_re = re.compile(r"--\[\[")
        self.ml_end_str = "]]"

    def rehighlight_with_theme(self):
        self._build_rules()
        self.rehighlight()

    # ------------------------------------------------------------------
    def highlightBlock(self, text):
        # ---- 1. Apply simple regex rules (keywords, builtins, numbers) ----
        for pattern, fmt in self.highlighting_rules:
            for m in pattern.finditer(text):
                self.setFormat(m.start(), m.end() - m.start(), fmt)

        # ---- 2. Handle strings manually so we don't colour inside comments ----
        #         and so comments inside strings are ignored.
        self._highlight_strings(text)

        # ---- 3. Multi-line comment handling ----
        self.setCurrentBlockState(0)

        if self.previousBlockState() == 1:
            # We're continuing a multi-line comment from the previous block
            end = text.find(self.ml_end_str)
            if end == -1:
                # Entire line is inside the comment
                self.setCurrentBlockState(1)
                self.setFormat(0, len(text), self.comment_format)
                return
            else:
                # Comment ends on this line
                self.setFormat(0, end + 2, self.comment_format)
                # Continue scanning for a new --[[ after the ]]
                scan_from = end + 2
        else:
            scan_from = 0

        # Search for --[[ in the current block (outside strings)
        while True:
            m = self.ml_start_re.search(text, scan_from)
            if not m:
                break
            start = m.start()
            end_idx = text.find(self.ml_end_str, start + 4)
            if end_idx == -1:
                # Opens but doesn't close — mark rest of block
                self.setCurrentBlockState(1)
                self.setFormat(start, len(text) - start, self.comment_format)
                return
            else:
                self.setFormat(start, end_idx + 2 - start, self.comment_format)
                scan_from = end_idx + 2

        # ---- 4. Single-line comments (applied last so they override everything) ----
        for m in self.single_comment_re.finditer(text):
            self.setFormat(m.start(), len(text) - m.start(), self.comment_format)

    # ------------------------------------------------------------------
    def _highlight_strings(self, text):
        """Colour string literals, respecting escape sequences."""
        i = 0
        n = len(text)
        while i < n:
            ch = text[i]
            if ch in ('"', "'"):
                quote = ch
                j = i + 1
                while j < n:
                    if text[j] == "\\":
                        j += 2  # skip escaped char
                        continue
                    if text[j] == quote:
                        j += 1
                        break
                    j += 1
                self.setFormat(i, j - i, self.string_format)
                i = j
            else:
                i += 1


# --- Smart Comment Remover ---
class LuaCommentRemover:
    """Intelligently removes comments while preserving code structure."""

    @staticmethod
    def remove_comments(code):
        """
        Remove Lua comments intelligently:
        - Preserves strings (doesn't touch -- inside strings)
        - Keeps code on lines with trailing comments
        - Only removes lines that are purely comments
        - Handles multi-line comments properly
        """
        lines = code.split("\n")
        result_lines = []
        in_multiline_comment = False

        for line in lines:
            # Check if we're in a multi-line comment
            if in_multiline_comment:
                if "]]" in line:
                    # End of multi-line comment
                    after_comment = line.split("]]", 1)[1]
                    in_multiline_comment = False
                    if after_comment.strip():
                        result_lines.append(after_comment)
                continue

            # Check for start of multi-line comment
            if "--[[" in line:
                before_comment = line.split("--[[", 1)[0]
                remaining = line.split("--[[", 1)[1]

                # Check if it closes on the same line
                if "]]" in remaining:
                    after_comment = remaining.split("]]", 1)[1]
                    cleaned = before_comment + after_comment
                    if cleaned.strip():
                        result_lines.append(cleaned)
                else:
                    # Multi-line comment starts
                    in_multiline_comment = True
                    if before_comment.strip():
                        result_lines.append(before_comment)
                continue

            # Handle single-line comments
            cleaned_line = LuaCommentRemover._remove_single_line_comment(line)

            # Only add non-empty lines
            if cleaned_line.strip():
                result_lines.append(cleaned_line)

        return "\n".join(result_lines)

    @staticmethod
    def _remove_single_line_comment(line):
        """Remove single-line comment while respecting strings."""
        # We need to find -- that's not inside a string
        in_string = False
        string_char = None
        escaped = False

        for i, char in enumerate(line):
            if escaped:
                escaped = False
                continue

            if char == "\\":
                escaped = True
                continue

            # Track string state
            if char in ['"', "'"] and not in_string:
                in_string = True
                string_char = char
            elif char == string_char and in_string:
                in_string = False
                string_char = None

            # Look for -- outside of strings
            elif not in_string and char == "-" and i + 1 < len(line) and line[i + 1] == "-":
                # Found a comment marker outside a string
                return line[:i].rstrip()

        return line


# --- Lua Analyzer (ported from LuaFixer) ---
class LuaAnalyzer:
    """
    Static analyser that runs 10 checks on Lua/Luau source and returns
    a list of issue dicts: {line, sev, title, desc, code}
    sev = 'fatal' | 'warn' | 'info'
    """

    DEPRECATED = [
        (re.compile(r'\bunpack\s*\('),         'warn', 'unpack() deprecated',         'Use table.unpack() instead.'),
        (re.compile(r'\bmath\.mod\s*\('),      'warn', 'math.mod() deprecated',       'Use math.fmod() instead.'),
        (re.compile(r'\bstring\.gfind\s*\('),  'warn', 'string.gfind() deprecated',   'Use string.gmatch() instead.'),
        (re.compile(r'\btable\.getn\s*\('),    'warn', 'table.getn() deprecated',     'Use the # operator instead.'),
        (re.compile(r'\bloadstring\s*\('),     'warn', 'loadstring() may be disabled','Some executors block loadstring(). Use load() if available.'),
        (re.compile(r'\bsetfenv\s*\('),        'warn', 'setfenv() unavailable in Luau','setfenv is Lua 5.1 only — not supported in Luau/Roblox.'),
        (re.compile(r'\bgetfenv\s*\('),        'warn', 'getfenv() unavailable in Luau','getfenv is Lua 5.1 only — not supported in Luau/Roblox.'),
    ]

    @staticmethod
    def analyze(src: str) -> list:
        issues = []
        lines = src.split('\n')
        stripped = LuaAnalyzer._strip(lines)

        LuaAnalyzer._check_brackets(stripped, lines, issues)
        LuaAnalyzer._check_end_keywords(stripped, lines, issues)
        LuaAnalyzer._check_unclosed_strings(lines, issues)
        LuaAnalyzer._check_task_bloat(lines, issues)
        LuaAnalyzer._check_bad_method_calls(lines, issues)
        LuaAnalyzer._check_deprecated(lines, stripped, issues)
        LuaAnalyzer._check_nil_indexing(lines, issues)
        LuaAnalyzer._check_infinite_loops(lines, stripped, issues)
        LuaAnalyzer._check_empty_blocks(lines, stripped, issues)
        LuaAnalyzer._check_dead_code(lines, stripped, issues)

        order = {'fatal': 0, 'warn': 1, 'info': 2}
        issues.sort(key=lambda x: (order[x['sev']], x['line']))
        return issues

    # ── helpers ────────────────────────────────────────────────────────────
    @staticmethod
    def _strip(lines):
        src = '\n'.join(lines)
        out = re.sub(r'--\[=*\[[\s\S]*?\]=*\]', lambda m: ' ' * len(m.group()), src)
        out = re.sub(r'\[=*\[[\s\S]*?\]=*\]',   lambda m: '""' + ' ' * max(0, len(m.group()) - 2), out)
        out = re.sub(r'"(?:\\.|[^"\\])*"',       '""', out)
        out = re.sub(r"'(?:\\.|[^'\\])*'",       "''", out)
        out = re.sub(r'--[^\n]*',                lambda m: ' ' * len(m.group()), out)
        return out.split('\n')

    @staticmethod
    def _add(issues, line, sev, title, desc, code=''):
        issues.append({'line': line, 'sev': sev, 'title': title, 'desc': desc, 'code': code[:80]})

    # ── Check 1: bracket balance ───────────────────────────────────────────
    @staticmethod
    def _check_brackets(stripped, lines, issues):
        openers = {'(': ')', '[': ']', '{': '}'}
        stack = []
        for i, s in enumerate(stripped):
            for c in s:
                if c in openers:
                    stack.append((c, i + 1))
                elif c in (')', ']', '}'):
                    if not stack:
                        LuaAnalyzer._add(issues, i+1, 'fatal', f"Unexpected '{c}'",
                                         f"No matching opening bracket for '{c}'.", lines[i].strip())
                    else:
                        top_ch, top_line = stack[-1]
                        if openers[top_ch] == c:
                            stack.pop()
                        else:
                            LuaAnalyzer._add(issues, i+1, 'fatal', f"Mismatched bracket '{c}'",
                                             f"Expected '{openers[top_ch]}' to close '{top_ch}' opened on line {top_line}, got '{c}'.",
                                             lines[i].strip())
                            stack.pop()
        for ch, ln in stack:
            code = lines[ln-1].strip() if ln-1 < len(lines) else ''
            LuaAnalyzer._add(issues, ln, 'fatal', f"Unclosed '{ch}'",
                             f"Bracket '{ch}' opened here is never closed.", code)

    # ── Check 2: do/end balance ────────────────────────────────────────────
    @staticmethod
    def _check_end_keywords(stripped, lines, issues):
        opener_re = re.compile(r'\b(function|do|if|while|for|repeat)\b')
        closer_re = re.compile(r'\bend\b')
        until_re  = re.compile(r'\buntil\b')
        opens, closes, untils = 0, 0, 0
        open_lines, close_lines = [], []
        for i, s in enumerate(stripped):
            o = len(opener_re.findall(s))
            c = len(closer_re.findall(s))
            u = len(until_re.findall(s))
            open_lines.extend([i+1] * o)
            close_lines.extend([i+1] * c)
            opens += o; closes += c; untils += u
        expected = opens - untils
        if closes < expected:
            missing = expected - closes
            culprit = open_lines[-missing] if len(open_lines) >= missing else (open_lines[-1] if open_lines else 1)
            LuaAnalyzer._add(issues, culprit, 'fatal', f"Missing {missing} 'end'",
                             f"Script has {opens} block opener(s) but only {closes} 'end'(s).",
                             lines[culprit-1].strip() if culprit-1 < len(lines) else '')
        elif closes > expected:
            extra = closes - expected
            culprit = close_lines[-extra] if len(close_lines) >= extra else (close_lines[-1] if close_lines else 1)
            LuaAnalyzer._add(issues, culprit, 'fatal', f"{extra} extra 'end'",
                             f"Script has {extra} more 'end'(s) than block openers.",
                             lines[culprit-1].strip() if culprit-1 < len(lines) else '')

    # ── Check 3: unclosed strings ─────────────────────────────────────────
    @staticmethod
    def _check_unclosed_strings(lines, issues):
        for i, line in enumerate(lines):
            if line.strip().startswith('--'):
                continue
            clean = re.sub(r'--\[\[[\s\S]*?\]\]', '', line)
            clean = re.sub(r'\[\[[\s\S]*?\]\]', '""', clean)
            clean = re.sub(r'--[^\n]*', '', clean)
            in_str = None
            for j, ch in enumerate(clean):
                if ch == '\\':
                    continue
                if not in_str and ch in ('"', "'"):
                    in_str = ch
                elif in_str == ch:
                    in_str = None
            if in_str:
                LuaAnalyzer._add(issues, i+1, 'fatal', f"Unclosed string ({in_str})",
                                 f"String opened with {in_str} is never closed on this line.", line.strip())

    # ── Check 4: task.task bloat ──────────────────────────────────────────
    @staticmethod
    def _check_task_bloat(lines, issues):
        for i, line in enumerate(lines):
            if re.search(r'task\.task', line):
                LuaAnalyzer._add(issues, i+1, 'fatal', 'Doubled task prefix',
                                 'task.task.X — a bad auto-fixer prepended task. to an already-prefixed call.',
                                 line.strip())

    # ── Check 5: bad method calls ─────────────────────────────────────────
    @staticmethod
    def _check_bad_method_calls(lines, issues):
        for i, line in enumerate(lines):
            if re.search(r':\s*task\.(wait|spawn|delay)\b', line):
                LuaAnalyzer._add(issues, i+1, 'fatal', 'Mangled method call',
                                 ':task.wait() is invalid — should be :Wait() or task.wait().',
                                 line.strip())

    # ── Check 6: deprecated globals ───────────────────────────────────────
    @staticmethod
    def _check_deprecated(lines, stripped, issues):
        for i, s in enumerate(stripped):
            for pat, sev, title, desc in LuaAnalyzer.DEPRECATED:
                if pat.search(s):
                    LuaAnalyzer._add(issues, i+1, sev, title, desc, lines[i].strip())

    # ── Check 7: nil indexing ─────────────────────────────────────────────
    @staticmethod
    def _check_nil_indexing(lines, issues):
        for i, line in enumerate(lines):
            t = line.strip()
            if t.startswith('--'):
                continue
            if re.search(r'\bnil\s*\.\s*\w+', t):
                LuaAnalyzer._add(issues, i+1, 'fatal', 'Indexing nil',
                                 'Attempting to index a nil value directly.', t)

    # ── Check 8: infinite loops without wait ──────────────────────────────
    @staticmethod
    def _check_infinite_loops(lines, stripped, issues):
        in_wt = False; wl = 0; depth = 0; start_depth = 0; has_wait = False
        for i, s in enumerate(stripped):
            if re.search(r'\bwhile\s+true\s+do\b|\bwhile\s+1\s+do\b', s):
                in_wt = True; wl = i+1; start_depth = depth; has_wait = False
            o = len(re.findall(r'\b(function|do|if|while|for|repeat)\b', s))
            c = len(re.findall(r'\bend\b', s))
            u = len(re.findall(r'\buntil\b', s))
            depth += o - c - u
            if in_wt:
                if re.search(r'task\.wait|task\.sleep|wait\s*\(', lines[i]):
                    has_wait = True
                if depth <= start_depth and i+1 > wl:
                    if not has_wait:
                        code = lines[wl-1].strip() if wl-1 < len(lines) else ''
                        LuaAnalyzer._add(issues, wl, 'warn', 'Infinite loop without wait',
                                         'while true do loop has no task.wait() — this will freeze the script.', code)
                    in_wt = False

    # ── Check 9: empty blocks ─────────────────────────────────────────────
    @staticmethod
    def _check_empty_blocks(lines, stripped, issues):
        for i, s in enumerate(stripped):
            t = s.strip()
            if re.search(r'\bfunction\b[^)]*\)\s*end\b', t):
                LuaAnalyzer._add(issues, i+1, 'info', 'Empty function body',
                                 'Function has no body. Intentional?', lines[i].strip())
            if re.search(r'\bif\b.+\bthen\b\s*\bend\b', t):
                LuaAnalyzer._add(issues, i+1, 'info', 'Empty if block',
                                 'if/then/end with no body. Intentional?', lines[i].strip())

    # ── Check 10: dead code after return ──────────────────────────────────
    @staticmethod
    def _check_dead_code(lines, stripped, issues):
        ret_seen = False; ret_line = 0; depth = 0; ret_depth = 0
        for i, s in enumerate(stripped):
            t = s.strip()
            o = len(re.findall(r'\b(function|do|if|while|for|repeat)\b', s))
            c = len(re.findall(r'\bend\b', s))
            u = len(re.findall(r'\buntil\b', s))
            if (ret_seen and depth == ret_depth and t and
                    not t.startswith('--') and not t.startswith('end') and not t.startswith('until')):
                LuaAnalyzer._add(issues, i+1, 'warn', 'Unreachable code',
                                 f"Code after 'return' on line {ret_line} will never run.",
                                 lines[i].strip())
                ret_seen = False
            if re.match(r'\s*return\b', lines[i]) and not t.startswith('--'):
                ret_seen = True; ret_line = i+1; ret_depth = depth
            depth += o - c - u
            if depth < ret_depth:
                ret_seen = False; ret_depth = 0


# --- Format Options Dialog ---
class FormatOptionsDialog(QDialog):
    """
    Customisable Lua formatter options dialog.
    All settings are exposed so the user can tune exactly how the output looks.
    Includes Shape Mode — reflow code tokens to fill a silhouette (ASCII-art style).
    """

    DEFAULTS = {
        "indent_style": "spaces",
        "indent_size": 4,
        "max_blank_lines": 2,
        "space_operators": True,
        "space_after_comma": True,
        "trailing_whitespace": True,
        "normalize_min_indent": True,
        "semicolon_removal": False,
        "newline_before_end": False,
        "compact_empty_blocks": True,
        "align_assignments": False,
        # Shape mode
        "shape_mode": False,
        "shape_name": "Among Us",
        "shape_custom": "",
        "shape_width": 120,
    }

    PRESETS = {
        "Default": {},
        "Compact": {"max_blank_lines": 0, "newline_before_end": False, "align_assignments": False},
        "Expanded": {"max_blank_lines": 2, "newline_before_end": True},
        "Tabs": {"indent_style": "tabs"},
        "2-Space": {"indent_size": 2, "indent_style": "spaces"},
        "Strict": {
            "semicolon_removal": True,
            "trailing_whitespace": True,
            "normalize_min_indent": True,
            "space_operators": True,
            "space_after_comma": True,
        },
    }

    # ── Built-in shape silhouettes ────────────────────────────────────────────
    # Each shape is a list of strings. '#' = filled cell, ' ' = empty.
    # They're designed at ~60 chars wide; the engine scales to shape_width.
    SHAPES = {
        "Among Us": [
            "          ##########          ",
            "       ################       ",
            "      ##################      ",
            "     ####################     ",
            "    ######################    ",
            "    ######################    ",
            "    ######        ########    ",
            "    ######        ########    ",
            "    ######        ########    ",
            "    ######################    ",
            "    ######################    ",
            "    ######################    ",
            "    ######################    ",
            "    ######################    ",
            "    ######################    ",
            "    ######################    ",
            "    ######################    ",
            "    ######################    ",
            "     ####################     ",
            "     ####################     ",
            "     ###########  #######     ",
            "     ##########    ######     ",
            "    #########      ######     ",
            "    ########       ######     ",
            "    ########       ######     ",
            "    ########       ######     ",
            "    #########     #######     ",
            "     #####################    ",
        ],
        "Heart": [
            "    ######    ######    ",
            "  ##########  #######   ",
            " ############ ########  ",
            " #####################  ",
            " #####################  ",
            "  ###################   ",
            "   #################    ",
            "    ###############     ",
            "     #############      ",
            "      ###########       ",
            "       #########        ",
            "        #######         ",
            "         #####          ",
            "          ###           ",
            "           #            ",
        ],
        "Skull": [
            "     ###########     ",
            "   ###############   ",
            "  #################  ",
            " ################### ",
            " ################### ",
            " ## ### ##### ### ## ",
            " ##     #####     ## ",
            " ## ### ##### ### ## ",
            " ################### ",
            " ################### ",
            "  #################  ",
            "  ### ######### ###  ",
            "  ### ######### ###  ",
            "   #################   ",
            "    ###########    ",
        ],
        "Roblox R": [
            " ################  ",
            " ################  ",
            " ####   ########   ",
            " ####   ########   ",
            " ####   ########   ",
            " ################  ",
            " ################  ",
            " ########          ",
            " #######           ",
            " ######            ",
            " #####             ",
            " ####              ",
            " ###               ",
        ],
        "Arrow": [
            "          #         ",
            "         ###        ",
            "        #####       ",
            "       #######      ",
            "      #########     ",
            "         ###        ",
            "         ###        ",
            "         ###        ",
            "         ###        ",
            "         ###        ",
            "         ###        ",
        ],
        "Diamond": [
            "          #          ",
            "         ###         ",
            "        #####        ",
            "       #######       ",
            "      #########      ",
            "     ###########     ",
            "    #############    ",
            "     ###########     ",
            "      #########      ",
            "       #######       ",
            "        #####        ",
            "         ###         ",
            "          #          ",
        ],
        "Custom": [],  # filled from the text box
    }

    def __init__(self, parent=None, saved_options: dict = None):
        super().__init__(parent)
        self.setWindowTitle("Format Options")
        self.setModal(True)
        self.setMinimumWidth(520)

        self.opts = dict(self.DEFAULTS)
        if saved_options:
            self.opts.update(saved_options)

        root = QVBoxLayout(self)
        root.setSpacing(8)

        # ── Preset row ────────────────────────────────────────────────────
        preset_row = QHBoxLayout()
        preset_row.addWidget(QLabel("Preset:"))
        self.preset_combo = QComboBox()
        self.preset_combo.addItems(list(self.PRESETS.keys()))
        self.preset_combo.currentTextChanged.connect(self._apply_preset)
        preset_row.addWidget(self.preset_combo)
        preset_row.addStretch()
        root.addLayout(preset_row)

        sep0 = QWidget()
        sep0.setFixedHeight(1)
        sep0.setStyleSheet("background-color:#CCCCCC;")
        root.addWidget(sep0)

        # ── Standard formatter form ───────────────────────────────────────
        form = QFormLayout()
        form.setHorizontalSpacing(16)
        form.setVerticalSpacing(6)

        self.indent_style = QComboBox()
        self.indent_style.addItems(["spaces", "tabs"])
        self.indent_style.setCurrentText(self.opts["indent_style"])
        self.indent_style.currentTextChanged.connect(self._sync_indent_size_state)
        form.addRow("Indent style:", self.indent_style)

        self.indent_size = QSpinBox()
        self.indent_size.setRange(1, 8)
        self.indent_size.setValue(self.opts["indent_size"])
        self.indent_size.setSuffix(" spaces")
        form.addRow("Indent size:", self.indent_size)
        self._sync_indent_size_state(self.opts["indent_style"])

        self.max_blank_lines = QSpinBox()
        self.max_blank_lines.setRange(0, 5)
        self.max_blank_lines.setValue(self.opts["max_blank_lines"])
        self.max_blank_lines.setToolTip("Collapse runs of blank lines to at most this many")
        form.addRow("Max blank lines:", self.max_blank_lines)

        root.addLayout(form)

        # ── Toggle options ────────────────────────────────────────────────
        toggles_box = QWidget()
        toggles_box.setStyleSheet("QWidget{background:#F7F7F7;border-radius:5px;}")
        tlay = QVBoxLayout(toggles_box)
        tlay.setContentsMargins(10, 8, 10, 8)
        tlay.setSpacing(4)

        def _chk(label, key, tip=""):
            cb = QCheckBox(label)
            cb.setChecked(self.opts[key])
            cb.setToolTip(tip)
            tlay.addWidget(cb)
            return cb

        self.chk_ops = _chk("Space around operators ( == ~= <= >= .. )", "space_operators")
        self.chk_comma = _chk("Space after commas", "space_after_comma")
        self.chk_trail = _chk("Strip trailing whitespace", "trailing_whitespace")
        self.chk_norm = _chk(
            "Normalize minimum indent to zero",
            "normalize_min_indent",
            "Shift whole block left so the shallowest line has no leading spaces",
        )
        self.chk_semi = _chk("Remove standalone semicolons", "semicolon_removal")
        self.chk_nl_end = _chk("Blank line before 'end'", "newline_before_end")
        self.chk_align = _chk("Align consecutive local assignments ( = )", "align_assignments")

        root.addWidget(toggles_box)

        # ── Shape Mode ────────────────────────────────────────────────────
        sep1 = QWidget()
        sep1.setFixedHeight(1)
        sep1.setStyleSheet("background-color:#CCCCCC;")
        root.addWidget(sep1)

        shape_header = QHBoxLayout()
        self.chk_shape = QCheckBox("🎨  Shape Mode  —  reflow code tokens into a silhouette")
        self.chk_shape.setStyleSheet("font-weight:bold; color:#C00080;")
        self.chk_shape.setChecked(self.opts.get("shape_mode", False))
        self.chk_shape.stateChanged.connect(self._toggle_shape_panel)
        shape_header.addWidget(self.chk_shape)
        root.addLayout(shape_header)

        # Shape options panel (shown/hidden)
        self._shape_panel = QWidget()
        sp_lay = QVBoxLayout(self._shape_panel)
        sp_lay.setContentsMargins(12, 4, 12, 4)
        sp_lay.setSpacing(6)

        shape_pick_row = QHBoxLayout()
        shape_pick_row.addWidget(QLabel("Shape:"))
        self.shape_combo = QComboBox()
        self.shape_combo.addItems(list(self.SHAPES.keys()))
        self.shape_combo.setCurrentText(self.opts.get("shape_name", "Among Us"))
        self.shape_combo.currentTextChanged.connect(self._on_shape_changed)
        shape_pick_row.addWidget(self.shape_combo)

        shape_pick_row.addWidget(QLabel("  Width:"))
        self.shape_width = QSpinBox()
        self.shape_width.setRange(40, 300)
        self.shape_width.setValue(self.opts.get("shape_width", 120))
        self.shape_width.setSuffix(" chars")
        shape_pick_row.addWidget(self.shape_width)
        shape_pick_row.addStretch()
        sp_lay.addLayout(shape_pick_row)

        # Preview label
        self._preview_label = QLabel()
        self._preview_label.setFont(QFont("Consolas", 7))
        self._preview_label.setStyleSheet(
            "background:#1a1a1a; color:#00FF88; padding:6px; border-radius:4px;"
        )
        self._preview_label.setWordWrap(False)
        self._preview_label.setTextFormat(Qt.TextFormat.PlainText)
        sp_lay.addWidget(self._preview_label)

        # Custom shape input
        self._custom_label = QLabel("Paste your ASCII art below (use any non-space char for filled cells):")
        sp_lay.addWidget(self._custom_label)
        self._custom_input = QPlainTextEdit()
        self._custom_input.setFont(QFont("Consolas", 8))
        self._custom_input.setMaximumHeight(120)
        self._custom_input.setPlainText(self.opts.get("shape_custom", ""))
        self._custom_input.setPlaceholderText(
            "Example:\n" "  ###  \n" " ##### \n" "#######\n" " ##### \n" "  ###  "
        )
        sp_lay.addWidget(self._custom_input)

        root.addWidget(self._shape_panel)

        # ── Buttons ───────────────────────────────────────────────────────
        btn_row = QHBoxLayout()
        btn_reset = QPushButton("Reset Defaults")
        btn_reset.clicked.connect(self._reset_defaults)
        btn_ok = QPushButton("Format")
        btn_ok.setStyleSheet("background-color:#D6EAF8;font-weight:bold;")
        btn_cancel = QPushButton("Cancel")
        btn_ok.clicked.connect(self.accept)
        btn_cancel.clicked.connect(self.reject)
        btn_row.addWidget(btn_reset)
        btn_row.addStretch()
        btn_row.addWidget(btn_cancel)
        btn_row.addWidget(btn_ok)
        root.addLayout(btn_row)

        # Initial state
        self._on_shape_changed(self.shape_combo.currentText())
        self._toggle_shape_panel(self.chk_shape.checkState())

    # ── Shape panel helpers ───────────────────────────────────────────────
    def _toggle_shape_panel(self, state):
        self._shape_panel.setVisible(bool(state))
        self.adjustSize()

    def _on_shape_changed(self, name):
        is_custom = name == "Custom"
        self._custom_label.setVisible(is_custom)
        self._custom_input.setVisible(is_custom)
        self._update_preview()

    def _update_preview(self):
        name = self.shape_combo.currentText()
        if name == "Custom":
            lines = self._custom_input.toPlainText().split("\n")
            rows = [l for l in lines if l.strip()]
        else:
            rows = self.SHAPES.get(name, [])
        if not rows:
            self._preview_label.setText("(no shape)")
            return
        # Show a tiny preview using block chars
        preview = "\n".join(row.replace("#", "█").replace(" ", "·") for row in rows[:20])
        self._preview_label.setText(preview)

    # ── Standard helpers ──────────────────────────────────────────────────
    def _sync_indent_size_state(self, style):
        self.indent_size.setEnabled(style == "spaces")

    def _apply_preset(self, name):
        merged = dict(self.DEFAULTS)
        merged.update(self.PRESETS.get(name, {}))
        self.indent_style.setCurrentText(merged["indent_style"])
        self.indent_size.setValue(merged["indent_size"])
        self.max_blank_lines.setValue(merged["max_blank_lines"])
        self.chk_ops.setChecked(merged["space_operators"])
        self.chk_comma.setChecked(merged["space_after_comma"])
        self.chk_trail.setChecked(merged["trailing_whitespace"])
        self.chk_norm.setChecked(merged["normalize_min_indent"])
        self.chk_semi.setChecked(merged["semicolon_removal"])
        self.chk_nl_end.setChecked(merged["newline_before_end"])
        self.chk_align.setChecked(merged["align_assignments"])

    def _reset_defaults(self):
        self._apply_preset("Default")
        self.preset_combo.setCurrentText("Default")
        self.chk_shape.setChecked(False)
        self.shape_combo.setCurrentText("Among Us")
        self.shape_width.setValue(120)
        self._custom_input.setPlainText("")

    def get_options(self) -> dict:
        return {
            "indent_style": self.indent_style.currentText(),
            "indent_size": self.indent_size.value(),
            "max_blank_lines": self.max_blank_lines.value(),
            "space_operators": self.chk_ops.isChecked(),
            "space_after_comma": self.chk_comma.isChecked(),
            "trailing_whitespace": self.chk_trail.isChecked(),
            "normalize_min_indent": self.chk_norm.isChecked(),
            "semicolon_removal": self.chk_semi.isChecked(),
            "newline_before_end": self.chk_nl_end.isChecked(),
            "align_assignments": self.chk_align.isChecked(),
            "shape_mode": self.chk_shape.isChecked(),
            "shape_name": self.shape_combo.currentText(),
            "shape_custom": self._custom_input.toPlainText(),
            "shape_width": self.shape_width.value(),
        }


# --- Settings Dialog ---
class SettingsDialog(QDialog):
    # Defaults for all Monaco options
    MONACO_DEFAULTS = {
        "minimap":           True,
        "word_wrap":         True,
        "folding":           True,
        "font_ligatures":    True,
        "render_whitespace": "none",   # none | boundary | all
        "line_height":       22,
        "font_family":       "JetBrains Mono, Consolas, 'Courier New', monospace",
    }

    def __init__(self, parent=None, current_theme="Dark", current_font_size=11,
                 monaco_opts: dict = None):
        super().__init__(parent)
        self.setWindowTitle("Settings")
        self.setModal(True)
        self.setMinimumWidth(480)

        self._opts = dict(self.MONACO_DEFAULTS)
        if monaco_opts:
            self._opts.update(monaco_opts)

        root = QVBoxLayout(self)
        root.setSpacing(10)

        # ── Section header helper ─────────────────────────────────────────────
        def _section(text):
            lbl = QLabel(text)
            lbl.setStyleSheet(
                "font-weight: 700; font-size: 9pt; letter-spacing: 0.06em;"
                "color: #888; text-transform: uppercase; padding-top: 6px;"
            )
            return lbl

        # ── App section ───────────────────────────────────────────────────────
        root.addWidget(_section("Application"))
        app_form = QFormLayout()
        app_form.setHorizontalSpacing(16)
        app_form.setVerticalSpacing(6)

        self.font_size = QSpinBox()
        self.font_size.setRange(8, 28)
        self.font_size.setValue(current_font_size)
        self.font_size.setSuffix(" pt")
        app_form.addRow("Editor font size:", self.font_size)

        self.theme = QComboBox()
        self.theme.addItems(["Dark", "Light"])
        self.theme.setCurrentText(current_theme)
        app_form.addRow("UI theme:", self.theme)

        root.addLayout(app_form)

        # ── Monaco section ────────────────────────────────────────────────────
        sep = QWidget(); sep.setFixedHeight(1)
        sep.setStyleSheet("background:#444;")
        root.addWidget(sep)
        root.addWidget(_section("Monaco Editor"))

        mono_form = QFormLayout()
        mono_form.setHorizontalSpacing(16)
        mono_form.setVerticalSpacing(6)

        self.font_family = QLineEdit(self._opts["font_family"])
        self.font_family.setPlaceholderText("e.g. JetBrains Mono, Consolas")
        mono_form.addRow("Font family:", self.font_family)

        self.line_height = QSpinBox()
        self.line_height.setRange(14, 48)
        self.line_height.setValue(self._opts["line_height"])
        self.line_height.setSuffix(" px")
        mono_form.addRow("Line height:", self.line_height)

        self.render_ws = QComboBox()
        self.render_ws.addItems(["none", "boundary", "all"])
        self.render_ws.setCurrentText(self._opts["render_whitespace"])
        mono_form.addRow("Render whitespace:", self.render_ws)

        root.addLayout(mono_form)

        # ── Toggle row ────────────────────────────────────────────────────────
        toggle_box = QWidget()
        toggle_box.setStyleSheet("QWidget{background:rgba(128,128,128,0.08);border-radius:5px;}")
        tlay = QVBoxLayout(toggle_box)
        tlay.setContentsMargins(10, 8, 10, 8)
        tlay.setSpacing(4)

        def _chk(label, key, tip=""):
            cb = QCheckBox(label)
            cb.setChecked(bool(self._opts.get(key, True)))
            if tip: cb.setToolTip(tip)
            tlay.addWidget(cb)
            return cb

        self.chk_minimap    = _chk("Minimap",          "minimap",        "Show code overview on the right")
        self.chk_wordwrap   = _chk("Word wrap",         "word_wrap",      "Wrap long lines instead of scrolling")
        self.chk_folding    = _chk("Code folding",      "folding",        "Enable collapsible regions")
        self.chk_ligatures  = _chk("Font ligatures",    "font_ligatures", "Render → == != as combined glyphs")

        root.addWidget(toggle_box)

        # ── Buttons ───────────────────────────────────────────────────────────
        sep2 = QWidget(); sep2.setFixedHeight(1)
        sep2.setStyleSheet("background:#444;")
        root.addWidget(sep2)

        btn_row = QHBoxLayout()
        btn_reset = QPushButton("Reset Defaults")
        btn_reset.clicked.connect(self._reset)
        btn_ok = QPushButton("Apply")
        btn_ok.setStyleSheet("font-weight:bold;")
        btn_cancel = QPushButton("Cancel")
        btn_ok.clicked.connect(self.accept)
        btn_cancel.clicked.connect(self.reject)
        btn_row.addWidget(btn_reset)
        btn_row.addStretch()
        btn_row.addWidget(btn_cancel)
        btn_row.addWidget(btn_ok)
        root.addLayout(btn_row)

    def _reset(self):
        d = self.MONACO_DEFAULTS
        self.chk_minimap.setChecked(d["minimap"])
        self.chk_wordwrap.setChecked(d["word_wrap"])
        self.chk_folding.setChecked(d["folding"])
        self.chk_ligatures.setChecked(d["font_ligatures"])
        self.render_ws.setCurrentText(d["render_whitespace"])
        self.line_height.setValue(d["line_height"])
        self.font_family.setText(d["font_family"])

    def get_monaco_opts(self) -> dict:
        return {
            "minimap":           self.chk_minimap.isChecked(),
            "word_wrap":         self.chk_wordwrap.isChecked(),
            "folding":           self.chk_folding.isChecked(),
            "font_ligatures":    self.chk_ligatures.isChecked(),
            "render_whitespace": self.render_ws.currentText(),
            "line_height":       self.line_height.value(),
            "font_family":       self.font_family.text().strip(),
        }


# --- Find & Replace Dialog ---
class FindReplaceDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Find & Replace")
        self.setModal(False)
        self.setMinimumWidth(450)

        layout = QVBoxLayout()

        # Find section
        find_layout = QHBoxLayout()
        find_label = QLabel("Find:")
        find_label.setMinimumWidth(60)
        self.find_input = QTextEdit()
        self.find_input.setMaximumHeight(30)
        find_layout.addWidget(find_label)
        find_layout.addWidget(self.find_input)
        layout.addLayout(find_layout)

        # Replace section
        replace_layout = QHBoxLayout()
        replace_label = QLabel("Replace:")
        replace_label.setMinimumWidth(60)
        self.replace_input = QTextEdit()
        self.replace_input.setMaximumHeight(30)
        replace_layout.addWidget(replace_label)
        replace_layout.addWidget(self.replace_input)
        layout.addLayout(replace_layout)

        # Options
        options_layout = QHBoxLayout()
        self.case_sensitive = QCheckBox("Case Sensitive")
        self.whole_word = QCheckBox("Whole Words")
        options_layout.addWidget(self.case_sensitive)
        options_layout.addWidget(self.whole_word)
        options_layout.addStretch()
        layout.addLayout(options_layout)

        # Buttons
        btn_layout = QHBoxLayout()

        self.btn_find_next = QPushButton("Find Next")
        self.btn_find_prev = QPushButton("Find Previous")
        self.btn_replace = QPushButton("Replace")
        self.btn_replace_all = QPushButton("Replace All")
        btn_close = QPushButton("Close")

        btn_close.clicked.connect(self.close)

        btn_layout.addWidget(self.btn_find_next)
        btn_layout.addWidget(self.btn_find_prev)
        btn_layout.addWidget(self.btn_replace)
        btn_layout.addWidget(self.btn_replace_all)
        btn_layout.addStretch()
        btn_layout.addWidget(btn_close)

        layout.addLayout(btn_layout)

        # Status label
        self.status_label = QLabel("")
        self.status_label.setStyleSheet("color: #666666; font-size: 9pt;")
        layout.addWidget(self.status_label)

        self.setLayout(layout)


# --- Obfuscator Dialog ---
class MonacoEditor(QWebEngineView):
    """
    QWebEngineView wrapper that hosts Monaco.html.
    Provides synchronous get_text() / set_text() via a blocking QEventLoop,
    plus async set_text_async() for fire-and-forget writes.
    Also carries an optional .file_path attribute just like the old CodeEditor.
    """

    # Path to Monaco.html — works both normally and inside a PyInstaller bundle.
    @staticmethod
    def _base_dir():
        if getattr(sys, "frozen", False):
            return sys._MEIPASS
        return os.path.dirname(os.path.abspath(__file__))

    @property
    def MONACO_HTML(self):
        return os.path.join(self._base_dir(), "Monaco.html")

    def __init__(self, parent=None):
        super().__init__(parent)
        self.file_path = None  # mirrors old CodeEditor.file_path
        self._ready = False  # True once Monaco JS has initialised

        # Allow local file access so Monaco can load its VS files
        settings = self.settings()
        settings.setAttribute(QWebEngineSettings.WebAttribute.LocalContentCanAccessRemoteUrls, True)
        settings.setAttribute(QWebEngineSettings.WebAttribute.JavascriptEnabled, True)

        self.loadFinished.connect(self._on_load_finished)

        if os.path.exists(self.MONACO_HTML):
            self.load(QUrl.fromLocalFile(self.MONACO_HTML))
        else:
            # Fallback: blank page with a warning so the user knows what's wrong
            self.setHtml(
                "<body style='background:#1e1e1e;color:#f44;font-family:Consolas'>"
                "<h3>Monaco.html not found</h3>"
                f"<p>Expected: {self.MONACO_HTML}</p></body>"
            )

    def _on_load_finished(self, ok):
        # Give Monaco's require() a moment to finish registering globals
        QTimer.singleShot(300, lambda: setattr(self, "_ready", True))

    # ── public API ──────────────────────────────────────────────────────────

    def get_text(self) -> str:
        """Synchronously retrieve the editor contents."""
        if not self._ready:
            return ""
        result = [""]
        loop = QEventLoop()

        def _cb(val):
            # runJavaScript returns the JS value; GetText() returns a plain string
            result[0] = val if isinstance(val, str) else ""
            loop.quit()

        self.page().runJavaScript("GetText()", _cb)
        loop.exec()
        return result[0]

    def set_text(self, text: str):
        """Synchronously set the editor contents."""
        if not self._ready:
            # Queue for after ready
            QTimer.singleShot(400, lambda: self.set_text(text))
            return
        escaped = text.replace("\\", "\\\\").replace("`", "\\`").replace("$", "\\$")
        self.page().runJavaScript(f"SetText(`{escaped}`)")

    def set_text_async(self, text: str):
        """Fire-and-forget version of set_text (no event-loop spin)."""
        self.set_text(text)

    def set_monaco_theme(self, theme_name: str):
        """
        Map LuaBox theme names to Monaco theme names and apply.
        Dark  → PDark  (the rich PDark theme already in Monaco.html)
        Light → net-theme-light
        """
        mapping = {"Dark": "PDark", "Light": "net-theme-light"}
        monaco_theme = mapping.get(theme_name, "PDark")
        if self._ready:
            self.page().runJavaScript(f"SetTheme('{monaco_theme}')")
        else:
            QTimer.singleShot(400, lambda: self.page().runJavaScript(f"SetTheme('{monaco_theme}')"))

    def set_font_size(self, size: int):
        if self._ready:
            self.page().runJavaScript(f"SwitchFontSize({size})")

    def _js(self, code: str):
        """Fire-and-forget JS — queues until ready."""
        if self._ready:
            self.page().runJavaScript(code)
        else:
            QTimer.singleShot(500, lambda: self.page().runJavaScript(code))

    def apply_monaco_opts(self, opts: dict):
        """Push a full Monaco options dict to the live editor."""
        if not opts:
            return
        mm   = "true" if opts.get("minimap", True)        else "false"
        ww   = '"on"' if opts.get("word_wrap", True)      else '"off"'
        fold = "true" if opts.get("folding", True)        else "false"
        lig  = "true" if opts.get("font_ligatures", True) else "false"
        rws  = opts.get("render_whitespace", "none")
        lh   = int(opts.get("line_height", 22))
        ff   = opts.get("font_family", "Consolas").replace("\\", "\\\\").replace("'", "\\'")
        js = f"""
editor.updateOptions({{
    minimap: {{ enabled: {mm} }},
    wordWrap: {ww},
    folding: {fold},
    fontLigatures: {lig},
    renderWhitespace: '{rws}',
    lineHeight: {lh},
    fontFamily: '{ff}',
}});
"""
        self._js(js)

    def setup_cursor_callback(self, callback):
        """
        Wire up Monaco's onDidChangeCursorPosition to call callback(line, col).
        callback receives two ints and is invoked via a JS→Python bridge using
        a trivial polling trick: we store the cursor in a JS global and poll it
        from Python every 300 ms (avoids needing a full Qt channel setup).
        """
        js_setup = """
window._luabox_cursor = {line: 1, col: 1};
editor.onDidChangeCursorPosition(function(e) {
    window._luabox_cursor = {line: e.position.lineNumber, col: e.position.column};
});
"""
        if self._ready:
            self.page().runJavaScript(js_setup)
        else:
            QTimer.singleShot(600, lambda: self.page().runJavaScript(js_setup))

        self._cursor_timer = QTimer(self)
        self._cursor_timer.setInterval(300)
        self._cursor_timer.timeout.connect(lambda: self._poll_cursor(callback))
        self._cursor_timer.start()

    def _poll_cursor(self, callback):
        if not self._ready:
            return
        self.page().runJavaScript(
            "window._luabox_cursor || {line:1,col:1}",
            lambda v: callback(v.get("line", 1), v.get("col", 1)) if isinstance(v, dict) else None
        )

    def load_roblox_intellisense(self):
        """Push Roblox API completions into Monaco's suggestion provider."""
        # Comprehensive Roblox/Luau globals — snippets grouped by category
        snippets = [
            # ── Services ──────────────────────────────────────────────────────
            ("Module", "Players",           "Players",           "game:GetService(\"Players\")"),
            ("Module", "RunService",        "RunService",        "game:GetService(\"RunService\")"),
            ("Module", "UserInputService",  "UserInputService",  "game:GetService(\"UserInputService\")"),
            ("Module", "TweenService",      "TweenService",      "game:GetService(\"TweenService\")"),
            ("Module", "HttpService",       "HttpService",       "game:GetService(\"HttpService\")"),
            ("Module", "ReplicatedStorage", "ReplicatedStorage", "game:GetService(\"ReplicatedStorage\")"),
            ("Module", "ServerStorage",     "ServerStorage",     "game:GetService(\"ServerStorage\")"),
            ("Module", "CoreGui",           "CoreGui",           "game:GetService(\"CoreGui\")"),
            ("Module", "Lighting",          "Lighting",          "game:GetService(\"Lighting\")"),
            ("Module", "PathfindingService","PathfindingService","game:GetService(\"PathfindingService\")"),
            ("Module", "SoundService",      "SoundService",      "game:GetService(\"SoundService\")"),
            ("Module", "MarketplaceService","MarketplaceService","game:GetService(\"MarketplaceService\")"),
            ("Module", "PhysicsService",    "PhysicsService",    "game:GetService(\"PhysicsService\")"),
            ("Module", "CollectionService", "CollectionService", "game:GetService(\"CollectionService\")"),
            ("Module", "DataStoreService",  "DataStoreService",  "game:GetService(\"DataStoreService\")"),
            # ── task library ──────────────────────────────────────────────────
            ("Function", "task.wait",    "task.wait",    "task.wait(${1:seconds})"),
            ("Function", "task.spawn",   "task.spawn",   "task.spawn(${1:function}\n\t$0\nend)"),
            ("Function", "task.defer",   "task.defer",   "task.defer(${1:function}\n\t$0\nend)"),
            ("Function", "task.delay",   "task.delay",   "task.delay(${1:seconds}, ${2:function}\n\t$0\nend)"),
            ("Function", "task.cancel",  "task.cancel",  "task.cancel(${1:thread})"),
            ("Function", "task.desynchronize", "task.desynchronize", "task.desynchronize()"),
            ("Function", "task.synchronize",   "task.synchronize",   "task.synchronize()"),
            # ── Instance ──────────────────────────────────────────────────────
            ("Function", "Instance.new",        "Instance.new",        "Instance.new(\"${1:ClassName}\")"),
            ("Function", "inst:FindFirstChild", ":FindFirstChild",     ":FindFirstChild(\"${1:name}\")"),
            ("Function", "inst:WaitForChild",   ":WaitForChild",       ":WaitForChild(\"${1:name}\")"),
            ("Function", "inst:FindFirstChildOfClass", ":FindFirstChildOfClass", ":FindFirstChildOfClass(\"${1:ClassName}\")"),
            ("Function", "inst:FindFirstAncestorOfClass", ":FindFirstAncestorOfClass", ":FindFirstAncestorOfClass(\"${1:ClassName}\")"),
            ("Function", "inst:GetChildren",    ":GetChildren",        ":GetChildren()"),
            ("Function", "inst:GetDescendants", ":GetDescendants",     ":GetDescendants()"),
            ("Function", "inst:IsA",            ":IsA",                ":IsA(\"${1:ClassName}\")"),
            ("Function", "inst:Destroy",        ":Destroy",            ":Destroy()"),
            ("Function", "inst:Clone",          ":Clone",              ":Clone()"),
            ("Function", "inst:GetFullName",    ":GetFullName",        ":GetFullName()"),
            ("Function", "inst:ConnectEvent",   ":Connect",            ":Connect(function(${1})\n\t$0\nend)"),
            ("Function", "inst:Once",           ":Once",               ":Once(function(${1})\n\t$0\nend)"),
            # ── math ──────────────────────────────────────────────────────────
            ("Function", "math.clamp",   "math.clamp",   "math.clamp(${1:n}, ${2:min}, ${3:max})"),
            ("Function", "math.floor",   "math.floor",   "math.floor(${1:n})"),
            ("Function", "math.ceil",    "math.ceil",    "math.ceil(${1:n})"),
            ("Function", "math.abs",     "math.abs",     "math.abs(${1:n})"),
            ("Function", "math.sqrt",    "math.sqrt",    "math.sqrt(${1:n})"),
            ("Function", "math.random",  "math.random",  "math.random(${1:min}, ${2:max})"),
            ("Function", "math.max",     "math.max",     "math.max(${1:a}, ${2:b})"),
            ("Function", "math.min",     "math.min",     "math.min(${1:a}, ${2:b})"),
            ("Function", "math.sin",     "math.sin",     "math.sin(${1:angle})"),
            ("Function", "math.cos",     "math.cos",     "math.cos(${1:angle})"),
            ("Function", "math.atan2",   "math.atan2",   "math.atan2(${1:y}, ${2:x})"),
            ("Function", "math.pi",      "math.pi",      "math.pi"),
            ("Function", "math.huge",    "math.huge",    "math.huge"),
            # ── string ────────────────────────────────────────────────────────
            ("Function", "string.format", "string.format", "string.format(\"${1:%s}\", ${2:value})"),
            ("Function", "string.find",   "string.find",   "string.find(${1:str}, \"${2:pattern}\")"),
            ("Function", "string.match",  "string.match",  "string.match(${1:str}, \"${2:pattern}\")"),
            ("Function", "string.gmatch", "string.gmatch", "string.gmatch(${1:str}, \"${2:pattern}\")"),
            ("Function", "string.gsub",   "string.gsub",   "string.gsub(${1:str}, \"${2:pattern}\", \"${3:repl}\")"),
            ("Function", "string.sub",    "string.sub",    "string.sub(${1:str}, ${2:i}, ${3:j})"),
            ("Function", "string.len",    "string.len",    "string.len(${1:str})"),
            ("Function", "string.upper",  "string.upper",  "string.upper(${1:str})"),
            ("Function", "string.lower",  "string.lower",  "string.lower(${1:str})"),
            ("Function", "string.rep",    "string.rep",    "string.rep(${1:str}, ${2:n})"),
            ("Function", "string.byte",   "string.byte",   "string.byte(${1:str}, ${2:i})"),
            ("Function", "string.char",   "string.char",   "string.char(${1:code})"),
            ("Function", "string.split",  "string.split",  "string.split(${1:str}, \"${2:sep}\")"),
            # ── table ─────────────────────────────────────────────────────────
            ("Function", "table.insert",  "table.insert",  "table.insert(${1:tbl}, ${2:value})"),
            ("Function", "table.remove",  "table.remove",  "table.remove(${1:tbl}, ${2:pos})"),
            ("Function", "table.concat",  "table.concat",  "table.concat(${1:tbl}, \"${2:sep}\")"),
            ("Function", "table.sort",    "table.sort",    "table.sort(${1:tbl}, ${2:func})"),
            ("Function", "table.unpack",  "table.unpack",  "table.unpack(${1:tbl})"),
            ("Function", "table.find",    "table.find",    "table.find(${1:tbl}, ${2:value})"),
            ("Function", "table.move",    "table.move",    "table.move(${1:a1}, ${2:f}, ${3:e}, ${4:t}, ${5:a2})"),
            ("Function", "table.clear",   "table.clear",   "table.clear(${1:tbl})"),
            # ── Roblox datatypes ──────────────────────────────────────────────
            ("Constructor", "Vector3.new",    "Vector3.new",    "Vector3.new(${1:x}, ${2:y}, ${3:z})"),
            ("Constructor", "Vector2.new",    "Vector2.new",    "Vector2.new(${1:x}, ${2:y})"),
            ("Constructor", "CFrame.new",     "CFrame.new",     "CFrame.new(${1:x}, ${2:y}, ${3:z})"),
            ("Constructor", "Color3.new",     "Color3.new",     "Color3.new(${1:r}, ${2:g}, ${3:b})"),
            ("Constructor", "Color3.fromRGB", "Color3.fromRGB", "Color3.fromRGB(${1:r}, ${2:g}, ${3:b})"),
            ("Constructor", "UDim2.new",      "UDim2.new",      "UDim2.new(${1:xs}, ${2:xo}, ${3:ys}, ${4:yo})"),
            ("Constructor", "UDim.new",       "UDim.new",       "UDim.new(${1:scale}, ${2:offset})"),
            ("Constructor", "TweenInfo.new",  "TweenInfo.new",  "TweenInfo.new(${1:time}, Enum.EasingStyle.${2:Quad}, Enum.EasingDirection.${3:Out})"),
            ("Constructor", "Ray.new",        "Ray.new",        "Ray.new(${1:origin}, ${2:direction})"),
            ("Constructor", "BrickColor.new", "BrickColor.new", "BrickColor.new(\"${1:Bright red}\")"),
            ("Constructor", "NumberRange.new","NumberRange.new","NumberRange.new(${1:min}, ${2:max})"),
            ("Constructor", "Rect.new",       "Rect.new",       "Rect.new(${1:x0}, ${2:y0}, ${3:x1}, ${4:y1})"),
            # ── globals ───────────────────────────────────────────────────────
            ("Function", "print",         "print",         "print(${1:value})"),
            ("Function", "warn",          "warn",          "warn(${1:message})"),
            ("Function", "error",         "error",         "error(${1:message}, ${2:level})"),
            ("Function", "assert",        "assert",        "assert(${1:condition}, \"${2:message}\")"),
            ("Function", "pcall",         "pcall",         "pcall(${1:func}, ${2:...})"),
            ("Function", "xpcall",        "xpcall",        "xpcall(${1:func}, ${2:handler})"),
            ("Function", "type",          "type",          "type(${1:value})"),
            ("Function", "typeof",        "typeof",        "typeof(${1:value})"),
            ("Function", "tostring",      "tostring",      "tostring(${1:value})"),
            ("Function", "tonumber",      "tonumber",      "tonumber(${1:value})"),
            ("Function", "pairs",         "pairs",         "pairs(${1:tbl})"),
            ("Function", "ipairs",        "ipairs",        "ipairs(${1:tbl})"),
            ("Function", "next",          "next",          "next(${1:tbl}, ${2:key})"),
            ("Function", "select",        "select",        "select(${1:index}, ${2:...})"),
            ("Function", "unpack",        "unpack",        "table.unpack(${1:tbl})"),
            ("Function", "rawget",        "rawget",        "rawget(${1:tbl}, ${2:key})"),
            ("Function", "rawset",        "rawset",        "rawset(${1:tbl}, ${2:key}, ${3:value})"),
            ("Function", "rawequal",      "rawequal",      "rawequal(${1:a}, ${2:b})"),
            ("Function", "setmetatable",  "setmetatable",  "setmetatable(${1:tbl}, ${2:mt})"),
            ("Function", "getmetatable",  "getmetatable",  "getmetatable(${1:tbl})"),
            ("Function", "require",       "require",       "require(${1:module})"),
            ("Function", "loadstring",    "loadstring",    "loadstring(${1:code})"),
            # ── executor globals ──────────────────────────────────────────────
            ("Function", "getgenv",            "getgenv",            "getgenv()"),
            ("Function", "getrawmetatable",    "getrawmetatable",    "getrawmetatable(${1:obj})"),
            ("Function", "setreadonly",        "setreadonly",        "setreadonly(${1:tbl}, ${2:bool})"),
            ("Function", "newcclosure",        "newcclosure",        "newcclosure(${1:func})"),
            ("Function", "hookfunction",       "hookfunction",       "hookfunction(${1:target}, ${2:hook})"),
            ("Function", "islclosure",         "islclosure",         "islclosure(${1:func})"),
            ("Function", "iscclosure",         "iscclosure",         "iscclosure(${1:func})"),
            ("Function", "getnamecallmethod",  "getnamecallmethod",  "getnamecallmethod()"),
            ("Function", "clonefunction",      "clonefunction",      "clonefunction(${1:func})"),
            ("Function", "setidentity",        "setidentity",        "setidentity(${1:level})"),
            ("Function", "getidentity",        "getidentity",        "getidentity()"),
            ("Function", "readfile",           "readfile",           "readfile(\"${1:path}\")"),
            ("Function", "writefile",          "writefile",          "writefile(\"${1:path}\", ${2:content})"),
            ("Function", "isfile",             "isfile",             "isfile(\"${1:path}\")"),
            ("Function", "isfolder",           "isfolder",           "isfolder(\"${1:path}\")"),
            ("Function", "listfiles",          "listfiles",          "listfiles(\"${1:path}\")"),
            ("Function", "makefolder",         "makefolder",         "makefolder(\"${1:path}\")"),
            ("Function", "getgc",              "getgc",              "getgc(${1:includeTables})"),
            ("Function", "getupvalues",        "getupvalues",        "getupvalues(${1:func})"),
            ("Function", "getconstants",       "getconstants",       "getconstants(${1:func})"),
            ("Function", "getprotos",          "getprotos",          "getprotos(${1:func})"),
            ("Function", "request",            "request",            "request({\n\tUrl = \"${1:url}\",\n\tMethod = \"${2:GET}\",\n})"),
            ("Function", "http_request",       "http_request",       "http_request({\n\tUrl = \"${1:url}\",\n\tMethod = \"${2:GET}\",\n})"),
            # ── Luau keywords / snippets ───────────────────────────────────────
            ("Snippet",  "if/then/end",    "if",    "if ${1:condition} then\n\t$0\nend"),
            ("Snippet",  "if/else/end",    "ife",   "if ${1:condition} then\n\t$2\nelse\n\t$0\nend"),
            ("Snippet",  "for/do/end",     "for",   "for ${1:i} = ${2:1}, ${3:10} do\n\t$0\nend"),
            ("Snippet",  "for/in/do/end",  "fori",  "for ${1:_, v} in ipairs(${2:tbl}) do\n\t$0\nend"),
            ("Snippet",  "while/do/end",   "while", "while ${1:true} do\n\t$0\n\ttask.wait()\nend"),
            ("Snippet",  "function",       "fn",    "local function ${1:name}(${2:args})\n\t$0\nend"),
            ("Snippet",  "function method","method","function ${1:Class}:${2:method}(${3:args})\n\t$0\nend"),
            ("Snippet",  "pcall block",    "pcall", "local ok, err = pcall(function()\n\t$0\nend)\nif not ok then warn(err) end"),
            ("Snippet",  "task.spawn",     "spawn", "task.spawn(function()\n\t$0\nend)"),
            ("Snippet",  "local",          "local", "local ${1:name} = ${2:value}"),
        ]

        # Build JS calls — one AddSnippet per item
        js_lines = []
        for kind, label, insert_label, insert_text in snippets:
            # Escape for JS string
            label_esc  = label.replace("\\", "\\\\").replace("'", "\\'")
            it_esc     = insert_text.replace("\\", "\\\\").replace("`", "\\`").replace("$", "\\$") \
                                    .replace("\n", "\\n").replace("\t", "\\t")
            # For snippets use InsertAsSnippet rule
            if kind == "Snippet":
                js_lines.append(
                    f"AddSnippet('{kind}', '{label_esc}', "
                    f"{{label: '{label_esc}', insertText: `{insert_text.replace('`','\\`')}`, "
                    f"insertTextRules: 4, detail: 'Luau snippet'}});"
                )
            else:
                js_lines.append(
                    f"AddSnippet('{kind}', '{label_esc}', "
                    f"{{label: '{label_esc}', insertText: `{insert_text.replace('`','\\`')}`, "
                    f"insertTextRules: 4, detail: 'Roblox / Luau'}});"
                )

        js = "\n".join(js_lines)
        if self._ready:
            self.page().runJavaScript(js)
        else:
            QTimer.singleShot(800, lambda: self.page().runJavaScript(js))

    # ── compatibility shims so callers don't need changing ──────────────────

    def toPlainText(self) -> str:
        return self.get_text()

    def setPlainText(self, text: str):
        self.set_text(text)

    def clear(self):
        self.set_text("")

    # find() / textCursor() / setTextCursor() — these were used by the old
    # QPlainTextEdit-based find-replace; with Monaco we delegate to its
    # built-in Ctrl+H / Ctrl+F or do JS-side replacement.  We implement
    # stubs that always return False so callers degrade gracefully.
    def find(self, *args, **kwargs):
        return False

    def textCursor(self):
        return _FakeCursor()

    def setTextCursor(self, cur):
        pass

    def setFocus(self):
        super().setFocus()
        # Also give focus to the embedded page so Monaco key-events work
        self.page().runJavaScript("editor && editor.focus()")


class _FakeCursor:
    """Minimal stand-in for QTextCursor so old code doesn't crash."""

    def hasSelection(self):
        return False

    def insertText(self, t):
        pass

    def position(self):
        return 0

    def setPosition(self, p):
        pass

    def movePosition(self, *a):
        pass


# --- Text to ASCII Art Tab ---
class AsciiArtTab(QWidget):
    """
    Self-contained Text → ASCII Art panel, embedded as a left-panel tab.
    Requires pyfiglet (pip install pyfiglet).
    """

    def __init__(self, parent=None):
        super().__init__(parent)
        self._build_ui()

    def _build_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(5, 6, 5, 6)
        layout.setSpacing(5)

        if not _PYFIGLET_AVAILABLE:
            lbl = QLabel("pyfiglet not installed.\nRun: pip install pyfiglet")
            lbl.setStyleSheet("color:#f85149; font-size:9pt;")
            lbl.setWordWrap(True)
            layout.addWidget(lbl)
            layout.addStretch()
            return

        # Font picker
        font_row = QHBoxLayout()
        font_row.addWidget(QLabel("Font:"))
        self._font_combo = QComboBox()
        self._font_combo.addItems(_pyfiglet.FigletFont.getFonts())
        default = "standard"
        if default in _pyfiglet.FigletFont.getFonts():
            self._font_combo.setCurrentText(default)
        font_row.addWidget(self._font_combo, 1)
        layout.addLayout(font_row)

        # Input
        input_row = QHBoxLayout()
        self._input = QLineEdit()
        self._input.setPlaceholderText("Type text here…")
        self._input.returnPressed.connect(self._generate)
        input_row.addWidget(self._input, 1)
        btn_gen = QPushButton("Generate")
        btn_gen.setFixedWidth(70)
        btn_gen.clicked.connect(self._generate)
        input_row.addWidget(btn_gen)
        layout.addLayout(input_row)

        # Output
        self._output = QTextEdit()
        self._output.setReadOnly(True)
        self._output.setFont(QFont("Courier New", 7))
        self._output.setLineWrapMode(QTextEdit.LineWrapMode.NoWrap)
        self._output.setPlaceholderText("ASCII art appears here…")
        layout.addWidget(self._output, 1)

        # Action buttons
        btn_row = QHBoxLayout()
        btn_copy = QPushButton("Copy")
        btn_copy.clicked.connect(self._copy)
        btn_send = QPushButton("→ Editor")
        btn_send.setToolTip("Send as Lua comment block to active editor tab")
        btn_send.clicked.connect(self._send_to_editor)
        btn_clear = QPushButton("Clear")
        btn_clear.clicked.connect(self._clear)
        btn_row.addWidget(btn_copy)
        btn_row.addWidget(btn_send)
        btn_row.addWidget(btn_clear)
        layout.addLayout(btn_row)

    def _generate(self):
        if not _PYFIGLET_AVAILABLE:
            return
        text = self._input.text().strip()
        if not text:
            return
        font = self._font_combo.currentText()
        try:
            art = _pyfiglet.Figlet(font=font).renderText(text)
            self._output.setPlainText(art)
        except _pyfiglet.FontNotFound:
            self._output.setPlainText(f"-- Font '{font}' not found.")
        except Exception as e:
            self._output.setPlainText(f"-- Error: {e}")

    def _copy(self):
        text = self._output.toPlainText()
        if text:
            QApplication.clipboard().setText(text)

    def _clear(self):
        self._input.clear()
        self._output.clear()

    def _send_to_editor(self):
        """Insert ASCII art as a Lua comment block into the active Monaco editor."""
        art = self._output.toPlainText()
        if not art:
            return
        # Walk up to find the LuaIDE main window
        parent = self.parent()
        while parent and not isinstance(parent, LuaIDE):
            parent = parent.parent()
        if not parent:
            return
        editor = parent.get_current_editor()
        if not editor:
            return
        comment_block = "\n".join(f"-- {line}" for line in art.splitlines())
        existing = editor.get_text()
        sep = "\n\n" if existing.strip() else ""
        editor.set_text(existing + sep + comment_block)
        editor.setFocus()


# --- Main Application Window ---
class _BridgeSettingsDialog(QDialog):
    def __init__(self, parent=None, pipe="", auto_push=False, ext_path=""):
        super().__init__(parent)
        self.setWindowTitle("DLL Bridge Settings")
        self.setMinimumWidth(500)
        lay = QVBoxLayout(self)
        lay.setSpacing(10)

        lay.addWidget(QLabel("<b>Pipe / Socket Path</b>"))
        pr = QHBoxLayout()
        self._pipe = QLineEdit(pipe)
        self._pipe.setPlaceholderText("\\\\.\\pipe\\LuaBoxBridge  or  /tmp/luabox.sock")
        pr.addWidget(self._pipe)
        bt = QPushButton("Test")
        bt.setFixedWidth(52)
        bt.clicked.connect(self._test)
        pr.addWidget(bt)
        lay.addLayout(pr)
        self._status = QLabel("")
        self._status.setStyleSheet("font-size:9pt;")
        lay.addWidget(self._status)

        _sep = lambda: (lambda w: (w.setFixedHeight(1), w.setStyleSheet("background:#555;"), w))(QWidget())[2]
        lay.addWidget(_sep())

        self._auto = QCheckBox("Auto-push to executor on every Save (Ctrl+S)")
        self._auto.setChecked(auto_push)
        lay.addWidget(self._auto)

        lay.addWidget(_sep())
        lay.addWidget(QLabel("<b>External Edit -- Watch File</b>"))
        _nl = QLabel(
            "Watch a .lua file on disk. Any time it is saved by an external editor, LuaBox auto-pushes it to the executor."
        )
        _nl.setWordWrap(True)
        lay.addWidget(_nl)

        er = QHBoxLayout()
        self._ext = QLineEdit(ext_path)
        self._ext.setPlaceholderText("Path to .lua file to watch...")
        er.addWidget(self._ext)
        bb = QPushButton("Browse...")
        bb.setFixedWidth(70)
        bb.clicked.connect(self._browse)
        er.addWidget(bb)
        lay.addLayout(er)

        lay.addWidget(_sep())
        note = QLabel(
            "<b>DLL protocol:</b> open the pipe name above, read 4-byte LE uint32 = script length, then read that many UTF-8 bytes. Pass the string to your internal execute function."
        )
        note.setWordWrap(True)
        note.setTextFormat(Qt.TextFormat.RichText)
        lay.addWidget(note)

        br = QHBoxLayout()
        ok_btn = QPushButton("Save")
        ok_btn.clicked.connect(self.accept)
        cn_btn = QPushButton("Cancel")
        cn_btn.clicked.connect(self.reject)
        br.addStretch()
        br.addWidget(ok_btn)
        br.addWidget(cn_btn)
        lay.addLayout(br)

    def _test(self):
        pipe = self._pipe.text().strip()
        try:
            data = struct.pack("<I", 0)
            if sys.platform == "win32":
                import ctypes, ctypes.wintypes as wt

                h = ctypes.windll.kernel32.CreateFileW(pipe, 0x40000000, 0, None, 3, 0, None)
                if h == wt.HANDLE(-1).value:
                    raise OSError("Pipe not found")
                ctypes.windll.kernel32.CloseHandle(h)
            else:
                with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                    s.settimeout(1.5)
                    s.connect(pipe)
            self._status.setText("✓  Connected")
            self._status.setStyleSheet("color:#3fb950;font-size:9pt;")
        except Exception as e:
            self._status.setText(f"✗  {e}")
            self._status.setStyleSheet("color:#f85149;font-size:9pt;")

    def _browse(self):
        p, _ = QFileDialog.getOpenFileName(self, "Watch file", "", "Lua Files (*.lua *.luau);;All Files (*)")
        if p:
            self._ext.setText(p)

    def get_config(self):
        return {
            "pipe": self._pipe.text().strip(),
            "auto_push": self._auto.isChecked(),
            "ext_path": self._ext.text().strip(),
        }


class _InjectDialog(QDialog):
    """
    Pick a target process from a live list and choose the DLL to inject.
    Uses Windows PSAPI (EnumProcesses + GetModuleBaseNameW) to build the list.
    """

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Inject DLL into Process")
        self.setMinimumSize(520, 400)
        lay = QVBoxLayout(self)
        lay.setSpacing(8)

        # ── DLL path row ──────────────────────────────────────────────────────
        lay.addWidget(QLabel("<b>DLL Path</b>"))
        dll_row = QHBoxLayout()
        self._dll_edit = QLineEdit()
        self._dll_edit.setPlaceholderText("Path to LuaBoxBridge.dll ...")
        dll_row.addWidget(self._dll_edit)
        btn_browse = QPushButton("Browse...")
        btn_browse.setFixedWidth(72)
        btn_browse.clicked.connect(self._browse_dll)
        dll_row.addWidget(btn_browse)
        lay.addLayout(dll_row)

        # ── Process list ──────────────────────────────────────────────────────
        hdr = QHBoxLayout()
        hdr.addWidget(QLabel("<b>Target Process</b>"))
        hdr.addStretch()
        btn_refresh = QPushButton("Refresh")
        btn_refresh.setFixedWidth(80)
        btn_refresh.clicked.connect(self._populate)
        hdr.addWidget(btn_refresh)
        lay.addLayout(hdr)

        self._search = QLineEdit()
        self._search.setPlaceholderText("Filter by name...")
        self._search.textChanged.connect(self._filter)
        lay.addWidget(self._search)

        self._list = QTreeWidget()
        self._list.setHeaderLabels(["PID", "Process Name"])
        self._list.setColumnWidth(0, 70)
        self._list.setSortingEnabled(True)
        self._list.sortByColumn(1, Qt.SortOrder.AscendingOrder)
        self._list.itemDoubleClicked.connect(self._on_double)
        lay.addWidget(self._list)

        # ── Buttons ───────────────────────────────────────────────────────────
        btn_row = QHBoxLayout()
        btn_row.addStretch()
        self._btn_ok = QPushButton("Inject")
        self._btn_ok.setDefault(True)
        self._btn_ok.clicked.connect(self._confirm)
        btn_cancel = QPushButton("Cancel")
        btn_cancel.clicked.connect(self.reject)
        btn_row.addWidget(self._btn_ok)
        btn_row.addWidget(btn_cancel)
        lay.addLayout(btn_row)

        self._all_items: list[tuple[int, str]] = []
        self._selected_pid: int = 0
        self._populate()

    # ── internal helpers ──────────────────────────────────────────────────────

    def _browse_dll(self):
        path, _ = QFileDialog.getOpenFileName(self, "Select DLL", "", "DLL Files (*.dll);;All Files (*)")
        if path:
            self._dll_edit.setText(path)

    def _populate(self):
        self._list.clear()
        self._all_items = []
        try:
            import ctypes, ctypes.wintypes as wt

            k32 = ctypes.windll.kernel32
            psapi = ctypes.windll.psapi

            arr_size = 1024
            pid_arr = (wt.DWORD * arr_size)()
            cb_needed = wt.DWORD(0)
            psapi.EnumProcesses(pid_arr, ctypes.sizeof(pid_arr), ctypes.byref(cb_needed))
            count = cb_needed.value // ctypes.sizeof(wt.DWORD)

            PROCESS_QUERY_LIMITED = 0x1000
            PROCESS_VM_READ = 0x0010

            for i in range(count):
                pid = pid_arr[i]
                if pid == 0:
                    continue
                h = k32.OpenProcess(PROCESS_QUERY_LIMITED | PROCESS_VM_READ, False, pid)
                if not h:
                    continue
                name_buf = ctypes.create_unicode_buffer(260)
                psapi.GetModuleBaseNameW(h, None, name_buf, 260)
                k32.CloseHandle(h)
                name = name_buf.value or "<unknown>"
                self._all_items.append((pid, name))

        except Exception as e:
            QTreeWidgetItem(self._list).setText(0, f"Error: {e}")
            return

        self._all_items.sort(key=lambda x: x[1].lower())
        for pid, name in self._all_items:
            item = QTreeWidgetItem([str(pid), name])
            self._list.addTopLevelItem(item)

    def _filter(self, text: str):
        text = text.lower()
        self._list.clear()
        for pid, name in self._all_items:
            if text in name.lower() or text in str(pid):
                self._list.addTopLevelItem(QTreeWidgetItem([str(pid), name]))

    def _on_double(self, item, _col):
        self._selected_pid = int(item.text(0))
        self._confirm()

    def _confirm(self):
        item = self._list.currentItem()
        if item:
            self._selected_pid = int(item.text(0))
        if not self._selected_pid:
            QMessageBox.warning(self, "Inject", "Select a process first.")
            return
        if not self._dll_edit.text().strip():
            QMessageBox.warning(self, "Inject", "Choose a DLL to inject.")
            return
        self.accept()

    def get_selection(self) -> tuple[str, int]:
        return self._dll_edit.text().strip(), self._selected_pid


class LuaIDE(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("LuaBox v4")
        self.setGeometry(100, 100, 1400, 850)

        self.current_file = None
        self.current_directory = QDir.homePath()

        # Recent files tracking
        self.recent_files = []
        self.max_recent_files = 10
        self.load_recent_files()

        # Find & Replace dialog
        self.find_replace_dialog = None

        # Bridge state
        self._bridge_pipe = "\\\\.\\pipe\\LuaBoxBridge" if sys.platform == "win32" else "/tmp/luabox.sock"
        self._bridge_auto_push = False
        self._bridge_ext_path = ""
        self._bridge_watcher = QFileSystemWatcher(self)
        self._bridge_watcher.fileChanged.connect(self._bridge_ext_changed)

        # Script Importer tab tracking
        self._importer_tab_index = -1

        # Decompiler tab tracking
        self._decomp_tab_index = -1
        self._decomp_server_thread = None
        self._decomp_server_running = False

        # Theme state
        self._current_theme = "Dark"
        self._current_font_size = 11

        # Monaco editor options (persisted across tabs)
        self._monaco_opts = dict(SettingsDialog.MONACO_DEFAULTS)

        # Apply dark theme
        self._apply_app_stylesheet("Dark")

        # --- Menu Bar / Toolbar ---
        self._toolbar_widget = QWidget()
        self._toolbar_widget.setFixedHeight(36)
        toolbar_layout = QHBoxLayout(self._toolbar_widget)
        toolbar_layout.setContentsMargins(6, 4, 6, 4)
        toolbar_layout.setSpacing(2)

        btn_new = QPushButton("New")
        btn_new.clicked.connect(self.new_file)

        btn_open = QPushButton("Open")
        btn_open.clicked.connect(self.open_file)

        btn_save = QPushButton("Save")
        btn_save.clicked.connect(self.save_file)

        # Separator helper — stored so we can restyle on theme change
        self._separators = []

        def create_separator():
            sep = QWidget()
            sep.setFixedWidth(1)
            sep.setFixedHeight(22)
            self._separators.append(sep)
            return sep

        self._btn_settings = QPushButton("Settings")
        self._btn_settings.clicked.connect(self.show_settings)

        self._btn_format = QPushButton("Format Code")
        self._btn_format.clicked.connect(self.format_current_code)
        self._btn_format.setToolTip("Format / Beautify Lua code  (Ctrl+Shift+F)")
        from PyQt6.QtGui import QShortcut, QKeySequence

        QShortcut(QKeySequence("Ctrl+Shift+F"), self).activated.connect(self.format_current_code)
        QShortcut(QKeySequence("Ctrl+Return"), self).activated.connect(self._bridge_push)

        self._btn_stylua = QPushButton("StyLua")
        self._btn_stylua.clicked.connect(self.format_with_stylua)
        self._btn_stylua.setToolTip(
            "Format with stylua.exe  (Ctrl+Alt+F)" "\nExpects stylua.exe in the same folder as LuaBox.pyw"
        )
        QShortcut(QKeySequence("Ctrl+Alt+F"), self).activated.connect(self.format_with_stylua)

        btn_strip = QPushButton("Strip Comments")
        btn_strip.clicked.connect(self.remove_comments)

        btn_find_replace = QPushButton("Find / Replace")
        btn_find_replace.clicked.connect(self.show_find_replace)

        # Recent files dropdown button
        self.btn_recent = QPushButton("Recent  v")
        self.btn_recent.clicked.connect(self.show_recent_files_menu)

        toolbar_layout.addWidget(btn_new)
        toolbar_layout.addWidget(btn_open)
        toolbar_layout.addWidget(btn_save)
        toolbar_layout.addWidget(self.btn_recent)
        toolbar_layout.addWidget(create_separator())
        toolbar_layout.addWidget(btn_find_replace)
        toolbar_layout.addWidget(create_separator())
        toolbar_layout.addWidget(self._btn_settings)
        toolbar_layout.addWidget(create_separator())
        toolbar_layout.addWidget(btn_strip)
        toolbar_layout.addWidget(self._btn_format)
        toolbar_layout.addWidget(self._btn_stylua)
        toolbar_layout.addWidget(create_separator())
        self._btn_obfuscate = QPushButton("Obfuscate")
        self._btn_obfuscate.setToolTip("Open ZukaTech Obfuscator panel  (Ctrl+Shift+O)")
        self._btn_obfuscate.clicked.connect(self.show_obfuscator_tab)
        QShortcut(QKeySequence("Ctrl+Shift+O"), self).activated.connect(self.show_obfuscator_tab)
        toolbar_layout.addWidget(self._btn_obfuscate)
        toolbar_layout.addWidget(create_separator())
        self._btn_lint = QPushButton("Lint")
        self._btn_lint.setToolTip("Analyze current script for issues (Ctrl+Shift+L)")
        self._btn_lint.clicked.connect(self.run_lint)
        QShortcut(QKeySequence("Ctrl+Shift+L"), self).activated.connect(self.run_lint)
        toolbar_layout.addWidget(self._btn_lint)
        toolbar_layout.addWidget(create_separator())
        self._btn_bridge_push = QPushButton("Push Script")
        self._btn_bridge_push.setToolTip("Send current script to executor via pipe/socket  (Ctrl+Return)")
        self._btn_bridge_push.clicked.connect(self._bridge_push)
        toolbar_layout.addWidget(self._btn_bridge_push)
        self._btn_bridge_cfg = QPushButton("Bridge")
        self._btn_bridge_cfg.setToolTip("Configure DLL bridge / external edit settings")
        self._btn_bridge_cfg.clicked.connect(self._bridge_show_settings)
        toolbar_layout.addWidget(self._btn_bridge_cfg)
        self._btn_inject = QPushButton("Inject DLL")
        self._btn_inject.setToolTip("Inject LuaBoxBridge.dll into a running process")
        self._btn_inject.clicked.connect(self._bridge_inject_dialog)
        toolbar_layout.addWidget(self._btn_inject)
        self._lbl_bridge_status = QLabel("●")
        self._lbl_bridge_status.setToolTip("Bridge: not connected")
        self._lbl_bridge_status.setStyleSheet("color: #888; font-size: 10pt;")
        self._btn_importer = QPushButton("Script Importer")
        self._btn_importer.clicked.connect(self.open_script_importer)
        toolbar_layout.addWidget(self._lbl_bridge_status)
        toolbar_layout.addWidget(self._btn_importer)
        self._btn_decomp = QPushButton("Decompiler")
        self._btn_decomp.setToolTip("Open zukv3 external decompiler tab (receives from in-game)")
        self._btn_decomp.clicked.connect(self.open_decompiler_tab)
        toolbar_layout.addWidget(self._btn_decomp)
        toolbar_layout.addStretch()

        # ── Central editor widget (pure tab area, no splitters) ───────────────
        editor_widget = QWidget()
        editor_layout = QVBoxLayout(editor_widget)
        editor_layout.setContentsMargins(0, 0, 0, 0)
        editor_layout.setSpacing(0)
        editor_layout.addWidget(self._toolbar_widget)

        self.tab_widget = QTabWidget()
        self.tab_widget.setTabsClosable(True)
        self.tab_widget.tabCloseRequested.connect(self.close_tab)
        self.create_new_tab("new")
        editor_layout.addWidget(self.tab_widget)
        self.setCentralWidget(editor_widget)

        # ── QDockWidget helper ────────────────────────────────────────────────
        from PyQt6.QtWidgets import QDockWidget
        AllDock = (
            Qt.DockWidgetArea.LeftDockWidgetArea
            | Qt.DockWidgetArea.RightDockWidgetArea
            | Qt.DockWidgetArea.TopDockWidgetArea
            | Qt.DockWidgetArea.BottomDockWidgetArea
        )

        def _make_dock(title, widget, area, min_w=None, min_h=None):
            dock = QDockWidget(title, self)
            dock.setAllowedAreas(AllDock)
            dock.setFeatures(
                QDockWidget.DockWidgetFeature.DockWidgetMovable
                | QDockWidget.DockWidgetFeature.DockWidgetFloatable
                | QDockWidget.DockWidgetFeature.DockWidgetClosable
            )
            dock.setWidget(widget)
            if min_w:
                widget.setMinimumWidth(min_w)
            if min_h:
                widget.setMinimumHeight(min_h)
            self.addDockWidget(area, dock)
            return dock

        # ── Explorer dock ─────────────────────────────────────────────────────
        self._left_panel_tabs = QTabWidget()

        # Files tab
        explorer_tab = QWidget()
        explorer_tab_layout = QVBoxLayout(explorer_tab)
        explorer_tab_layout.setContentsMargins(0, 0, 0, 0)

        self._explorer_header = QWidget()
        self._explorer_header.setMaximumHeight(30)
        explorer_header_layout = QHBoxLayout(self._explorer_header)
        explorer_header_layout.setContentsMargins(5, 2, 5, 2)
        self._explorer_label = QLabel("EXPLORER")
        self._explorer_label.setStyleSheet("font-weight: bold;")
        btn_browse = QPushButton("...")
        btn_browse.setMaximumWidth(28)
        btn_browse.setToolTip("Browse for directory")
        btn_browse.clicked.connect(self.browse_directory)
        btn_refresh = QPushButton("R")
        btn_refresh.setMaximumWidth(28)
        btn_refresh.setToolTip("Refresh explorer")
        btn_refresh.clicked.connect(self.refresh_explorer)
        explorer_header_layout.addWidget(self._explorer_label)
        explorer_header_layout.addStretch()
        explorer_header_layout.addWidget(btn_browse)
        explorer_header_layout.addWidget(btn_refresh)

        self.file_tree = QTreeWidget()
        self.file_tree.setHeaderLabels(["Name", "Size"])
        self.file_tree.setColumnWidth(0, 150)
        self.file_tree.itemDoubleClicked.connect(self.tree_item_double_clicked)
        self.file_tree.itemExpanded.connect(self.tree_item_expanded)
        self.file_tree.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        self.file_tree.customContextMenuRequested.connect(self.show_tree_context_menu)
        explorer_tab_layout.addWidget(self._explorer_header)
        explorer_tab_layout.addWidget(self.file_tree)

        # Templates tab
        templates_tab = QWidget()
        templates_tab_layout = QVBoxLayout(templates_tab)
        templates_tab_layout.setContentsMargins(5, 5, 5, 5)
        self.templates_tree = QTreeWidget()
        self.templates_tree.setHeaderLabel("Audit Templates")
        self.templates_tree.itemDoubleClicked.connect(self.insert_template)
        self.populate_templates()
        templates_tab_layout.addWidget(self.templates_tree)

        # Obfuscator tab
        obf_tab = QWidget()
        obf_tab_layout = QVBoxLayout(obf_tab)
        obf_tab_layout.setContentsMargins(5, 6, 5, 6)
        obf_tab_layout.setSpacing(6)
        obf_tab_layout.addWidget(QLabel("lua.exe:"))
        _lua_row = QHBoxLayout()
        self._obf_lua_path = QLineEdit()
        self._obf_lua_path.setPlaceholderText("Path to lua.exe ...")
        _lua_row.addWidget(self._obf_lua_path)
        _lua_browse = QPushButton("...")
        _lua_browse.setFixedWidth(28)
        _lua_browse.clicked.connect(self._obf_browse_lua)
        _lua_row.addWidget(_lua_browse)
        obf_tab_layout.addLayout(_lua_row)
        obf_tab_layout.addWidget(QLabel("main.lua (bundled):"))
        _script_row = QHBoxLayout()
        self._obf_script_path = QLineEdit()
        self._obf_script_path.setPlaceholderText("Path to main.lua ...")
        _script_row.addWidget(self._obf_script_path)
        _script_browse = QPushButton("...")
        _script_browse.setFixedWidth(28)
        _script_browse.clicked.connect(self._obf_browse_script)
        _script_row.addWidget(_script_browse)
        obf_tab_layout.addLayout(_script_row)
        obf_tab_layout.addWidget(QLabel("Preset:"))
        self._obf_preset = QComboBox()
        self._obf_preset.addItems(["Luraph", "byte", "Hercules"])
        obf_tab_layout.addWidget(self._obf_preset)
        self._obf_load_result = QCheckBox("Open result in new editor tab")
        self._obf_load_result.setChecked(True)
        obf_tab_layout.addWidget(self._obf_load_result)
        self._obf_run_btn = QPushButton("Run Obfuscator")
        self._obf_run_btn.setStyleSheet("font-weight:bold; padding:5px;")
        self._obf_run_btn.clicked.connect(self.run_obfuscator)
        obf_tab_layout.addWidget(self._obf_run_btn)
        self._obf_status = QLabel("")
        self._obf_status.setWordWrap(True)
        self._obf_status.setStyleSheet("font-size:8pt; color:#888;")
        obf_tab_layout.addWidget(self._obf_status)
        obf_tab_layout.addStretch()

        self._left_panel_tabs.addTab(explorer_tab, "Files")
        self._left_panel_tabs.addTab(templates_tab, "Templates")
        self._left_panel_tabs.addTab(obf_tab, "Obfusc")
        self._ascii_tab = AsciiArtTab(self)
        self._left_panel_tabs.addTab(self._ascii_tab, "ASCII")

        self._dock_explorer = _make_dock(
            "Explorer", self._left_panel_tabs,
            Qt.DockWidgetArea.LeftDockWidgetArea, min_w=220
        )
        self._dock_explorer.setMinimumWidth(180)

        # ── Lint dock ─────────────────────────────────────────────────────────
        self._lint_container = QWidget()
        lint_layout = QVBoxLayout(self._lint_container)
        lint_layout.setContentsMargins(0, 0, 0, 0)
        lint_layout.setSpacing(0)

        lint_header = QWidget()
        lint_header.setFixedHeight(28)
        lh_layout = QHBoxLayout(lint_header)
        lh_layout.setContentsMargins(6, 0, 6, 0)
        lh_layout.setSpacing(6)
        self._lint_title_lbl = QLabel("  LINT RESULTS")
        self._lint_title_lbl.setStyleSheet("font-weight:bold;font-size:9pt;letter-spacing:1px;")
        lh_layout.addWidget(self._lint_title_lbl)
        self._lint_stats_lbl = QLabel("")
        self._lint_stats_lbl.setStyleSheet("font-size:9pt;")
        lh_layout.addWidget(self._lint_stats_lbl)
        lh_layout.addStretch()
        self._lint_filter_combo = QComboBox()
        self._lint_filter_combo.addItems(["All", "Fatal", "Warn", "Info"])
        self._lint_filter_combo.setFixedWidth(80)
        self._lint_filter_combo.currentTextChanged.connect(self._lint_apply_filter)
        lh_layout.addWidget(self._lint_filter_combo)
        lint_layout.addWidget(lint_header)

        self._lint_table = QTreeWidget()
        self._lint_table.setHeaderLabels(["Sev", "Line", "Title", "Description", "Code"])
        self._lint_table.setColumnWidth(0, 52)
        self._lint_table.setColumnWidth(1, 46)
        self._lint_table.setColumnWidth(2, 200)
        self._lint_table.setColumnWidth(3, 340)
        self._lint_table.setColumnWidth(4, 280)
        self._lint_table.setRootIsDecorated(False)
        self._lint_table.setSortingEnabled(True)
        self._lint_table.itemClicked.connect(self._lint_jump_to_line)
        lint_layout.addWidget(self._lint_table)

        self._lint_all_issues = []
        self._dock_lint = _make_dock(
            "Lint Results", self._lint_container,
            Qt.DockWidgetArea.BottomDockWidgetArea, min_h=160
        )
        self._dock_lint.hide()

        # ── Terminal dock ─────────────────────────────────────────────────────
        term_container = QWidget()
        term_layout = QVBoxLayout(term_container)
        term_layout.setContentsMargins(0, 0, 0, 0)
        term_layout.setSpacing(0)

        term_header = QWidget()
        term_header.setFixedHeight(28)
        th_layout = QHBoxLayout(term_header)
        th_layout.setContentsMargins(6, 0, 6, 0)
        th_layout.setSpacing(6)
        self._term_title_lbl = QLabel("  TERMINAL")
        self._term_title_lbl.setStyleSheet("font-weight:bold;font-size:9pt;letter-spacing:1px;")
        th_layout.addWidget(self._term_title_lbl)
        th_layout.addStretch()
        self._term_cwd_label = QLabel("")
        self._term_cwd_label.setStyleSheet("font-size:8pt;")
        th_layout.addWidget(self._term_cwd_label)
        btn_term_clear = QPushButton("Clear")
        btn_term_clear.setFixedSize(48, 20)
        btn_term_clear.clicked.connect(self._term_clear)
        th_layout.addWidget(btn_term_clear)
        btn_term_kill = QPushButton("Kill")
        btn_term_kill.setFixedSize(38, 20)
        btn_term_kill.clicked.connect(self._term_kill)
        th_layout.addWidget(btn_term_kill)
        term_layout.addWidget(term_header)

        from PyQt6.QtGui import QFont as _QFont
        self._term_output = QPlainTextEdit()
        self._term_output.setReadOnly(True)
        self._term_output.setMaximumBlockCount(2000)
        self._term_output.setFont(_QFont("Consolas", 10))
        term_layout.addWidget(self._term_output)

        input_row = QWidget()
        in_layout = QHBoxLayout(input_row)
        in_layout.setContentsMargins(4, 2, 4, 2)
        in_layout.setSpacing(4)
        self._term_prompt = QLabel("$")
        self._term_prompt.setFixedWidth(14)
        self._term_prompt.setStyleSheet("font-family:Consolas;font-size:10pt;font-weight:bold;")
        in_layout.addWidget(self._term_prompt)
        self._term_input = QLineEdit()
        self._term_input.setFont(_QFont("Consolas", 10))
        self._term_input.setPlaceholderText("Enter command...")
        self._term_input.returnPressed.connect(self._term_run)
        in_layout.addWidget(self._term_input)
        btn_run = QPushButton("Run")
        btn_run.setFixedWidth(42)
        btn_run.clicked.connect(self._term_run)
        in_layout.addWidget(btn_run)
        term_layout.addWidget(input_row)

        self._dock_terminal = _make_dock(
            "Terminal", term_container,
            Qt.DockWidgetArea.BottomDockWidgetArea, min_h=160
        )
        # Tabify terminal and lint at the bottom so they share the same slot
        self.tabifyDockWidget(self._dock_lint, self._dock_terminal)
        self._dock_terminal.raise_()

        self._term_process = None
        self._term_history = []
        self._term_hist_idx = -1
        self._term_input.installEventFilter(self)

        # ── View menu with dock toggles ───────────────────────────────────────
        view_menu = self.menuBar().addMenu("View")
        view_menu.addAction(self._dock_explorer.toggleViewAction())
        view_menu.addAction(self._dock_lint.toggleViewAction())
        view_menu.addAction(self._dock_terminal.toggleViewAction())
        view_menu.addSeparator()
        act_reset = view_menu.addAction("Reset Layout")
        act_reset.triggered.connect(self._reset_dock_layout)

        # Populate file explorer
        self.refresh_explorer()

        # Apply full theme now that all widget refs exist
        self.apply_theme(self._current_theme)

    def create_new_tab(self, title):
        """Create a new Monaco editor tab."""
        tab_container = QWidget()
        tab_layout = QVBoxLayout(tab_container)
        tab_layout.setContentsMargins(0, 0, 0, 0)

        editor = MonacoEditor()
        # Apply current theme/font once Monaco is ready
        QTimer.singleShot(500, lambda: editor.set_monaco_theme(self._current_theme))
        QTimer.singleShot(500, lambda: editor.set_font_size(self._current_font_size))
        # Apply stored Monaco options
        QTimer.singleShot(600, lambda: editor.apply_monaco_opts(getattr(self, "_monaco_opts", {})))
        # Load Roblox intellisense completions
        QTimer.singleShot(700, lambda: editor.load_roblox_intellisense())
        # Wire cursor → status bar
        QTimer.singleShot(700, lambda: editor.setup_cursor_callback(self._on_cursor_change))
        tab_layout.addWidget(editor)

        index = self.tab_widget.addTab(tab_container, title)
        self.tab_widget.setCurrentIndex(index)
        return editor

    def get_current_editor(self):
        """Get the current active Monaco editor."""
        current_widget = self.tab_widget.currentWidget()
        if current_widget:
            return current_widget.findChild(MonacoEditor)
        return None

    def new_file(self):
        """Create a new file tab."""
        self.create_new_tab("new")

    def open_file(self):
        """Open a file dialog and load a file."""
        filename, _ = QFileDialog.getOpenFileName(
            self,
            "Open File",
            self.current_directory,
            "Lua Files (*.lua);;Luau Files (*.luau);;All Files (*.*)",
        )
        if filename:
            self.current_directory = os.path.dirname(filename)
            with open(filename, "r", encoding="utf-8") as f:
                content = f.read()
            editor = self.create_new_tab(os.path.basename(filename))
            editor.file_path = filename
            QTimer.singleShot(600, lambda: editor.set_text(content))
            self.add_recent_file(filename)

    def save_file(self):
        """Save the current file."""
        editor = self.get_current_editor()
        if not editor:
            return
        if hasattr(editor, "file_path") and editor.file_path:
            filename = editor.file_path
        else:
            filename, _ = QFileDialog.getSaveFileName(
                self,
                "Save File",
                self.current_directory,
                "Lua Files (*.lua);;Luau Files (*.luau);;All Files (*.*)",
            )
        if filename:
            content = editor.get_text()
            with open(filename, "w", encoding="utf-8") as f:
                f.write(content)
            editor.file_path = filename
            current_index = self.tab_widget.currentIndex()
            self.tab_widget.setTabText(current_index, os.path.basename(filename))
            self.add_recent_file(filename)
            QMessageBox.information(self, "Success", "File saved successfully!")
            if self._bridge_auto_push:
                self._bridge_push(silent=True)

    def close_tab(self, index):
        """Close a tab."""
        if self.tab_widget.count() > 1:
            if index == self._importer_tab_index:
                self._importer_tab_index = -1
            elif index < self._importer_tab_index:
                self._importer_tab_index -= 1
            if index == self._decomp_tab_index:
                self._decomp_tab_index = -1
                self._decomp_stop_server()
            elif index < self._decomp_tab_index:
                self._decomp_tab_index -= 1
            self.tab_widget.removeTab(index)
        else:
            # Keep at least one tab
            editor = self.get_current_editor()
            if editor:
                editor.clear()
                self.tab_widget.setTabText(0, "Untitled")

    def refresh_explorer(self):
        """Refresh the file explorer with directory tree."""
        self.file_tree.clear()

        # Add current path as root
        root_item = QTreeWidgetItem(self.file_tree)
        root_item.setText(0, self.current_directory)
        root_item.setText(1, "")
        root_item.setData(0, Qt.ItemDataRole.UserRole, self.current_directory)
        root_item.setExpanded(True)

        # Populate directory tree
        self.populate_directory_tree(root_item, self.current_directory)

    def populate_directory_tree(self, parent_item, directory_path):
        """Recursively populate directory tree."""
        try:
            directory = QDir(directory_path)

            # Get directories first
            dirs = directory.entryInfoList(QDir.Filter.Dirs | QDir.Filter.NoDotAndDotDot, QDir.SortFlag.Name)

            for dir_info in dirs:
                dir_item = QTreeWidgetItem(parent_item)
                dir_item.setText(0, f"{dir_info.fileName()}")
                dir_item.setText(1, "<DIR>")
                dir_item.setData(0, Qt.ItemDataRole.UserRole, dir_info.absoluteFilePath())

                # Add placeholder for lazy loading
                placeholder = QTreeWidgetItem(dir_item)
                placeholder.setText(0, "Loading...")

            # Get files
            files = directory.entryInfoList(
                QDir.Filter.Files | QDir.Filter.NoDotAndDotDot, QDir.SortFlag.Name
            )

            for file_info in files:
                file_item = QTreeWidgetItem(parent_item)
                file_item.setText(0, f"📄 {file_info.fileName()}")
                size_kb = file_info.size() / 1024
                file_item.setText(1, f"{size_kb:.2f} KB")
                file_item.setData(0, Qt.ItemDataRole.UserRole, file_info.absoluteFilePath())

        except Exception as e:
            error_item = QTreeWidgetItem(parent_item)
            error_item.setText(0, f"Error: {str(e)}")

    def browse_directory(self):
        """Open dialog to browse and select a directory."""
        directory = QFileDialog.getExistingDirectory(self, "Select Directory", self.current_directory)
        if directory:
            self.current_directory = directory
            self.refresh_explorer()

    def show_tree_context_menu(self, position):
        """Show context menu for file tree items."""
        item = self.file_tree.itemAt(position)
        if not item:
            return

        filepath = item.data(0, Qt.ItemDataRole.UserRole)
        if not filepath:
            return

        menu = QMenu(self)

        # Add actions based on whether it's a file or directory
        if os.path.isfile(filepath):
            open_action = menu.addAction("Open")
            open_action.triggered.connect(lambda: self.tree_item_double_clicked(item, 0))

        if os.path.isdir(filepath):
            set_as_root_action = menu.addAction("Set as Root Directory")
            set_as_root_action.triggered.connect(lambda: self.set_root_directory(filepath))

        menu.addSeparator()

        copy_path_action = menu.addAction("Copy Path")
        copy_path_action.triggered.connect(lambda: QApplication.clipboard().setText(filepath))

        copy_name_action = menu.addAction("Copy Name")
        copy_name_action.triggered.connect(
            lambda: QApplication.clipboard().setText(os.path.basename(filepath))
        )

        menu.addSeparator()

        if os.path.exists(filepath):
            show_in_folder_action = menu.addAction("Show in Folder")
            show_in_folder_action.triggered.connect(lambda: self.show_in_system_explorer(filepath))

        menu.exec(self.file_tree.viewport().mapToGlobal(position))

    def set_root_directory(self, directory_path):
        """Set the selected directory as the root in explorer."""
        self.current_directory = directory_path
        self.refresh_explorer()

    def show_in_system_explorer(self, filepath):
        """Open the system file explorer at the given path."""
        try:
            if os.path.isfile(filepath):
                filepath = os.path.dirname(filepath)

            if sys.platform == "win32":
                os.startfile(filepath)
            elif sys.platform == "darwin":
                subprocess.run(["open", filepath])
            else:  # Linux and other Unix-like
                subprocess.run(["xdg-open", filepath])
        except Exception as e:
            QMessageBox.warning(self, "Error", f"Could not open folder: {str(e)}")

    def tree_item_expanded(self, item):
        """Handle tree item expansion for lazy loading."""
        # Check if this item has a placeholder child
        if item.childCount() == 1:
            child = item.child(0)
            if child.text(0) == "Loading...":
                # Remove placeholder
                item.removeChild(child)

                # Get the directory path
                directory_path = item.data(0, Qt.ItemDataRole.UserRole)

                # Populate this directory
                if directory_path and os.path.isdir(directory_path):
                    self.populate_directory_tree(item, directory_path)

    def tree_item_double_clicked(self, item, column):
        """Handle double-click on file explorer item."""
        filepath = item.data(0, Qt.ItemDataRole.UserRole)
        if filepath:
            if os.path.isfile(filepath):
                try:
                    with open(filepath, "r", encoding="utf-8") as f:
                        content = f.read()
                    editor = self.create_new_tab(os.path.basename(filepath))
                    editor.file_path = filepath
                    QTimer.singleShot(600, lambda: editor.set_text(content))
                    self.add_recent_file(filepath)
                except Exception as e:
                    QMessageBox.warning(self, "Error", f"Could not open file: {str(e)}")
            elif os.path.isdir(filepath):
                item.setExpanded(not item.isExpanded())

    def _on_cursor_change(self, line: int, col: int):
        """Update status bar with current cursor position."""
        self.statusBar().showMessage(f"Ln {line},  Col {col}", 0)

    def show_settings(self):
        """Show settings dialog."""
        dialog = SettingsDialog(
            self,
            current_theme=self._current_theme,
            current_font_size=self._current_font_size,
            monaco_opts=self._monaco_opts,
        )
        if dialog.exec():
            new_font_size  = dialog.font_size.value()
            new_theme_name = dialog.theme.currentText()
            new_opts       = dialog.get_monaco_opts()

            self._current_font_size = new_font_size
            self._monaco_opts = new_opts

            # Apply to every open Monaco editor
            for i in range(self.tab_widget.count()):
                widget = self.tab_widget.widget(i)
                editor = widget.findChild(MonacoEditor)
                if editor:
                    editor.set_font_size(new_font_size)
                    editor.apply_monaco_opts(new_opts)

            # Apply theme if it changed
            if new_theme_name != self._current_theme:
                self.apply_theme(new_theme_name)

    # ── Theme engine ──────────────────────────────────────────────────────────

    def _apply_app_stylesheet(self, theme_name: str):
        """Build and apply the main QSS stylesheet from the theme dict."""
        global _current_theme
        _current_theme = theme_name
        t = THEMES[theme_name]

        self.setStyleSheet(f"""
            QMainWindow, QWidget {{
                background-color: {t['app_bg']};
                color: {t['label_fg']};
                font-family: "Segoe UI", "SF Pro Text", "Helvetica Neue", sans-serif;
                font-size: 9pt;
            }}
            QDialog {{
                background-color: {t['app_bg']};
                color: {t['label_fg']};
            }}
            QLabel {{
                color: {t['label_fg']};
                background: transparent;
            }}
            QSpinBox, QComboBox, QLineEdit, QTextEdit, QPlainTextEdit {{
                background-color: {t['tree_bg']};
                color: {t['label_fg']};
                border: 1px solid {t['tree_border']};
                border-radius: 3px;
                padding: 3px 6px;
                selection-background-color: {t['accent']};
            }}
            QSpinBox::up-button, QSpinBox::down-button {{
                background-color: {t['btn_bg']};
                border: none;
                width: 16px;
            }}
            QComboBox::drop-down {{
                border: none;
                width: 20px;
            }}
            QComboBox QAbstractItemView {{
                background-color: {t['tree_bg']};
                color: {t['label_fg']};
                border: 1px solid {t['tree_border']};
                selection-background-color: {t['accent']};
                selection-color: #ffffff;
                outline: none;
            }}
            QCheckBox {{
                color: {t['label_fg']};
                spacing: 6px;
            }}
            QCheckBox::indicator {{
                width: 13px;
                height: 13px;
                border: 1px solid {t['tree_border']};
                border-radius: 2px;
                background-color: {t['tree_bg']};
            }}
            QCheckBox::indicator:checked {{
                background-color: {t['accent']};
                border-color: {t['accent']};
            }}
            QRadioButton {{
                color: {t['label_fg']};
                spacing: 6px;
            }}
            QRadioButton::indicator {{
                width: 13px;
                height: 13px;
                border: 1px solid {t['tree_border']};
                border-radius: 7px;
                background-color: {t['tree_bg']};
            }}
            QRadioButton::indicator:checked {{
                background-color: {t['accent']};
                border-color: {t['accent']};
            }}
            QPushButton {{
                background-color: {t['btn_bg']};
                color: {t['btn_fg']};
                border: 1px solid {t['btn_border_out']};
                border-radius: 3px;
                padding: 4px 12px;
                font-size: 9pt;
                min-width: 54px;
            }}
            QPushButton:hover {{
                background-color: {t['btn_hover_bg']};
                border-color: {t['accent']};
                color: {t['accent']};
            }}
            QPushButton:pressed {{
                background-color: {t['btn_press_bg']};
            }}
            QPushButton:disabled {{
                color: {t['lineno_fg']};
                border-color: {t['tree_border']};
            }}
            QTreeWidget {{
                background-color: {t['tree_bg']};
                color: {t['label_fg']};
                border: none;
                border-right: 1px solid {t['tree_border']};
                font-size: 9pt;
                alternate-background-color: {t['tree_alt']};
                outline: none;
                show-decoration-selected: 1;
            }}
            QTreeWidget::item {{
                padding: 3px 4px;
                border: none;
            }}
            QTreeWidget::item:selected {{
                background-color: {t['tree_sel_bg']};
                color: {t['tree_sel_fg']};
                border-radius: 0px;
            }}
            QTreeWidget::item:hover:!selected {{
                background-color: {t['tree_hover']};
            }}
            QHeaderView::section {{
                background-color: {t['toolbar_bg']};
                color: {t['status_fg']};
                border: none;
                border-bottom: 1px solid {t['tree_border']};
                border-right: 1px solid {t['tree_border']};
                padding: 4px 6px;
                font-size: 8pt;
                text-transform: uppercase;
                letter-spacing: 0.05em;
            }}
            QTabWidget::pane {{
                border: none;
                border-top: 1px solid {t['tab_pane_border']};
                background-color: {t['tab_pane_bg']};
            }}
            QTabBar::tab {{
                background-color: transparent;
                color: {t['status_fg']};
                border: none;
                border-bottom: 2px solid transparent;
                padding: 6px 14px;
                margin-right: 0px;
                font-size: 9pt;
                min-width: 56px;
            }}
            QTabBar::tab:selected {{
                color: {t['label_fg']};
                border-bottom: 2px solid {t['accent']};
            }}
            QTabBar::tab:hover:!selected {{
                color: {t['label_fg']};
                background-color: {t['tab_hover_bg']};
            }}
            QTabBar::close-button {{
                image: none;
                subcontrol-position: right;
                subcontrol-origin: padding;
                background-color: transparent;
                border: none;
                width: 14px;
                height: 14px;
                margin: 2px;
                border-radius: 3px;
            }}
            QTabBar::close-button:hover {{
                background-color: #C0392B;
            }}
            QScrollBar:vertical {{
                background: transparent;
                width: 8px;
                margin: 0;
            }}
            QScrollBar::handle:vertical {{
                background: {t['splitter_bg']};
                border-radius: 4px;
                min-height: 24px;
                margin: 1px 1px;
            }}
            QScrollBar::handle:vertical:hover {{
                background: {t['status_fg']};
            }}
            QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical,
            QScrollBar::add-page:vertical, QScrollBar::sub-page:vertical {{
                height: 0px; background: transparent;
            }}
            QScrollBar:horizontal {{
                background: transparent;
                height: 8px;
                margin: 0;
            }}
            QScrollBar::handle:horizontal {{
                background: {t['splitter_bg']};
                border-radius: 4px;
                min-width: 24px;
                margin: 1px 1px;
            }}
            QScrollBar::handle:horizontal:hover {{
                background: {t['status_fg']};
            }}
            QScrollBar::add-line:horizontal, QScrollBar::sub-line:horizontal,
            QScrollBar::add-page:horizontal, QScrollBar::sub-page:horizontal {{
                width: 0px; background: transparent;
            }}
            QStatusBar {{
                background-color: {t['toolbar_bg']};
                color: {t['status_fg']};
                border-top: 1px solid {t['toolbar_border']};
                font-size: 8pt;
                padding: 0 6px;
            }}
            QSplitter::handle {{
                background-color: {t['splitter_bg']};
            }}
            QSplitter::handle:horizontal {{ width: 1px; }}
            QSplitter::handle:vertical   {{ height: 1px; }}
            QMenu {{
                background-color: {t['tree_bg']};
                color: {t['label_fg']};
                border: 1px solid {t['tree_border']};
                padding: 3px 0;
                border-radius: 4px;
            }}
            QMenu::item {{
                padding: 5px 18px;
            }}
            QMenu::item:selected {{
                background-color: {t['tree_sel_bg']};
                color: {t['tree_sel_fg']};
            }}
            QMenu::separator {{
                height: 1px;
                background: {t['tree_border']};
                margin: 3px 0;
            }}
            QMessageBox {{
                background-color: {t['app_bg']};
            }}
            QMessageBox QPushButton {{
                min-width: 70px;
            }}
        """)

    def apply_theme(self, theme_name: str):
        """Switch to the named theme and repaint everything."""
        global _current_theme
        self._current_theme = theme_name
        _current_theme = theme_name
        t = THEMES[theme_name]

        # 1. Main app stylesheet
        self._apply_app_stylesheet(theme_name)

        # 2. Toolbar
        self._toolbar_widget.setStyleSheet(
            f"background-color: {t['toolbar_bg']};"
            f"border-bottom: 1px solid {t['toolbar_border']};"
        )

        # 3. Separator lines
        for sep in self._separators:
            sep.setStyleSheet(f"background-color: {t['toolbar_border']};")

        # 4. Accent buttons — subtle tinted backgrounds, no individual overrides needed
        #    All buttons inherit from QSS; just clear any leftover per-widget styles.
        for btn, key in (
            (self._btn_settings,   "btn_settings"),
            (self._btn_format,     "btn_format"),
            (self._btn_stylua,     "btn_format"),
            (self._btn_bridge_push,"btn_bridge"),
            (self._btn_bridge_cfg, "btn_bridge"),
            (self._btn_inject,     "btn_bridge"),
            (self._btn_obfuscate,  "btn_obfuscate"),
            (self._btn_lint,       "btn_format"),
        ):
            btn.setStyleSheet(
                f"background-color: {t[key]};"
                f"border: 1px solid {t['btn_border_out']};"
                f"border-radius: 3px;"
                f"padding: 4px 10px;"
                f"color: {t['btn_fg']};"
            )

        # 5. Explorer header
        self._explorer_header.setStyleSheet(
            f"background-color: {t['explorer_hdr_bg']};"
            f"border-bottom: 1px solid {t['explorer_hdr_bd']};"
        )
        self._explorer_label.setStyleSheet(
            f"font-weight: 600;"
            f"font-size: 8pt;"
            f"letter-spacing: 0.08em;"
            f"color: {t['status_fg']};"
            f"text-transform: uppercase;"
        )

        # 6. Left panel tabs
        self._left_panel_tabs.setStyleSheet(f"""
            QTabWidget::pane {{
                border: none;
                border-top: 1px solid {t['tab_border']};
                background-color: {t['tab_pane_bg']};
            }}
            QTabBar::tab {{
                background-color: transparent;
                color: {t['status_fg']};
                border: none;
                border-bottom: 2px solid transparent;
                padding: 5px 10px;
                font-size: 8.5pt;
            }}
            QTabBar::tab:selected {{
                color: {t['label_fg']};
                border-bottom: 2px solid {t['accent']};
            }}
            QTabBar::tab:hover:!selected {{
                color: {t['label_fg']};
                background-color: {t['tab_hover_bg']};
            }}
        """)

        # 7. Terminal header / prompt
        self._term_title_lbl.setStyleSheet(
            f"font-weight: 600; font-size: 8pt; letter-spacing: 0.08em; color: {t['status_fg']};"
        )
        self._term_prompt.setStyleSheet(
            f"font-family: 'Consolas', monospace; font-size: 10pt; color: {t['accent']};"
        )

        # 8. Lint panel header
        self._lint_title_lbl.setStyleSheet(
            f"font-weight: 600; font-size: 8pt; letter-spacing: 0.08em; color: {t['status_fg']};"
        )

        # 9. Monaco editors — switch theme, font size, and options
        for i in range(self.tab_widget.count()):
            widget = self.tab_widget.widget(i)
            editor = widget.findChild(MonacoEditor)
            if editor:
                editor.set_monaco_theme(theme_name)
                editor.set_font_size(self._current_font_size)
                editor.apply_monaco_opts(self._monaco_opts)

        # 10. Dock widget title bars
        from PyQt6.QtWidgets import QDockWidget
        dock_qss = f"""
            QDockWidget {{
                color: {t['label_fg']};
                font-size: 9pt;
                font-weight: 600;
                titlebar-close-icon: none;
            }}
            QDockWidget::title {{
                background-color: {t['toolbar_bg']};
                border-bottom: 1px solid {t['toolbar_border']};
                padding: 4px 8px;
                text-align: left;
            }}
            QDockWidget::close-button, QDockWidget::float-button {{
                background: transparent;
                border: none;
                padding: 2px;
            }}
            QDockWidget::close-button:hover, QDockWidget::float-button:hover {{
                background: {t['btn_hover_bg']};
                border-radius: 3px;
            }}
        """
        for dock in self.findChildren(QDockWidget):
            dock.setStyleSheet(dock_qss)

        self.statusBar().showMessage(f"Theme: {theme_name}", 2000)

    def _reset_dock_layout(self):
        """Restore docks to their default positions."""
        from PyQt6.QtWidgets import QDockWidget
        # Remove all docks from layout then re-add them
        self.addDockWidget(Qt.DockWidgetArea.LeftDockWidgetArea, self._dock_explorer)
        self._dock_explorer.setFloating(False)
        self._dock_explorer.show()

        self.addDockWidget(Qt.DockWidgetArea.BottomDockWidgetArea, self._dock_lint)
        self._dock_lint.setFloating(False)

        self.addDockWidget(Qt.DockWidgetArea.BottomDockWidgetArea, self._dock_terminal)
        self._dock_terminal.setFloating(False)
        self.tabifyDockWidget(self._dock_lint, self._dock_terminal)
        self._dock_terminal.show()
        self._dock_terminal.raise_()

    def remove_comments(self):
        """Smart comment removal that preserves code structure."""
        editor = self.get_current_editor()
        if not editor:
            return
        code = editor.get_text()
        if not code.strip():
            QMessageBox.warning(self, "Empty Editor", "Editor is empty. Nothing to remove.")
            return
        try:
            cleaned_code = LuaCommentRemover.remove_comments(code)
            editor.set_text(cleaned_code)
            QMessageBox.information(
                self,
                "Success",
                "Comments removed intelligently.\n\nPreserved:\n"
                "• Code structure and line integrity\n"
                "• Strings containing '--' patterns\n"
                "• Code on lines with trailing comments",
            )
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Error removing comments: {str(e)}")

    def populate_templates(self):
        """Populate the templates tree with advanced audit and research templates."""
        templates_data = {
            "Security Headers": {
                "Anti-Tamper Guard": """-- Detects metatable tampering / read-only bypasses
local function checkIntegrity()
    local mt = getrawmetatable(game)
    if not mt then warn("[Security] No metatable"); return false end
    local idx = rawget(mt, "__index")
    if type(idx) ~= "function" and type(idx) ~= "table" then
        warn("[Security] __index tampered"); return false
    end
    return true
end
if not checkIntegrity() then
    error("[Security] Integrity check failed -- aborting", 2)
end
""",
                "Anti-Debug / Decompiler Traps": """local function isDecompilerPresent()
    local info = debug and debug.getinfo and debug.getinfo(1, "u")
    if info and info.nups and info.nups > 32 then return true end
    for _, k in ipairs({"dumpfunction","decompile","getscriptbytecode"}) do
        if _G[k] ~= nil then return true end
    end
    return false
end
if isDecompilerPresent() then return end
local _s = {}
local function _c() return _s end
assert(_c() == _s, "[Security] Closure integrity violated")
""",
                "Anti-WebSocket Detection": """local mt = getrawmetatable(game)
local origNC = rawget(mt, "__namecall")
if origNC and iscclosure and not iscclosure(origNC) then
    warn("[Security] __namecall hook detected -- possible remote spy")
end
local _mon = {}
local function watchRemote(remote)
    if _mon[remote] then return end
    _mon[remote] = true
    if islclosure and islclosure(remote.FireServer) then
        warn("[Security] FireServer hooked on", remote:GetFullName())
    end
end
-- watchRemote(game.ReplicatedStorage:WaitForChild("SomeRemote"))
""",
                "WebSocket Block Header": """local _bWS = setmetatable({}, {
    __index    = function(_, k) warn("[Security] WebSocket."..k.." blocked"); return function() end end,
    __newindex = function() end,
    __call     = function() warn("[Security] WebSocket() blocked"); return nil end,
})
if rawget(_G,"WebSocket")~=nil then rawset(_G,"WebSocket",_bWS) end
if rawget(_G,"websocket")~=nil then rawset(_G,"websocket",_bWS) end
local _origReq = http_request or request
local function safeRequest(opts)
    local url = (opts and opts.Url) or ""
    for _, d in ipairs({"roblox.com","robloxlabs.com"}) do
        if url:find(d,1,true) then return _origReq(opts) end
    end
    warn("[Security] Blocked:", url)
    return {StatusCode=403, Body=""}
end
http_request = safeRequest; request = safeRequest
""",
                "identifyexecutor Spoof -- Generic": """-- Spoofs identifyexecutor to return a chosen executor name
local SPOOF_NAME = "Synapse X"
local SPOOF_VER  = "2.1.0"
local function spoofedIE() return SPOOF_NAME, SPOOF_VER end
if rawget(_G,"identifyexecutor")~=nil then rawset(_G,"identifyexecutor",spoofedIE) end
if rawget(_G,"getexecutorname")~=nil  then rawset(_G,"getexecutorname",spoofedIE)  end
""",
                "identifyexecutor Spoof -- Nil (hide executor)": """-- Returns nil so scripts that gate on executor name get nothing
local function hiddenIE() return nil, nil end
if rawget(_G,"identifyexecutor")~=nil then rawset(_G,"identifyexecutor",hiddenIE) end
if rawget(_G,"getexecutorname")~=nil  then rawset(_G,"getexecutorname",hiddenIE)  end
""",
                "identifyexecutor Spoof -- Dynamic Table": """local SPOOF_AS = "Synapse X"
local spoofTable = {
    ["Synapse X"]  = {"Synapse X",  "2.1.0"},
    ["KRNL"]       = {"KRNL",        "2.1.0"},
    ["Fluxus"]     = {"Fluxus",      "1.0.0"},
    ["Script-Ware"]= {"Script-Ware", "2.5.0"},
    ["Electron"]   = {"Electron",    "1.0.0"},
}
local chosen = spoofTable[SPOOF_AS] or spoofTable["Synapse X"]
local function spoofedIE() return chosen[1], chosen[2] end
if rawget(_G,"identifyexecutor")~=nil then rawset(_G,"identifyexecutor",spoofedIE) end
if rawget(_G,"getexecutorname")~=nil  then rawset(_G,"getexecutorname",spoofedIE)  end
""",
                "identifyexecutor Spoof -- genv Hook": """-- Hooks via getgenv() -- visible script-wide, most reliable method
local genv = getgenv()
local SPOOF_NAME = "Synapse X"
local SPOOF_VER  = "2.1.0"
genv.identifyexecutor  = function() return SPOOF_NAME, SPOOF_VER end
genv.getexecutorname   = function() return SPOOF_NAME, SPOOF_VER end
genv.getexecutorversion= function() return SPOOF_VER end
""",
            },
            "Loadstring Templates": {
                "Basic HttpGet Loadstring": """loadstring(game:HttpGet("https://raw.githubusercontent.com/User/Repo/main/script.lua"))()
""",
                "Protected Loadstring (pcall)": """local url = "https://raw.githubusercontent.com/User/Repo/main/script.lua"
local ok, err = pcall(function()
    local src = game:HttpGet(url)
    assert(type(src)=="string" and #src>0, "Empty response")
    local fn, e = loadstring(src)
    assert(fn, "loadstring failed: "..tostring(e))
    fn()
end)
if not ok then warn("[Loader] Failed:", err) end
""",
                "Loadstring with Version Check": """local BASE="https://raw.githubusercontent.com/User/Repo/main/"
local LOCAL_VER="1.0.0"
local ok,rv=pcall(function() return game:HttpGet(BASE.."version.txt"):match("^%S+") end)
if ok and rv and rv~=LOCAL_VER then warn("[Loader] Update -- remote:",rv,"local:",LOCAL_VER) end
local ok2,err=pcall(function() loadstring(game:HttpGet(BASE.."script.lua"))() end)
if not ok2 then warn("[Loader] Error:",err) end
""",
                "Multi-File Loader": """local BASE="https://raw.githubusercontent.com/User/Repo/main/"
local files={"modules/utils.lua","modules/ui.lua","main.lua"}
local function loadRemote(path)
    local src=game:HttpGet(BASE..path)
    local fn,err=loadstring(src)
    if not fn then warn("[Loader] Parse error:",path,err);return end
    local ok,e=pcall(fn)
    if not ok then warn("[Loader] Runtime error:",path,e) end
end
for _,f in ipairs(files) do loadRemote(f);task.wait() end
""",
                "Loadstring with Integrity Hash": """local url="https://raw.githubusercontent.com/User/Repo/main/script.lua"
local expected="PASTE_SHA256_HASH_HERE"
local src=game:HttpGet(url)
local function getHash(d)
    if crypt and crypt.hash then return crypt.hash(d) end
    if hashlib and hashlib.sha256 then return hashlib.sha256(d) end
end
local hash=getHash(src)
if hash and hash~=expected then error("[Loader] Integrity check FAILED!",2) end
loadstring(src)()
""",
                "require() by Asset ID": """-- Replace 0000000000 with the actual ModuleScript asset ID
local mod=require(0000000000)
-- mod:Init()
-- mod:Start()
""",
                "HttpService:GetAsync Variant": """local HttpService = game:GetService("HttpService")
local url = "https://raw.githubusercontent.com/User/Repo/main/script.lua"
local ok, src = pcall(function()
    return HttpService:GetAsync(url, true)
end)
if not ok or not src then warn("[Loader] HttpGet failed:", src); return end
local fn, err = loadstring(src)
if not fn then warn("[Loader] Parse error:", err); return end
pcall(fn)
""",
                "Loadstring via Variable Split": """local a = "https://raw.githubuserco"
local b = "ntent.com/User/Repo/main/script.lua"
loadstring(game:HttpGet(a..b))()
""",
                "Loadstring with Retry Logic": """local url = "https://raw.githubusercontent.com/User/Repo/main/script.lua"
local MAX_RETRIES = 3
local src, fn, err
for i = 1, MAX_RETRIES do
    local ok
    ok, src = pcall(function() return game:HttpGet(url) end)
    if ok and src and #src > 0 then
        fn, err = loadstring(src)
        if fn then break end
    end
    warn("[Loader] Attempt", i, "failed. Retrying in 2s...")
    task.wait(2)
end
if not fn then warn("[Loader] All retries failed:", err); return end
local ok2, e = pcall(fn)
if not ok2 then warn("[Loader] Runtime error:", e) end
""",
                "Loadstring with Timeout Guard": """local url = "https://raw.githubusercontent.com/User/Repo/main/script.lua"
local result = nil
local done = false
task.spawn(function()
    local ok, src = pcall(function() return game:HttpGet(url) end)
    if ok and src and #src > 0 then result = src end
    done = true
end)
local t = 0
repeat task.wait(0.1); t = t + 0.1 until done or t >= 10
if not result then warn("[Loader] Timed out fetching script."); return end
local fn, err = loadstring(result)
if not fn then warn("[Loader] Parse error:", err); return end
pcall(fn)
""",
                "Loadstring with Environment Passthrough": """local url = "https://raw.githubusercontent.com/User/Repo/main/script.lua"
local src = game:HttpGet(url)
local fn, err = loadstring(src)
if not fn then warn("[Loader] Error:", err); return end
-- Pass custom env values into the loaded script via upvalues
local env = getfenv and getfenv(fn) or _ENV
env.__LOADER_VERSION = "1.0.0"
env.__LOADER_DEBUG   = false
if setfenv then setfenv(fn, env) end
pcall(fn)
""",
                "Loadstring with Argument Passing": """local url = "https://raw.githubusercontent.com/User/Repo/main/script.lua"
local args = {
    debug = false,
    config = { speed = 16, autoFarm = true },
    key = "YOUR_KEY_HERE",
}
local fn, err = loadstring(game:HttpGet(url))
if not fn then warn("[Loader] Error:", err); return end
pcall(fn, args)
""",
                "Silent Loadstring (No Output)": """local function silent_load(url)
    local s,r=pcall(game.HttpGet,game,url)
    if not s then return end
    local f=loadstring(r)
    if f then pcall(f) end
end
silent_load("https://raw.githubusercontent.com/User/Repo/main/script.lua")
""",
                "Loadstring from Pastebin": """-- Pastebin raw URL format:
-- https://pastebin.com/raw/PASTE_ID
local id = "PASTE_ID_HERE"
local url = "https://pastebin.com/raw/" .. id
local ok, src = pcall(function() return game:HttpGet(url) end)
if not ok or not src then warn("[Loader] Pastebin fetch failed:", src); return end
local fn, err = loadstring(src)
if not fn then warn("[Loader] Parse error:", err); return end
pcall(fn)
""",
                "Loadstring Coroutine Wrapped": """local url = "https://raw.githubusercontent.com/User/Repo/main/script.lua"
coroutine.wrap(function()
    local ok, src = pcall(function() return game:HttpGet(url) end)
    if not ok then warn("[Loader] Fetch error:", src); return end
    local fn, err = loadstring(src)
    if not fn then warn("[Loader] Parse error:", err); return end
    local ok2, e = pcall(fn)
    if not ok2 then warn("[Loader] Runtime error:", e) end
end)()
""",
                "Loadstring task.spawn Wrapped": """local url = "https://raw.githubusercontent.com/User/Repo/main/script.lua"
task.spawn(function()
    local src = game:HttpGet(url)
    if not src or #src == 0 then warn("[Loader] Empty response"); return end
    local fn, err = loadstring(src)
    if not fn then warn("[Loader] Compile error:", err); return end
    fn()
end)
""",
                "Loadstring with Whitelist Check": """local HWID = game:GetService("RbxAnalyticsService"):GetClientId()
local url = "https://raw.githubusercontent.com/User/Repo/main/script.lua"
local wlUrl = "https://raw.githubusercontent.com/User/Repo/main/whitelist.txt"
local wl = game:HttpGet(wlUrl)
if not wl:find(HWID) then
    warn("[Loader] Not whitelisted.")
    return
end
loadstring(game:HttpGet(url))()
""",
                "Loadstring with Game Check": """local ALLOWED_GAMES = { 1234567890, 9876543210 } -- add place IDs here
local placeId = game.PlaceId
local allowed = false
for _, id in ipairs(ALLOWED_GAMES) do
    if placeId == id then allowed = true; break end
end
if not allowed then warn("[Loader] Wrong game. PlaceId:", placeId); return end
loadstring(game:HttpGet("https://raw.githubusercontent.com/User/Repo/main/script.lua"))()
""",
                "Loader with Config JSON": """local BASE = "https://raw.githubusercontent.com/User/Repo/main/"
local HttpService = game:GetService("HttpService")
-- Load config first, then main script
local cfgOk, cfgSrc = pcall(function() return game:HttpGet(BASE.."config.json") end)
local config = {}
if cfgOk and cfgSrc then
    local ok2, parsed = pcall(function() return HttpService:JSONDecode(cfgSrc) end)
    if ok2 then config = parsed end
end
-- Make config globally accessible before loading main
_G.CONFIG = config
loadstring(game:HttpGet(BASE.."main.lua"))()
""",
                "Loadstring One-liner (Minimal)": """loadstring(game:HttpGet("https://raw.githubusercontent.com/User/Repo/main/script.lua"))()
""",
                "load() Variant (Executor Compatible)": """-- Some executors expose load() instead of loadstring()
local url = "https://raw.githubusercontent.com/User/Repo/main/script.lua"
local src = game:HttpGet(url);
(load or loadstring)(src)()
""",
                "Loadstring with Auto-Update": """local BASE = "https://raw.githubusercontent.com/User/Repo/main/"
local LOCAL_VER = "1.0.0"
local remoteVer = (pcall(function() return game:HttpGet(BASE.."version.txt"):match("^%S+") end) and
    game:HttpGet(BASE.."version.txt"):match("^%S+")) or LOCAL_VER
if remoteVer ~= LOCAL_VER then
    warn("[Loader] Updating from", LOCAL_VER, "->", remoteVer)
end
loadstring(game:HttpGet(BASE.."script.lua"))()
""",
            },
            "Script Headers": {
                "Minimal Header": """-- Script  : MyScript
-- Author  : YourName
-- Version : 1.0.0
-- Game    : Universal
""",
                "Full Banner Header": """-- ╔══════════════════════════════════════════════════════╗
-- ║  Script  : MyScript v1.0.0                          ║
-- ║  Author  : YourName                                 ║
-- ║  Executor : Universal                               ║
-- ╚══════════════════════════════════════════════════════╝
local ScriptInfo = { Name="MyScript", Version="1.0.0", Author="YourName" }
""",
                "Section Divider": """-- ═══════════════════════════════════════════════
--   SECTION: 
-- ═══════════════════════════════════════════════
""",
                "Module Header": """-- ┌──────────────────────────────────────────────┐
-- │  Module : MyModule                           │
-- └──────────────────────────────────────────────┘
local MyModule = {}
MyModule.__index = MyModule

function MyModule.new()
    return setmetatable({ State = { IsEnabled = false } }, MyModule)
end

function MyModule:Enable()  self.State.IsEnabled = true  end
function MyModule:Disable() self.State.IsEnabled = false end
function MyModule:Toggle()
    if self.State.IsEnabled then self:Disable() else self:Enable() end
end

return MyModule
""",
                "Service Cache Block": """local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera
local Mouse            = LocalPlayer:GetMouse()
""",
            },
            "RegisterCommand Templates": {
                "Basic Command": """RegisterCommand({
    Name        = "cmdname",
    Aliases     = {"alias1"},
    Description = "Does something",
}, function(args)
    -- args[1], args[2] ...
end)
""",
                "Player Arg Command": """RegisterCommand({
    Name        = "cmdname",
    Aliases     = {},
    Description = "Targets a player",
}, function(args)
    local name = args[1]
    if not name then return DoNotif("Usage: cmdname [player]", 2) end
    local target
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p.Name:lower():find(name:lower(), 1, true) then target = p; break end
    end
    if not target then return DoNotif("Player not found.", 2) end
    local char = target.Character
    if not char then return DoNotif("No character.", 2) end
    -- use char here
end)
""",
                "Number Arg Command": """RegisterCommand({
    Name        = "cmdname",
    Aliases     = {},
    Description = "Takes a number",
}, function(args)
    local value = tonumber(args[1])
    if not value then return DoNotif("Usage: cmdname [number]", 2) end
    value = math.clamp(value, 0, 9999)
    -- use value here
end)
""",
                "Toggle Command": """RegisterCommand({
    Name        = "cmdname",
    Aliases     = {},
    Description = "Toggles on/off",
}, function(args)
    getgenv().CmdName_On = not getgenv().CmdName_On
    if getgenv().CmdName_On then
        DoNotif("CmdName: ON", 2)
        -- enable
    else
        DoNotif("CmdName: OFF", 2)
        -- disable
    end
end)
""",
                "Loop Command": """RegisterCommand({
    Name        = "cmdname",
    Aliases     = {},
    Description = "Loops until re-run",
}, function(args)
    if getgenv().CmdName_Running then
        getgenv().CmdName_Running = false
        return DoNotif("CmdName: Stopped", 2)
    end
    getgenv().CmdName_Running = true
    DoNotif("CmdName: Running", 2)
    task.spawn(function()
        while getgenv().CmdName_Running do
            -- loop body
            task.wait(0.1)
        end
    end)
end)
""",
                "Heartbeat Command": """RegisterCommand({
    Name        = "cmdname",
    Aliases     = {},
    Description = "Per-frame loop, re-run to stop",
}, function(args)
    if getgenv().CmdName_Conn then
        getgenv().CmdName_Conn:Disconnect()
        getgenv().CmdName_Conn = nil
        return DoNotif("CmdName: OFF", 2)
    end
    DoNotif("CmdName: ON", 2)
    getgenv().CmdName_Conn = game:GetService("RunService").Heartbeat:Connect(function(dt)
        local char = game:GetService("Players").LocalPlayer.Character
        if not char then return end
        -- per-frame logic
    end)
end)
""",
            },
            "Utility Snippets": {
                "Safe pcall Wrapper": """local function safeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then warn("[SafeCall]", result); return nil end
    return result
end
""",
                "WaitForChild + Timeout": """local function waitForChild(parent, name, timeout)
    timeout = timeout or 5
    local t = 0
    local child = parent:FindFirstChild(name)
    while not child and t < timeout do
        task.wait(0.1); t = t + 0.1
        child = parent:FindFirstChild(name)
    end
    return child
end
""",
                "Deep Find by Class": """local function deepFind(root, className, maxDepth)
    maxDepth = maxDepth or 10
    local results = {}
    local function recurse(inst, d)
        if d > maxDepth then return end
        for _, child in ipairs(inst:GetChildren()) do
            if child:IsA(className) then table.insert(results, child) end
            recurse(child, d + 1)
        end
    end
    recurse(root, 0)
    return results
end
""",
                "Tween Helper": """local TweenService = game:GetService("TweenService")
local function tween(inst, props, dur, style, dir)
    local t = TweenService:Create(inst,
        TweenInfo.new(dur or 0.3, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props)
    t:Play(); return t
end
""",
                "Debounce Wrapper": """local function debounce(fn, cd)
    local last = 0
    return function(...)
        local now = tick()
        if now - last < (cd or 0.5) then return end
        last = now; return fn(...)
    end
end
""",
                "Settings Persist": """local HS   = game:GetService("HttpService")
local FILE = "MyScript_Settings.json"
local DEFAULTS = { enabled=true, speed=16, theme="default" }

local function loadSettings()
    if not isfile or not isfile(FILE) then return DEFAULTS end
    local ok, d = pcall(function() return HS:JSONDecode(readfile(FILE)) end)
    return (ok and type(d)=="table") and d or DEFAULTS
end

local function saveSettings(s)
    if writefile then pcall(writefile, FILE, HS:JSONEncode(s)) end
end

local Settings = loadSettings()
""",
                "Signal / Event": """local Signal = {}
Signal.__index = Signal
function Signal.new() return setmetatable({_l={}}, Signal) end
function Signal:Connect(fn)
    table.insert(self._l, fn)
    return {Disconnect=function() for i,f in ipairs(self._l) do if f==fn then table.remove(self._l,i);break end end end}
end
function Signal:Fire(...) for _,fn in ipairs(self._l) do task.spawn(fn,...) end end
""",
                "Remote Spy": """local mt   = getrawmetatable(game)
local orig = rawget(mt, "__namecall")
setreadonly(mt, false)
rawset(mt, "__namecall", newcclosure(function(self, ...)
    local m = getnamecallmethod()
    if m == "FireServer" or m == "InvokeServer" then
        print(("[RemoteSpy] %s::%s"):format(self:GetFullName(), m))
        for i,v in ipairs({...}) do print(("  [%d] %s"):format(i, tostring(v))) end
    end
    return orig(self, ...)
end))
setreadonly(mt, true)
""",
            },
            "ESP / Drawing Templates": {
                "Box ESP (Drawing API)": """local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Camera=workspace.CurrentCamera
local LP=Players.LocalPlayer
local boxes={}

local function makeBox()
    local b=Drawing.new("Square")
    b.Visible=false; b.Color=Color3.fromRGB(255,80,80)
    b.Thickness=1.5; b.Filled=false; return b
end

RunService.RenderStepped:Connect(function()
    for _,p in ipairs(Players:GetPlayers()) do
        if p==LP then continue end
        local hrp=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then if boxes[p] then boxes[p].Visible=false end; continue end
        if not boxes[p] then boxes[p]=makeBox() end
        local pos,vis=Camera:WorldToViewportPoint(hrp.Position)
        if vis then
            local s=1/pos.Z*100
            boxes[p].Size=Vector2.new(s*1.5,s*3)
            boxes[p].Position=Vector2.new(pos.X-s*0.75,pos.Y-s*1.5)
            boxes[p].Visible=true
        else boxes[p].Visible=false end
    end
end)
""",
                "Name + Distance Label": """local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Camera=workspace.CurrentCamera
local LP=Players.LocalPlayer
local labels={}

local function makeLabel()
    local l=Drawing.new("Text")
    l.Visible=false; l.Size=14; l.Center=true
    l.Outline=true; l.Color=Color3.new(1,1,1); return l
end

RunService.RenderStepped:Connect(function()
    for _,p in ipairs(Players:GetPlayers()) do
        if p==LP then continue end
        local hrp=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then if labels[p] then labels[p].Visible=false end; continue end
        if not labels[p] then labels[p]=makeLabel() end
        local lhrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local dist=lhrp and math.floor((hrp.Position-lhrp.Position).Magnitude) or 0
        local pos,vis=Camera:WorldToViewportPoint(hrp.Position+Vector3.new(0,3,0))
        labels[p].Text=p.Name.." ["..dist.."m]"
        labels[p].Position=Vector2.new(pos.X,pos.Y)
        labels[p].Visible=vis
    end
end)
""",
                "Highlight ESP": """local Players=game:GetService("Players")
local LP=Players.LocalPlayer
local HLs={}

local function addHL(p)
    if p==LP then return end
    local function onChar(char)
        task.wait(0.3)
        if HLs[p] then HLs[p]:Destroy() end
        local hl=Instance.new("Highlight")
        hl.Adornee=char; hl.FillColor=Color3.fromRGB(255,60,60)
        hl.FillTransparency=0.5; hl.OutlineColor=Color3.new(1,1,1)
        hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent=game:GetService("CoreGui"); HLs[p]=hl
    end
    if p.Character then onChar(p.Character) end
    p.CharacterAdded:Connect(onChar)
end

for _,p in ipairs(Players:GetPlayers()) do addHL(p) end
Players.PlayerAdded:Connect(addHL)
Players.PlayerRemoving:Connect(function(p)
    if HLs[p] then HLs[p]:Destroy(); HLs[p]=nil end
end)
""",
            },
            "Movement / Physics": {
                "Fly Script": """local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local lp=Players.LocalPlayer
local SPEED=60; local bv,bg

local char=lp.Character or lp.CharacterAdded:Wait()
local hrp=char:WaitForChild("HumanoidRootPart")
char:WaitForChild("Humanoid").PlatformStand=true
bv=Instance.new("BodyVelocity",hrp); bv.MaxForce=Vector3.new(1e5,1e5,1e5)
bg=Instance.new("BodyGyro",hrp); bg.MaxTorque=Vector3.new(1e5,1e5,1e5); bg.P=1e4

RunService.RenderStepped:Connect(function()
    local cam=workspace.CurrentCamera
    local d=Vector3.zero
    if UIS:IsKeyDown(Enum.KeyCode.W) then d=d+cam.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then d=d-cam.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then d=d-cam.CFrame.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then d=d+cam.CFrame.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then d=d+Vector3.new(0,1,0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then d=d-Vector3.new(0,1,0) end
    bv.Velocity=d.Magnitude>0 and d.Unit*SPEED or Vector3.zero
    bg.CFrame=cam.CFrame
end)
""",
                "Speed + JumpPower": """local hum=game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
hum.WalkSpeed=50
hum.JumpPower=80
""",
                "Noclip": """local RunService=game:GetService("RunService")
local lp=game:GetService("Players").LocalPlayer
local on=true
RunService.Stepped:Connect(function()
    if not on then return end
    local char=lp.Character; if not char then return end
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide=false end
    end
end)
-- Set on=false to stop
""",
                "Teleport to XYZ": """local hrp=game:GetService("Players").LocalPlayer.Character.HumanoidRootPart
hrp.CFrame=CFrame.new(0, 50, 0)
""",
                "Infinite Jump": """game:GetService("UserInputService").JumpRequest:Connect(function()
    local hum=game:GetService("Players").LocalPlayer.Character
        and game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)
""",
                "Gravity Control": """workspace.Gravity = 50  -- default is 196.2
-- 0   = zero gravity
-- 50  = moon-like
-- 196 = normal
-- 400 = heavy
""",
            },
            "Anti-Detection Templates": {
                "Anti-Kick": """local lp=game:GetService("Players").LocalPlayer
local mt=getrawmetatable(lp)
setreadonly(mt,false)
local orig=rawget(mt,"__index")
rawset(mt,"__index",newcclosure(function(self,key)
    if key=="Kick" then return function() warn("[AntiKick] blocked") end end
    return orig(self,key)
end))
setreadonly(mt,true)
""",
                "Anti-Character Reset": """local lp=game:GetService("Players").LocalPlayer
local last
game:GetService("RunService").Heartbeat:Connect(function()
    local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if last and (hrp.Position-last.Position).Magnitude>200 then
        hrp.CFrame=last; warn("[AntiReset] blocked")
    else last=hrp.CFrame end
end)
""",
                "Set Thread Identity": """if setidentity then setidentity(7)
elseif syn and syn.set_thread_identity then syn.set_thread_identity(7)
elseif setthreadidentity then setthreadidentity(7) end
""",
            },
            "Junk / Padding Code": {
                "No-op Junk (small)": """-- junk --
local _j1=math.random();local _j2=tostring(_j1);local _j3=#_j2
local _j4={};for _i=1,_j3 do _j4[_i]=_j2:sub(_i,_i) end
table.concat(_j4,"");_j4=nil
-- end junk --
""",
                "No-op Junk (large)": """-- junk --
local _jt={}
for _ji=1,32 do _jt[_ji]=math.random(0,0xFFFF) end
local _js=""
for _,v in ipairs(_jt) do _js=_js..string.char(v%94+33) end
local _jn=0
for _i=1,#_js do _jn=_jn+string.byte(_js,_i) end
_jt=nil;_js=nil;_jn=nil
-- end junk --
""",
                "Dead Branch": """-- dead branch -- never executes
if false then
    local _d={}
    for _i=1,100 do _d[_i]=_i*math.pi end
    warn(table.concat(_d,","))
end
""",
                "Variable Alias Chain": """-- alias chain to obscure symbol names
local function _w(x) return x end
local _a=_w;local _b=_a;local _c=_b;local _d=_c
-- use _d(yourValue) instead of yourValue
""",
                "Fake Module Stub": """local _fmod=setmetatable({},{
    __index=function(_,k) return function(...) return ... end end,
    __tostring=function() return "ModuleScript" end,
})
local _freq=function() return _fmod end
""",
                "String Constant Obfuscation": """-- Splits a string constant so static scanners miss it
local function _s(...) return table.concat({...}) end
local TARGET_URL = _s("https://raw.","githubusercontent",".com/User/Repo/main/script.lua")
""",
                "Fake Upvalue Chain": """-- Creates a chain of upvalues that resolve to nothing useful
local _u0 = math.huge
local _u1 = _u0 ~= _u0  -- false (NaN check)
local _u2 = _u1 and _u0 or 0
local _u3 = (_u2 * 0) + 0
local _u4 = _u3 == _u3 and _u3 or _u3
_u0=nil;_u1=nil;_u2=nil;_u3=nil;_u4=nil
""",
                "Pointless String Hashing": """-- Fake checksum that does nothing
local function _fhash(s)
    local h = 5381
    for i = 1, #s do
        h = (h * 33 + string.byte(s, i)) % 0x100000000
    end
    return h
end
local _fh1 = _fhash("padding_block_a")
local _fh2 = _fhash("padding_block_b")
local _fh3 = _fhash(tostring(_fh1 ~ _fh2))
_fhash=nil;_fh1=nil;_fh2=nil;_fh3=nil
""",
                "Fake Config Table": """-- Dummy config that is never read
local _cfg = {
    _version   = tostring(math.random(1,9)).."."..tostring(math.random(0,9)),
    _build     = math.random(1000,9999),
    _flags     = {false,true,false,false,true},
    _reserved  = {},
    _checksum  = 0,
}
for _,v in ipairs(_cfg._flags) do
    _cfg._checksum = _cfg._checksum + (v and 1 or 0)
end
_cfg = nil
""",
                "Coroutine Sink": """-- Spawns a coroutine that immediately yields and never resumes
local _co = coroutine.create(function()
    local _x = 0
    while true do
        _x = _x + 1
        coroutine.yield(_x)
    end
end)
coroutine.resume(_co)  -- advances once, result discarded
_co = nil
""",
                "Fake Integrity Nonce": """-- Generates a one-time nonce that is never validated
local function _nonce(len)
    local t = {}
    for i = 1, len do
        t[i] = string.char(math.random(65, 90))
    end
    return table.concat(t)
end
local _nc1 = _nonce(16)
local _nc2 = _nonce(16)
local _nc3 = (_nc1 ~= _nc2) -- almost always true, result unused
_nonce=nil;_nc1=nil;_nc2=nil;_nc3=nil
""",
                "Opaque Predicate (always true)": """-- Opaque predicate: evaluates to true but looks non-trivial
local _op_a = math.floor(math.abs(math.sin(0)) * 1000)   -- 0
local _op_b = math.floor(math.abs(math.cos(0)) * 1000)   -- 1000
local _op_result = (_op_a < _op_b)  -- always true
if not _op_result then
    -- unreachable dead block to confuse static analysis
    error("opaque predicate violated", 2)
end
_op_a=nil;_op_b=nil;_op_result=nil
""",
                "Opaque Predicate (always false)": """-- Opaque predicate: evaluates to false, dead block inside
local _p = (math.floor(math.pi) == 4)  -- always false
if _p then
    local _sink = {}
    for _i = 1, 64 do _sink[_i] = _i ^ 2 end
    warn(table.concat(_sink, ","))
end
_p = nil
""",
                "Fake Scheduler Heartbeat": """-- Connects to Heartbeat once, immediately disconnects
local _con
_con = game:GetService("RunService").Heartbeat:Connect(function()
    _con:Disconnect()
    _con = nil
end)
""",
                "Table Shuffle Noise": """-- Fills, shuffles, and clears a table
local _noise = {}
for _i = 1, 48 do _noise[_i] = math.random(0, 255) end
for _i = #_noise, 2, -1 do
    local _j = math.random(1, _i)
    _noise[_i], _noise[_j] = _noise[_j], _noise[_i]
end
_noise = nil
""",
                "Fake Environment Probe": """-- Probes common executor globals and stores results nowhere useful
local _probes = {
    "syn", "fluxus", "KRNL_ENV", "is_sirhurt_closure",
    "getgc", "getrawmetatable", "setreadonly", "newcclosure",
    "hookfunction", "replaceclosure", "clonefunction",
}
local _found = 0
for _, k in ipairs(_probes) do
    if rawget(_G, k) ~= nil then _found = _found + 1 end
end
_probes=nil;_found=nil
""",
                "Bitwise Scramble Pad": """-- Meaningless bitwise operations on random values
local _bv = math.random(0, 0xFFFFFF)
_bv = _bv ~ 0xDEADBE
_bv = _bv & 0xFFFFFF
_bv = (_bv << 3) | (_bv >> 21)
_bv = _bv ~ math.random(0, 0xFFFF)
_bv = nil
""",
                "Deep Metatable Dummy": """-- Creates a dummy object with a deep metatable stack
local _mk = function(n)
    local t = {}
    local mt = {}
    for _i = 1, n do
        mt = { __index = setmetatable({}, mt) }
    end
    return setmetatable(t, mt)
end
local _dummy = _mk(8)
_dummy = nil; _mk = nil
""",
                "Fake HWID Stub": """-- Generates a fake hardware fingerprint that goes unused
local function _fakeHWID()
    local parts = {}
    for i = 1, 4 do
        parts[i] = string.format("%08X", math.random(0, 0xFFFFFFFF))
    end
    return table.concat(parts, "-")
end
local _hwid = _fakeHWID()
_fakeHWID = nil; _hwid = nil
""",
                "Recursive No-op": """-- A recursive function that returns immediately at every depth
local function _rnoop(depth)
    if depth <= 0 then return 0 end
    return _rnoop(depth - 1) + 0
end
local _rres = _rnoop(12)
_rnoop = nil; _rres = nil
""",
                "Fake XOR Cipher Stub": """-- XOR encode/decode stub that produces output discarded immediately
local function _xor(data, key)
    local out = {}
    for i = 1, #data do
        out[i] = string.char(string.byte(data, i) ~ (key % 256))
        key = math.floor(key * 1.1) % 256
    end
    return table.concat(out)
end
local _enc = _xor("padding_noise_block", 0x5A)
local _dec = _xor(_enc, 0x5A)
_xor=nil;_enc=nil;_dec=nil
""",
            },
            "Variable Aliasing / Anti-Theft": {
                "Service Alias Chain": """-- Re-aliases every common service through indirection layers.
-- Script stealers that grep for raw GetService calls get noise.
local _gs = function(n) return game:GetService(n) end
local _P   = _gs("Players")
local _RS  = _gs("RunService")
local _UIS = _gs("UserInputService")
local _TS  = _gs("TweenService")
local _HS  = _gs("HttpService")
local _Rep = _gs("ReplicatedStorage")
local _CG  = _gs("CoreGui")
-- Canonical names are now aliases of the above
local Players           = _P
local RunService        = _RS
local UserInputService  = _UIS
local TweenService      = _TS
local HttpService       = _HS
local ReplicatedStorage = _Rep
local CoreGui           = _CG
local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera
local Mouse             = LocalPlayer:GetMouse()
""",
                "Indirect LocalPlayer + Character Refs": """-- Wraps LocalPlayer access behind closures so static analysis
-- can't trivially resolve Players.LocalPlayer chains.
local _getLP = function()
    return game:GetService("Players").LocalPlayer
end
local _getChar = function()
    return _getLP().Character or _getLP().CharacterAdded:Wait()
end
local _getHRP = function()
    return _getChar():WaitForChild("HumanoidRootPart")
end
local _getHum = function()
    return _getChar():FindFirstChildOfClass("Humanoid")
end
-- Expose as locals for use below
local LocalPlayer = _getLP()
local Character   = _getChar()
local HRP         = _getHRP()
local Humanoid    = _getHum()
""",
                "Shuffled Service Table": """-- Stores services in a numerically-keyed table in random order
-- so name→service mapping is non-obvious to a static reader.
local _svc = {}
local _keys = {
    {1,"Players"},{2,"RunService"},{3,"UserInputService"},
    {4,"TweenService"},{5,"HttpService"},{6,"ReplicatedStorage"},
    {7,"CoreGui"},{8,"Lighting"},{9,"SoundService"},{10,"PathfindingService"},
}
-- shuffle
for i = #_keys, 2, -1 do
    local j = math.random(1, i)
    _keys[i], _keys[j] = _keys[j], _keys[i]
end
for _, pair in ipairs(_keys) do
    _svc[pair[1]] = game:GetService(pair[2])
end
-- Access via index, not by name:
local Players           = _svc[1]
local RunService        = _svc[2]
local UserInputService  = _svc[3]
local TweenService      = _svc[4]
local HttpService       = _svc[5]
local ReplicatedStorage = _svc[6]
local CoreGui           = _svc[7]
local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera
local Mouse             = LocalPlayer:GetMouse()
_svc=nil;_keys=nil
""",
                "String-Split Service Resolver": """-- Reconstructs service name strings at runtime from fragments
-- so grep / regex scanners can't match the literal names.
local function _j(...) return table.concat({...}) end
local Players           = game:GetService(_j("Pl","aye","rs"))
local RunService        = game:GetService(_j("Run","Ser","vice"))
local UserInputService  = game:GetService(_j("User","Input","Service"))
local TweenService      = game:GetService(_j("Twe","en","Service"))
local HttpService       = game:GetService(_j("Htt","p","Service"))
local ReplicatedStorage = game:GetService(_j("Repli","cated","Storage"))
local CoreGui           = game:GetService(_j("Cor","eGui"))
local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera
local Mouse             = LocalPlayer:GetMouse()
_j=nil
""",
                "Char-Code Service Resolver": """-- Builds service name strings from character codes at runtime.
-- Defeats any scanner that matches string literals.
local function _cs(t)
    local r={}
    for i,v in ipairs(t) do r[i]=string.char(v) end
    return table.concat(r)
end
local Players           = game:GetService(_cs({80,108,97,121,101,114,115}))
local RunService        = game:GetService(_cs({82,117,110,83,101,114,118,105,99,101}))
local UserInputService  = game:GetService(_cs({85,115,101,114,73,110,112,117,116,83,101,114,118,105,99,101}))
local TweenService      = game:GetService(_cs({84,119,101,101,110,83,101,114,118,105,99,101}))
local HttpService       = game:GetService(_cs({72,116,116,112,83,101,114,118,105,99,101}))
local ReplicatedStorage = game:GetService(_cs({82,101,112,108,105,99,97,116,101,100,83,116,111,114,97,103,101}))
local CoreGui           = game:GetService(_cs({67,111,114,101,71,117,105}))
local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera
local Mouse             = LocalPlayer:GetMouse()
_cs=nil
""",
                "XOR-Encoded Service Names": """-- Service names are XOR-encoded at rest and decoded at runtime.
local _k = 0x3F
local function _dx(t)
    local r={}
    for i,v in ipairs(t) do r[i]=string.char(v ~ _k) end
    return table.concat(r)
end
-- Encoded: each byte is serviceName[i] XOR 0x3F
local Players           = game:GetService(_dx({111,91,64,102,80,81,87}))
local RunService        = game:GetService(_dx({114,90,113,126,80,81,87,76,64,80}))
local TweenService      = game:GetService(_dx({107,91,90,80,113,126,80,81,87,76,64,80}))
local HttpService       = game:GetService(_dx({103,90,90,111,126,80,81,87,76,64,80}))
local ReplicatedStorage = game:GetService(_dx({114,80,111,91,76,64,80,93,80,83,126,116,93,111,81,64,90,80}))
local CoreGui           = game:GetService(_dx({100,80,81,80,104,90,76}))
local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera
local Mouse             = LocalPlayer:GetMouse()
_dx=nil;_k=nil
""",
                "Metatable-Hidden Service Cache": """-- Stores services inside a metatable so indexing looks opaque.
local _cache = setmetatable({}, {
    __index = function(t, k)
        local ok, svc = pcall(function() return game:GetService(k) end)
        if ok then rawset(t, k, svc) end
        return svc
    end,
    __newindex = function() end,  -- freeze after first access
})
local Players           = _cache.Players
local RunService        = _cache.RunService
local UserInputService  = _cache.UserInputService
local TweenService      = _cache.TweenService
local HttpService       = _cache.HttpService
local ReplicatedStorage = _cache.ReplicatedStorage
local CoreGui           = _cache.CoreGui
local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera
local Mouse             = LocalPlayer:GetMouse()
_cache = nil
""",
                "Upvalue-Shadowed Locals": """-- Declares each canonical name twice: once as an upvalue capture,
-- once as a shadowing local. Confuses upvalue-based deobfuscators.
local Players, RunService, UserInputService, TweenService,
      HttpService, ReplicatedStorage, CoreGui
do
    local _g = game.GetService
    Players           = _g(game, "Players")
    RunService        = _g(game, "RunService")
    UserInputService  = _g(game, "UserInputService")
    TweenService      = _g(game, "TweenService")
    HttpService       = _g(game, "HttpService")
    ReplicatedStorage = _g(game, "ReplicatedStorage")
    CoreGui           = _g(game, "CoreGui")
    _g = nil
end
local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()
-- Shadow again inside an inner scope to break upvalue tracing:
do
    local Players=Players; local RunService=RunService
    local UserInputService=UserInputService; local TweenService=TweenService
    local LocalPlayer=LocalPlayer; local Camera=Camera
end
""",
                "pcall-Wrapped Service Init": """-- Wraps every GetService in a pcall so the call site is indirect
-- and errors are swallowed — harder to hook at the API level.
local function _svc(name)
    local ok, s = pcall(game.GetService, game, name)
    return ok and s or nil
end
local Players           = _svc("Players")
local RunService        = _svc("RunService")
local UserInputService  = _svc("UserInputService")
local TweenService      = _svc("TweenService")
local HttpService       = _svc("HttpService")
local ReplicatedStorage = _svc("ReplicatedStorage")
local CoreGui           = _svc("CoreGui")
local LocalPlayer       = Players and Players.LocalPlayer
local Camera            = workspace.CurrentCamera
local Mouse             = LocalPlayer and LocalPlayer:GetMouse()
_svc = nil
""",
                "Fake Duplicate Declarations": """-- Declares plausible-looking fake service variables alongside real ones.
-- Script stealers copying locals get dead weight.
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
-- Fakes (all nil — services that don't exist)
local _DataService      = pcall(game.GetService,game,"DataService")           and nil
local _PhysicsService   = pcall(game.GetService,game,"PhysicsWorldService2")  and nil
local _InputCore        = pcall(game.GetService,game,"InputCoreService")      and nil
local _EventBus         = pcall(game.GetService,game,"EventBusService")       and nil
-- Real locals
local LocalPlayer  = Players.LocalPlayer
local Camera       = workspace.CurrentCamera
local Mouse        = LocalPlayer:GetMouse()
_DataService=nil;_PhysicsService=nil;_InputCore=nil;_EventBus=nil
""",
            },
        }
        for category, templates in templates_data.items():
            category_item = QTreeWidgetItem(self.templates_tree)
            category_item.setText(0, category)
            category_item.setExpanded(False)

            for name, code in templates.items():
                template_item = QTreeWidgetItem(category_item)
                template_item.setText(0, name)
                template_item.setData(0, Qt.ItemDataRole.UserRole, code)

    def insert_template(self, item, column):
        """Insert selected template into the current Monaco editor."""
        template_code = item.data(0, Qt.ItemDataRole.UserRole)
        if not template_code:
            return
        editor = self.get_current_editor()
        if not editor:
            return
        # Append template at the end of whatever is already in the editor
        existing = editor.get_text()
        separator = "\n\n" if existing.strip() else ""
        editor.set_text(existing + separator + template_code)
        editor.setFocus()

    # --- Find & Replace Methods ---
    def show_find_replace(self):
        """Show the Find & Replace dialog."""
        if not self.find_replace_dialog:
            self.find_replace_dialog = FindReplaceDialog(self)

            # Connect buttons to methods
            self.find_replace_dialog.btn_find_next.clicked.connect(self.find_next)
            self.find_replace_dialog.btn_find_prev.clicked.connect(self.find_previous)
            self.find_replace_dialog.btn_replace.clicked.connect(self.replace_current)
            self.find_replace_dialog.btn_replace_all.clicked.connect(self.replace_all)

        self.find_replace_dialog.show()
        self.find_replace_dialog.raise_()
        self.find_replace_dialog.activateWindow()

    def find_next(self):
        """Trigger Monaco's built-in find widget (next)."""
        if not self.find_replace_dialog:
            return
        editor = self.get_current_editor()
        if not editor:
            return
        search_text = self.find_replace_dialog.find_input.toPlainText()
        if not search_text:
            self.find_replace_dialog.status_label.setText("Please enter text to find")
            return
        case = str(self.find_replace_dialog.case_sensitive.isChecked()).lower()
        whole = str(self.find_replace_dialog.whole_word.isChecked()).lower()
        esc = search_text.replace("\\", "\\\\").replace("`", "\\`").replace("$", "\\$")
        js = (
            f"editor.getAction('actions.find').run();"
            f"editor.trigger('', 'editor.action.nextMatchFindAction', {{}});"
        )
        # Use Monaco's IFindController API for case/word options
        js_full = f"""
(function() {{
    var c = editor.getContribution('editor.contrib.findController');
    if (c) {{
        c.start({{
            forceRevealReplace: false,
            seedSearchStringFromSelection: 'never',
            shouldFocus: 0,
            shouldAnimate: false,
            updateSearchScope: false,
            loop: true
        }});
        c.setSearchString(`{esc}`);
        c.find(false);
    }}
}})();
"""
        editor.page().runJavaScript(js_full)
        self.find_replace_dialog.status_label.setText(f"Searching: {search_text}")

    def find_previous(self):
        """Trigger Monaco's built-in find widget (previous)."""
        if not self.find_replace_dialog:
            return
        editor = self.get_current_editor()
        if not editor:
            return
        search_text = self.find_replace_dialog.find_input.toPlainText()
        if not search_text:
            self.find_replace_dialog.status_label.setText("Please enter text to find")
            return
        esc = search_text.replace("\\", "\\\\").replace("`", "\\`").replace("$", "\\$")
        js_full = f"""
(function() {{
    var c = editor.getContribution('editor.contrib.findController');
    if (c) {{
        c.setSearchString(`{esc}`);
        c.find(true);
    }}
}})();
"""
        editor.page().runJavaScript(js_full)
        self.find_replace_dialog.status_label.setText(f"Searching: {search_text}")

    def replace_current(self):
        """Replace the first occurrence of the search text from cursor onward."""
        if not self.find_replace_dialog:
            return
        editor = self.get_current_editor()
        if not editor:
            return
        search_text = self.find_replace_dialog.find_input.toPlainText()
        replace_text = self.find_replace_dialog.replace_input.toPlainText()
        if not search_text:
            self.find_replace_dialog.status_label.setText("Please enter text to find")
            return
        code = editor.get_text()
        idx = code.find(search_text)
        if idx == -1:
            self.find_replace_dialog.status_label.setText(f"Not found: {search_text}")
            return
        new_code = code[:idx] + replace_text + code[idx + len(search_text) :]
        editor.set_text(new_code)
        self.find_replace_dialog.status_label.setText("Replaced 1 occurrence")

    def replace_all(self):
        """Replace all occurrences of the search text."""
        if not self.find_replace_dialog:
            return
        editor = self.get_current_editor()
        if not editor:
            return
        search_text = self.find_replace_dialog.find_input.toPlainText()
        replace_text = self.find_replace_dialog.replace_input.toPlainText()
        if not search_text:
            self.find_replace_dialog.status_label.setText("Please enter text to find")
            return
        code = editor.get_text()
        flags = 0 if self.find_replace_dialog.case_sensitive.isChecked() else re.IGNORECASE
        pat = re.escape(search_text)
        if self.find_replace_dialog.whole_word.isChecked():
            pat = r"\b" + pat + r"\b"
        new_code, count = re.subn(pat, lambda m: replace_text, code, flags=flags)
        editor.set_text(new_code)
        self.find_replace_dialog.status_label.setText(f"Replaced {count} occurrence(s)")

    # --- Recent Files Methods ---
    def load_recent_files(self):
        """Load recent files from a config file."""
        config_file = os.path.join(os.path.expanduser("~"), ".luabox_recent")
        if os.path.exists(config_file):
            try:
                with open(config_file, "r") as f:
                    self.recent_files = [line.strip() for line in f.readlines() if line.strip()]
                    self.recent_files = self.recent_files[: self.max_recent_files]
            except:
                pass

    def save_recent_files(self):
        """Save recent files to a config file."""
        config_file = os.path.join(os.path.expanduser("~"), ".luabox_recent")
        try:
            with open(config_file, "w") as f:
                for filepath in self.recent_files:
                    f.write(filepath + "\n")
        except:
            pass

    def add_recent_file(self, filepath):
        """Add a file to the recent files list."""
        # Remove if already exists
        if filepath in self.recent_files:
            self.recent_files.remove(filepath)

        # Add to beginning
        self.recent_files.insert(0, filepath)

        # Keep only max recent files
        self.recent_files = self.recent_files[: self.max_recent_files]

        # Save to disk
        self.save_recent_files()

    def show_recent_files_menu(self):
        """Show a dropdown menu with recent files."""
        if not self.recent_files:
            QMessageBox.information(self, "No Recent Files", "No recent files to display.")
            return

        menu = QMenu(self)

        for filepath in self.recent_files:
            if os.path.exists(filepath):
                filename = os.path.basename(filepath)
                action = menu.addAction(filename)
                action.setData(filepath)
                action.triggered.connect(lambda checked, path=filepath: self.open_recent_file(path))
            else:
                # File doesn't exist anymore, show grayed out
                filename = os.path.basename(filepath) + " (missing)"
                action = menu.addAction(filename)
                action.setEnabled(False)

        menu.addSeparator()
        clear_action = menu.addAction("Clear Recent Files")
        clear_action.triggered.connect(self.clear_recent_files)

        # Show menu at button position
        menu.exec(self.btn_recent.mapToGlobal(self.btn_recent.rect().bottomLeft()))

    def open_recent_file(self, filepath):
        """Open a file from the recent files list."""
        if os.path.exists(filepath):
            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    content = f.read()
                editor = self.create_new_tab(os.path.basename(filepath))
                editor.file_path = filepath
                QTimer.singleShot(600, lambda: editor.set_text(content))
                self.add_recent_file(filepath)
            except Exception as e:
                QMessageBox.critical(self, "Error", f"Failed to open file: {str(e)}")

    # ── Lint / Analyze ─────────────────────────────────────────────────────────

    def run_lint(self):
        """Run LuaAnalyzer on the current editor and populate the lint panel."""
        editor = self.get_current_editor()
        if not editor:
            return
        code = editor.get_text()
        if not code.strip():
            QMessageBox.information(self, "Lint", "Editor is empty — nothing to analyze.")
            return

        issues = LuaAnalyzer.analyze(code)
        self._lint_all_issues = issues
        self._lint_filter_combo.setCurrentText("All")
        self._lint_populate_table(issues)

        fatal = sum(1 for x in issues if x['sev'] == 'fatal')
        warn  = sum(1 for x in issues if x['sev'] == 'warn')
        info  = sum(1 for x in issues if x['sev'] == 'info')

        if not issues:
            self._lint_stats_lbl.setText("  ✓  No issues found")
            self._lint_stats_lbl.setStyleSheet("font-size:9pt; color:#3fb950;")
        else:
            parts = []
            if fatal: parts.append(f"● {fatal} fatal")
            if warn:  parts.append(f"● {warn} warn")
            if info:  parts.append(f"● {info} info")
            self._lint_stats_lbl.setText("  " + "   ".join(parts))
            self._lint_stats_lbl.setStyleSheet("font-size:9pt;")

        self._dock_lint.show()
        self._dock_lint.raise_()
        self.statusBar().showMessage(
            f"Lint complete — {fatal} fatal, {warn} warnings, {info} info", 3000
        )

    def _lint_populate_table(self, issues):
        self._lint_table.clear()
        SEV_COLORS = {'fatal': '#f85149', 'warn': '#e3b341', 'info': '#58a6ff'}
        SEV_LABELS = {'fatal': '🔴 FATAL', 'warn': '🟡 WARN', 'info': '🔵 INFO'}
        for issue in issues:
            item = QTreeWidgetItem([
                SEV_LABELS.get(issue['sev'], issue['sev']),
                str(issue['line']),
                issue['title'],
                issue['desc'],
                issue['code'],
            ])
            color = SEV_COLORS.get(issue['sev'], '#cccccc')
            from PyQt6.QtGui import QColor
            item.setForeground(0, QColor(color))
            item.setForeground(2, QColor(color))
            item.setData(0, Qt.ItemDataRole.UserRole, issue['line'])
            self._lint_table.addTopLevelItem(item)

    def _lint_apply_filter(self, text):
        filt = text.lower()
        filtered = self._lint_all_issues if filt == 'all' else [
            x for x in self._lint_all_issues if x['sev'] == filt
        ]
        self._lint_populate_table(filtered)

    def _lint_jump_to_line(self, item, _col):
        """Scroll the Monaco editor to the line of the clicked issue."""
        line = item.data(0, Qt.ItemDataRole.UserRole)
        if not line:
            return
        editor = self.get_current_editor()
        if not editor:
            return
        js = f"""
(function() {{
    editor.revealLineInCenter({line});
    editor.setPosition({{ lineNumber: {line}, column: 1 }});
    editor.focus();
}})();
"""
        editor.page().runJavaScript(js)

    def format_current_code(self):
        """Show format-options dialog, then format the code in the current editor tab."""
        editor = self.get_current_editor()
        if not editor:
            return
        code = editor.get_text()
        if not code.strip():
            QMessageBox.information(self, "Format Code", "No code to format.")
            return
        if not hasattr(self, "_last_format_options"):
            self._last_format_options = None
        dialog = FormatOptionsDialog(self, self._last_format_options)
        if not dialog.exec():
            return
        options = dialog.get_options()
        self._last_format_options = options
        try:
            formatted_code = self.format_lua_code(code, options)
            editor.set_text(formatted_code)
            self.statusBar().showMessage("Code formatted successfully", 3000)
        except Exception as e:
            QMessageBox.warning(self, "Format Error", f"Error formatting code: {str(e)}")

    def format_with_stylua(self):
        """
        Format the current editor content using stylua.exe.
        Looks for stylua.exe in the same directory as LuaBox.pyw (or the frozen bundle dir).
        Shortcut: Ctrl+Alt+F
        """
        editor = self.get_current_editor()
        if not editor:
            return
        code = editor.get_text()
        if not code.strip():
            QMessageBox.information(self, "StyLua", "Editor is empty — nothing to format.")
            return

        # Resolve stylua.exe path — same dir as the script / bundle
        if getattr(sys, "frozen", False):
            base_dir = sys._MEIPASS
        else:
            base_dir = os.path.dirname(os.path.abspath(__file__))
        stylua_path = os.path.join(base_dir, "stylua.exe")

        if not os.path.isfile(stylua_path):
            QMessageBox.warning(
                self,
                "StyLua Not Found",
                f"Could not find stylua.exe at:\n{stylua_path}\n\n"
                "Place stylua.exe in the same folder as LuaBox.pyw and try again.",
            )
            return

        # Write to a temp file, run stylua in-place, read back
        tmp_fd, tmp_path = tempfile.mkstemp(suffix=".lua")
        try:
            with os.fdopen(tmp_fd, "w", encoding="utf-8") as f:
                f.write(code)

            result = subprocess.run([stylua_path, tmp_path], capture_output=True, text=True, timeout=15)

            if result.returncode != 0:
                err = (result.stderr or result.stdout or "(no output)").strip()
                QMessageBox.critical(
                    self, "StyLua Error", f"stylua exited with code {result.returncode}:\n\n{err[:800]}"
                )
                return

            with open(tmp_path, "r", encoding="utf-8") as f:
                formatted = f.read()

            editor.set_text(formatted)
            self.statusBar().showMessage("StyLua: formatted successfully", 3000)

        except subprocess.TimeoutExpired:
            QMessageBox.critical(self, "StyLua", "stylua timed out after 15 seconds.")
        except Exception as e:
            QMessageBox.critical(self, "StyLua Error", str(e))
        finally:
            try:
                os.unlink(tmp_path)
            except Exception:
                pass

    def format_lua_code(self, code, options: dict = None):
        """
        Lua beautifier / formatter with customisable options.

        Options dict (see FormatOptionsDialog.DEFAULTS for keys):
          indent_style         – 'spaces' | 'tabs'
          indent_size          – int 1-8 (ignored when style=tabs)
          max_blank_lines      – int 0-5
          space_operators      – bool  (== ~= <= >= ..)
          space_after_comma    – bool
          trailing_whitespace  – bool  (strip trailing spaces)
          normalize_min_indent – bool  (shift block left so min indent = 0)
          semicolon_removal    – bool  (remove standalone ';' lines)
          newline_before_end   – bool  (insert blank line before 'end')
          align_assignments    – bool  (align '=' in consecutive local lines)
          shape_mode           – bool  (reflow tokens into a silhouette shape)
          shape_name           – str   (shape key from FormatOptionsDialog.SHAPES)
          shape_custom         – str   (raw ASCII art for Custom shape)
          shape_width          – int   (target character width of the shape)
        """
        import re

        if options is None:
            options = dict(FormatOptionsDialog.DEFAULTS)

        # ── Shape mode bypasses normal indentation entirely ───────────────
        if options.get("shape_mode"):
            return self._shape_format_code(code, options)

        indent_unit = "\t" if options.get("indent_style") == "tabs" else " " * options.get("indent_size", 4)
        max_blanks = options.get("max_blank_lines", 2)

        # ── Pass 1: tokenise into (kind, text) segments ──────────────────
        # kind = 'code' | 'string' | 'comment'
        LONG_STR = re.compile(r"\[(=*)\[")
        segments = []
        i, n = 0, len(code)

        while i < n:
            m = LONG_STR.match(code, i)
            if m:
                level = len(m.group(1))
                close = "]" + "=" * level + "]"
                end_idx = code.find(close, m.end())
                if end_idx != -1:
                    end_idx += len(close)
                    kind = "comment" if (i >= 2 and code[i - 2 : i] == "--") else "string"
                    segments.append((kind, code[i:end_idx]))
                    i = end_idx
                    continue
            if code[i] in ('"', "'"):
                q = code[i]
                j = i + 1
                while j < n:
                    if code[j] == "\\":
                        j += 2
                        continue
                    if code[j] == q:
                        j += 1
                        break
                    j += 1
                segments.append(("string", code[i:j]))
                i = j
                continue
            if code[i : i + 2] == "--":
                end_idx = code.find("\n", i)
                if end_idx == -1:
                    end_idx = n
                segments.append(("comment", code[i:end_idx]))
                i = end_idx
                continue
            j = i
            while j < n:
                m2 = LONG_STR.match(code, j)
                if m2:
                    break
                if code[j : j + 2] == "--" or code[j] in ('"', "'"):
                    break
                if code[j] == "\n":
                    j += 1
                    break
                j += 1
            segments.append(("code", code[i:j]))
            i = j

        # ── Pass 2: operator / comma spacing (code segments only) ────────
        def fmt_code(s):
            if options.get("space_operators", True):
                s = re.sub(r"\s*==\s*", " == ", s)
                s = re.sub(r"\s*~=\s*", " ~= ", s)
                s = re.sub(r"\s*<=\s*", " <= ", s)
                s = re.sub(r"\s*>=\s*", " >= ", s)
                s = re.sub(r"\s*\.\.\s*", " .. ", s)
            if options.get("space_after_comma", True):
                s = re.sub(r",(\S)", r", \1", s)
                s = re.sub(r"\s+,", ",", s)
            # collapse runs of interior spaces (outside strings)
            s = re.sub(r"(?<=\S) {2,}", " ", s)
            return s

        rebuilt = "".join(fmt_code(t) if k == "code" else t for k, t in segments)

        # ── Pass 2b: strip existing leading whitespace before re-indenting
        rebuilt = "\n".join(line.lstrip() for line in rebuilt.split("\n"))

        # ── Pass 3: line-by-line indent ───────────────────────────────────
        KW_CLOSE = re.compile(r"^\s*(end|until|else|elseif)\b")
        KW_ELSE = re.compile(r"^\s*(else|elseif)\b")

        def count_deltas(stripped):
            bare = re.sub(r'"(?:[^"\\]|\\.)*"', '""', stripped)
            bare = re.sub(r"'(?:[^'\\]|\\.)*'", "''", bare)
            bare = re.sub(r"--.*$", "", bare)
            opens = 0
            if re.search(r"\bfunction\b", bare):
                opens += 1
            if re.search(r"\bif\b", bare) and re.search(r"\bthen\b", bare):
                opens += 1
            if re.search(r"\belseif\b", bare) and re.search(r"\bthen\b", bare):
                opens += 1
            if re.search(r"\bfor\b", bare) and re.search(r"\bdo\b", bare):
                opens += 1
            if re.search(r"\bwhile\b", bare) and re.search(r"\bdo\b", bare):
                opens += 1
            if re.match(r"^\s*do\b", stripped) and not re.search(r"\bfor\b|\bwhile\b", bare):
                opens += 1
            if re.match(r"^\s*repeat\b", stripped):
                opens += 1
            closes = len(re.findall(r"\bend\b", bare)) + len(re.findall(r"\buntil\b", bare))
            return opens, closes

        lines = rebuilt.split("\n")
        out = []
        depth = 0
        blank_run = 0
        in_ml = False
        ml_close = None

        for raw in lines:
            stripped = raw.strip()

            # ── optional semicolon removal ────────────────────────────────
            if options.get("semicolon_removal") and stripped == ";":
                continue

            if not stripped:
                blank_run += 1
                if blank_run <= max_blanks:
                    out.append("")
                continue
            blank_run = 0

            # multi-line string/comment passthrough
            if in_ml:
                out.append(indent_unit * depth + stripped)
                if ml_close and ml_close in stripped:
                    in_ml = False
                    ml_close = None
                continue

            ml_m = re.search(r"--(=*)\[\[|\[(=*)\[", stripped)
            if ml_m:
                eq = ml_m.group(1) if ml_m.group(1) is not None else (ml_m.group(2) or "")
                close = "]" + eq + "]"
                if close not in stripped[ml_m.end() :]:
                    in_ml = True
                    ml_close = close

            if stripped.startswith("--"):
                out.append(indent_unit * depth + stripped)
                continue

            is_close = bool(KW_CLOSE.match(stripped))
            is_else = bool(KW_ELSE.match(stripped))

            if is_close:
                depth = max(0, depth - 1)

            # ── optional blank line before 'end' ──────────────────────────
            if options.get("newline_before_end") and re.match(r"^end\b", stripped):
                if out and out[-1] != "":
                    out.append("")

            line_text = indent_unit * depth + stripped
            if options.get("trailing_whitespace", True):
                line_text = line_text.rstrip()
            out.append(line_text)

            if is_else:
                depth += 1
            else:
                o, c = count_deltas(stripped)
                if is_close:
                    c -= 1
                depth = max(0, depth + o - c)

        result = "\n".join(out)

        # ── Pass 4: collapse excess blank lines ───────────────────────────
        if max_blanks >= 0:
            pattern = r"\n{" + str(max_blanks + 2) + r",}"
            result = re.sub(pattern, "\n" * (max_blanks + 1), result)

        # ── Pass 5: optional – align consecutive 'local x = ...' blocks ──
        if options.get("align_assignments"):
            result = self._align_local_assignments(result)

        # ── Pass 6: normalise minimum indent to zero ──────────────────────
        if options.get("normalize_min_indent", True):
            out_lines = result.split("\n")
            indents = [
                len(l) - len(l.lstrip()) for l in out_lines if l.strip() and not l.lstrip().startswith("--")
            ]
            if indents:
                shift = min(indents)
                if shift > 0:
                    out_lines = [
                        l[shift:] if len(l) >= shift and l[:shift] == l[:shift][0] * shift else l
                        for l in out_lines
                    ]
                    result = "\n".join(out_lines)

        return result

    @staticmethod
    def _align_local_assignments(code: str) -> str:
        """
        Align the '=' sign in runs of consecutive 'local x = ...' lines.
        Lines that are blank or non-local break a run.
        """
        import re

        LOCAL_RE = re.compile(r"^(\s*local\s+\w[\w\d_]*)\s*=\s*(.+)$")
        lines = code.split("\n")
        out = []
        i = 0

        while i < len(lines):
            m = LOCAL_RE.match(lines[i])
            if not m:
                out.append(lines[i])
                i += 1
                continue

            # collect the run
            run_start = i
            run = []
            while i < len(lines):
                lm = LOCAL_RE.match(lines[i])
                if lm:
                    run.append((lines[i], lm.group(1), lm.group(2)))
                    i += 1
                elif lines[i].strip() == "":
                    break
                else:
                    break

            if len(run) == 1:
                out.append(run[0][0])
            else:
                max_lhs = max(len(r[1]) for r in run)
                for orig, lhs, rhs in run:
                    out.append(lhs.ljust(max_lhs) + " = " + rhs)
            # consume any blank lines that ended the run
            while i < len(lines) and lines[i].strip() == "":
                out.append(lines[i])
                i += 1

        return "\n".join(out)

    @staticmethod
    def _shape_format_code(code: str, options: dict) -> str:
        """
        Reflow code tokens so the block of text forms a shape silhouette.

        Strategy:
          1. Tokenise code into a flat list of atomic Lua tokens,
             stripping all original whitespace/newlines.
          2. Load the shape bitmap and scale it to `shape_width` columns.
          3. For each row of the bitmap, find the leftmost and rightmost
             filled cell to define a contiguous content span. Pack tokens
             left-to-right within that span.
          4. Tokens that are longer than the current row's span are always
             advanced (never stall) -- they get split across the boundary so
             tok_idx always moves forward and no row stalls indefinitely.
          5. Any tokens still remaining after the shape is exhausted get
             appended as wrapped lines at the bottom so no code is lost.
        """
        import re

        shape_name = options.get("shape_name", "Among Us")
        target_w = max(40, options.get("shape_width", 120))
        custom_text = options.get("shape_custom", "")

        # -- 1. Get silhouette rows ------------------------------------------
        if shape_name == "Custom":
            raw_rows = [l for l in custom_text.split("\n") if l.strip()]
        else:
            raw_rows = list(FormatOptionsDialog.SHAPES.get(shape_name, []))

        if not raw_rows:
            return code  # nothing to do

        # -- 2. Scale rows to target_w ----------------------------------------
        # Nearest-neighbour scaling; guard src_col so it never goes out of range.
        def scale_row(row, target):
            src_w = max(len(row), 1)
            result = []
            for col in range(target):
                src_col = min(int(col * src_w / target), src_w - 1)
                result.append("#" if row[src_col] != " " else " ")
            return "".join(result)

        rows = [scale_row(r, target_w) for r in raw_rows]

        # -- 3. Tokenise: preserve Lua tokens as atomic units -----------------
        TOKEN_RE = re.compile(
            r'"(?:[^"\\]|\\.)*"'  # double-quoted string
            r"|'(?:[^'\\]|\\.)*'"  # single-quoted string
            r"|--\[=*\[.*?\]=*\]"  # long comment  --[[ ... ]]
            r"|--[^\n]*"  # single-line comment
            r"|\[=*\[.*?\]=*\]"  # long string  [[ ... ]]
            r"|[a-zA-Z_]\w*"  # identifier / keyword
            r"|0[xX][0-9a-fA-F]+"  # hex number
            r"|\d+\.?\d*(?:[eE][+-]?\d+)?"  # decimal number
            r"|\.\.\.|\.\.|[~<>=!]="  # multi-char operators (longest first)
            r"|[^\s]",  # any other single non-space char
            re.DOTALL,
        )
        tokens = list(TOKEN_RE.findall(code))
        if not tokens:
            return code

        tok_idx = 0
        out_lines = []

        # -- 4. Pack tokens row by row ----------------------------------------
        for row in rows:
            if tok_idx >= len(tokens):
                out_lines.append("")
                continue

            # Use the span from leftmost to rightmost filled cell.
            # This respects interior gaps (e.g. Among Us visor cutout) visually.
            first_fill = next((c for c, ch in enumerate(row) if ch == "#"), None)
            last_fill_rev = next((c for c, ch in enumerate(reversed(row)) if ch == "#"), None)

            if first_fill is None:
                out_lines.append("")
                continue

            left = first_fill
            last_fill_col = (target_w - 1) - last_fill_rev  # convert to column from left
            budget = last_fill_col - left + 1  # inclusive span width

            if budget <= 0:
                out_lines.append("")
                continue

            # Protected tokens must never be character-split -- only skipped to next row.
            # Strings, comments, long strings, identifiers, keywords, and numbers are all
            # protected. Only pure-punctuation/operator tokens (no alphanum, no quotes) can
            # be hard-split, but since they are at most 3 chars they almost always fit anyway.
            def is_protected(tok):
                if not tok:
                    return False
                if tok[0] in ('"', "'", "[", "-"):
                    return True
                # identifiers, keywords, numbers -- contain alphanumeric chars
                return any(c.isalnum() or c == "_" for c in tok)

            line_tokens = []
            used = 0
            first_tok = tokens[tok_idx]

            if len(first_tok) > budget:
                if is_protected(first_tok):
                    # Protected literal too wide -- leave this row blank, retry next row.
                    out_lines.append(" " * left)
                    continue
                else:
                    # Plain identifier/operator/number: safe to split at char boundary.
                    cut = first_tok[:budget]
                    remainder = first_tok[budget:]
                    line_tokens.append(cut)
                    used = len(cut)
                    if remainder:
                        tokens[tok_idx] = remainder  # leftover retried next row
                    else:
                        tok_idx += 1
            else:
                line_tokens.append(first_tok)
                used = len(first_tok)
                tok_idx += 1

            # Pack additional tokens until budget is exhausted.
            while tok_idx < len(tokens):
                tok = tokens[tok_idx]
                need = 1 + len(tok)
                if used + need > budget:
                    break
                line_tokens.append(tok)
                used += need
                tok_idx += 1

            content = " ".join(line_tokens).ljust(budget)
            out_lines.append(" " * left + content)

        # -- 5. If tokens remain after one pass, cycle the shape rows again -------
        # Keep repeating shape rows until every token is placed. This prevents
        # leftover tokens from being dumped as unshaped flat text below the shape.
        cycle_pass = 0
        max_cycles = 20  # safety cap
        while tok_idx < len(tokens) and cycle_pass < max_cycles:
            cycle_pass += 1
            for row in rows:
                if tok_idx >= len(tokens):
                    break

                first_fill_c = next((c for c, ch in enumerate(row) if ch == "#"), None)
                last_fill_rev_c = next((c for c, ch in enumerate(reversed(row)) if ch == "#"), None)
                if first_fill_c is None:
                    out_lines.append("")
                    continue

                left_c = first_fill_c
                lfc = (target_w - 1) - last_fill_rev_c
                budget_c = lfc - left_c + 1
                if budget_c <= 0:
                    out_lines.append("")
                    continue

                def is_protected_c(tok):
                    if not tok:
                        return False
                    if tok[0] in ('"', "'", "[", "-"):
                        return True
                    return any(c.isalnum() or c == "_" for c in tok)

                lt2 = []
                used2 = 0
                ft2 = tokens[tok_idx]

                if len(ft2) > budget_c:
                    if is_protected_c(ft2):
                        out_lines.append(" " * left_c)
                        continue
                    else:
                        cut2 = ft2[:budget_c]
                        rem2 = ft2[budget_c:]
                        lt2.append(cut2)
                        used2 = len(cut2)
                        if rem2:
                            tokens[tok_idx] = rem2
                        else:
                            tok_idx += 1
                else:
                    lt2.append(ft2)
                    used2 = len(ft2)
                    tok_idx += 1

                while tok_idx < len(tokens):
                    t2 = tokens[tok_idx]
                    n2 = 1 + len(t2)
                    if used2 + n2 > budget_c:
                        break
                    lt2.append(t2)
                    used2 += n2
                    tok_idx += 1

                c2 = " ".join(lt2).ljust(budget_c)
                out_lines.append(" " * left_c + c2)

        return "\n".join(out_lines)

    def clear_recent_files(self):
        """Clear the recent files list."""
        reply = QMessageBox.question(
            self,
            "Clear Recent Files",
            "Are you sure you want to clear the recent files list?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
        )
        if reply == QMessageBox.StandardButton.Yes:
            self.recent_files = []
            self.save_recent_files()

    # ── Obfuscator ─────────────────────────────────────────────────────────────

    def show_obfuscator_tab(self):
        """Switch the left panel to the Obfuscate tab."""
        # Find the tab index by title
        for i in range(self._left_panel_tabs.count()):
            if "Obfusc" in self._left_panel_tabs.tabText(i):
                self._left_panel_tabs.setCurrentIndex(i)
                return

    def _obf_browse_lua(self):
        """Browse for lua.exe."""
        path, _ = QFileDialog.getOpenFileName(
            self, "Select lua.exe", "", "Executable (*.exe lua lua.exe);;All Files (*)"
        )
        if path:
            self._obf_lua_path.setText(path)

    def _obf_browse_script(self):
        """Browse for the bundled main.lua obfuscator script."""
        path, _ = QFileDialog.getOpenFileName(
            self, "Select bundled obfuscator script", "", "Lua Files (*.lua);;All Files (*)"
        )
        if path:
            self._obf_script_path.setText(path)

    def run_obfuscator(self):
        """
        Invoke the bundled ZukaTech obfuscator:
            lua.exe main.lua <input.lua> <preset> <output.lua>
        Output is written to a temp file then read back into LuaBox.
        """
        editor = self.get_current_editor()
        if not editor:
            QMessageBox.warning(self, "Obfuscator", "No active editor tab.")
            return

        code = editor.get_text()
        if not code.strip():
            QMessageBox.warning(self, "Obfuscator", "Editor is empty.")
            return

        lua_exe = self._obf_lua_path.text().strip()
        script  = self._obf_script_path.text().strip()

        if not lua_exe or not os.path.isfile(lua_exe):
            QMessageBox.warning(self, "Obfuscator",
                "lua.exe path is not set or invalid.")
            return

        if not script or not os.path.isfile(script):
            QMessageBox.warning(self, "Obfuscator",
                "Bundled main.lua path is not set or invalid.")
            return

        preset = self._obf_preset.currentText()

        # Write source to a temp file
        tmp_dir  = tempfile.mkdtemp()
        in_path  = os.path.join(tmp_dir, "input.lua")
        out_path = os.path.join(tmp_dir, "input.obfuscated.lua")

        try:
            with open(in_path, "w", encoding="utf-8") as f:
                f.write(code)
        except Exception as e:
            QMessageBox.critical(self, "Obfuscator", f"Failed to write temp file:\n{e}")
            return

        # lua main.lua input.lua <preset> output.lua
        cmd = [lua_exe, script, in_path, preset, out_path]

        self._obf_status.setText("Running...")
        self._obf_run_btn.setEnabled(False)
        QApplication.processEvents()

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=60,
                cwd=os.path.dirname(script),   # run from script dir so any relative requires resolve
            )
        except subprocess.TimeoutExpired:
            self._obf_run_btn.setEnabled(True)
            self._obf_status.setText("Timed out after 60 s")
            return
        except Exception as e:
            self._obf_run_btn.setEnabled(True)
            self._obf_status.setText(f"Launch error: {e}")
            QMessageBox.critical(self, "Obfuscator", f"Failed to launch obfuscator:\n{e}")
            return
        finally:
            self._obf_run_btn.setEnabled(True)

        stderr_txt = result.stderr.strip() if result.stderr else ""
        stdout_txt = result.stdout.strip() if result.stdout else ""

        if result.returncode != 0:
            details = stderr_txt or stdout_txt or "(no output)"
            self._obf_status.setText(f"Exited {result.returncode}")
            QMessageBox.critical(self, "Obfuscator Failed",
                f"Exited {result.returncode}\n\n{details[:800]}")
            return

        # Read the output file back
        if not os.path.isfile(out_path):
            # Fallback — scan temp dir for any .lua that isn't the input
            candidates = [f for f in os.listdir(tmp_dir)
                          if f != "input.lua" and f.endswith(".lua")]
            if candidates:
                out_path = os.path.join(tmp_dir, candidates[0])
            else:
                self._obf_status.setText("Output file not found")
                QMessageBox.critical(self, "Obfuscator",
                    f"Obfuscator ran but no output file was produced.\n\nstdout:\n{stdout_txt[:400]}")
                return

        try:
            with open(out_path, "r", encoding="utf-8", errors="replace") as f:
                obf_code = f.read()
        except Exception as e:
            self._obf_status.setText(f"Read error: {e}")
            QMessageBox.critical(self, "Obfuscator", f"Could not read output file:\n{e}")
            return

        if self._obf_load_result.isChecked():
            new_editor = self.create_new_tab("obfuscated.lua")
            QTimer.singleShot(600, lambda: new_editor.set_text(obf_code))
        else:
            editor.set_text(obf_code)

        in_kb  = len(code.encode())    / 1024
        out_kb = len(obf_code.encode()) / 1024
        ratio  = (out_kb / in_kb * 100) if in_kb > 0 else 0
        self._obf_status.setText(f"Done  {in_kb:.1f} KB -> {out_kb:.1f} KB ({ratio:.0f}%)")
        self.statusBar().showMessage(
            f"Obfuscation complete  ({preset},  {in_kb:.1f} -> {out_kb:.1f} KB)", 4000)

        try:
            import shutil
            shutil.rmtree(tmp_dir, ignore_errors=True)
        except Exception:
            pass

    # ── Terminal ───────────────────────────────────────────────────────────────

    def eventFilter(self, obj, event):
        from PyQt6.QtCore import QEvent

        if obj is self._term_input and event.type() == QEvent.Type.KeyPress:
            key = event.key()
            if key == Qt.Key.Key_Up:
                if self._term_history and self._term_hist_idx > 0:
                    self._term_hist_idx -= 1
                    self._term_input.setText(self._term_history[self._term_hist_idx])
                return True
            if key == Qt.Key.Key_Down:
                self._term_hist_idx = min(self._term_hist_idx + 1, len(self._term_history))
                if self._term_hist_idx < len(self._term_history):
                    self._term_input.setText(self._term_history[self._term_hist_idx])
                else:
                    self._term_input.clear()
                return True
        return super().eventFilter(obj, event)

    def _term_write(self, text, colour=None):
        if colour:
            escaped = (
                text.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace(" ", "&nbsp;")
                .replace(chr(10), "<br>")
            )
            self._term_output.appendHtml(f'<span style="color:{colour};">{escaped}</span>')
        else:
            self._term_output.appendPlainText(text.rstrip())
        sb = self._term_output.verticalScrollBar()
        sb.setValue(sb.maximum())

    def _term_run(self):
        cmd = self._term_input.text().strip()
        if not cmd:
            return
        if not self._term_history or self._term_history[-1] != cmd:
            self._term_history.append(cmd)
        self._term_hist_idx = len(self._term_history)
        self._term_input.clear()
        cwd = os.getcwd()
        self._term_write(f"{cwd} $ {cmd}", colour="#6cb6ff")
        parts = cmd.split(None, 1)
        if parts[0] == "cd":
            target = os.path.expandvars(os.path.expanduser(parts[1].strip() if len(parts) > 1 else "~"))
            try:
                os.chdir(target)
                self._term_cwd_label.setText(os.getcwd())
            except Exception as e:
                self._term_write(str(e), colour="#f97583")
            return
        if parts[0] in ("clear", "cls"):
            self._term_clear()
            return
        self._term_kill()
        self._term_process = QProcess(self)
        self._term_process.setWorkingDirectory(os.getcwd())
        self._term_process.setProcessEnvironment(QProcessEnvironment.systemEnvironment())
        self._term_process.readyReadStandardOutput.connect(self._term_on_stdout)
        self._term_process.readyReadStandardError.connect(self._term_on_stderr)
        self._term_process.finished.connect(self._term_on_finished)
        if sys.platform == "win32":
            self._term_process.start("cmd.exe", ["/c", cmd])
        else:
            self._term_process.start("/bin/sh", ["-c", cmd])

    def _term_on_stdout(self):
        self._term_write(bytes(self._term_process.readAllStandardOutput()).decode("utf-8", "replace"))

    def _term_on_stderr(self):
        self._term_write(
            bytes(self._term_process.readAllStandardError()).decode("utf-8", "replace"), colour="#f97583"
        )

    def _term_on_finished(self, code, _):
        self._term_write(f"[exited {code}]", colour="#888")
        self._term_process = None

    def _term_kill(self):
        if self._term_process and self._term_process.state() != QProcess.ProcessState.NotRunning:
            self._term_process.kill()
            self._term_process.waitForFinished(500)
            self._term_process = None

    def _term_clear(self):
        self._term_output.clear()

    # ── DLL Bridge ─────────────────────────────────────────────────────────────

    def _bridge_set_status(self, ok: bool):
        if ok:
            self._lbl_bridge_status.setStyleSheet("color:#3fb950;font-size:10pt;")
            self._lbl_bridge_status.setToolTip("Bridge: connected")
        else:
            self._lbl_bridge_status.setStyleSheet("color:#f85149;font-size:10pt;")
            self._lbl_bridge_status.setToolTip("Bridge: not connected")

    def _bridge_send(self, script: str) -> tuple[bool, str]:
        """
        Send script to DLL via named pipe and receive response.
        Returns: (success: bool, response_message: str)

        Protocol:
        - Send: [4-byte LE length] + [UTF-8 script]
        - Receive: [4-byte LE length] + [UTF-8 JSON response]
        """
        payload = script.encode("utf-8")
        data = struct.pack("<I", len(payload)) + payload
        try:
            if sys.platform == "win32":
                import ctypes, ctypes.wintypes as wt

                h = ctypes.windll.kernel32.CreateFileW(
                    self._bridge_pipe, 0x40000000 | 0x80000000, 0, None, 3, 0, None
                )
                if h == wt.HANDLE(-1).value:
                    return False, "Failed to open pipe"

                # Send the script
                written = wt.DWORD(0)
                ctypes.windll.kernel32.WriteFile(h, data, len(data), ctypes.byref(written), None)
                if written.value != len(data):
                    ctypes.windll.kernel32.CloseHandle(h)
                    return False, "Failed to write all data to pipe"

                # Read response length (4 bytes)
                resp_len_buf = ctypes.create_string_buffer(4)
                read_bytes = wt.DWORD(0)
                if not ctypes.windll.kernel32.ReadFile(h, resp_len_buf, 4, ctypes.byref(read_bytes), None):
                    ctypes.windll.kernel32.CloseHandle(h)
                    return False, "Failed to read response length"

                if read_bytes.value != 4:
                    ctypes.windll.kernel32.CloseHandle(h)
                    return False, "Invalid response length"

                # Parse response length
                resp_len = struct.unpack("<I", resp_len_buf.raw)[0]
                if resp_len == 0 or resp_len > 4096:
                    ctypes.windll.kernel32.CloseHandle(h)
                    return False, f"Invalid response size: {resp_len}"

                # Read response data
                resp_data = ctypes.create_string_buffer(resp_len)
                read_bytes = wt.DWORD(0)
                if not ctypes.windll.kernel32.ReadFile(
                    h, resp_data, resp_len, ctypes.byref(read_bytes), None
                ):
                    ctypes.windll.kernel32.CloseHandle(h)
                    return False, "Failed to read response data"

                ctypes.windll.kernel32.CloseHandle(h)

                # Parse JSON response
                try:
                    import json

                    resp_str = resp_data.raw[:resp_len].decode("utf-8")
                    resp_json = json.loads(resp_str)
                    success = resp_json.get("success", False)
                    message = resp_json.get("message", "Unknown response")
                    return success, message
                except Exception as e:
                    return False, f"Failed to parse response: {e}"
            else:
                # Unix socket implementation
                with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                    s.settimeout(5.0)
                    s.connect(self._bridge_pipe)
                    s.sendall(data)

                    # Read response length
                    resp_len_bytes = s.recv(4)
                    if len(resp_len_bytes) != 4:
                        return False, "Failed to read response length"

                    resp_len = struct.unpack("<I", resp_len_bytes)[0]
                    if resp_len == 0 or resp_len > 4096:
                        return False, f"Invalid response size: {resp_len}"

                    # Read response data
                    resp_data = s.recv(resp_len)
                    if len(resp_data) != resp_len:
                        return False, "Incomplete response"

                    # Parse JSON response
                    import json

                    resp_json = json.loads(resp_data.decode("utf-8"))
                    success = resp_json.get("success", False)
                    message = resp_json.get("message", "Unknown response")
                    return success, message
        except Exception as e:
            return False, f"Bridge error: {str(e)}"

    # ── DLL Injector ──────────────────────────────────────────────────────────

    def _bridge_inject_dialog(self):
        """Show a dialog to pick a process and DLL path, then inject."""
        if sys.platform != "win32":
            QMessageBox.warning(self, "Inject DLL", "DLL injection is only supported on Windows.")
            return

        dlg = _InjectDialog(self)
        if dlg.exec():
            dll_path, pid = dlg.get_selection()
            if not dll_path or not pid:
                return
            ok, msg = self._bridge_inject(dll_path, pid)
            if ok:
                self.statusBar().showMessage(f"[Inject] {msg}", 4000)
                # Give the DLL a moment to start the pipe server then ping it
                from PyQt6.QtCore import QTimer

                QTimer.singleShot(1500, lambda: self._bridge_set_status(self._bridge_send("")[0]))
            else:
                QMessageBox.critical(self, "Inject Failed", msg)

    def _bridge_inject(self, dll_path: str, pid: int) -> tuple[bool, str]:
        """
        Classic LoadLibrary injection via CreateRemoteThread.
        Works for any DLL that has a DllMain — including LuaBoxBridge.dll.
        """
        import ctypes
        import ctypes.wintypes as wt
        import os

        if not os.path.isabs(dll_path):
            dll_path = os.path.abspath(dll_path)
        if not os.path.isfile(dll_path):
            return False, f"DLL not found: {dll_path}"

        k32 = ctypes.windll.kernel32

        PROCESS_ALL_ACCESS = 0x1F0FFF
        MEM_COMMIT = 0x1000
        MEM_RESERVE = 0x2000
        MEM_RELEASE = 0x8000
        PAGE_READWRITE = 0x04

        # Open target process
        h_proc = k32.OpenProcess(PROCESS_ALL_ACCESS, False, pid)
        if not h_proc:
            return False, f"OpenProcess failed (PID {pid}). Error: {k32.GetLastError()}"

        try:
            dll_bytes = (dll_path + "\0").encode("utf-8")
            n_bytes = len(dll_bytes)

            # Allocate memory in target for the DLL path string
            remote_mem = k32.VirtualAllocEx(h_proc, None, n_bytes, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE)
            if not remote_mem:
                return False, f"VirtualAllocEx failed. Error: {k32.GetLastError()}"

            # Write the DLL path into target memory
            written = wt.SIZE_T(0)
            ok = k32.WriteProcessMemory(h_proc, remote_mem, dll_bytes, n_bytes, ctypes.byref(written))
            if not ok or written.value != n_bytes:
                k32.VirtualFreeEx(h_proc, remote_mem, 0, MEM_RELEASE)
                return False, f"WriteProcessMemory failed. Error: {k32.GetLastError()}"

            # Get address of LoadLibraryA in kernel32 (same in all processes on x64 Windows)
            load_lib = k32.GetProcAddress(k32.GetModuleHandleW("kernel32.dll"), b"LoadLibraryA")
            if not load_lib:
                k32.VirtualFreeEx(h_proc, remote_mem, 0, MEM_RELEASE)
                return False, "Could not resolve LoadLibraryA"

            # Spawn remote thread at LoadLibraryA(dll_path)
            h_thread = k32.CreateRemoteThread(h_proc, None, 0, load_lib, remote_mem, 0, None)
            if not h_thread:
                k32.VirtualFreeEx(h_proc, remote_mem, 0, MEM_RELEASE)
                return False, f"CreateRemoteThread failed. Error: {k32.GetLastError()}"

            # Wait for LoadLibrary to finish (5 s timeout)
            WAIT_TIMEOUT = 0x102
            wait_result = k32.WaitForSingleObject(h_thread, 5000)
            exit_code = wt.DWORD(0)
            k32.GetExitCodeThread(h_thread, ctypes.byref(exit_code))
            k32.CloseHandle(h_thread)
            k32.VirtualFreeEx(h_proc, remote_mem, 0, MEM_RELEASE)

            if wait_result == WAIT_TIMEOUT:
                return False, "LoadLibrary timed out in target process"
            if exit_code.value == 0:
                return False, "LoadLibrary returned NULL — DLL may have failed DllMain"

            return True, f"Injected '{os.path.basename(dll_path)}' into PID {pid} successfully"

        finally:
            k32.CloseHandle(h_proc)

    def _bridge_push(self, silent=False):
        editor = self.get_current_editor()
        if not editor:
            if not silent:
                QMessageBox.warning(self, "Bridge", "No active editor.")
            return
        script = editor.get_text().strip()
        if not script:
            if not silent:
                QMessageBox.warning(self, "Bridge", "Editor is empty.")
            return
        ok, message = self._bridge_send(script)
        self._bridge_set_status(ok)
        if not silent:
            if ok:
                self.statusBar().showMessage(f"Script executed: {message}", 3000)
            else:
                QMessageBox.warning(
                    self,
                    "Bridge Execution Failed",
                    f"Error: {message}\n\n"
                    "Make sure your Roblox process is running and the executor DLL is properly loaded.",
                )

    def _bridge_push_file(self, path: str):
        try:
            with open(path, "r", encoding="utf-8") as f:
                script = f.read()
        except Exception as e:
            self.statusBar().showMessage(f"[Bridge] Read error: {e}", 3000)
            return
        ok, message = self._bridge_send(script)
        self._bridge_set_status(ok)
        status_msg = f"[Bridge] Auto-pushed {os.path.basename(path)}"
        if not ok:
            status_msg += f" -- Error: {message}"
        self.statusBar().showMessage(status_msg, 2500)

    def _bridge_ext_changed(self, path: str):
        if path not in self._bridge_watcher.files():
            self._bridge_watcher.addPath(path)
        self._bridge_push_file(path)

    def _bridge_show_settings(self):
        dlg = _BridgeSettingsDialog(
            self, pipe=self._bridge_pipe, auto_push=self._bridge_auto_push, ext_path=self._bridge_ext_path
        )
        if not dlg.exec():
            return
        cfg = dlg.get_config()
        self._bridge_pipe = cfg["pipe"]
        self._bridge_auto_push = cfg["auto_push"]
        if self._bridge_watcher.files():
            self._bridge_watcher.removePaths(self._bridge_watcher.files())
        self._bridge_ext_path = cfg["ext_path"]
        if self._bridge_ext_path and os.path.isfile(self._bridge_ext_path):
            self._bridge_watcher.addPath(self._bridge_ext_path)
            self.statusBar().showMessage(f"[Bridge] Watching {self._bridge_ext_path}", 2500)
        ok = self._bridge_send("")
        self._bridge_set_status(ok)

    # ── Script Importer ───────────────────────────────────────────────────────

    _IMPORT_PATTERNS = {
        "loadstring": [
            r"loadstring\s*\(\s*game\s*:\s*HttpGet\s*\(",
            r"loadstring\s*\(\s*game\.HttpGet\s*\(",
            r"loadstring\s*\(\s*HttpGet\s*\(",
            r"require\s*\(\s*\d+\s*\)",
        ],
        "modules": [
            r"Modules\s*\.\s*\w+\s*=\s*\{",
            r"function\s+Modules\s*\.\s*\w+\s*:\s*Initialize\s*\(",
        ],
        "register": [
            r"RegisterCommand\s*\(",
            r"RegisterCommandDual\s*\(",
        ],
        # Nameless Admin / cmd.add style
        "nameless": [
            r"cmd\.add\s*\(",
            r"cmd\.addPatched\s*\(",
            r"NAmanage\.",
        ],
    }

    def open_script_importer(self):
        """Open or focus the Script Importer tab."""
        # If we have a valid recorded index, check the tab is still there
        if 0 <= self._importer_tab_index < self.tab_widget.count():
            if self.tab_widget.tabText(self._importer_tab_index) == "Script Importer":
                self.tab_widget.setCurrentIndex(self._importer_tab_index)
                return
        # Tab doesn't exist yet (or was closed) — reset and build it
        self._importer_tab_index = -1

        # Build the importer widget
        container = QWidget()
        outer = QHBoxLayout(container)
        outer.setContentsMargins(10, 10, 10, 10)
        outer.setSpacing(10)

        # ── Left panel ────────────────────────────────────────────────────────
        left = QWidget()
        left.setMaximumWidth(420)
        left_layout = QVBoxLayout(left)
        left_layout.setContentsMargins(0, 0, 0, 0)
        left_layout.setSpacing(6)

        lbl_paste = QLabel("PASTE SCRIPT  (any format)")
        lbl_paste.setStyleSheet("font-weight: bold; font-size: 11px;")
        left_layout.addWidget(lbl_paste)

        self._imp_input = QPlainTextEdit()
        self._imp_input.setPlaceholderText("Paste your Lua script here…")
        self._imp_input.setMinimumHeight(200)
        self._imp_input.textChanged.connect(self._imp_schedule_detect)
        left_layout.addWidget(self._imp_input)

        # Detection row
        det_row = QWidget()
        det_layout = QHBoxLayout(det_row)
        det_layout.setContentsMargins(4, 2, 4, 2)
        det_lbl = QLabel("DETECTED:")
        det_lbl.setStyleSheet("font-size: 10px; font-weight: bold;")
        det_layout.addWidget(det_lbl)
        self._imp_det_label = QLabel("—  paste a script above")
        self._imp_det_label.setStyleSheet("font-size: 10px;")
        det_layout.addWidget(self._imp_det_label)
        det_layout.addStretch()
        left_layout.addWidget(det_row)

        # Separator
        sep_line = QWidget()
        sep_line.setFixedHeight(1)
        sep_line.setStyleSheet("background: #555;")
        left_layout.addWidget(sep_line)

        # Metadata fields
        wrap_lbl = QLabel("WRAP AS COMMAND")
        wrap_lbl.setStyleSheet("font-weight: bold; font-size: 11px;")
        left_layout.addWidget(wrap_lbl)

        from PyQt6.QtWidgets import QFormLayout, QLineEdit, QRadioButton, QButtonGroup

        form = QFormLayout()
        form.setContentsMargins(0, 0, 0, 0)
        form.setSpacing(4)

        self._imp_cmd_edit = QLineEdit()
        self._imp_cmd_edit.setPlaceholderText("e.g. myscript")
        form.addRow("Cmd name:", self._imp_cmd_edit)

        self._imp_aliases_edit = QLineEdit()
        self._imp_aliases_edit.setPlaceholderText("a, ms  (comma sep)")
        form.addRow("Aliases:", self._imp_aliases_edit)

        self._imp_args_edit = QLineEdit()
        self._imp_args_edit.setPlaceholderText("optional description")
        form.addRow("Args desc:", self._imp_args_edit)

        left_layout.addLayout(form)

        # Output style radio
        style_lbl = QLabel("OUTPUT STYLE")
        style_lbl.setStyleSheet("font-weight: bold; font-size: 11px;")
        left_layout.addWidget(style_lbl)

        style_row = QWidget()
        style_layout = QHBoxLayout(style_row)
        style_layout.setContentsMargins(0, 0, 0, 0)
        self._imp_style_group = QButtonGroup(style_row)
        self._imp_radio_addcmd = QRadioButton("addcmd()")
        self._imp_radio_register = QRadioButton("RegisterCommand()")
        self._imp_radio_addcmd.setChecked(True)
        self._imp_style_group.addButton(self._imp_radio_addcmd, 0)
        self._imp_style_group.addButton(self._imp_radio_register, 1)
        style_layout.addWidget(self._imp_radio_addcmd)
        style_layout.addWidget(self._imp_radio_register)
        style_layout.addStretch()
        left_layout.addWidget(style_row)

        # Cleanup checkbox
        self._imp_chk_cleanup = QCheckBox("Auto-clean Nameless globals → zuk equivalents")
        self._imp_chk_cleanup.setChecked(True)
        self._imp_chk_cleanup.setToolTip(
            "Replaces Nameless Admin shorthands (Concat, Lower, Insert, Spawn, Wait, Notify…)\n"
            "with their zuk / standard Lua equivalents after conversion."
        )
        left_layout.addWidget(self._imp_chk_cleanup)

        # Buttons
        btn_row = QWidget()
        btn_layout = QHBoxLayout(btn_row)
        btn_layout.setContentsMargins(0, 0, 0, 0)
        btn_convert = QPushButton("CONVERT & WRAP")
        btn_convert.clicked.connect(self._imp_do_convert)
        btn_send = QPushButton("SEND TO EDITOR")
        btn_send.clicked.connect(self._imp_to_editor)
        btn_clear = QPushButton(" CLEAR")
        btn_clear.clicked.connect(self._imp_clear)
        btn_layout.addWidget(btn_convert)
        btn_layout.addWidget(btn_send)
        btn_layout.addWidget(btn_clear)
        left_layout.addWidget(btn_row)
        left_layout.addStretch()

        outer.addWidget(left)

        # ── Right panel ───────────────────────────────────────────────────────
        right = QWidget()
        right_layout = QVBoxLayout(right)
        right_layout.setContentsMargins(0, 0, 0, 0)
        right_layout.setSpacing(6)

        out_lbl = QLabel("OUTPUT  —  ready to paste into your panel")
        out_lbl.setStyleSheet("font-weight: bold; font-size: 11px;")
        right_layout.addWidget(out_lbl)

        self._imp_out = QPlainTextEdit()
        self._imp_out.setReadOnly(True)
        self._imp_out.setPlaceholderText("Converted output will appear here…")
        right_layout.addWidget(self._imp_out)

        out_btn_row = QWidget()
        out_btn_layout = QHBoxLayout(out_btn_row)
        out_btn_layout.setContentsMargins(0, 0, 0, 0)
        btn_copy = QPushButton("COPY")
        btn_copy.clicked.connect(self._imp_copy_output)
        btn_save = QPushButton("SAVE")
        btn_save.clicked.connect(self._imp_save_output)
        out_btn_layout.addWidget(btn_copy)
        out_btn_layout.addWidget(btn_save)
        out_btn_layout.addStretch()
        right_layout.addWidget(out_btn_row)

        outer.addWidget(right)

        # Add to tab_widget (not closable — pinned)
        index = self.tab_widget.addTab(container, "Script Importer")
        self._importer_tab_index = index
        self.tab_widget.setCurrentIndex(index)

        # Make it not closable by hiding its close button
        tab_bar = self.tab_widget.tabBar()
        if tab_bar:
            tab_bar.setTabButton(index, tab_bar.ButtonPosition.RightSide, None)

    def _imp_detect_format(self, src: str) -> str:
        """Return 'nameless' | 'loadstring' | 'modules' | 'register' | 'raw'.

        Nameless is checked first and wins if 3+ cmd.add() calls are found,
        so a Source.lua that also contains HttpGet calls doesn't misfire as
        'loadstring' and wrap the whole 89k-line file as one command body.
        """
        # Nameless Admin priority check — count cmd.add occurrences
        na_hits = len(re.findall(r'cmd\.add(?:Patched)?\s*\(', src))
        if na_hits >= 3:
            return "nameless"

        # Also catch single-cmd.add pastes via the normal pattern list
        for pat in self._IMPORT_PATTERNS.get("nameless", []):
            if re.search(pat, src, re.IGNORECASE):
                return "nameless"

        # Everything else in original priority order, skipping nameless
        for fmt, patterns in self._IMPORT_PATTERNS.items():
            if fmt == "nameless":
                continue
            for pat in patterns:
                if re.search(pat, src, re.IGNORECASE):
                    return fmt
        return "raw"

    def _imp_schedule_detect(self):
        """Debounce: only run detection 250 ms after typing stops."""
        if not hasattr(self, "_imp_detect_timer"):
            self._imp_detect_timer = QTimer()
            self._imp_detect_timer.setSingleShot(True)
            self._imp_detect_timer.timeout.connect(self._imp_auto_detect)
        self._imp_detect_timer.start(250)

    def _imp_auto_detect(self):
        src = self._imp_input.toPlainText().strip()
        if not src:
            self._imp_det_label.setText("—  paste a script above")
            self._imp_det_label.setStyleSheet("font-size: 10px;")
            return
        fmt = self._imp_detect_format(src)
        FMT_LABELS = {
            "loadstring": ("loadstring / HttpGet", "#22d3ee"),
            "modules": ("Modules.X:Initialize() style", "#facc15"),
            "register": ("RegisterCommand style", "#ab54f7"),
            "nameless": ("Nameless Admin / cmd.add style", "#f97316"),
            "raw": ("Raw Lua", "#4ade80"),
        }
        text, color = FMT_LABELS[fmt]
        self._imp_det_label.setText(text)
        self._imp_det_label.setStyleSheet(f"font-size: 10px; color: {color};")

    def _imp_extract_body(self, src: str, fmt: str) -> str:
        if fmt in ("raw", "loadstring"):
            return src
        if fmt == "modules":
            m = re.search(
                r"function\s+Modules\s*\.\s*\w+\s*:\s*Initialize\s*\(\s*\)(.*?)^end",
                src,
                re.DOTALL | re.MULTILINE,
            )
            if m:
                body = m.group(1).strip()
                return body if body else src
            return src
        if fmt == "register":
            calls = re.findall(r"RegisterCommand(?:Dual)?\s*\(.*?\)\s*\)", src, re.DOTALL)
            if calls:
                return "\n\n".join(c.strip() for c in calls)
            return src
        if fmt == "nameless":
            # Return whole source — _imp_do_convert handles nameless parsing itself
            return src
        return src

    # ── Nameless Admin parser ─────────────────────────────────────────────────
    def _parse_nameless_commands(self, src: str) -> list:
        """
        Parse all cmd.add / cmd.addPatched calls from Nameless Admin source.
        Returns a list of dicts:
          { 'aliases': [str, ...], 'usage': str, 'desc': str, 'body': str }
        Uses a bracket-depth walker so nested function bodies are captured
        correctly even across hundreds of lines.
        """
        results = []

        # Find every cmd.add / cmd.addPatched call start position
        starts = [(m.start(), m.group(0)) for m in re.finditer(r"cmd\.add(?:Patched)?\s*\(", src)]

        for call_start, _ in starts:
            # Walk forward from the opening paren to find the balanced close
            paren_pos = src.index("(", call_start)
            depth = 0
            i = paren_pos
            while i < len(src):
                c = src[i]
                if c == "(":
                    depth += 1
                elif c == ")":
                    depth -= 1
                    if depth == 0:
                        break
                # Skip string literals so parens inside strings don't confuse us
                elif c in ('"', "'"):
                    quote = c
                    i += 1
                    while i < len(src) and src[i] != quote:
                        if src[i] == "\\":
                            i += 1  # skip escaped char
                        i += 1
                elif c == "[" and i + 1 < len(src) and src[i + 1] == "[":
                    # long string [[...]]
                    i += 2
                    while i < len(src) and not (src[i] == "]" and i + 1 < len(src) and src[i + 1] == "]"):
                        i += 1
                    i += 1  # skip second ]
                elif c == "-" and i + 1 < len(src) and src[i + 1] == "-":
                    # line comment
                    while i < len(src) and src[i] != "\n":
                        i += 1
                i += 1

            call_body = src[paren_pos + 1 : i].strip()  # everything inside outer parens

            # ── Parse arg 1: aliases table {"a", "b", ...} ──────────────────
            aliases = re.findall(r'["\']([^"\']+)["\']', call_body.split("}")[0])
            if not aliases:
                continue

            # ── Parse arg 2: info table {usage, desc} ──────────────────────
            info_match = re.search(r"\}\s*,\s*\{(.*?)\}", call_body, re.DOTALL)
            usage, desc = "", ""
            if info_match:
                info_str = info_match.group(1)
                info_parts = re.findall(r'["\']([^"\']*)["\'\']', info_str)
                if len(info_parts) >= 1:
                    usage = info_parts[0]
                if len(info_parts) >= 2:
                    desc = info_parts[1]
            else:
                # info may be a single string
                m2 = re.search(r'\}\s*,\s*["\']([^"\']+)["\']', call_body)
                if m2:
                    usage = m2.group(1)

            # ── Parse the function body ─────────────────────────────────────
            # Find the function keyword after the info arg
            func_search_start = info_match.end() if info_match else 0
            func_m = re.search(
                r"function\s*\(([^)]*)\)(.*?)(?=\bend\b\s*(?:\)|,|$))",
                call_body[func_search_start:],
                re.DOTALL,
            )
            if func_m:
                func_body = func_m.group(2).strip()
            else:
                # Fallback: grab everything after the second }
                after_info = call_body[func_search_start:]
                fb_m = re.search(r"function\s*\([^)]*\)(.*)", after_info, re.DOTALL)
                func_body = fb_m.group(1).strip().rstrip(")").strip() if fb_m else ""
                # Remove trailing `end`
                if func_body.endswith("end"):
                    func_body = func_body[:-3].strip()

            results.append(
                {
                    "aliases": aliases,
                    "usage": usage,
                    "desc": desc,
                    "body": func_body,
                }
            )

        return results

    def _imp_do_convert(self):
        if not hasattr(self, "_imp_input"):
            return
        src = self._imp_input.toPlainText().strip()
        if not src:
            QMessageBox.warning(self, "Empty", "Paste a script first.")
            return

        fmt = self._imp_detect_format(src)
        style = "addcmd" if self._imp_radio_addcmd.isChecked() else "register"

        lines = []

        def w(s=""):
            lines.append(s)

        # ── Nameless Admin bulk-conversion path ──────────────────────────────
        if fmt == "nameless":
            cmds = self._parse_nameless_commands(src)
            if not cmds:
                self._imp_out.setPlainText(
                    "-- No cmd.add() calls found.\n" "-- Make sure you pasted Nameless Admin source."
                )
                return

            w(f"-- ── Nameless Admin → {style}  ({len(cmds)} command(s)) ───────────────")
            w()
            for entry in cmds:
                primary = entry["aliases"][0]
                rest = entry["aliases"][1:]
                desc_text = entry["desc"] or entry["usage"] or primary + " command"
                # sanitise: strip Nameless '(alias)' parenthetical noise from desc
                desc_text = re.sub(r"\s*\([^)]*\)", "", desc_text).strip()
                desc_text = desc_text.replace('"', '\\"')

                body = entry["body"]

                # Indent body consistently
                indented = []
                for line in body.splitlines():
                    indented.append("    " + line if line.strip() else "")

                if style == "addcmd":
                    alias_lua = "{" + ", ".join(f'"{a}"' for a in rest) + "}"
                    w(f'addcmd("{primary}", {alias_lua}, function(args, speaker)')
                    w("\n".join(indented))
                    w("end)")
                else:
                    alias_lua = "{" + ", ".join(f'"{a}"' for a in rest) + "}"
                    w(f"RegisterCommand({{")
                    w(f'    Name        = "{primary}",')
                    w(f"    Aliases     = {alias_lua},")
                    w(f'    Description = "{desc_text}",')
                    w(f"}}, function(args)")
                    w("\n".join(indented))
                    w("end)")
                w()

            converted = "\n".join(lines)
            if getattr(self, "_imp_chk_cleanup", None) and self._imp_chk_cleanup.isChecked():
                converted = self._imp_clean_nameless_globals(converted)
            self._imp_out.setPlainText(converted)
            return

        # ── Standard single-command conversion path ──────────────────────────
        cmd_raw = self._imp_cmd_edit.text().strip() or "myscript"
        cmd = cmd_raw.lower().replace(" ", "_")

        aliases_raw = self._imp_aliases_edit.text().strip()
        aliases = [a.strip() for a in aliases_raw.split(",") if a.strip()] if aliases_raw else []

        desc_raw = self._imp_args_edit.text().strip()

        body = self._imp_extract_body(src, fmt)

        w(f"-- ── Imported: {cmd}  [{fmt} → {style}] ──────────────────────")
        w()

        if style == "addcmd":
            alias_lua = "{" + ", ".join(f'"{a}"' for a in aliases) + "}"
            w(f'addcmd("{cmd}", {alias_lua}, function(args, speaker)')
            for line in body.splitlines():
                w("    " + line if line.strip() else line)
            w("end)")
        else:
            alias_lua = "{" + ", ".join(f'"{a}"' for a in aliases) + "}"
            w(f"RegisterCommand({{")
            w(f'    Name        = "{cmd}",')
            w(f"    Aliases     = {alias_lua},")
            w(f'    Description = "{desc_raw or cmd + " command"}",')
            w(f"}}, function(args)")
            for line in body.splitlines():
                w("    " + line if line.strip() else line)
            w("end)")

        converted = "\n".join(lines)
        if getattr(self, "_imp_chk_cleanup", None) and self._imp_chk_cleanup.isChecked():
            converted = self._imp_clean_nameless_globals(converted)
        self._imp_out.setPlainText(converted)

    # ── Nameless → zuk global cleanup pass ────────────────────────────────────────
    # Ordered so longer / more-specific patterns match before shorter ones.
    _NA_GLOBAL_MAP = [
        # ── Nameless notify/UI calls → zuk (↑ before generic word matches) ──────────
        (r"\bNACaller\s*\(", "pcall("),
        (r"\bDoWindow\s*\(", "DoNotif("),
        (r"\bDoPopup\s*\(", "DoNotif("),
        (r"\bNotify\s*\(", "DoNotif("),
        # DoNotif already matches zuk — no replacement needed
        # ── Nameless-internal namespaces → comment markers ──────────────────
        (r"\bNAmanage\.\w+\b", "--[[NAmanage removed]]"),
        (r"\bNAStuff\.\w+\b", "--[[NAStuff removed]]"),
        (r"\bNAgui\.\w+\b", "--[[NAgui removed]]"),
        (r"\bNAfiles\.\w+\b", "--[[NAfiles removed]]"),
        (r"\bcmd\.run\s*\(", "--[[cmd.run removed]] pcall("),
        # ── Player helpers → comment stubs ──────────────────────────────
        (r"\bplrFromStr\s*\(", "--[[plrFromStr: resolve manually]]("),
        (r"\bgetChar\s*\(", "--[[getChar → LocalPlayer.Character]]("),
        (r"\bgetRoot\s*\(", "--[[getRoot → Character.HumanoidRootPart]]("),
        (r"\bgetPlrHum\s*\(", "--[[getPlrHum: use Character:FindFirstChildOfClass Humanoid]]("),
        # ── HTTP wrapper ─────────────────────────────────────────────
        (r"\bNAREQUEST\b", "request"),
        # ── task shorthands ─────────────────────────────────────────
        (r"\bSpawnCall\b", "task.spawn"),
        (r"\bSpawn\b", "task.spawn"),
        (r"\bDefer\b", "task.defer"),
        (r"\bWait\b", "task.wait"),
        (r"\bDelay\b", "task.delay"),
        # ── string shorthands ───────────────────────────────────────
        (r"\bFormat\b", "string.format"),
        (r"\bLower\b", "string.lower"),
        (r"\bUpper\b", "string.upper"),
        (r"\bMatch\b", "string.match"),
        (r"\bFind\b", "string.find"),
        (r"\bSub\b", "string.sub"),
        (r"\bGsub\b", "string.gsub"),
        (r"\bRep\b", "string.rep"),
        (r"\bByte\b", "string.byte"),
        (r"\bChar\b", "string.char"),
        # ── table shorthands ────────────────────────────────────────
        (r"\bConcat\b", "table.concat"),
        (r"\bInsert\b", "table.insert"),
        (r"\bRemove\b", "table.remove"),
        (r"\bSort\b", "table.sort"),
        (r"\bUnpack\b", "table.unpack"),
        (r"\bMove\b", "table.move"),
        # ── math shorthands ─────────────────────────────────────────
        (r"\bClamp\b", "math.clamp"),
        (r"\bFloor\b", "math.floor"),
        (r"\bCeil\b", "math.ceil"),
        (r"\bAbs\b", "math.abs"),
        (r"\bSqrt\b", "math.sqrt"),
        (r"\bRand\b", "math.random"),
    ]

    @staticmethod
    def _reindent_lua_body(body: str) -> str:
        """
        Strip the mixed tab/space indentation that Nameless Admin source uses
        and re-indent using consistent 4-space depth tracking.

        Rules:
          - else / elseif: close current block then reopen  (depth -= 1, print, depth += 1)
          - end / until / }: close block                    (depth -= 1, print)
          - then / do / repeat / function ... / {:          (print, depth += 1)
          - one-liners (open+close on same line) don't change depth
        """
        import re

        # Patterns anchored to start of stripped line
        CLOSE_REOPEN = re.compile(r'^(else\b|elseif\b)')   # close + reopen
        CLOSE_ONLY   = re.compile(r'^(end\b|until\b|\})')  # close only

        # Patterns that open a new level (at end of line, after printing)
        OPEN = re.compile(
            r'\b(then|do|repeat|else)\s*(?:--.*)?$'
            r'|\bfunction\b[^\n]*\)\s*(?:--.*)?$'
            r'|\{\s*(?:--.*)?$'
        )

        result = []
        depth = 0

        for raw in body.splitlines():
            stripped = raw.strip()
            if not stripped:
                result.append("")
                continue

            if CLOSE_REOPEN.match(stripped):
                # else / elseif: step out, print at outer level, step back in
                depth = max(0, depth - 1)
                result.append("    " * depth + stripped)
                depth += 1
                continue

            if CLOSE_ONLY.match(stripped):
                depth = max(0, depth - 1)
                result.append("    " * depth + stripped)
                continue

            result.append("    " * depth + stripped)

            # Open a new level if line ends with an opening keyword,
            # but skip one-liners where open and close are on the same line
            if OPEN.search(stripped):
                opens  = len(re.findall(r'\b(then|do|repeat|function)\b|\{', stripped))
                closes = len(re.findall(r'\bend\b|\}', stripped))
                if opens > closes:
                    depth += 1

        return "\n".join(result)

    def _imp_clean_nameless_globals(self, code: str) -> str:
        """
        1. Re-indent every RegisterCommand body using consistent 4-space Lua depth.
        2. Replace Nameless Admin shorthands with zuk / standard-Lua equivalents.
        3. Annotate removed Nameless-internal calls with --[[...]] markers.
        """
        import re

        # ── Step 1: re-indent each command body block ─────────────────────────
        # Match the function body between `}, function(args)` and the closing `end)`
        def reindent_block(m):
            header = m.group(1)   # RegisterCommand({...}, function(args)
            body   = m.group(2)   # everything inside
            return header + "\n" + self._reindent_lua_body(body) + "\nend)\n"

        code = re.sub(
            r'(RegisterCommand\(\{.*?\}\s*,\s*function\([^)]*\)\s*\n)(.*?)\nend\)',
            reindent_block,
            code,
            flags=re.DOTALL,
        )

        # Also handle addcmd style
        def reindent_addcmd(m):
            header = m.group(1)
            body   = m.group(2)
            return header + "\n" + self._reindent_lua_body(body) + "\nend)\n"

        code = re.sub(
            r'(addcmd\([^,]+,\s*\{[^}]*\}\s*,\s*function\([^)]*\)\s*\n)(.*?)\nend\)',
            reindent_addcmd,
            code,
            flags=re.DOTALL,
        )

        # ── Step 2: global substitution pass ─────────────────────────────────
        result_lines = []
        for line in code.splitlines():
            stripped = line.lstrip()
            if stripped.startswith("--"):
                result_lines.append(line)
                continue
            for pattern, replacement in self._NA_GLOBAL_MAP:
                line = re.sub(pattern, replacement, line)
            result_lines.append(line)

        output = "\n".join(result_lines)

        # ── Step 3: append attention summary ─────────────────────────────────
        markers = list(dict.fromkeys(re.findall(r"--\[\[([^\]]+)\]\]", output)))
        if markers:
            note = ["", "-- ┌─ Nameless cleanup: items still needing manual attention ─────────────────────"]
            for m in markers:
                note.append(f"-- │  {m}")
            note.append("-- └" + "─" * 70)
            output += "\n" + "\n".join(note)

        return output

    def _imp_to_editor(self):
        """Push converted output into a new Monaco editor tab."""
        if not hasattr(self, "_imp_out"):
            return
        code = self._imp_out.toPlainText().strip()
        if not code:
            src = self._imp_input.toPlainText().strip()
            if not src:
                QMessageBox.information(self, "Empty", "Convert a script first, or paste input.")
                return
            self._imp_do_convert()
            code = self._imp_out.toPlainText().strip()
            if not code:
                return

        cmd_raw = self._imp_cmd_edit.text().strip() or "imported"
        tab_name = cmd_raw.lower().replace(" ", "_")

        editor = self.create_new_tab(tab_name)

        # Extract just the body (strip outer wrapper) to send as clean code
        inner = re.search(r"function\s*\(args,\s*speaker\)(.*?)^end\)", code, re.DOTALL | re.MULTILINE)
        body = inner.group(1).strip() if inner else code

        # Delay so Monaco is ready
        from PyQt6.QtCore import QTimer

        QTimer.singleShot(800, lambda: editor.set_text(body))

        QMessageBox.information(self, "Sent", f'Script body sent to new tab "{tab_name}".')

    def _imp_copy_output(self):
        if not hasattr(self, "_imp_out"):
            return
        text = self._imp_out.toPlainText()
        if text:
            QApplication.clipboard().setText(text)

    def _imp_save_output(self):
        if not hasattr(self, "_imp_out"):
            return
        text = self._imp_out.toPlainText()
        if not text:
            return
        from PyQt6.QtWidgets import QFileDialog

        path, _ = QFileDialog.getSaveFileName(self, "Save Output", "", "Lua Files (*.lua);;All Files (*)")
        if path:
            with open(path, "w", encoding="utf-8") as f:
                f.write(text)

    def _imp_clear(self):
        if not hasattr(self, "_imp_input"):
            return
        self._imp_input.clear()
        self._imp_out.setPlainText("")
        self._imp_det_label.setText("—  paste a script above")
        self._imp_det_label.setStyleSheet("font-size: 10px;")
        self._imp_cmd_edit.clear()
        self._imp_aliases_edit.clear()
        self._imp_args_edit.clear()

    # ── zukv3 Decompiler Tab ─────────────────────────────────────────────────

    def open_decompiler_tab(self):
        """Open or focus the zukv3 Decompiler tab."""
        if 0 <= self._decomp_tab_index < self.tab_widget.count():
            if self.tab_widget.tabText(self._decomp_tab_index) == "Decompiler":
                self.tab_widget.setCurrentIndex(self._decomp_tab_index)
                return
        self._decomp_tab_index = -1

        container = QWidget()
        outer = QVBoxLayout(container)
        outer.setContentsMargins(10, 10, 10, 10)
        outer.setSpacing(8)

        # ── Top bar: server status + port ────────────────────────────────────
        top_bar = QWidget()
        top_layout = QHBoxLayout(top_bar)
        top_layout.setContentsMargins(0, 0, 0, 0)
        top_layout.setSpacing(8)

        self._decomp_status_dot = QLabel("●")
        self._decomp_status_dot.setStyleSheet("color: #888; font-size: 14pt;")
        self._decomp_status_dot.setToolTip("Server status")
        top_layout.addWidget(self._decomp_status_dot)

        self._decomp_status_lbl = QLabel("Server stopped")
        self._decomp_status_lbl.setStyleSheet("font-size: 9pt;")
        top_layout.addWidget(self._decomp_status_lbl)

        top_layout.addSpacing(16)
        top_layout.addWidget(QLabel("Port:"))
        self._decomp_port = QSpinBox()
        self._decomp_port.setRange(1024, 65535)
        self._decomp_port.setValue(5000)
        self._decomp_port.setFixedWidth(80)
        self._decomp_port.setToolTip("Must match the port in zukv3externaldecomp.lua")
        top_layout.addWidget(self._decomp_port)

        self._decomp_btn_start = QPushButton("▶  Start Server")
        self._decomp_btn_start.setStyleSheet("font-weight: bold;")
        self._decomp_btn_start.clicked.connect(self._decomp_start_server)
        top_layout.addWidget(self._decomp_btn_start)

        self._decomp_btn_stop = QPushButton("■  Stop")
        self._decomp_btn_stop.setEnabled(False)
        self._decomp_btn_stop.clicked.connect(self._decomp_stop_server)
        top_layout.addWidget(self._decomp_btn_stop)

        top_layout.addStretch()

        req_lbl = QLabel("Requests received:")
        req_lbl.setStyleSheet("font-size: 9pt;")
        top_layout.addWidget(req_lbl)
        self._decomp_req_count = QLabel("0")
        self._decomp_req_count.setStyleSheet("font-weight: bold; font-size: 9pt;")
        top_layout.addWidget(self._decomp_req_count)

        outer.addWidget(top_bar)

        # ── Separator ─────────────────────────────────────────────────────────
        sep = QWidget()
        sep.setFixedHeight(1)
        sep.setStyleSheet("background: #555;")
        outer.addWidget(sep)

        # ── Main split: output viewer left, log right ─────────────────────────
        split = QSplitter(Qt.Orientation.Horizontal)

        # Left — decompiled script viewer
        left = QWidget()
        left_lay = QVBoxLayout(left)
        left_lay.setContentsMargins(0, 0, 0, 0)
        left_lay.setSpacing(4)

        left_hdr = QHBoxLayout()
        out_lbl = QLabel("RECEIVED SCRIPT")
        out_lbl.setStyleSheet("font-weight: bold; font-size: 10px;")
        left_hdr.addWidget(out_lbl)
        left_hdr.addStretch()

        self._decomp_script_name = QLabel("—")
        self._decomp_script_name.setStyleSheet("font-size: 9pt; color: #888;")
        left_hdr.addWidget(self._decomp_script_name)
        left_lay.addLayout(left_hdr)

        self._decomp_output = QPlainTextEdit()
        self._decomp_output.setReadOnly(True)
        self._decomp_output.setPlaceholderText(
            "Waiting for a decompile request from in-game...\n\n"
            "In-game: local zukv3 = loadstring(readfile('zukv3externaldecomp.lua'))()\n"
            "         zukv3.decompile(someScript, true)"
        )
        self._decomp_output.setFont(QFont("Consolas", 10))
        left_lay.addWidget(self._decomp_output)

        # Action buttons under the viewer
        action_row = QWidget()
        action_lay = QHBoxLayout(action_row)
        action_lay.setContentsMargins(0, 0, 0, 0)
        action_lay.setSpacing(6)

        btn_send_editor = QPushButton("→ Send to Editor")
        btn_send_editor.setToolTip("Open this script in a new Monaco editor tab")
        btn_send_editor.clicked.connect(self._decomp_send_to_editor)
        action_lay.addWidget(btn_send_editor)

        btn_copy = QPushButton("Copy")
        btn_copy.clicked.connect(self._decomp_copy)
        action_lay.addWidget(btn_copy)

        btn_save = QPushButton("Save .lua")
        btn_save.clicked.connect(self._decomp_save)
        action_lay.addWidget(btn_save)

        btn_clear = QPushButton("Clear")
        btn_clear.clicked.connect(self._decomp_clear_output)
        action_lay.addWidget(btn_clear)

        action_lay.addStretch()
        left_lay.addWidget(action_row)

        split.addWidget(left)

        # Right — request log
        right = QWidget()
        right_lay = QVBoxLayout(right)
        right_lay.setContentsMargins(0, 0, 0, 0)
        right_lay.setSpacing(4)

        log_hdr = QHBoxLayout()
        log_lbl = QLabel("SERVER LOG")
        log_lbl.setStyleSheet("font-weight: bold; font-size: 10px;")
        log_hdr.addWidget(log_lbl)
        log_hdr.addStretch()
        btn_clear_log = QPushButton("Clear Log")
        btn_clear_log.setFixedHeight(20)
        btn_clear_log.clicked.connect(self._decomp_clear_log)
        log_hdr.addWidget(btn_clear_log)
        right_lay.addLayout(log_hdr)

        self._decomp_log = QPlainTextEdit()
        self._decomp_log.setReadOnly(True)
        self._decomp_log.setMaximumBlockCount(500)
        self._decomp_log.setFont(QFont("Consolas", 9))
        self._decomp_log.setPlaceholderText("Server log appears here...")
        right_lay.addWidget(self._decomp_log)

        split.addWidget(right)
        split.setSizes([700, 300])

        outer.addWidget(split)

        # ── Lua usage hint ────────────────────────────────────────────────────
        hint_lbl = QLabel(
            "<b>In-game usage:</b>  "
            "<code>local zukv3 = loadstring(readfile('zukv3externaldecomp.lua'))()</code>  "
            "then  "
            "<code>zukv3.decompile(script, true)</code>"
        )
        hint_lbl.setTextFormat(Qt.TextFormat.RichText)
        hint_lbl.setStyleSheet("font-size: 8pt; color: #888; padding-top: 4px;")
        outer.addWidget(hint_lbl)

        # ── Add to tab widget (pinned — no close button) ──────────────────────
        index = self.tab_widget.addTab(container, "Decompiler")
        self._decomp_tab_index = index
        self.tab_widget.setCurrentIndex(index)

        tab_bar = self.tab_widget.tabBar()
        if tab_bar:
            tab_bar.setTabButton(index, tab_bar.ButtonPosition.RightSide, None)

        # Counter for received requests
        self._decomp_request_count = 0

    # ── Server management ─────────────────────────────────────────────────────

    def _decomp_log_line(self, text: str):
        """Append a line to the decompiler server log (thread-safe via QTimer)."""
        if hasattr(self, "_decomp_log") and self._decomp_log:
            from PyQt6.QtCore import QTimer

            QTimer.singleShot(0, lambda: self._decomp_log.appendPlainText(text))

    def _decomp_set_status(self, running: bool):
        """Update the status dot and buttons (must be called from main thread)."""
        if not hasattr(self, "_decomp_status_dot"):
            return
        if running:
            self._decomp_status_dot.setStyleSheet("color: #4ade80; font-size: 14pt;")
            self._decomp_status_lbl.setText(f"Server running on port {self._decomp_port.value()}")
            self._decomp_btn_start.setEnabled(False)
            self._decomp_btn_stop.setEnabled(True)
            self._decomp_port.setEnabled(False)
        else:
            self._decomp_status_dot.setStyleSheet("color: #888; font-size: 14pt;")
            self._decomp_status_lbl.setText("Server stopped")
            self._decomp_btn_start.setEnabled(True)
            self._decomp_btn_stop.setEnabled(False)
            self._decomp_port.setEnabled(True)

    def _decomp_start_server(self):
        """Start the Flask receiver server in a background thread."""
        if not _FLASK_AVAILABLE:
            QMessageBox.warning(
                self,
                "Flask Missing",
                "Flask is not installed.\n\nRun:  pip install flask\n\nthen restart LuaBox.",
            )
            return

        if self._decomp_server_running:
            return

        port = self._decomp_port.value()
        self._decomp_server_running = True

        # Build a minimal Flask app that accepts POST /fix_script
        app = _Flask("zukv3_decomp_receiver")
        app.logger.disabled = True
        import logging

        log = logging.getLogger("werkzeug")
        log.setLevel(logging.ERROR)

        parent = self  # capture for closure

        @app.route("/fix_script", methods=["POST"])
        def fix_script():
            try:
                data = _flask_request.get_json(force=True, silent=True) or {}
                raw = data.get("script", "")
                script_name = data.get("name", "unknown")

                parent._decomp_request_count = getattr(parent, "_decomp_request_count", 0) + 1
                count = parent._decomp_request_count

                parent._decomp_log_line(f"[{count}] Received {len(raw)} chars  name={script_name}")

                # Push to UI — must happen on main thread
                from PyQt6.QtCore import QTimer

                QTimer.singleShot(0, lambda: parent._decomp_receive(raw, script_name, count))

                return _flask_jsonify({"fixed_script": raw, "status": "ok"})
            except Exception as e:
                parent._decomp_log_line(f"[ERR] {e}")
                return _flask_jsonify({"error": str(e)}), 500

        def _run():
            try:
                app.run(host="127.0.0.1", port=port, debug=False, use_reloader=False)
            except Exception as e:
                parent._decomp_log_line(f"[ERR] Server crashed: {e}")
                from PyQt6.QtCore import QTimer

                QTimer.singleShot(0, lambda: parent._decomp_set_status(False))

        self._decomp_flask_app = app
        self._decomp_server_thread = threading.Thread(target=_run, daemon=True)
        self._decomp_server_thread.start()

        from PyQt6.QtCore import QTimer

        QTimer.singleShot(0, lambda: self._decomp_set_status(True))
        self._decomp_log_line(f"Server started on 127.0.0.1:{port}")

    def _decomp_stop_server(self):
        """Stop the Flask server (best-effort — sends a shutdown request)."""
        self._decomp_server_running = False
        port = self._decomp_port.value() if hasattr(self, "_decomp_port") else 5000
        try:
            # Werkzeug doesn't have a clean shutdown API; we hit the endpoint
            # to unblock the thread, then let the daemon thread die naturally.
            import urllib.request

            urllib.request.urlopen(f"http://127.0.0.1:{port}/fix_script", data=b"{}", timeout=1)
        except Exception:
            pass
        if hasattr(self, "_decomp_status_dot"):
            self._decomp_set_status(False)
        self._decomp_log_line("Server stopped.")

    def _decomp_receive(self, script: str, name: str, count: int):
        """Called on the main thread when a script arrives from in-game."""
        if not hasattr(self, "_decomp_output"):
            return
        self._decomp_output.setPlainText(script)
        if hasattr(self, "_decomp_script_name"):
            self._decomp_script_name.setText(f"Script: {name}  |  #{count}")
        if hasattr(self, "_decomp_req_count"):
            self._decomp_req_count.setText(str(count))
        # Flash the tab text briefly
        if 0 <= self._decomp_tab_index < self.tab_widget.count():
            self.tab_widget.setTabText(self._decomp_tab_index, "Decompiler *")
            from PyQt6.QtCore import QTimer

            QTimer.singleShot(
                2000,
                lambda: (
                    self.tab_widget.setTabText(self._decomp_tab_index, "Decompiler")
                    if 0 <= self._decomp_tab_index < self.tab_widget.count()
                    else None
                ),
            )

    def _decomp_send_to_editor(self):
        """Send the current decompiled output to a new Monaco editor tab."""
        if not hasattr(self, "_decomp_output"):
            return
        code = self._decomp_output.toPlainText().strip()
        if not code:
            QMessageBox.information(self, "Empty", "No decompiled script to send yet.")
            return
        name = "decompiled"
        if hasattr(self, "_decomp_script_name"):
            txt = self._decomp_script_name.text()
            m = re.search(r"Script:\s*(\S+)", txt)
            if m:
                name = m.group(1).replace(":", "_")
        editor = self.create_new_tab(name)
        from PyQt6.QtCore import QTimer

        QTimer.singleShot(800, lambda: editor.set_text(code))

    def _decomp_copy(self):
        if hasattr(self, "_decomp_output"):
            text = self._decomp_output.toPlainText()
            if text:
                QApplication.clipboard().setText(text)

    def _decomp_save(self):
        if not hasattr(self, "_decomp_output"):
            return
        text = self._decomp_output.toPlainText()
        if not text:
            return
        path, _ = QFileDialog.getSaveFileName(
            self, "Save Decompiled Script", "", "Lua Files (*.lua);;All Files (*)"
        )
        if path:
            with open(path, "w", encoding="utf-8") as f:
                f.write(text)

    def _decomp_clear_output(self):
        if hasattr(self, "_decomp_output"):
            self._decomp_output.clear()
        if hasattr(self, "_decomp_script_name"):
            self._decomp_script_name.setText("—")

    def _decomp_clear_log(self):
        if hasattr(self, "_decomp_log"):
            self._decomp_log.clear()


if __name__ == "__main__":
    app = QApplication(sys.argv)
    ide = LuaIDE()
    ide.show()
    sys.exit(app.exec())
