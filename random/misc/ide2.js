// ==UserScript==
// @name         Browser IDE Pro
// @namespace    http://tampermonkey.net/
// @version      2.4.0
// @description  Full Monaco-powered IDE floating on any webpage — snippets, output console, theme toggle
// @author       You
// @match        *://*/*
// @grant        GM_setValue
// @grant        GM_getValue
// @grant        GM_addStyle
// @grant        GM_xmlhttpRequest
// @connect      cdn.jsdelivr.net
// @run-at       document-idle
// ==/UserScript==

(function () {
    'use strict';

    // ─── Persistent State ──────────────────────────────────────────────────────
    const S = {
        code:     () => GM_getValue('bide_code', DEFAULT_CODE),
        pos:      () => GM_getValue('bide_pos',  { x: 40, y: 30 }),
        size:     () => GM_getValue('bide_size', { w: 820, h: 540 }),
        theme:    () => GM_getValue('bide_theme', 'dark'),
        lang:     () => GM_getValue('bide_lang', 'javascript'),
        snippets: () => GM_getValue('bide_snippets', DEFAULT_SNIPPETS),
        save: (k, v) => GM_setValue(k, v),
    };

    const DEFAULT_CODE_JS = `// Browser IDE Pro — Monaco Edition
// Ctrl+Enter or click ▶ Run to execute
// Full access to window, document, and page globals

const greet = (name) => \`Hello, \${name}!\`;
console.log(greet("Browser IDE"));

// Try grabbing page info:
// console.log(document.title);
// console.log(document.querySelectorAll('a').length + ' links on page');
`;

    const DEFAULT_CODE_LUA = `-- Browser IDE Pro — Lua (Fengari)
-- Ctrl+Enter or click ▶ Run to execute
-- Full Lua 5.3 via Fengari WASM runtime

local function greet(name)
  return "Hello, " .. name .. "!"
end

print(greet("Lua"))

-- Tables, closures, metatables all work:
local t = { 1, 2, 3, 4, 5 }
for i, v in ipairs(t) do
  print(i, v * v)
end
`;

    const DEFAULT_CODE = DEFAULT_CODE_JS;

    const LUA_SNIPPETS = [
        { name: '[Lua] Hello world',      code: `print("Hello, world!")` },
        { name: '[Lua] For loop',         code: `for i = 1, 10 do\n  print(i)\nend` },
        { name: '[Lua] Table map',        code: `local t = {1,2,3,4,5}\nfor i,v in ipairs(t) do\n  print(i, v * 2)\nend` },
        { name: '[Lua] String format',    code: `local name = "world"\nprint(string.format("Hello, %s! Pi is %.4f", name, math.pi))` },
        { name: '[Lua] Closure counter',  code: `local function counter(start)\n  local n = start or 0\n  return function()\n    n = n + 1\n    return n\n  end\nend\nlocal c = counter(10)\nprint(c(), c(), c())` },
        { name: '[Lua] Metatable',        code: `local Vec = {}\nVec.__index = Vec\nfunction Vec.new(x,y) return setmetatable({x=x,y=y},Vec) end\nfunction Vec:len() return math.sqrt(self.x^2+self.y^2) end\nlocal v = Vec.new(3,4)\nprint(v:len())` },
        { name: '[Lua] pcall error',      code: `local ok, err = pcall(function()\n  error("something went wrong")\nend)\nprint(ok, err)` },
        { name: '[Lua] String split',     code: `local function split(s, sep)\n  local t={}\n  for p in s:gmatch("[^"..sep.."]+") do t[#t+1]=p end\n  return t\nend\nfor _,v in ipairs(split("a,b,c,d", ",")) do print(v) end` },
    ];

    const DEFAULT_SNIPPETS = [
        { name: 'Query selector',    code: `const el = document.querySelector('');\nconsole.log(el);` },
        { name: 'All links',         code: `const links = [...document.querySelectorAll('a')].map(a => a.href);\nconsole.log(links);` },
        { name: 'Fetch JSON',        code: `const res = await fetch('');\nconst data = await res.json();\nconsole.log(data);` },
        { name: 'Page cookies',      code: `console.log(document.cookie);` },
        { name: 'Local storage dump',code: `console.log({...localStorage});` },
        { name: 'Copy to clipboard', code: `navigator.clipboard.writeText('').then(() => console.log('Copied!'));` },
        { name: 'Scroll to top',     code: `window.scrollTo({ top: 0, behavior: 'smooth' });` },
        { name: 'Dark mode toggle',  code: `document.body.style.filter = document.body.style.filter ? '' : 'invert(1) hue-rotate(180deg)';` },
        { name: 'Count elements',    code: `const tag = 'div';\nconsole.log(\`\${document.getElementsByTagName(tag).length} <\${tag}> elements\`);` },
        { name: 'Timestamp',         code: `console.log(new Date().toISOString());` },
    ];

    // ─── Styles ────────────────────────────────────────────────────────────────
    GM_addStyle(`
        @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600&display=swap');

        #__bide_root {
            position: fixed;
            z-index: 2147483647;
            display: flex;
            flex-direction: column;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 16px 64px rgba(0,0,0,0.6), 0 0 0 1px rgba(255,255,255,0.06);
            min-width: 400px;
            min-height: 280px;
            font-family: 'JetBrains Mono', 'Cascadia Code', 'Fira Mono', monospace;
            font-size: 13px;
            transition: opacity 0.18s ease, transform 0.18s ease;
        }
        #__bide_root.hidden { opacity: 0; pointer-events: none; transform: scale(0.97); }

        /* Titlebar */
        #__bide_titlebar {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 0 12px;
            height: 38px;
            cursor: grab;
            user-select: none;
            flex-shrink: 0;
        }
        #__bide_titlebar:active { cursor: grabbing; }
        .bide-dot {
            width: 13px; height: 13px;
            border-radius: 50%;
            cursor: pointer;
            flex-shrink: 0;
            transition: filter 0.12s, transform 0.1s;
            position: relative;
        }
        .bide-dot:hover { filter: brightness(1.3); transform: scale(1.1); }
        .bide-dot::after {
            content: attr(data-tip);
            position: absolute;
            top: 18px; left: 50%;
            transform: translateX(-50%);
            background: rgba(0,0,0,0.75);
            color: #fff;
            font-size: 10px;
            padding: 2px 6px;
            border-radius: 4px;
            white-space: nowrap;
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.15s;
        }
        .bide-dot:hover::after { opacity: 1; }
        #__bide_ide_title {
            flex: 1;
            text-align: center;
            font-size: 11px;
            font-weight: 600;
            letter-spacing: 0.1em;
            text-transform: uppercase;
            opacity: 0.4;
        }
        #__bide_hdr_btns { display: flex; gap: 4px; align-items: center; }
        .bide-hdr-btn {
            background: none;
            border: none;
            cursor: pointer;
            font-size: 13px;
            padding: 3px 6px;
            border-radius: 5px;
            opacity: 0.5;
            transition: opacity 0.12s, background 0.12s;
            font-family: inherit;
        }
        .bide-hdr-btn:hover { opacity: 1; }

        /* Tab bar */
        #__bide_tabs {
            display: flex;
            align-items: stretch;
            gap: 0;
            flex-shrink: 0;
            border-bottom: 1px solid;
        }
        .bide-tab {
            padding: 7px 18px;
            font-size: 11px;
            font-weight: 600;
            cursor: pointer;
            letter-spacing: 0.06em;
            text-transform: uppercase;
            border: none;
            background: none;
            font-family: inherit;
            transition: color 0.12s, border-bottom 0.12s;
            border-bottom: 2px solid transparent;
            margin-bottom: -1px;
        }

        /* Main layout */
        #__bide_body {
            flex: 1;
            display: flex;
            overflow: hidden;
        }

        /* Sidebar */
        #__bide_sidebar {
            width: 190px;
            flex-shrink: 0;
            display: flex;
            flex-direction: column;
            border-right: 1px solid;
            overflow: hidden;
        }
        #__bide_sidebar_hdr {
            padding: 8px 10px 6px;
            font-size: 10px;
            font-weight: 600;
            letter-spacing: 0.1em;
            text-transform: uppercase;
            opacity: 0.45;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        #__bide_add_snippet {
            background: none;
            border: none;
            font-size: 16px;
            cursor: pointer;
            opacity: 0.5;
            padding: 0 2px;
            font-family: inherit;
            transition: opacity 0.12s;
        }
        #__bide_add_snippet:hover { opacity: 1; }
        #__bide_snippets_list {
            flex: 1;
            overflow-y: auto;
            padding: 2px 0;
            scrollbar-width: thin;
        }
        #__bide_snippets_list::-webkit-scrollbar { width: 4px; }
        #__bide_snippets_list::-webkit-scrollbar-thumb { border-radius: 2px; }
        .bide-snippet {
            padding: 7px 12px;
            font-size: 11.5px;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 6px;
            transition: background 0.1s;
            border-radius: 0;
        }
        .bide-snippet span { flex: 1; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .bide-snippet-del {
            opacity: 0;
            font-size: 12px;
            background: none;
            border: none;
            cursor: pointer;
            padding: 0 2px;
            font-family: inherit;
            transition: opacity 0.12s;
            flex-shrink: 0;
        }
        .bide-snippet:hover .bide-snippet-del { opacity: 0.5; }
        .bide-snippet-del:hover { opacity: 1 !important; }

        /* Editor container */
        #__bide_editor_pane {
            flex: 1;
            display: flex;
            flex-direction: column;
            overflow: hidden;
            position: relative;
        }
        #__bide_monaco_container {
            flex: 1;
            overflow: hidden;
        }

        /* Output */
        #__bide_output_pane {
            flex: 1;
            overflow-y: auto;
            padding: 12px 14px;
            font-size: 12px;
            line-height: 1.7;
            display: none;
            scrollbar-width: thin;
        }
        #__bide_output_pane.active { display: block; }
        #__bide_output_pane::-webkit-scrollbar { width: 4px; }
        #__bide_output_pane::-webkit-scrollbar-thumb { border-radius: 2px; }
        .bide-out-log   { opacity: 0.9; }
        .bide-out-warn  { color: #e5c07b; }
        .bide-out-error { color: #e06c75; }
        .bide-out-info  { color: #56b6c2; }
        .bide-out-result{ color: #98c379; font-style: italic; }
        .bide-out-sep   { border: none; border-top: 1px solid; opacity: 0.12; margin: 6px 0; }
        .bide-out-ts    { font-size: 10px; opacity: 0.3; margin-bottom: 4px; }
        .bide-out-line  { white-space: pre-wrap; word-break: break-all; margin: 1px 0; }

        /* Statusbar */
        #__bide_statusbar {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 4px 12px;
            height: 28px;
            font-size: 11px;
            flex-shrink: 0;
            border-top: 1px solid;
        }
        #__bide_status_msg { flex: 1; opacity: 0.45; }
        .bide-run-btn {
            background: #98c379;
            color: #1a1e24;
            border: none;
            border-radius: 5px;
            padding: 3px 14px;
            font-size: 11px;
            font-weight: 700;
            cursor: pointer;
            font-family: inherit;
            letter-spacing: 0.04em;
            transition: filter 0.1s, transform 0.08s;
        }
        .bide-run-btn:hover  { filter: brightness(1.1); }
        .bide-run-btn:active { transform: scale(0.96); }
        .bide-clear-btn {
            background: none;
            border: 1px solid;
            border-radius: 5px;
            padding: 2px 10px;
            font-size: 11px;
            cursor: pointer;
            font-family: inherit;
            opacity: 0.4;
            transition: opacity 0.12s;
        }
        .bide-clear-btn:hover { opacity: 0.9; }
        #__bide_cursor_pos { opacity: 0.3; font-size: 10px; }

        /* Language picker */
        #__bide_lang_picker {
            background: none;
            border: 1px solid;
            border-radius: 5px;
            padding: 2px 8px;
            font-size: 11px;
            font-weight: 600;
            font-family: inherit;
            cursor: pointer;
            letter-spacing: 0.04em;
            transition: opacity 0.12s;
        }
        .bide-dark  #__bide_lang_picker { border-color: #3e4451; color: #abb2bf; background: #1e2127; }
        .bide-light #__bide_lang_picker { border-color: #c0c0c0; color: #383a42; background: #f7f7f7; }

        /* Resize handle */
        #__bide_resize {
            position: absolute;
            bottom: 0; right: 0;
            width: 18px; height: 18px;
            cursor: se-resize;
            z-index: 10;
            opacity: 0.25;
            font-size: 10px;
            display: flex;
            align-items: flex-end;
            justify-content: flex-end;
            padding: 2px;
        }

        /* Restore button */
        #__bide_restore_btn {
            position: fixed;
            bottom: 22px;
            right: 22px;
            z-index: 2147483646;
            border-radius: 9px;
            padding: 9px 18px;
            font-family: 'JetBrains Mono', monospace;
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
            letter-spacing: 0.06em;
            box-shadow: 0 4px 24px rgba(0,0,0,0.4);
            transition: filter 0.12s, transform 0.1s;
            display: none;
        }
        #__bide_restore_btn:hover { filter: brightness(1.15); transform: scale(1.04); }

        /* Modal for add snippet */
        #__bide_modal_bg {
            position: fixed;
            inset: 0;
            z-index: 2147483648;
            background: rgba(0,0,0,0.55);
            display: none;
            align-items: center;
            justify-content: center;
        }
        #__bide_modal_bg.open { display: flex; }
        #__bide_modal {
            border-radius: 10px;
            padding: 20px 24px;
            width: 420px;
            box-shadow: 0 8px 40px rgba(0,0,0,0.5);
        }
        #__bide_modal h3 { margin: 0 0 14px; font-size: 14px; }
        #__bide_modal input, #__bide_modal textarea {
            width: 100%;
            border-radius: 6px;
            border: 1px solid;
            padding: 8px 10px;
            font-family: 'JetBrains Mono', monospace;
            font-size: 12px;
            margin-bottom: 10px;
            outline: none;
            resize: vertical;
        }
        #__bide_modal textarea { min-height: 120px; }
        #__bide_modal_btns { display: flex; gap: 8px; justify-content: flex-end; margin-top: 4px; }
        .bide-modal-save { background: #98c379; color: #1a1e24; border: none; border-radius: 6px; padding: 6px 18px; cursor: pointer; font-weight: 700; font-family: inherit; }
        .bide-modal-cancel { background: none; border: 1px solid; border-radius: 6px; padding: 5px 14px; cursor: pointer; font-family: inherit; opacity: 0.5; }
        .bide-modal-cancel:hover { opacity: 1; }

        /* DARK */
        .bide-dark#__bide_root           { background: #1e2127; color: #abb2bf; }
        .bide-dark #__bide_titlebar      { background: #171a1f; }
        .bide-dark #__bide_tabs          { background: #171a1f; border-color: #2c313a; }
        .bide-dark .bide-tab             { color: #5c6370; }
        .bide-dark .bide-tab.active      { color: #abb2bf; border-bottom-color: #61afef; }
        .bide-dark .bide-hdr-btn         { color: #abb2bf; }
        .bide-dark .bide-hdr-btn:hover   { background: #2c313a; }
        .bide-dark #__bide_sidebar       { background: #171a1f; border-color: #2c313a; }
        .bide-dark .bide-snippet         { color: #abb2bf; }
        .bide-dark .bide-snippet:hover   { background: #2c313a; }
        .bide-dark .bide-snippet-del     { color: #e06c75; }
        .bide-dark #__bide_output_pane   { background: #1a1d24; color: #abb2bf; }
        .bide-dark .bide-out-log         { color: #abb2bf; }
        .bide-dark .bide-out-sep         { border-color: #abb2bf; }
        .bide-dark #__bide_statusbar     { background: #171a1f; border-color: #2c313a; color: #abb2bf; }
        .bide-dark .bide-clear-btn       { border-color: #3e4451; color: #abb2bf; }
        .bide-dark #__bide_snippets_list::-webkit-scrollbar-thumb { background: #3e4451; }
        .bide-dark #__bide_output_pane::-webkit-scrollbar-thumb   { background: #3e4451; }
        .bide-dark #__bide_restore_btn   { background: #1e2127; color: #abb2bf; border: 1px solid #3e4451; }
        .bide-dark #__bide_modal         { background: #21252b; color: #abb2bf; }
        .bide-dark #__bide_modal input,
        .bide-dark #__bide_modal textarea { background: #1a1d24; color: #abb2bf; border-color: #3e4451; }
        .bide-dark .bide-modal-cancel    { color: #abb2bf; border-color: #3e4451; }

        /* LIGHT */
        .bide-light#__bide_root          { background: #f7f7f7; color: #383a42; box-shadow: 0 16px 64px rgba(0,0,0,0.18), 0 0 0 1px rgba(0,0,0,0.08); }
        .bide-light #__bide_titlebar     { background: #ececec; }
        .bide-light #__bide_tabs         { background: #ececec; border-color: #d4d4d4; }
        .bide-light .bide-tab            { color: #a0a0a0; }
        .bide-light .bide-tab.active     { color: #383a42; border-bottom-color: #4078f2; }
        .bide-light .bide-hdr-btn        { color: #383a42; }
        .bide-light .bide-hdr-btn:hover  { background: #ddd; }
        .bide-light #__bide_sidebar      { background: #ececec; border-color: #d4d4d4; }
        .bide-light .bide-snippet        { color: #383a42; }
        .bide-light .bide-snippet:hover  { background: #e0e0e0; }
        .bide-light .bide-snippet-del    { color: #ca1243; }
        .bide-light #__bide_output_pane  { background: #f0f0f0; color: #383a42; }
        .bide-light .bide-out-log        { color: #383a42; }
        .bide-light .bide-out-warn       { color: #9a6700; }
        .bide-light .bide-out-error      { color: #ca1243; }
        .bide-light .bide-out-result     { color: #0184bc; }
        .bide-light .bide-out-sep        { border-color: #383a42; }
        .bide-light #__bide_statusbar    { background: #ececec; border-color: #d4d4d4; color: #383a42; }
        .bide-light .bide-clear-btn      { border-color: #c0c0c0; color: #383a42; }
        .bide-light #__bide_snippets_list::-webkit-scrollbar-thumb { background: #c0c0c0; }
        .bide-light #__bide_output_pane::-webkit-scrollbar-thumb   { background: #c0c0c0; }
        .bide-light #__bide_restore_btn  { background: #f7f7f7; color: #383a42; border: 1px solid #d4d4d4; }
        .bide-light #__bide_modal        { background: #f7f7f7; color: #383a42; }
        .bide-light #__bide_modal input,
        .bide-light #__bide_modal textarea { background: #fff; color: #383a42; border-color: #d4d4d4; }
        .bide-light .bide-modal-cancel   { color: #383a42; border-color: #c0c0c0; }
    `);

    // ─── Build DOM ─────────────────────────────────────────────────────────────
    const root = document.createElement('div');
    root.id = '__bide_root';

    const pos  = S.pos();
    const size = S.size();
    root.style.cssText = `left:${pos.x}px;top:${pos.y}px;width:${size.w}px;height:${size.h}px;`;

    root.innerHTML = `
    <div id="__bide_titlebar">
      <div class="bide-dot" id="bide_close" style="background:#e06c75" data-tip="Close"></div>
      <div class="bide-dot" id="bide_min"   style="background:#e5c07b" data-tip="Minimize"></div>
      <div class="bide-dot" id="bide_max"   style="background:#98c379" data-tip="Maximize"></div>
      <span id="__bide_ide_title">Browser IDE Pro</span>
      <div id="__bide_hdr_btns">
        <button class="bide-hdr-btn" id="bide_theme_btn" title="Toggle theme">◐</button>
      </div>
    </div>
    <div id="__bide_tabs">
      <button class="bide-tab active" data-tab="editor">Editor</button>
      <button class="bide-tab"        data-tab="output">Output</button>
    </div>
    <div id="__bide_body">
      <div id="__bide_sidebar">
        <div id="__bide_sidebar_hdr">
          <span>Snippets</span>
          <button id="__bide_add_snippet" title="Add snippet">+</button>
        </div>
        <div id="__bide_snippets_list"></div>
      </div>
      <div id="__bide_editor_pane">
        <div id="__bide_monaco_container"></div>
        <div id="__bide_output_pane"></div>
      </div>
    </div>
    <div id="__bide_statusbar">
      <button class="bide-run-btn"   id="bide_run_btn">▶ Run</button>
      <button class="bide-clear-btn" id="bide_clear_btn">Clear</button>
      <select id="__bide_lang_picker">
        <option value="javascript">JavaScript</option>
        <option value="lua">Lua 5.3</option>
      </select>
      <span id="__bide_status_msg">ready</span>
      <span id="__bide_cursor_pos">Ln 1, Col 1</span>
    </div>
    <div id="__bide_resize" title="Drag to resize">⋱</div>`;

    // Modal
    const modalBg = document.createElement('div');
    modalBg.id = '__bide_modal_bg';
    modalBg.innerHTML = `
    <div id="__bide_modal">
      <h3>Add Snippet</h3>
      <input id="bide_snip_name" placeholder="Snippet name…" />
      <textarea id="bide_snip_code" placeholder="// code here…"></textarea>
      <div id="__bide_modal_btns">
        <button class="bide-modal-cancel" id="bide_modal_cancel">Cancel</button>
        <button class="bide-modal-save"   id="bide_modal_save">Save</button>
      </div>
    </div>`;

    // Restore button
    const restoreBtn = document.createElement('button');
    restoreBtn.id = '__bide_restore_btn';
    restoreBtn.textContent = '{ IDE }';

    document.body.appendChild(root);
    document.body.appendChild(modalBg);
    document.body.appendChild(restoreBtn);

    // ─── Theme ─────────────────────────────────────────────────────────────────
    let theme = S.theme();

    function applyTheme() {
        root.classList.toggle('bide-dark',  theme === 'dark');
        root.classList.toggle('bide-light', theme === 'light');
        if (window.__bide_monaco) {
            monaco.editor.setTheme(theme === 'dark' ? 'bide-dark' : 'bide-light');
        }
    }

    document.getElementById('bide_theme_btn').addEventListener('click', () => {
        theme = theme === 'dark' ? 'light' : 'dark';
        S.save('bide_theme', theme);
        applyTheme();
    });

    // ─── Tabs ──────────────────────────────────────────────────────────────────
    let activeTab = 'editor';
    const tabBtns      = root.querySelectorAll('.bide-tab');
    const editorPane   = root.querySelector('#__bide_editor_pane');
    const monacoContainer = root.querySelector('#__bide_monaco_container');
    const outputPane   = root.querySelector('#__bide_output_pane');

    function switchTab(name) {
        activeTab = name;
        tabBtns.forEach(t => t.classList.toggle('active', t.dataset.tab === name));
        if (name === 'editor') {
            monacoContainer.style.display = 'block';
            outputPane.classList.remove('active');
            if (window.__bide_monaco) window.__bide_monaco.layout();
        } else {
            monacoContainer.style.display = 'none';
            outputPane.classList.add('active');
        }
    }

    tabBtns.forEach(t => t.addEventListener('click', () => switchTab(t.dataset.tab)));

    // ─── Language (declared early — renderSnippets reads this) ─────────────────
    let currentLang = S.lang();

    // ─── Snippets ──────────────────────────────────────────────────────────────
    function renderSnippets() {
        const list = document.getElementById('__bide_snippets_list');
        const jsSnips  = S.snippets();
        const allSnips = currentLang === 'lua'
            ? [...LUA_SNIPPETS, ...jsSnips.filter(s => s.name.startsWith('[Lua]'))]
            : jsSnips.filter(s => !s.name.startsWith('[Lua]'));
        list.innerHTML = '';
        allSnips.forEach((s, i) => {
            const item = document.createElement('div');
            item.className = 'bide-snippet';
            item.innerHTML = `<span title="${s.name}">${s.name}</span><button class="bide-snippet-del" data-i="${i}" title="Delete">✕</button>`;
            item.addEventListener('click', (e) => {
                if (e.target.classList.contains('bide-snippet-del')) return;
                if (window.__bide_monaco) {
                    window.__bide_monaco.setValue(s.code);
                    S.save('bide_code', s.code);
                    switchTab('editor');
                    setStatus('Snippet loaded');
                }
            });
            item.querySelector('.bide-snippet-del').addEventListener('click', () => {
                // Only delete user-saved snippets, not built-in Lua ones
                if (s.name.startsWith('[Lua]') && LUA_SNIPPETS.find(ls => ls.name === s.name)) return;
                const arr = S.snippets();
                const idx = arr.findIndex(a => a.name === s.name && a.code === s.code);
                if (idx !== -1) { arr.splice(idx, 1); S.save('bide_snippets', arr); }
                renderSnippets();
            });
            list.appendChild(item);
        });
    }

    renderSnippets();

    // Add snippet modal
    document.getElementById('__bide_add_snippet').addEventListener('click', () => {
        document.getElementById('bide_snip_name').value = '';
        document.getElementById('bide_snip_code').value = window.__bide_monaco ? window.__bide_monaco.getValue() : '';
        modalBg.classList.add('open');
        setTimeout(() => document.getElementById('bide_snip_name').focus(), 50);
    });

    document.getElementById('bide_modal_cancel').addEventListener('click', () => modalBg.classList.remove('open'));
    modalBg.addEventListener('click', (e) => { if (e.target === modalBg) modalBg.classList.remove('open'); });

    document.getElementById('bide_modal_save').addEventListener('click', () => {
        const name = document.getElementById('bide_snip_name').value.trim();
        const code = document.getElementById('bide_snip_code').value;
        if (!name) return;
        const arr = S.snippets();
        arr.push({ name, code });
        S.save('bide_snippets', arr);
        renderSnippets();
        modalBg.classList.remove('open');
        setStatus(`Snippet "${name}" saved`);
    });

    // ─── Language ───────────────────────────────────────────────────────────────
    const langPicker = document.getElementById('__bide_lang_picker');
    langPicker.value = currentLang;

    function switchLang(lang) {
        currentLang = lang;
        S.save('bide_lang', lang);
        S.save('bide_code', lang === 'lua' ? DEFAULT_CODE_LUA : DEFAULT_CODE_JS);

        if (window.__bide_monaco) {
            const model = window.__bide_monaco.getModel();
            if (model) {
                monaco.editor.setModelLanguage(model, lang === 'lua' ? 'lua' : 'javascript');
            }
            window.__bide_monaco.setValue(S.code());
        }

        // Refresh snippet list to show/hide Lua snippets
        renderSnippets();
        setStatus(`Switched to ${lang === 'lua' ? 'Lua 5.3' : 'JavaScript'}`);
    }

    langPicker.addEventListener('change', () => switchLang(langPicker.value));

    // ─── Fengari Loader ────────────────────────────────────────────────────────
    // Use GM_xmlhttpRequest to fetch fengari as text, then inject as a blob URL.
    // This runs in TM's network context so page CSP doesn't apply.
    let fengariLoaded = false;
    let fengariLoading = null;

    function loadFengari() {
        if (fengariLoaded && window.fengari) return Promise.resolve();
        if (fengariLoading) return fengariLoading;

        fengariLoading = new Promise((resolve, reject) => {
            GM_xmlhttpRequest({
                method: 'GET',
                url: 'https://cdn.jsdelivr.net/npm/fengari-web@0.1.4/dist/fengari-web.js',
                onload: (res) => {
                    const blob = new Blob([res.responseText], { type: 'text/javascript' });
                    const url  = URL.createObjectURL(blob);
                    const s    = document.createElement('script');
                    s.src = url;
                    s.onload = () => {
                        URL.revokeObjectURL(url);
                        setTimeout(() => {
                            if (window.fengari && window.fengari.lua) {
                                fengariLoaded = true;
                                resolve();
                            } else {
                                reject(new Error('fengari loaded but window.fengari.lua not found'));
                            }
                        }, 50);
                    };
                    s.onerror = () => reject(new Error('fengari blob inject failed'));
                    document.head.appendChild(s);
                },
                onerror: () => reject(new Error('GM_xmlhttpRequest failed for fengari')),
            });
        });
        return fengariLoading;
    }

    // ─── Lua Runner ────────────────────────────────────────────────────────────
    async function runLua(code) {
        setStatus('loading Fengari…', 0);
        try {
            await loadFengari();
        } catch (e) {
            appendOutput('⚠ Could not load Fengari runtime: ' + e.message, 'bide-out-error');
            setStatus('Fengari load failed');
            return;
        }

        setStatus('running…', 0);
        const t0 = performance.now();

        try {
            // fengari-web's actual API: fengari.load(src) returns a JS function
            // that when called runs the Lua chunk. It uses the module's internal
            // shared state (lua/lauxlib/lualib) exposed on the fengari object.
            const { lua, lauxlib, lualib, to_luastring, to_jsstring } = fengari;

            // Create a fresh Lua state for each run
            const L = lauxlib.luaL_newstate();
            lualib.luaL_openlibs(L);

            // Capture print() by replacing Lua's print with a JS-bridged version
            const captured = [];

            // Push a JS function onto the Lua stack as a C function
            lua.lua_pushcclosure(L, (LS) => {
                const nargs = lua.lua_gettop(LS);
                const parts = [];
                for (let i = 1; i <= nargs; i++) {
                    // coerce each arg to string via tostring()
                    luaL_tolstring(LS, i);
                    parts.push(to_jsstring(lua.lua_tostring(LS, -1)));
                    lua.lua_pop(LS, 1);
                }
                captured.push(parts.join('\t'));
                return 0;
            }, 0);
            lua.lua_setglobal(L, to_luastring('print'));

            // Helper: Lua's luaL_tolstring (tostring coercion) — call via Lua
            function luaL_tolstring(LS, idx) {
                // push tostring function
                lua.lua_getglobal(LS, to_luastring('tostring'));
                lua.lua_pushvalue(LS, idx);
                lua.lua_call(LS, 1, 1);
            }

            // Load and execute the code
            const status = lauxlib.luaL_loadstring(L, to_luastring(code));
            if (status !== lua.LUA_OK) {
                const errMsg = to_jsstring(lua.lua_tostring(L, -1));
                appendOutput('⚠ ' + errMsg, 'bide-out-error');
                setStatus('error');
                return;
            }

            const callStatus = lua.lua_pcall(L, 0, lua.LUA_MULTRET, 0);
            if (callStatus !== lua.LUA_OK) {
                const errMsg = to_jsstring(lua.lua_tostring(L, -1));
                appendOutput('⚠ ' + errMsg, 'bide-out-error');
                setStatus('error');
                return;
            }

            captured.forEach(line => appendOutput(line, 'bide-out-log'));
            if (captured.length === 0) appendOutput('(no output)', 'bide-out-info');

        } catch (err) {
            appendOutput('⚠ ' + err.message, 'bide-out-error');
            setStatus('error');
            return;
        }

        const ms = (performance.now() - t0).toFixed(1);
        setStatus(`done in ${ms}ms`);
    }


    function appendOutput(text, cls) {
        const line = document.createElement('div');
        line.className = `bide-out-line ${cls}`;
        line.textContent = text;
        outputPane.appendChild(line);
        outputPane.scrollTop = outputPane.scrollHeight;
    }

    function appendSep() {
        const ts = document.createElement('div');
        ts.className = 'bide-out-ts';
        ts.textContent = new Date().toLocaleTimeString();
        const hr = document.createElement('hr');
        hr.className = 'bide-out-sep';
        outputPane.appendChild(hr);
        outputPane.appendChild(ts);
    }

    function serializeArg(v) {
        if (v === null || v === undefined) return String(v);
        if (v instanceof Error) return `${v.name}: ${v.message}`;
        if (typeof v === 'object') { try { return JSON.stringify(v, null, 2); } catch { return String(v); } }
        return String(v);
    }

    // ─── Run ───────────────────────────────────────────────────────────────────
    function setStatus(msg, duration = 2000) {
        const el = document.getElementById('__bide_status_msg');
        el.textContent = msg;
        clearTimeout(el._t);
        if (duration) el._t = setTimeout(() => { el.textContent = 'ready'; }, duration);
    }

    async function runCode() {
        const code = window.__bide_monaco ? window.__bide_monaco.getValue() : '';
        appendSep();
        switchTab('output');
        if (currentLang === 'lua') {
            await runLua(code);
            return;
        }
        setStatus('running…', 0);
        const t0 = performance.now();

        // CSP-safe execution: wrap code in a blob-URL script injected via a
        // sandboxed iframe. The iframe has no src so it gets a null origin and
        // is not subject to the host page's Content-Security-Policy.
        // We use postMessage to relay console output back to the IDE.
        await new Promise((resolve) => {
            // Build the runner script that lives inside the blob
            const runnerSrc = `
(async () => {
    const _send = (type, args) => parent.postMessage({ __bide: true, type, args }, '*');
    const _ser  = (v) => {
        if (v === null || v === undefined) return String(v);
        if (v instanceof Error) return v.name + ': ' + v.message;
        if (typeof v === 'object') { try { return JSON.stringify(v, null, 2); } catch(e) { return String(v); } }
        return String(v);
    };
    const console = {
        log:   (...a) => _send('log',   a.map(_ser)),
        warn:  (...a) => _send('warn',  a.map(_ser)),
        error: (...a) => _send('error', a.map(_ser)),
        info:  (...a) => _send('info',  a.map(_ser)),
    };
    try {
        const __result = await (async () => { ${code} })();
        _send('result', [__result === undefined ? null : _ser(__result), __result === undefined]);
    } catch(err) {
        _send('error', [err.name + ': ' + err.message]);
        _send('result', [null, true]);
    }
})();
`;
            // Create blob and iframe
            const blob = new Blob([runnerSrc], { type: 'text/javascript' });
            const blobUrl = URL.createObjectURL(blob);

            const frame = document.createElement('iframe');
            frame.style.cssText = 'display:none;width:0;height:0;border:none;';
            // allow-scripts is enough; no allow-same-origin so it stays sandboxed
            frame.sandbox = 'allow-scripts';
            document.body.appendChild(frame);

            const listener = (e) => {
                if (!e.data || !e.data.__bide) return;
                const { type, args } = e.data;
                if (type === 'result') {
                    window.removeEventListener('message', listener);
                    frame.remove();
                    URL.revokeObjectURL(blobUrl);
                    const ms = (performance.now() - t0).toFixed(1);
                    if (!args[1]) appendOutput('→ ' + args[0], 'bide-out-result');
                    setStatus(`done in ${ms}ms`);
                    resolve();
                } else {
                    const cls = { log:'bide-out-log', warn:'bide-out-warn', error:'bide-out-error', info:'bide-out-info' }[type] || 'bide-out-log';
                    appendOutput(args.join(' '), cls);
                }
            };
            window.addEventListener('message', listener);

            // Inject the blob script into the sandboxed iframe
            frame.srcdoc = `<script src="${blobUrl}"><\/script>`;
        });
    }

    document.getElementById('bide_run_btn').addEventListener('click', runCode);
    document.getElementById('bide_clear_btn').addEventListener('click', () => {
        outputPane.innerHTML = '';
        setStatus('cleared', 1000);
    });

    // ─── Monaco Loader ─────────────────────────────────────────────────────────
    // Fetch Monaco's AMD loader via GM_xmlhttpRequest, inject as blob to bypass
    // CSP, then use the AMD require() it exposes to pull in editor.main normally.
    function loadMonaco() {
        return new Promise((resolve, reject) => {
            if (window.monaco) { resolve(window.monaco); return; }

            GM_xmlhttpRequest({
                method: 'GET',
                url: 'https://cdn.jsdelivr.net/npm/monaco-editor@0.47.0/min/vs/loader.js',
                onload: (res) => {
                    const blob = new Blob([res.responseText], { type: 'text/javascript' });
                    const url  = URL.createObjectURL(blob);
                    const s    = document.createElement('script');
                    s.src = url;
                    s.onload = () => {
                        URL.revokeObjectURL(url);
                        try {
                            require.config({
                                paths: { vs: 'https://cdn.jsdelivr.net/npm/monaco-editor@0.47.0/min/vs' }
                            });
                            require(['vs/editor/editor.main'], () => {
                                if (window.monaco) resolve(window.monaco);
                                else reject(new Error('monaco undefined after require'));
                            });
                        } catch (e) { reject(e); }
                    };
                    s.onerror = () => reject(new Error('Monaco loader blob inject failed'));
                    document.head.appendChild(s);
                },
                onerror: () => reject(new Error('GM_xmlhttpRequest failed for Monaco loader')),
            });
        });
    }
        });
    }

    async function initMonaco() {
        setStatus('loading Monaco…', 0);

        try {
            const monaco = await loadMonaco();

            // Custom dark theme
            monaco.editor.defineTheme('bide-dark', {
                base: 'vs-dark',
                inherit: true,
                rules: [
                    { token: 'comment',     foreground: '5c6370', fontStyle: 'italic' },
                    { token: 'keyword',     foreground: 'c678dd' },
                    { token: 'string',      foreground: '98c379' },
                    { token: 'number',      foreground: 'd19a66' },
                    { token: 'identifier',  foreground: 'e06c75' },
                    { token: 'type',        foreground: 'e5c07b' },
                    { token: 'delimiter',   foreground: 'abb2bf' },
                ],
                colors: {
                    'editor.background':           '#1e2127',
                    'editor.foreground':           '#abb2bf',
                    'editorLineNumber.foreground': '#495162',
                    'editorLineNumber.activeForeground': '#abb2bf',
                    'editor.lineHighlightBackground': '#2c313a',
                    'editorCursor.foreground':     '#528bff',
                    'editor.selectionBackground':  '#3e4451',
                    'editorWidget.background':     '#21252b',
                    'editorSuggestWidget.background': '#21252b',
                    'editorSuggestWidget.border':  '#3e4451',
                    'editorSuggestWidget.selectedBackground': '#2c313a',
                },
            });

            // Custom light theme
            monaco.editor.defineTheme('bide-light', {
                base: 'vs',
                inherit: true,
                rules: [
                    { token: 'comment',    foreground: 'a0a1a7', fontStyle: 'italic' },
                    { token: 'keyword',    foreground: 'a626a4' },
                    { token: 'string',     foreground: '50a14f' },
                    { token: 'number',     foreground: '986801' },
                    { token: 'identifier', foreground: 'e45649' },
                ],
                colors: {
                    'editor.background':           '#f7f7f7',
                    'editor.foreground':           '#383a42',
                    'editorLineNumber.foreground': '#c0c0c0',
                    'editor.lineHighlightBackground': '#ececec',
                    'editor.selectionBackground':  '#d4d4d4',
                    'editorWidget.background':     '#f0f0f0',
                },
            });

            const ed = monaco.editor.create(monacoContainer, {
                value:           S.code(),
                language:        currentLang === 'lua' ? 'lua' : 'javascript',
                theme:           theme === 'dark' ? 'bide-dark' : 'bide-light',
                fontSize:        13,
                fontFamily:      "'JetBrains Mono', 'Cascadia Code', 'Fira Mono', monospace",
                fontLigatures:   true,
                lineHeight:      22,
                minimap:         { enabled: false },
                scrollBeyondLastLine: false,
                automaticLayout: false,
                wordWrap:        'off',
                cursorBlinking:  'smooth',
                cursorSmoothCaretAnimation: 'on',
                smoothScrolling: true,
                roundedSelection: true,
                padding:         { top: 12, bottom: 12 },
                tabSize:         2,
                insertSpaces:    true,
                renderLineHighlight: 'line',
                suggest: {
                    showKeywords: true,
                    showSnippets: true,
                },
            });

            window.__bide_monaco = ed;

            // Auto-save
            ed.onDidChangeModelContent(() => {
                S.save('bide_code', ed.getValue());
                setStatus('saved', 1200);
            });

            // Cursor position
            ed.onDidChangeCursorPosition((e) => {
                document.getElementById('__bide_cursor_pos').textContent =
                    `Ln ${e.position.lineNumber}, Col ${e.position.column}`;
            });

            // Ctrl+Enter to run
            ed.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.Enter, runCode);

            // Add JS globals to autocomplete
            monaco.languages.typescript.javascriptDefaults.setCompilerOptions({
                allowNonTsExtensions: true,
                noLib: false,
            });

            setStatus('Monaco ready');
            langPicker.value = currentLang;

            // Resize observer
            const ro = new ResizeObserver(() => ed.layout());
            ro.observe(monacoContainer);

        } catch (err) {
            console.error('Monaco failed to load:', err);
            setStatus('Monaco load failed — check network');

            // Fallback textarea
            monacoContainer.innerHTML = `<textarea id="__bide_fallback_ta" style="width:100%;height:100%;border:none;outline:none;resize:none;padding:12px;font-family:'JetBrains Mono',monospace;font-size:13px;background:transparent;tab-size:2;"></textarea>`;
            const ta = document.getElementById('__bide_fallback_ta');
            ta.value = S.code();
            ta.addEventListener('input', () => S.save('bide_code', ta.value));
            ta.addEventListener('keydown', (e) => {
                if (e.key === 'Tab') { e.preventDefault(); const s = ta.selectionStart; ta.value = ta.value.substring(0,s)+'  '+ta.value.substring(ta.selectionEnd); ta.selectionStart=ta.selectionEnd=s+2; }
                if (e.key==='Enter'&&(e.ctrlKey||e.metaKey)) runCode();
            });
            window.__bide_monaco = { getValue: ()=>ta.value, setValue: (v)=>{ta.value=v;}, layout: ()=>{} };
        }
    }

    // ─── Drag ──────────────────────────────────────────────────────────────────
    const titlebar = document.getElementById('__bide_titlebar');
    let dragging = false, dox = 0, doy = 0;

    titlebar.addEventListener('mousedown', (e) => {
        if (['bide-dot','bide-hdr-btn'].some(c => e.target.classList.contains(c))) return;
        dragging = true;
        dox = e.clientX - root.offsetLeft;
        doy = e.clientY - root.offsetTop;
        e.preventDefault();
    });

    document.addEventListener('mousemove', (e) => {
        if (!dragging) return;
        const x = Math.max(0, Math.min(window.innerWidth  - root.offsetWidth,  e.clientX - dox));
        const y = Math.max(0, Math.min(window.innerHeight - root.offsetHeight, e.clientY - doy));
        root.style.left = x + 'px';
        root.style.top  = y + 'px';
    });

    document.addEventListener('mouseup', () => {
        if (!dragging) return;
        dragging = false;
        S.save('bide_pos', { x: parseInt(root.style.left), y: parseInt(root.style.top) });
    });

    // ─── Resize ────────────────────────────────────────────────────────────────
    const resizeHandle = document.getElementById('__bide_resize');
    let resizing = false, rox=0, roy=0, rw0=0, rh0=0;

    resizeHandle.addEventListener('mousedown', (e) => {
        resizing = true; rox=e.clientX; roy=e.clientY; rw0=root.offsetWidth; rh0=root.offsetHeight;
        e.preventDefault(); e.stopPropagation();
    });

    document.addEventListener('mousemove', (e) => {
        if (!resizing) return;
        const w = Math.max(400, rw0+(e.clientX-rox));
        const h = Math.max(280, rh0+(e.clientY-roy));
        root.style.width  = w+'px';
        root.style.height = h+'px';
    });

    document.addEventListener('mouseup', () => {
        if (!resizing) return;
        resizing = false;
        S.save('bide_size', { w: root.offsetWidth, h: root.offsetHeight });
        if (window.__bide_monaco) window.__bide_monaco.layout();
    });

    // ─── Window controls ───────────────────────────────────────────────────────
    document.getElementById('bide_close').addEventListener('click', () => {
        root.classList.add('hidden');
        restoreBtn.style.display = 'block';
    });

    document.getElementById('bide_min').addEventListener('click', () => {
        root.classList.add('hidden');
        restoreBtn.style.display = 'block';
    });

    let maximized = false, prevRect = {};
    document.getElementById('bide_max').addEventListener('click', () => {
        if (!maximized) {
            prevRect = { left: root.style.left, top: root.style.top, width: root.style.width, height: root.style.height };
            root.style.cssText = 'left:0;top:0;width:100vw;height:100vh;border-radius:0;';
        } else {
            root.style.left   = prevRect.left;
            root.style.top    = prevRect.top;
            root.style.width  = prevRect.width;
            root.style.height = prevRect.height;
            root.style.borderRadius = '12px';
        }
        maximized = !maximized;
        setTimeout(() => { if (window.__bide_monaco) window.__bide_monaco.layout(); }, 50);
    });

    restoreBtn.addEventListener('click', () => {
        root.classList.remove('hidden');
        restoreBtn.style.display = 'none';
        setTimeout(() => { if (window.__bide_monaco) window.__bide_monaco.layout(); }, 50);
    });

    // ─── Init ──────────────────────────────────────────────────────────────────
    applyTheme();
    initMonaco();

})();
