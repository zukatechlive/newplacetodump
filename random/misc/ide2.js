

(function () {
    'use strict';


    const _conQueue = [];
    const _timers   = Object.create(null);
    const _counters = Object.create(null);
    let   _groupDepth = 0;
    const _nativeConsole = window.console;

    function _conCapture(level, args) {
        _conQueue.push({ level, args, depth: _groupDepth, ts: Date.now() });
        if (window.__bide_conFlush) window.__bide_conFlush();
    }

    window.console = new Proxy(_nativeConsole, {
        get(target, prop) {
            switch (prop) {
                case 'log':   return (...a) => { _nativeConsole.log(...a);   _conCapture('log',   a); };
                case 'warn':  return (...a) => { _nativeConsole.warn(...a);  _conCapture('warn',  a); };
                case 'error': return (...a) => { _nativeConsole.error(...a); _conCapture('error', a); };
                case 'info':  return (...a) => { _nativeConsole.info(...a);  _conCapture('info',  a); };
                case 'debug': return (...a) => { _nativeConsole.debug(...a); _conCapture('debug', a); };
                case 'assert': return (cond, ...a) => {
                    if (!cond) {
                        const msg = a.length ? a : ['Assertion failed'];
                        _nativeConsole.assert(cond, ...msg);
                        _conCapture('assert', ['Assertion failed:', ...msg]);
                    }
                };
                case 'table': return (data, cols) => {
                    _nativeConsole.table(data, cols);
                    _conCapture('table', [data, cols]);
                };
                case 'group': return (...a) => {
                    _nativeConsole.group(...a);
                    _conCapture('group', a);
                    _groupDepth++;
                };
                case 'groupCollapsed': return (...a) => {
                    _nativeConsole.groupCollapsed(...a);
                    _conCapture('groupCollapsed', a);
                    _groupDepth++;
                };
                case 'groupEnd': return () => {
                    _nativeConsole.groupEnd();
                    _groupDepth = Math.max(0, _groupDepth - 1);
                    _conCapture('groupEnd', []);
                };
                case 'count': return (label = 'default') => {
                    _counters[label] = (_counters[label] || 0) + 1;
                    _nativeConsole.count(label);
                    _conCapture('log', [`${label}: ${_counters[label]}`]);
                };
                case 'countReset': return (label = 'default') => {
                    _counters[label] = 0;
                    _nativeConsole.countReset(label);
                };
                case 'time': return (label = 'default') => {
                    _timers[label] = performance.now();
                    _nativeConsole.time(label);
                };
                case 'timeEnd': return (label = 'default') => {
                    const elapsed = _timers[label] != null
                        ? (performance.now() - _timers[label]).toFixed(3) + 'ms'
                        : 'unknown';
                    delete _timers[label];
                    _nativeConsole.timeEnd(label);
                    _conCapture('log', [`${label}: ${elapsed}`]);
                };
                case 'timeLog': return (label = 'default', ...data) => {
                    const elapsed = _timers[label] != null
                        ? (performance.now() - _timers[label]).toFixed(3) + 'ms'
                        : 'unknown';
                    _nativeConsole.timeLog(label, ...data);
                    _conCapture('log', [`${label}: ${elapsed}`, ...data]);
                };
                case 'trace': return (...a) => {
                    const err = new Error();
                    const stack = err.stack || '';
                    _nativeConsole.trace(...a);
                    _conCapture('trace', [...a, '\n' + stack]);
                };
                case 'clear': return () => {
                    _nativeConsole.clear();
                    _conCapture('clear', []);
                };
                default: return typeof target[prop] === 'function'
                    ? target[prop].bind(target)
                    : target[prop];
            }
        }
    });

    // Also capture unhandled errors and promise rejections
    window.addEventListener('error', (e) => {
        _conCapture('uncaught', [e.message || 'Uncaught error', e.filename, e.lineno]);
    });
    window.addEventListener('unhandledrejection', (e) => {
        _conCapture('uncaught', ['Unhandled Promise rejection:', e.reason]);
    });

    // ─── Wait for DOM ──────────────────────────────────────────────────────────
    function domReady(fn) {
        if (document.readyState !== 'loading') { fn(); return; }
        document.addEventListener('DOMContentLoaded', fn, { once: true });
    }

    domReady(initIDE);

    function initIDE() {

    // ─── Persistent State ──────────────────────────────────────────────────────
    const S = {
        code:     (lang) => GM_getValue(`bide_code_${lang ?? currentLang}`, lang === 'lua' ? DEFAULT_CODE_LUA : DEFAULT_CODE_JS),
        pos:      () => GM_getValue('bide_pos',  { x: 40, y: 30 }),
        size:     () => GM_getValue('bide_size', { w: 880, h: 580 }),
        theme:    () => GM_getValue('bide_theme', 'dark'),
        lang:     () => GM_getValue('bide_lang', 'lua'),
        snippets: () => GM_getValue('bide_snippets', DEFAULT_SNIPPETS),
        save:     (k, v) => GM_setValue(k, v),
    };

    // ─── Default Code ──────────────────────────────────────────────────────────
    const DEFAULT_CODE_JS = `// Browser IDE Pro — Monaco Edition
// Ctrl+Enter or ▶ Run to execute

const greet = (name) => \`Hello, \${name}!\`;
console.log(greet("Browser IDE"));

// console.log(document.title);
// console.log(document.querySelectorAll('a').length + ' links on page');
`;

    const DEFAULT_CODE_LUA = `-- Browser IDE Pro — Lua (Fengari WASM)
-- Ctrl+Enter or ▶ Run to execute

local function greet(name)
    return "Hello, " .. name .. "!"
end

print(greet("ZukaTech"))

local t = { 1, 2, 3, 4, 5 }
for i, v in ipairs(t) do
    print(i, v * v)
end
`;

    // ─── Built-in Snippets ─────────────────────────────────────────────────────
    const LUA_SNIPPETS = [
        { name: 'Hello world',
          code: `print("Hello, world!")` },
        { name: 'For loop',
          code: `for i = 1, 10 do\n    print(i)\nend` },
        { name: 'Table map',
          code: `local t = {1, 2, 3, 4, 5}\nfor i, v in ipairs(t) do\n    print(i, v * 2)\nend` },
        { name: 'String format',
          code: `local name = "world"\nprint(string.format("Hello, %s! Pi is %.4f", name, math.pi))` },
        { name: 'Closure counter',
          code: `local function counter(start)\n    local n = start or 0\n    return function()\n        n = n + 1\n        return n\n    end\nend\nlocal c = counter(10)\nprint(c(), c(), c())` },
        { name: 'Metatable / OOP',
          code: `local Vec = {}\nVec.__index = Vec\nfunction Vec.new(x, y)\n    return setmetatable({x = x, y = y}, Vec)\nend\nfunction Vec:len()\n    return math.sqrt(self.x^2 + self.y^2)\nend\nlocal v = Vec.new(3, 4)\nprint(v:len())` },
        { name: 'pcall error handling',
          code: `local ok, err = pcall(function()\n    error("something went wrong")\nend)\nprint(ok, err)` },
        { name: 'String split',
          code: `local function split(s, sep)\n    local t = {}\n    for p in s:gmatch("[^" .. sep .. "]+") do\n        t[#t + 1] = p\n    end\n    return t\nend\nfor _, v in ipairs(split("a,b,c,d", ",")) do\n    print(v)\nend` },
        { name: 'Coroutine demo',
          code: `local co = coroutine.create(function()\n    for i = 1, 5 do\n        print("yield", i)\n        coroutine.yield(i)\n    end\nend)\nfor i = 1, 5 do\n    local ok, v = coroutine.resume(co)\n    print("resumed", ok, v)\nend` },
        { name: 'Deep copy table',
          code: `local function deepcopy(orig)\n    local t = type(orig)\n    if t ~= "table" then return orig end\n    local copy = {}\n    for k, v in pairs(orig) do\n        copy[deepcopy(k)] = deepcopy(v)\n    end\n    return setmetatable(copy, getmetatable(orig))\nend\nlocal a = {1, {2, 3}, {x = 4}}\nlocal b = deepcopy(a)\nb[2][1] = 99\nprint(a[2][1], b[2][1]) -- 2, 99` },
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
        @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;700&display=swap');

        #__bide_root {
            position: fixed;
            z-index: 2147483647;
            display: flex;
            flex-direction: column;
            border-radius: 8px;
            overflow: hidden;
            min-width: 420px;
            min-height: 300px;
            font-family: 'JetBrains Mono', 'Cascadia Code', 'Fira Code', monospace;
            font-size: 12px;
            transition: opacity 0.15s ease, transform 0.15s ease;
        }
        #__bide_root.hidden {
            opacity: 0;
            pointer-events: none;
            transform: scale(0.96) translateY(6px);
        }

        /* ── Titlebar ── */
        #__bide_titlebar {
            display: flex;
            align-items: center;
            gap: 7px;
            padding: 0 10px;
            height: 36px;
            cursor: grab;
            user-select: none;
            flex-shrink: 0;
        }
        #__bide_titlebar:active { cursor: grabbing; }
        .bide-dot {
            width: 12px; height: 12px;
            border-radius: 50%;
            cursor: pointer;
            flex-shrink: 0;
            transition: filter 0.1s, transform 0.08s;
            position: relative;
        }
        .bide-dot:hover { filter: brightness(1.25); transform: scale(1.12); }
        .bide-dot::after {
            content: attr(data-tip);
            position: absolute;
            top: 18px; left: 50%;
            transform: translateX(-50%);
            background: rgba(0,0,0,0.85);
            color: #e0e0e0;
            font-size: 10px;
            padding: 2px 6px;
            border-radius: 3px;
            white-space: nowrap;
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.12s;
        }
        .bide-dot:hover::after { opacity: 1; }
        #__bide_ide_title {
            flex: 1;
            text-align: center;
            font-size: 10px;
            font-weight: 700;
            letter-spacing: 0.18em;
            text-transform: uppercase;
        }
        #__bide_hdr_btns { display: flex; gap: 2px; align-items: center; }
        .bide-hdr-btn, #__bide_sidebar_toggle {
            background: none;
            border: none;
            cursor: pointer;
            font-size: 12px;
            padding: 3px 6px;
            border-radius: 4px;
            font-family: inherit;
            transition: opacity 0.1s, background 0.1s;
            line-height: 1;
        }

        /* ── Tab bar ── */
        #__bide_tabs {
            display: flex;
            align-items: stretch;
            flex-shrink: 0;
            border-bottom: 1px solid;
        }
        .bide-tab {
            padding: 6px 14px;
            font-size: 10px;
            font-weight: 700;
            cursor: pointer;
            letter-spacing: 0.1em;
            text-transform: uppercase;
            border: none;
            background: none;
            font-family: inherit;
            border-bottom: 2px solid transparent;
            margin-bottom: -1px;
            transition: color 0.1s, border-color 0.1s;
            display: flex;
            align-items: center;
            gap: 5px;
        }
        .bide-tab-badge {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-width: 16px;
            height: 14px;
            padding: 0 4px;
            border-radius: 7px;
            font-size: 9px;
            font-weight: 700;
            line-height: 1;
            display: none;
        }
        .bide-tab-badge.visible { display: inline-flex; }

        /* ── Body ── */
        #__bide_body { flex: 1; display: flex; overflow: hidden; position: relative; }

        /* ── Sidebar ── */
        #__bide_sidebar {
            width: 180px;
            flex-shrink: 0;
            display: flex;
            flex-direction: column;
            border-right: 1px solid;
            overflow: hidden;
            transition: width 0.18s ease;
        }
        #__bide_sidebar.collapsed { width: 0; }
        #__bide_sidebar_hdr {
            padding: 8px 10px 5px;
            font-size: 9px;
            font-weight: 700;
            letter-spacing: 0.14em;
            text-transform: uppercase;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-shrink: 0;
        }
        #__bide_add_snippet {
            background: none; border: none;
            font-size: 15px; cursor: pointer;
            padding: 0 2px; font-family: inherit;
            transition: opacity 0.1s; line-height: 1;
        }
        #__bide_snippets_list {
            flex: 1; overflow-y: auto;
            padding: 2px 0; scrollbar-width: thin;
        }
        #__bide_snippets_list::-webkit-scrollbar { width: 3px; }
        .bide-snippet {
            padding: 6px 10px; font-size: 11px;
            cursor: pointer; display: flex;
            align-items: center; justify-content: space-between;
            gap: 4px; transition: background 0.08s;
        }
        .bide-snippet span { flex: 1; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .bide-snippet-del {
            opacity: 0; font-size: 11px;
            background: none; border: none;
            cursor: pointer; padding: 0 2px;
            font-family: inherit; transition: opacity 0.1s; flex-shrink: 0;
        }
        .bide-snippet:hover .bide-snippet-del { opacity: 0.45; }
        .bide-snippet-del:hover { opacity: 1 !important; }

        /* ── Editor / Output pane ── */
        #__bide_editor_pane { flex: 1; display: flex; flex-direction: column; overflow: hidden; position: relative; }
        #__bide_monaco_container { flex: 1; overflow: hidden; }
        #__bide_output_pane {
            flex: 1; overflow-y: auto;
            padding: 10px 14px; font-size: 12px;
            line-height: 1.65; display: none; scrollbar-width: thin;
        }
        #__bide_output_pane.active { display: block; }
        #__bide_output_pane::-webkit-scrollbar { width: 3px; }
        .bide-out-line  { white-space: pre-wrap; word-break: break-all; margin: 1px 0; }
        .bide-out-warn  { color: #e5c07b; }
        .bide-out-error { color: #e06c75; }
        .bide-out-info  { color: #56b6c2; }
        .bide-out-result{ color: #98c379; font-style: italic; }
        .bide-out-sep   { border: none; border-top: 1px solid; opacity: 0.1; margin: 5px 0; }
        .bide-out-ts    { font-size: 9px; opacity: 0.28; margin-bottom: 3px; }

        /* ═══════════════ CONSOLE PANE ═══════════════ */
        #__bide_console_pane {
            flex: 1;
            display: none;
            flex-direction: column;
            overflow: hidden;
        }
        #__bide_console_pane.active { display: flex; }

        /* Console toolbar */
        #__bide_con_toolbar {
            display: flex;
            align-items: center;
            gap: 6px;
            padding: 5px 8px;
            flex-shrink: 0;
            border-bottom: 1px solid;
        }
        #__bide_con_filter_wrap {
            flex: 1;
            display: flex;
            align-items: center;
            gap: 0;
            border-radius: 4px;
            overflow: hidden;
            border: 1px solid;
        }
        .bide-con-filter {
            background: none;
            border: none;
            padding: 3px 9px;
            font-size: 9px;
            font-weight: 700;
            letter-spacing: 0.08em;
            cursor: pointer;
            font-family: inherit;
            transition: background 0.1s, color 0.1s;
        }
        #__bide_con_search {
            flex: 1;
            background: none;
            border: none;
            border-left: 1px solid;
            padding: 3px 8px;
            font-size: 11px;
            font-family: inherit;
            outline: none;
            min-width: 0;
        }
        #__bide_con_clear_btn {
            background: none;
            border: 1px solid;
            border-radius: 4px;
            padding: 3px 9px;
            font-size: 9px;
            font-weight: 700;
            cursor: pointer;
            font-family: inherit;
            letter-spacing: 0.06em;
            opacity: 0.6;
            transition: opacity 0.1s;
            flex-shrink: 0;
        }
        #__bide_con_clear_btn:hover { opacity: 1; }

        /* Console log list */
        #__bide_con_list {
            flex: 1;
            overflow-y: auto;
            scrollbar-width: thin;
            padding: 0;
        }
        #__bide_con_list::-webkit-scrollbar { width: 3px; }

        .bide-con-entry {
            display: flex;
            align-items: flex-start;
            gap: 0;
            border-bottom: 1px solid transparent;
            transition: background 0.06s;
            font-size: 11px;
            line-height: 1.5;
        }
        .bide-con-entry:hover { filter: brightness(1.12); }
        .bide-con-entry.hidden { display: none; }

        .bide-con-level-badge {
            flex-shrink: 0;
            width: 4px;
            align-self: stretch;
        }
        .bide-con-meta {
            flex-shrink: 0;
            padding: 4px 6px 4px 6px;
            font-size: 9px;
            opacity: 0.35;
            white-space: nowrap;
            font-weight: 500;
            min-width: 52px;
            text-align: right;
        }
        .bide-con-body {
            flex: 1;
            padding: 4px 8px 4px 0;
            min-width: 0;
            word-break: break-all;
            white-space: pre-wrap;
        }
        .bide-con-entry[data-level="warn"]   .bide-con-level-badge { background: #e5c07b; }
        .bide-con-entry[data-level="error"]  .bide-con-level-badge { background: #e06c75; }
        .bide-con-entry[data-level="info"]   .bide-con-level-badge { background: #56b6c2; }
        .bide-con-entry[data-level="debug"]  .bide-con-level-badge { background: #636d83; }
        .bide-con-entry[data-level="uncaught"] .bide-con-level-badge { background: #ff5f5f; }
        .bide-con-entry[data-level="assert"] .bide-con-level-badge { background: #ff5f5f; }
        .bide-con-entry[data-level="trace"]  .bide-con-level-badge { background: #7c72e8; }
        .bide-con-entry[data-level="group"]  .bide-con-level-badge { background: #4f8ef7; }
        .bide-con-entry[data-level="clear"]  .bide-con-level-badge { background: #2a2f3d; }

        /* Expandable object trees */
        .bide-con-obj {
            display: inline-block;
            cursor: pointer;
            border-radius: 2px;
            padding: 0 2px;
        }
        .bide-con-obj::before { content: '▶ '; font-size: 9px; opacity: 0.5; }
        .bide-con-obj.open::before { content: '▼ '; }
        .bide-con-tree {
            display: none;
            margin-left: 16px;
            border-left: 1px solid;
            padding-left: 8px;
        }
        .bide-con-obj.open + .bide-con-tree { display: block; }
        .bide-con-tree-row { display: flex; gap: 4px; padding: 1px 0; font-size: 10px; }
        .bide-con-tree-key   { opacity: 0.55; flex-shrink: 0; }
        .bide-con-tree-colon { opacity: 0.3; flex-shrink: 0; }
        .bide-con-tree-val   { color: inherit; }

        /* Table rendering */
        .bide-con-table-wrap { overflow-x: auto; margin: 4px 0; max-width: 100%; }
        .bide-con-table {
            border-collapse: collapse;
            font-size: 10px;
            white-space: nowrap;
        }
        .bide-con-table th,
        .bide-con-table td {
            border: 1px solid;
            padding: 2px 8px;
            text-align: left;
        }
        .bide-con-table th { font-weight: 700; opacity: 0.7; }

        /* Group indentation */
        .bide-con-body[data-depth="1"] { padding-left: 16px; }
        .bide-con-body[data-depth="2"] { padding-left: 28px; }
        .bide-con-body[data-depth="3"] { padding-left: 40px; }

        /* Console REPL input */
        #__bide_con_repl_wrap {
            display: flex;
            align-items: center;
            gap: 0;
            border-top: 1px solid;
            flex-shrink: 0;
        }
        #__bide_con_repl_prompt {
            padding: 0 8px;
            font-size: 11px;
            opacity: 0.35;
            flex-shrink: 0;
            user-select: none;
        }
        #__bide_con_repl {
            flex: 1;
            background: none;
            border: none;
            padding: 6px 0;
            font-size: 12px;
            font-family: 'JetBrains Mono', monospace;
            outline: none;
        }

        /* ── Statusbar ── */
        #__bide_statusbar {
            display: flex; align-items: center; gap: 8px;
            padding: 3px 10px; height: 26px; font-size: 10px;
            flex-shrink: 0; border-top: 1px solid;
        }
        #__bide_status_msg { flex: 1; }
        #__bide_cursor_pos { font-size: 9px; }
        .bide-run-btn {
            border: none; border-radius: 4px;
            padding: 3px 12px; font-size: 10px; font-weight: 700;
            cursor: pointer; font-family: inherit; letter-spacing: 0.06em;
            transition: filter 0.08s, transform 0.06s;
        }
        .bide-run-btn:hover  { filter: brightness(1.15); }
        .bide-run-btn:active { transform: scale(0.95); }
        .bide-clear-btn {
            background: none; border: 1px solid; border-radius: 4px;
            padding: 2px 9px; font-size: 10px; cursor: pointer;
            font-family: inherit; transition: opacity 0.1s;
        }
        .bide-clear-btn:hover { opacity: 0.9 !important; }
        #__bide_lang_picker {
            background: none; border: 1px solid; border-radius: 4px;
            padding: 2px 6px; font-size: 10px; font-weight: 700;
            font-family: inherit; cursor: pointer; letter-spacing: 0.05em;
        }

        /* ── Resize ── */
        #__bide_resize {
            position: absolute; bottom: 0; right: 0;
            width: 16px; height: 16px; cursor: se-resize; z-index: 10;
            display: flex; align-items: flex-end; justify-content: flex-end;
            padding: 2px; opacity: 0.2; font-size: 9px;
        }
        #__bide_resize:hover { opacity: 0.5; }

        /* ── Restore button ── */
        #__bide_restore_btn {
            position: fixed; bottom: 20px; right: 20px;
            z-index: 2147483646; border-radius: 6px; padding: 8px 16px;
            font-family: 'JetBrains Mono', monospace;
            font-size: 11px; font-weight: 700; cursor: pointer;
            letter-spacing: 0.08em; box-shadow: 0 4px 20px rgba(0,0,0,0.45);
            transition: filter 0.1s, transform 0.08s; display: none; border: 1px solid;
        }
        #__bide_restore_btn:hover  { filter: brightness(1.15); transform: translateY(-1px); }
        #__bide_restore_btn:active { transform: scale(0.97); }

        /* ── Add snippet modal ── */
        #__bide_modal_bg {
            position: fixed; inset: 0; z-index: 2147483647;
            background: rgba(0,0,0,0.55);
            display: flex; align-items: center; justify-content: center;
            opacity: 0; pointer-events: none; transition: opacity 0.15s;
        }
        #__bide_modal_bg.open { opacity: 1; pointer-events: all; }
        #__bide_modal {
            border-radius: 8px; padding: 20px; width: 360px;
            display: flex; flex-direction: column; gap: 10px;
            box-shadow: 0 16px 48px rgba(0,0,0,0.5);
        }
        #__bide_modal h3 { margin: 0; font-size: 11px; font-weight: 700; letter-spacing: 0.12em; text-transform: uppercase; }
        #__bide_modal input, #__bide_modal textarea {
            width: 100%; border-radius: 5px; padding: 7px 9px;
            font-size: 12px; font-family: 'JetBrains Mono', monospace;
            border: 1px solid; box-sizing: border-box; outline: none; resize: vertical;
        }
        #__bide_modal textarea { min-height: 110px; }
        #__bide_modal_btns { display: flex; gap: 8px; justify-content: flex-end; margin-top: 2px; }
        .bide-modal-save   { border: none; border-radius: 5px; padding: 6px 16px; cursor: pointer; font-weight: 700; font-family: inherit; font-size: 11px; }
        .bide-modal-cancel { background: none; border: 1px solid; border-radius: 5px; padding: 5px 12px; cursor: pointer; font-family: inherit; font-size: 11px; }
        .bide-modal-cancel:hover { opacity: 1 !important; }

        /* ═══════════════════ DARK THEME ═══════════════════ */
        .bide-dark#__bide_root {
            background: #111318;
            color: #c8cdd8;
            box-shadow: 0 20px 60px rgba(0,0,0,0.75), 0 0 0 1px rgba(255,255,255,0.05);
        }
        .bide-dark #__bide_titlebar      { background: #0d0f14; }
        .bide-dark #__bide_ide_title     { color: #3d4455; }
        .bide-dark .bide-hdr-btn, .bide-dark #__bide_sidebar_toggle { color: #6b7280; }
        .bide-dark .bide-hdr-btn:hover, .bide-dark #__bide_sidebar_toggle:hover { background: #1e2330; color: #c8cdd8; opacity: 1; }
        .bide-dark #__bide_tabs          { background: #0d0f14; border-color: #1e2330; }
        .bide-dark .bide-tab             { color: #3d4455; }
        .bide-dark .bide-tab:hover       { color: #8892a4; }
        .bide-dark .bide-tab.active      { color: #c8cdd8; border-bottom-color: #4f8ef7; }
        .bide-dark .bide-tab-badge       { background: #e06c75; color: #0d0f14; }
        .bide-dark .bide-tab-badge.warn  { background: #e5c07b; color: #0d0f14; }
        .bide-dark #__bide_sidebar       { background: #0d0f14; border-color: #1e2330; }
        .bide-dark #__bide_sidebar_hdr   { color: #3d4455; }
        .bide-dark #__bide_add_snippet   { color: #4f8ef7; opacity: 0.6; }
        .bide-dark #__bide_add_snippet:hover { opacity: 1; }
        .bide-dark .bide-snippet         { color: #8892a4; }
        .bide-dark .bide-snippet:hover   { background: #1a1e2a; color: #c8cdd8; }
        .bide-dark .bide-snippet-del     { color: #e06c75; }
        .bide-dark #__bide_snippets_list::-webkit-scrollbar-thumb { background: #1e2330; }
        .bide-dark #__bide_output_pane   { background: #0d0f14; color: #c8cdd8; }
        .bide-dark .bide-out-log         { color: #c8cdd8; }
        .bide-dark .bide-out-sep         { border-color: #1e2330; }
        .bide-dark #__bide_output_pane::-webkit-scrollbar-thumb { background: #1e2330; }
        /* Console dark */
        .bide-dark #__bide_console_pane  { background: #0d0f14; }
        .bide-dark #__bide_con_toolbar   { background: #0d0f14; border-color: #1e2330; }
        .bide-dark #__bide_con_filter_wrap { border-color: #1e2330; }
        .bide-dark .bide-con-filter      { color: #6b7280; }
        .bide-dark .bide-con-filter:hover{ background: #1e2330; color: #c8cdd8; }
        .bide-dark .bide-con-filter.active { background: #1e2a45; color: #4f8ef7; }
        .bide-dark #__bide_con_search    { color: #c8cdd8; border-color: #1e2330; }
        .bide-dark #__bide_con_search::placeholder { color: #3d4455; }
        .bide-dark #__bide_con_clear_btn { border-color: #1e2330; color: #6b7280; }
        .bide-dark #__bide_con_list      { }
        .bide-dark #__bide_con_list::-webkit-scrollbar-thumb { background: #1e2330; }
        .bide-dark .bide-con-entry       { border-color: #141820; }
        .bide-dark .bide-con-entry[data-level="warn"]    { background: rgba(229,192,123,0.06); color: #e5c07b; }
        .bide-dark .bide-con-entry[data-level="error"]   { background: rgba(224,108,117,0.07); color: #e06c75; }
        .bide-dark .bide-con-entry[data-level="info"]    { background: rgba(86,182,194,0.06);  color: #56b6c2; }
        .bide-dark .bide-con-entry[data-level="debug"]   { color: #636d83; }
        .bide-dark .bide-con-entry[data-level="uncaught"]{ background: rgba(255,95,95,0.09); color: #ff8080; }
        .bide-dark .bide-con-entry[data-level="assert"]  { background: rgba(255,95,95,0.09); color: #ff8080; }
        .bide-dark .bide-con-entry[data-level="trace"]   { color: #9d94e8; }
        .bide-dark .bide-con-entry[data-level="clear"]   { color: #3d4455; font-style: italic; }
        .bide-dark .bide-con-obj         { color: #7aa2f7; }
        .bide-dark .bide-con-tree        { border-color: #1e2330; }
        .bide-dark .bide-con-tree-key    { color: #e06c75; }
        .bide-dark .bide-con-table th,
        .bide-dark .bide-con-table td    { border-color: #1e2330; }
        .bide-dark .bide-con-table th    { background: #1a1e2a; }
        .bide-dark #__bide_con_repl_wrap { border-color: #1e2330; }
        .bide-dark #__bide_con_repl_prompt { color: #4f8ef7; }
        .bide-dark #__bide_con_repl      { color: #c8cdd8; }
        .bide-dark #__bide_con_repl::placeholder { color: #3d4455; }
        .bide-dark #__bide_statusbar     { background: #0d0f14; border-color: #1e2330; color: #3d4455; }
        .bide-dark #__bide_status_msg.running { color: #e5c07b; }
        .bide-dark #__bide_status_msg.done    { color: #98c379; }
        .bide-dark #__bide_status_msg.error   { color: #e06c75; }
        .bide-dark .bide-run-btn         { background: #4f8ef7; color: #0d0f14; }
        .bide-dark .bide-clear-btn       { border-color: #1e2330; color: #3d4455; opacity: 0.7; }
        .bide-dark #__bide_lang_picker   { border-color: #1e2330; color: #6b7280; background: #0d0f14; }
        .bide-dark #__bide_cursor_pos    { color: #3d4455; }
        .bide-dark #__bide_resize        { color: #3d4455; }
        .bide-dark #__bide_restore_btn   { background: #111318; color: #4f8ef7; border-color: #1e2330; }
        .bide-dark #__bide_modal         { background: #181c25; color: #c8cdd8; }
        .bide-dark #__bide_modal h3      { color: #6b7280; }
        .bide-dark #__bide_modal input,
        .bide-dark #__bide_modal textarea { background: #0d0f14; color: #c8cdd8; border-color: #1e2330; }
        .bide-dark .bide-modal-save      { background: #4f8ef7; color: #0d0f14; }
        .bide-dark .bide-modal-cancel    { color: #6b7280; border-color: #1e2330; opacity: 0.8; }

        /* ═══════════════════ LIGHT THEME ══════════════════ */
        .bide-light#__bide_root {
            background: #f5f5f7;
            color: #2c2e36;
            box-shadow: 0 20px 60px rgba(0,0,0,0.18), 0 0 0 1px rgba(0,0,0,0.07);
        }
        .bide-light #__bide_titlebar      { background: #e8e9ed; }
        .bide-light #__bide_ide_title     { color: #9ea5b5; }
        .bide-light .bide-hdr-btn, .bide-light #__bide_sidebar_toggle { color: #9ea5b5; }
        .bide-light .bide-hdr-btn:hover, .bide-light #__bide_sidebar_toggle:hover { background: #dcdde3; color: #2c2e36; opacity: 1; }
        .bide-light #__bide_tabs          { background: #e8e9ed; border-color: #d4d5dc; }
        .bide-light .bide-tab             { color: #b0b4c0; }
        .bide-light .bide-tab:hover       { color: #6b7280; }
        .bide-light .bide-tab.active      { color: #2c2e36; border-bottom-color: #2563eb; }
        .bide-light .bide-tab-badge       { background: #dc2626; color: #fff; }
        .bide-light .bide-tab-badge.warn  { background: #d97706; color: #fff; }
        .bide-light #__bide_sidebar       { background: #e8e9ed; border-color: #d4d5dc; }
        .bide-light #__bide_sidebar_hdr   { color: #b0b4c0; }
        .bide-light #__bide_add_snippet   { color: #2563eb; opacity: 0.6; }
        .bide-light #__bide_add_snippet:hover { opacity: 1; }
        .bide-light .bide-snippet         { color: #6b7280; }
        .bide-light .bide-snippet:hover   { background: #dcdde3; color: #2c2e36; }
        .bide-light .bide-snippet-del     { color: #dc2626; }
        .bide-light #__bide_snippets_list::-webkit-scrollbar-thumb { background: #d4d5dc; }
        .bide-light #__bide_output_pane   { background: #ecedf1; color: #2c2e36; }
        .bide-light .bide-out-log         { color: #2c2e36; }
        .bide-light .bide-out-warn        { color: #92400e; }
        .bide-light .bide-out-error       { color: #dc2626; }
        .bide-light .bide-out-result      { color: #0369a1; }
        .bide-light .bide-out-sep         { border-color: #d4d5dc; }
        .bide-light #__bide_output_pane::-webkit-scrollbar-thumb { background: #d4d5dc; }
        /* Console light */
        .bide-light #__bide_console_pane  { background: #ecedf1; }
        .bide-light #__bide_con_toolbar   { background: #e8e9ed; border-color: #d4d5dc; }
        .bide-light #__bide_con_filter_wrap { border-color: #d4d5dc; }
        .bide-light .bide-con-filter      { color: #9ea5b5; }
        .bide-light .bide-con-filter:hover{ background: #dcdde3; color: #2c2e36; }
        .bide-light .bide-con-filter.active { background: #c7d7f9; color: #2563eb; }
        .bide-light #__bide_con_search    { color: #2c2e36; border-color: #d4d5dc; }
        .bide-light #__bide_con_search::placeholder { color: #b0b4c0; }
        .bide-light #__bide_con_clear_btn { border-color: #d4d5dc; color: #9ea5b5; }
        .bide-light #__bide_con_list::-webkit-scrollbar-thumb { background: #d4d5dc; }
        .bide-light .bide-con-entry       { border-color: #e0e1e6; }
        .bide-light .bide-con-entry[data-level="warn"]    { background: rgba(217,119,6,0.07);  color: #92400e; }
        .bide-light .bide-con-entry[data-level="error"]   { background: rgba(220,38,38,0.06);  color: #dc2626; }
        .bide-light .bide-con-entry[data-level="info"]    { background: rgba(3,105,161,0.06);  color: #0369a1; }
        .bide-light .bide-con-entry[data-level="debug"]   { color: #9ea5b5; }
        .bide-light .bide-con-entry[data-level="uncaught"]{ background: rgba(220,38,38,0.08); color: #dc2626; }
        .bide-light .bide-con-entry[data-level="assert"]  { background: rgba(220,38,38,0.08); color: #dc2626; }
        .bide-light .bide-con-entry[data-level="trace"]   { color: #6d5fd4; }
        .bide-light .bide-con-entry[data-level="clear"]   { color: #b0b4c0; font-style: italic; }
        .bide-light .bide-con-obj         { color: #2563eb; }
        .bide-light .bide-con-tree        { border-color: #d4d5dc; }
        .bide-light .bide-con-tree-key    { color: #dc2626; }
        .bide-light .bide-con-table th,
        .bide-light .bide-con-table td    { border-color: #d4d5dc; }
        .bide-light .bide-con-table th    { background: #dcdde3; }
        .bide-light #__bide_con_repl_wrap { border-color: #d4d5dc; }
        .bide-light #__bide_con_repl_prompt { color: #2563eb; }
        .bide-light #__bide_con_repl      { color: #2c2e36; }
        .bide-light #__bide_con_repl::placeholder { color: #b0b4c0; }
        .bide-light #__bide_statusbar     { background: #e8e9ed; border-color: #d4d5dc; color: #9ea5b5; }
        .bide-light #__bide_status_msg.running { color: #92400e; }
        .bide-light #__bide_status_msg.done    { color: #166534; }
        .bide-light #__bide_status_msg.error   { color: #dc2626; }
        .bide-light .bide-run-btn         { background: #2563eb; color: #fff; }
        .bide-light .bide-clear-btn       { border-color: #d4d5dc; color: #9ea5b5; opacity: 0.8; }
        .bide-light #__bide_lang_picker   { border-color: #d4d5dc; color: #6b7280; background: #e8e9ed; }
        .bide-light #__bide_cursor_pos    { color: #b0b4c0; }
        .bide-light #__bide_resize        { color: #b0b4c0; }
        .bide-light #__bide_restore_btn   { background: #f5f5f7; color: #2563eb; border-color: #d4d5dc; }
        .bide-light #__bide_modal         { background: #f5f5f7; color: #2c2e36; }
        .bide-light #__bide_modal h3      { color: #9ea5b5; }
        .bide-light #__bide_modal input,
        .bide-light #__bide_modal textarea { background: #fff; color: #2c2e36; border-color: #d4d5dc; }
        .bide-light .bide-modal-save      { background: #2563eb; color: #fff; }
        .bide-light .bide-modal-cancel    { color: #6b7280; border-color: #d4d5dc; opacity: 0.8; }
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
      <span id="__bide_ide_title">BROWSER IDE</span>
      <div id="__bide_hdr_btns">
        <button id="__bide_sidebar_toggle" title="Toggle sidebar">≡</button>
        <button class="bide-hdr-btn" id="bide_theme_btn" title="Toggle theme">◑</button>
      </div>
    </div>
    <div id="__bide_tabs">
      <button class="bide-tab active" data-tab="editor">Editor</button>
      <button class="bide-tab"        data-tab="output">Output</button>
      <button class="bide-tab"        data-tab="console">
        Console
        <span class="bide-tab-badge" id="__bide_con_badge"></span>
      </button>
    </div>
    <div id="__bide_body">
      <div id="__bide_sidebar">
        <div id="__bide_sidebar_hdr">
          <span>Snippets</span>
          <button id="__bide_add_snippet" title="Save current code as snippet">+</button>
        </div>
        <div id="__bide_snippets_list"></div>
      </div>
      <div id="__bide_editor_pane">
        <div id="__bide_monaco_container"></div>
        <div id="__bide_output_pane"></div>
        <div id="__bide_console_pane">
          <div id="__bide_con_toolbar">
            <div id="__bide_con_filter_wrap">
              <button class="bide-con-filter active" data-filter="all">All</button>
              <button class="bide-con-filter"        data-filter="log">Log</button>
              <button class="bide-con-filter"        data-filter="warn">Warn</button>
              <button class="bide-con-filter"        data-filter="error">Error</button>
              <button class="bide-con-filter"        data-filter="info">Info</button>
              <input id="__bide_con_search" type="text" placeholder="Filter…" />
            </div>
            <button id="__bide_con_clear_btn">CLEAR</button>
          </div>
          <div id="__bide_con_list"></div>
          <div id="__bide_con_repl_wrap">
            <span id="__bide_con_repl_prompt">&gt;</span>
            <input id="__bide_con_repl" type="text" placeholder="Evaluate JS on the page…" autocomplete="off" />
          </div>
        </div>
      </div>
    </div>
    <div id="__bide_statusbar">
      <button class="bide-run-btn"   id="bide_run_btn">▶ Run</button>
      <button class="bide-clear-btn" id="bide_clear_btn">Clear</button>
      <select id="__bide_lang_picker">
        <option value="lua">Lua 5.3</option>
        <option value="javascript">JavaScript</option>
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
      <h3>Save Snippet</h3>
      <input id="bide_snip_name" placeholder="Snippet name…" />
      <textarea id="bide_snip_code" placeholder="-- code here…"></textarea>
      <div id="__bide_modal_btns">
        <button class="bide-modal-cancel" id="bide_modal_cancel">Cancel</button>
        <button class="bide-modal-save"   id="bide_modal_save">Save</button>
      </div>
    </div>`;

    const restoreBtn = document.createElement('button');
    restoreBtn.id = '__bide_restore_btn';
    restoreBtn.textContent = '{ IDE }';

    document.body.appendChild(root);
    document.body.appendChild(modalBg);
    document.body.appendChild(restoreBtn);

    // ─── State vars ────────────────────────────────────────────────────────────
    let theme       = S.theme();
    let currentLang = S.lang();
    let activeTab   = 'editor';

    const tabBtns         = root.querySelectorAll('.bide-tab');
    const monacoContainer = root.querySelector('#__bide_monaco_container');
    const outputPane      = root.querySelector('#__bide_output_pane');
    const consolePane     = root.querySelector('#__bide_console_pane');
    const langPicker      = document.getElementById('__bide_lang_picker');
    const sidebar         = document.getElementById('__bide_sidebar');
    const conBadge        = document.getElementById('__bide_con_badge');
    const conList         = document.getElementById('__bide_con_list');

    // ─── Theme ─────────────────────────────────────────────────────────────────
    function applyTheme() {
        root.classList.toggle('bide-dark',  theme === 'dark');
        root.classList.toggle('bide-light', theme === 'light');
        if (window.__bide_monaco) {
            window.monaco.editor.setTheme(theme === 'dark' ? 'bide-dark' : 'bide-light');
        }
    }

    document.getElementById('bide_theme_btn').addEventListener('click', () => {
        theme = theme === 'dark' ? 'light' : 'dark';
        S.save('bide_theme', theme);
        applyTheme();
    });

    // ─── Sidebar toggle ────────────────────────────────────────────────────────
    let sidebarOpen = true;
    document.getElementById('__bide_sidebar_toggle').addEventListener('click', () => {
        sidebarOpen = !sidebarOpen;
        sidebar.classList.toggle('collapsed', !sidebarOpen);
        setTimeout(() => { if (window.__bide_monaco) window.__bide_monaco.layout(); }, 200);
    });

    // ─── Tabs ──────────────────────────────────────────────────────────────────
    function switchTab(name) {
        activeTab = name;
        tabBtns.forEach(t => t.classList.toggle('active', t.dataset.tab === name));
        monacoContainer.style.display = name === 'editor' ? 'block' : 'none';
        outputPane.classList.toggle('active',  name === 'output');
        consolePane.classList.toggle('active', name === 'console');
        if (name === 'editor' && window.__bide_monaco) window.__bide_monaco.layout();
        if (name === 'console') {
            // Clear unread badge when tab is opened
            conBadge.classList.remove('visible', 'warn');
            conBadge.textContent = '';
            _conUnread = 0;
        }
    }
    tabBtns.forEach(t => t.addEventListener('click', () => switchTab(t.dataset.tab)));

    // ─── Status ────────────────────────────────────────────────────────────────
    const statusEl = document.getElementById('__bide_status_msg');
    let statusTimer = null;

    function setStatus(msg, duration = 2500, cls = '') {
        statusEl.textContent = msg;
        statusEl.className   = cls;
        clearTimeout(statusTimer);
        if (duration > 0) {
            statusTimer = setTimeout(() => {
                statusEl.textContent = 'ready';
                statusEl.className   = '';
            }, duration);
        }
    }

    // ─── Output helpers ────────────────────────────────────────────────────────
    function appendOutput(text, cls) {
        const line = document.createElement('div');
        line.className = `bide-out-line ${cls}`;
        line.textContent = text;
        outputPane.appendChild(line);
        outputPane.scrollTop = outputPane.scrollHeight;
    }

    function appendSep() {
        const hr = document.createElement('hr');
        hr.className = 'bide-out-sep';
        const ts = document.createElement('div');
        ts.className = 'bide-out-ts';
        ts.textContent = new Date().toLocaleTimeString();
        outputPane.appendChild(hr);
        outputPane.appendChild(ts);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CONSOLE RENDERER
    // ═══════════════════════════════════════════════════════════════════════════

    let _conFilter  = 'all';
    let _conSearch  = '';
    let _conUnread  = 0;
    let _replHistory = [];
    let _replHistIdx = -1;

    // Value serializer — produces a text token or an expandable element
    function serializeValue(v, depth = 0) {
        if (v === null)      return { type: 'text', text: 'null',      color: '#636d83' };
        if (v === undefined) return { type: 'text', text: 'undefined', color: '#636d83' };
        if (typeof v === 'boolean') return { type: 'text', text: String(v), color: '#ff9e64' };
        if (typeof v === 'number')  return { type: 'text', text: String(v), color: '#ff9e64' };
        if (typeof v === 'string')  return { type: 'text', text: v, color: null };
        if (v instanceof Error)     return { type: 'text', text: v.stack || `${v.name}: ${v.message}`, color: null };
        if (typeof v === 'object') {
            if (depth >= 2) {
                const tag = Array.isArray(v) ? `Array(${v.length})` : '[Object]';
                return { type: 'text', text: tag, color: '#636d83' };
            }
            return { type: 'object', value: v, preview: previewObj(v) };
        }
        return { type: 'text', text: String(v), color: null };
    }

    function previewObj(v) {
        if (Array.isArray(v)) {
            const items = v.slice(0, 5).map(i => {
                const s = serializeValue(i, 1);
                return s.type === 'text' ? s.text : s.preview;
            });
            return `[${items.join(', ')}${v.length > 5 ? ', …' : ''}]`;
        }
        const keys = Object.keys(v).slice(0, 4);
        const parts = keys.map(k => {
            const s = serializeValue(v[k], 1);
            return `${k}: ${s.type === 'text' ? s.text : s.preview}`;
        });
        return `{${parts.join(', ')}${Object.keys(v).length > 4 ? ', …' : ''}}`;
    }

    function buildObjectTree(v, container) {
        if (Array.isArray(v)) {
            v.forEach((item, i) => buildTreeRow(String(i), item, container));
            const row = document.createElement('div');
            row.className = 'bide-con-tree-row';
            row.innerHTML = `<span class="bide-con-tree-key">length</span><span class="bide-con-tree-colon">:</span><span class="bide-con-tree-val">${v.length}</span>`;
            container.appendChild(row);
        } else {
            Object.keys(v).forEach(k => buildTreeRow(k, v[k], container));
        }
    }

    function buildTreeRow(key, val, container) {
        const s = serializeValue(val, 1);
        const row = document.createElement('div');
        row.className = 'bide-con-tree-row';
        if (s.type === 'object') {
            row.innerHTML = `<span class="bide-con-tree-key">${key}</span><span class="bide-con-tree-colon">:</span>`;
            const objSpan = document.createElement('span');
            objSpan.className = 'bide-con-obj';
            objSpan.textContent = s.preview;
            const subTree = document.createElement('div');
            subTree.className = 'bide-con-tree';
            objSpan.addEventListener('click', (e) => {
                e.stopPropagation();
                if (!subTree.children.length) buildObjectTree(val, subTree);
                objSpan.classList.toggle('open');
            });
            row.appendChild(objSpan);
            row.appendChild(subTree);
        } else {
            const valSpan = document.createElement('span');
            valSpan.className = 'bide-con-tree-val';
            valSpan.textContent = s.text;
            if (s.color) valSpan.style.color = s.color;
            row.innerHTML = `<span class="bide-con-tree-key">${key}</span><span class="bide-con-tree-colon">:</span>`;
            row.appendChild(valSpan);
        }
        container.appendChild(row);
    }

    function buildArgNode(v) {
        const s = serializeValue(v);
        if (s.type === 'text') {
            const span = document.createElement('span');
            span.textContent = s.text + ' ';
            if (s.color) span.style.color = s.color;
            return span;
        }
        // Object: expandable
        const wrapper = document.createElement('span');
        const objSpan = document.createElement('span');
        objSpan.className = 'bide-con-obj';
        objSpan.textContent = s.preview + ' ';
        const tree = document.createElement('div');
        tree.className = 'bide-con-tree';
        objSpan.addEventListener('click', () => {
            if (!tree.children.length) buildObjectTree(s.value, tree);
            objSpan.classList.toggle('open');
        });
        wrapper.appendChild(objSpan);
        wrapper.appendChild(tree);
        return wrapper;
    }

    function buildTableEntry(data) {
        const wrap = document.createElement('div');
        wrap.className = 'bide-con-table-wrap';
        const table = document.createElement('table');
        table.className = 'bide-con-table';

        const rows = Array.isArray(data) ? data : Object.values(data);
        if (!rows.length) { wrap.textContent = '(empty table)'; return wrap; }

        const cols = new Set(['(index)']);
        rows.forEach((r, i) => {
            if (r && typeof r === 'object') Object.keys(r).forEach(k => cols.add(k));
        });
        const colArr = [...cols];

        const thead = document.createElement('thead');
        const hr = document.createElement('tr');
        colArr.forEach(c => {
            const th = document.createElement('th');
            th.textContent = c;
            hr.appendChild(th);
        });
        thead.appendChild(hr);
        table.appendChild(thead);

        const tbody = document.createElement('tbody');
        rows.forEach((row, i) => {
            const tr = document.createElement('tr');
            colArr.forEach(col => {
                const td = document.createElement('td');
                if (col === '(index)') {
                    td.textContent = Array.isArray(data) ? i : Object.keys(data)[i] ?? i;
                } else {
                    const v = row && typeof row === 'object' ? row[col] : '';
                    td.textContent = v == null ? '' : (typeof v === 'object' ? previewObj(v) : String(v));
                }
                tr.appendChild(td);
            });
            tbody.appendChild(tr);
        });
        table.appendChild(tbody);
        wrap.appendChild(table);
        return wrap;
    }

    function renderConEntry(entry) {
        const { level, args, depth, ts } = entry;

        const row = document.createElement('div');
        row.className = 'bide-con-entry';
        row.dataset.level = level;

        const badge = document.createElement('div');
        badge.className = 'bide-con-level-badge';

        const meta = document.createElement('div');
        meta.className = 'bide-con-meta';
        meta.textContent = new Date(ts).toLocaleTimeString([], { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' });

        const body = document.createElement('div');
        body.className = 'bide-con-body';
        if (depth > 0) body.dataset.depth = String(Math.min(depth, 3));

        if (level === 'clear') {
            body.textContent = '── console.clear() ──';
        } else if (level === 'groupEnd') {
            // invisible spacer, already decremented depth
        } else if (level === 'group' || level === 'groupCollapsed') {
            body.textContent = '▾ ' + args.join(' ');
        } else if (level === 'table' && args[0] != null && typeof args[0] === 'object') {
            body.appendChild(buildTableEntry(args[0]));
        } else {
            args.forEach(a => body.appendChild(buildArgNode(a)));
        }

        row.appendChild(badge);
        row.appendChild(meta);
        row.appendChild(body);

        // Store raw text for filtering
        row.dataset.text = args.map(a => {
            if (a == null) return String(a);
            if (typeof a === 'object') { try { return JSON.stringify(a); } catch { return '[Object]'; } }
            return String(a);
        }).join(' ').toLowerCase();

        applyConFilter(row);
        return row;
    }

    function applyConFilter(row) {
        const level   = row.dataset.level;
        const text    = row.dataset.text || '';
        const matchF  = _conFilter === 'all' || level === _conFilter ||
                        (_conFilter === 'error' && level === 'uncaught') ||
                        (_conFilter === 'error' && level === 'assert');
        const matchS  = !_conSearch || text.includes(_conSearch);
        row.classList.toggle('hidden', !(matchF && matchS));
    }

    function refilterAll() {
        conList.querySelectorAll('.bide-con-entry').forEach(applyConFilter);
    }

    // Badge update
    function updateBadge(level) {
        if (activeTab === 'console') return;
        _conUnread++;
        const isError = level === 'error' || level === 'uncaught' || level === 'assert';
        const isWarn  = level === 'warn';
        conBadge.classList.add('visible');
        if (isError) {
            conBadge.classList.remove('warn');
        } else if (isWarn && !conBadge.classList.contains('visible')) {
            conBadge.classList.add('warn');
        }
        conBadge.textContent = _conUnread > 99 ? '99+' : _conUnread;
    }

    // Flush the pre-DOM queue and hook live rendering
    function flushConQueue() {
        while (_conQueue.length) {
            const entry = _conQueue.shift();
            const row = renderConEntry(entry);
            if (row) {
                conList.appendChild(row);
                conList.scrollTop = conList.scrollHeight;
                updateBadge(entry.level);
            }
        }
    }

    // Register flush callback so real-time entries render immediately
    window.__bide_conFlush = flushConQueue;

    // Drain whatever queued up before the DOM was ready
    flushConQueue();

    // Console filter buttons
    document.querySelectorAll('.bide-con-filter').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.bide-con-filter').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            _conFilter = btn.dataset.filter;
            refilterAll();
        });
    });

    // Console search
    document.getElementById('__bide_con_search').addEventListener('input', (e) => {
        _conSearch = e.target.value.toLowerCase().trim();
        refilterAll();
    });

    // Console clear
    document.getElementById('__bide_con_clear_btn').addEventListener('click', () => {
        conList.innerHTML = '';
        conBadge.classList.remove('visible', 'warn');
        conBadge.textContent = '';
        _conUnread = 0;
    });

    // ─── REPL input ────────────────────────────────────────────────────────────
    const replInput = document.getElementById('__bide_con_repl');

    replInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
            const code = replInput.value.trim();
            if (!code) return;
            _replHistory.unshift(code);
            _replHistIdx = -1;
            replInput.value = '';

            // Echo the input
            const echoEntry = { level: 'log', args: ['> ' + code], depth: 0, ts: Date.now() };
            const echoRow = renderConEntry(echoEntry);
            echoRow.style.opacity = '0.5';
            conList.appendChild(echoRow);

            // Execute in page context (direct eval — full window access, no sandbox)
            let result, errored = false;
            try {
                // eslint-disable-next-line no-eval
                result = (0, eval)(code);
            } catch (err) {
                result = err;
                errored = true;
            }

            if (errored) {
                const entry = { level: 'error', args: [result], depth: 0, ts: Date.now() };
                conList.appendChild(renderConEntry(entry));
            } else if (result !== undefined) {
                const entry = { level: 'log', args: [result], depth: 0, ts: Date.now() };
                conList.appendChild(renderConEntry(entry));
            }

            conList.scrollTop = conList.scrollHeight;
        } else if (e.key === 'ArrowUp') {
            if (_replHistory.length) {
                _replHistIdx = Math.min(_replHistIdx + 1, _replHistory.length - 1);
                replInput.value = _replHistory[_replHistIdx];
                e.preventDefault();
            }
        } else if (e.key === 'ArrowDown') {
            if (_replHistIdx > 0) {
                _replHistIdx--;
                replInput.value = _replHistory[_replHistIdx];
            } else {
                _replHistIdx = -1;
                replInput.value = '';
            }
            e.preventDefault();
        }
    });

    // ─── Snippets ──────────────────────────────────────────────────────────────
    function renderSnippets() {
        const list = document.getElementById('__bide_snippets_list');
        const userSnips = S.snippets();
        const allSnips = currentLang === 'lua'
            ? [...LUA_SNIPPETS, ...userSnips.filter(s => s._lang === 'lua')]
            : [...userSnips.filter(s => s._lang !== 'lua')];
        list.innerHTML = '';
        allSnips.forEach((s) => {
            const item = document.createElement('div');
            item.className = 'bide-snippet';
            item.innerHTML = `<span title="${s.name}">${s.name}</span><button class="bide-snippet-del" title="Delete">✕</button>`;
            item.addEventListener('click', (e) => {
                if (e.target.classList.contains('bide-snippet-del')) return;
                if (window.__bide_monaco) {
                    window.__bide_monaco.setValue(s.code);
                    S.save(`bide_code_${currentLang}`, s.code);
                    switchTab('editor');
                    setStatus(`"${s.name}" loaded`);
                }
            });
            const delBtn = item.querySelector('.bide-snippet-del');
            if (LUA_SNIPPETS.find(ls => ls.name === s.name && ls.code === s.code)) {
                delBtn.style.display = 'none';
            } else {
                delBtn.addEventListener('click', () => {
                    const arr = S.snippets();
                    const idx = arr.findIndex(a => a.name === s.name && a.code === s.code);
                    if (idx !== -1) { arr.splice(idx, 1); S.save('bide_snippets', arr); }
                    renderSnippets();
                });
            }
            list.appendChild(item);
        });
    }

    renderSnippets();

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
        arr.push({ name, code, _lang: currentLang });
        S.save('bide_snippets', arr);
        renderSnippets();
        modalBg.classList.remove('open');
        setStatus(`"${name}" saved`, 2000);
    });

    // ─── Language switcher ─────────────────────────────────────────────────────
    langPicker.value = currentLang;

    function switchLang(lang) {
        if (window.__bide_monaco) {
            S.save(`bide_code_${currentLang}`, window.__bide_monaco.getValue());
        }
        currentLang = lang;
        S.save('bide_lang', lang);
        if (window.__bide_monaco) {
            const model = window.__bide_monaco.getModel();
            if (model) window.monaco.editor.setModelLanguage(model, lang === 'lua' ? 'lua' : 'javascript');
            window.__bide_monaco.setValue(S.code(lang));
        }
        renderSnippets();
        setStatus(`${lang === 'lua' ? 'Lua 5.3' : 'JavaScript'}`);
    }

    langPicker.addEventListener('change', () => switchLang(langPicker.value));

    // ─── Fengari loader ────────────────────────────────────────────────────────
    let fengariLoaded  = false;
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
                            if (window.fengari && window.fengari.lua) { fengariLoaded = true; resolve(); }
                            else reject(new Error('fengari loaded but window.fengari.lua not found'));
                        }, 60);
                    };
                    s.onerror = () => reject(new Error('fengari blob inject failed'));
                    document.head.appendChild(s);
                },
                onerror: () => reject(new Error('GM_xmlhttpRequest failed for fengari')),
            });
        });
        return fengariLoading;
    }

    // ─── Lua runner ────────────────────────────────────────────────────────────
    async function runLua(code) {
        setStatus('loading Fengari…', 0, 'running');
        try { await loadFengari(); }
        catch (e) {
            appendOutput('⚠ Could not load Fengari: ' + e.message, 'bide-out-error');
            setStatus('fengari failed', 3000, 'error');
            return;
        }
        setStatus('running…', 0, 'running');
        const t0 = performance.now();
        try {
            const { lua, lauxlib, lualib, to_luastring, to_jsstring } = fengari;
            const L = lauxlib.luaL_newstate();
            lualib.luaL_openlibs(L);
            const captured = [];
            function luaL_tolstring(LS, idx) {
                lua.lua_getglobal(LS, to_luastring('tostring'));
                lua.lua_pushvalue(LS, idx);
                lua.lua_call(LS, 1, 1);
            }
            lua.lua_pushcclosure(L, (LS) => {
                const nargs = lua.lua_gettop(LS);
                const parts = [];
                for (let i = 1; i <= nargs; i++) {
                    luaL_tolstring(LS, i);
                    parts.push(to_jsstring(lua.lua_tostring(LS, -1)));
                    lua.lua_pop(LS, 1);
                }
                captured.push(parts.join('\t'));
                return 0;
            }, 0);
            lua.lua_setglobal(L, to_luastring('print'));
            const status = lauxlib.luaL_loadstring(L, to_luastring(code));
            if (status !== lua.LUA_OK) {
                appendOutput('⚠ ' + to_jsstring(lua.lua_tostring(L, -1)), 'bide-out-error');
                setStatus('error', 3000, 'error');
                return;
            }
            const callStatus = lua.lua_pcall(L, 0, lua.LUA_MULTRET, 0);
            if (callStatus !== lua.LUA_OK) {
                appendOutput('⚠ ' + to_jsstring(lua.lua_tostring(L, -1)), 'bide-out-error');
                setStatus('error', 3000, 'error');
                return;
            }
            if (captured.length === 0) appendOutput('(no output)', 'bide-out-info');
            else captured.forEach(line => appendOutput(line, 'bide-out-log'));
        } catch (err) {
            appendOutput('⚠ ' + err.message, 'bide-out-error');
            setStatus('error', 3000, 'error');
            return;
        }
        const ms = (performance.now() - t0).toFixed(1);
        setStatus(`done in ${ms}ms`, 3000, 'done');
    }

    // ─── JS runner ─────────────────────────────────────────────────────────────
    async function runJS(code) {
        setStatus('running…', 0, 'running');
        const t0 = performance.now();
        await new Promise((resolve) => {
            const runnerSrc = `
(async () => {
    const _send = (type, args) => parent.postMessage({ __bide: true, type, args }, '*');
    const _ser  = (v) => {
        if (v === null || v === undefined) return String(v);
        if (v instanceof Error) return v.name + ': ' + v.message;
        if (typeof v === 'object') { try { return JSON.stringify(v, null, 2); } catch { return String(v); } }
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
            const blob    = new Blob([runnerSrc], { type: 'text/javascript' });
            const blobUrl = URL.createObjectURL(blob);
            const frame   = document.createElement('iframe');
            frame.style.cssText = 'display:none;width:0;height:0;border:none;';
            frame.sandbox = 'allow-scripts';
            document.body.appendChild(frame);
            const listener = (e) => {
                if (!e.data || !e.data.__bide) return;
                const { type, args } = e.data;
                if (type === 'result') {
                    window.removeEventListener('message', listener);
                    frame.remove();
                    URL.revokeObjectURL(blobUrl);
                    if (!args[1]) appendOutput('→ ' + args[0], 'bide-out-result');
                    const ms = (performance.now() - t0).toFixed(1);
                    setStatus(`done in ${ms}ms`, 3000, 'done');
                    resolve();
                } else {
                    const cls = { log:'bide-out-log', warn:'bide-out-warn', error:'bide-out-error', info:'bide-out-info' }[type] || 'bide-out-log';
                    appendOutput(args.join(' '), cls);
                }
            };
            window.addEventListener('message', listener);
            frame.srcdoc = `<script src="${blobUrl}"><\/script>`;
        });
    }

    // ─── Run dispatch ──────────────────────────────────────────────────────────
    async function runCode() {
        const code = window.__bide_monaco ? window.__bide_monaco.getValue() : '';
        appendSep();
        switchTab('output');
        if (currentLang === 'lua') await runLua(code);
        else await runJS(code);
    }

    document.getElementById('bide_run_btn').addEventListener('click', runCode);
    document.getElementById('bide_clear_btn').addEventListener('click', () => {
        if (activeTab === 'output') { outputPane.innerHTML = ''; }
        else if (activeTab === 'console') {
            conList.innerHTML = '';
            conBadge.classList.remove('visible', 'warn');
            conBadge.textContent = '';
            _conUnread = 0;
        }
        setStatus('cleared', 1200);
    });

    // ─── Monaco loader ─────────────────────────────────────────────────────────
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
                            require.config({ paths: { vs: 'https://cdn.jsdelivr.net/npm/monaco-editor@0.47.0/min/vs' } });
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

    // ─── Monaco init ───────────────────────────────────────────────────────────
    async function initMonaco() {
        setStatus('loading Monaco…', 0);
        try {
            const monaco = await loadMonaco();

            monaco.editor.defineTheme('bide-dark', {
                base: 'vs-dark', inherit: true,
                rules: [
                    { token: 'comment',    foreground: '3d4455', fontStyle: 'italic' },
                    { token: 'keyword',    foreground: '7aa2f7' },
                    { token: 'string',     foreground: '9ece6a' },
                    { token: 'number',     foreground: 'ff9e64' },
                    { token: 'identifier', foreground: 'c8cdd8' },
                    { token: 'type',       foreground: 'e0af68' },
                    { token: 'delimiter',  foreground: '636d83' },
                ],
                colors: {
                    'editor.background':                '#111318',
                    'editor.foreground':                '#c8cdd8',
                    'editorLineNumber.foreground':      '#2a2f3d',
                    'editorLineNumber.activeForeground':'#636d83',
                    'editor.lineHighlightBackground':   '#181c25',
                    'editorCursor.foreground':          '#4f8ef7',
                    'editor.selectionBackground':       '#1e2a45',
                    'editorWidget.background':          '#181c25',
                    'editorSuggestWidget.background':   '#181c25',
                    'editorSuggestWidget.border':       '#1e2330',
                    'editorSuggestWidget.selectedBackground': '#1e2a45',
                    'editorIndentGuide.background':     '#1e2330',
                },
            });

            monaco.editor.defineTheme('bide-light', {
                base: 'vs', inherit: true,
                rules: [
                    { token: 'comment',    foreground: 'a8afc0', fontStyle: 'italic' },
                    { token: 'keyword',    foreground: '2563eb' },
                    { token: 'string',     foreground: '166534' },
                    { token: 'number',     foreground: 'c2410c' },
                    { token: 'identifier', foreground: '2c2e36' },
                    { token: 'type',       foreground: '0369a1' },
                ],
                colors: {
                    'editor.background':              '#f5f5f7',
                    'editor.foreground':              '#2c2e36',
                    'editorLineNumber.foreground':    '#c8cad2',
                    'editor.lineHighlightBackground': '#ecedf1',
                    'editor.selectionBackground':     '#c7d7f9',
                    'editorWidget.background':        '#ecedf1',
                },
            });

            const ed = monaco.editor.create(monacoContainer, {
                value:           S.code(),
                language:        currentLang === 'lua' ? 'lua' : 'javascript',
                theme:           theme === 'dark' ? 'bide-dark' : 'bide-light',
                fontSize:        13,
                fontFamily:      "'JetBrains Mono', 'Cascadia Code', 'Fira Code', monospace",
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
                padding:         { top: 10, bottom: 10 },
                tabSize:         4,
                insertSpaces:    true,
                renderLineHighlight: 'line',
                suggest: { showKeywords: true, showSnippets: true },
            });

            window.__bide_monaco = ed;

            ed.onDidChangeModelContent(() => {
                S.save(`bide_code_${currentLang}`, ed.getValue());
                setStatus('saved', 1000);
            });
            ed.onDidChangeCursorPosition((e) => {
                document.getElementById('__bide_cursor_pos').textContent =
                    `Ln ${e.position.lineNumber}, Col ${e.position.column}`;
            });
            ed.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.Enter, runCode);

            monaco.languages.typescript.javascriptDefaults.setCompilerOptions({
                allowNonTsExtensions: true, noLib: false,
            });

            setStatus('ready', 0);
            langPicker.value = currentLang;
            const ro = new ResizeObserver(() => ed.layout());
            ro.observe(monacoContainer);

        } catch (err) {
            console.error('[BIDE] Monaco failed:', err);
            setStatus('Monaco failed — check network', 0, 'error');
            monacoContainer.innerHTML = `<textarea id="__bide_fallback_ta" style="width:100%;height:100%;border:none;outline:none;resize:none;padding:12px;font-family:'JetBrains Mono',monospace;font-size:13px;background:transparent;tab-size:4;"></textarea>`;
            const ta = document.getElementById('__bide_fallback_ta');
            ta.value = S.code();
            ta.addEventListener('input', () => S.save(`bide_code_${currentLang}`, ta.value));
            ta.addEventListener('keydown', (e) => {
                if (e.key === 'Tab') {
                    e.preventDefault();
                    const s = ta.selectionStart;
                    ta.value = ta.value.substring(0, s) + '    ' + ta.value.substring(ta.selectionEnd);
                    ta.selectionStart = ta.selectionEnd = s + 4;
                }
                if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) runCode();
            });
            window.__bide_monaco = { getValue: () => ta.value, setValue: (v) => { ta.value = v; }, layout: () => {}, getModel: () => null };
        }
    }

    // ─── Drag ──────────────────────────────────────────────────────────────────
    const titlebar = document.getElementById('__bide_titlebar');
    let dragging = false, dox = 0, doy = 0;

    titlebar.addEventListener('mousedown', (e) => {
        const el = e.target;
        if (el.classList.contains('bide-dot') || el.classList.contains('bide-hdr-btn') ||
            el.id === '__bide_sidebar_toggle') return;
        dragging = true;
        dox = e.clientX - root.offsetLeft;
        doy = e.clientY - root.offsetTop;
        e.preventDefault();
    });
    document.addEventListener('mousemove', (e) => {
        if (!dragging) return;
        root.style.left = Math.max(0, Math.min(window.innerWidth  - root.offsetWidth,  e.clientX - dox)) + 'px';
        root.style.top  = Math.max(0, Math.min(window.innerHeight - root.offsetHeight, e.clientY - doy)) + 'px';
    });
    document.addEventListener('mouseup', () => {
        if (!dragging) return;
        dragging = false;
        S.save('bide_pos', { x: parseInt(root.style.left), y: parseInt(root.style.top) });
    });

    // ─── Resize ────────────────────────────────────────────────────────────────
    const resizeHandle = document.getElementById('__bide_resize');
    let resizing = false, rox = 0, roy = 0, rw0 = 0, rh0 = 0;

    resizeHandle.addEventListener('mousedown', (e) => {
        resizing = true; rox = e.clientX; roy = e.clientY;
        rw0 = root.offsetWidth; rh0 = root.offsetHeight;
        e.preventDefault(); e.stopPropagation();
    });
    document.addEventListener('mousemove', (e) => {
        if (!resizing) return;
        root.style.width  = Math.max(420, rw0 + (e.clientX - rox)) + 'px';
        root.style.height = Math.max(300, rh0 + (e.clientY - roy)) + 'px';
    });
    document.addEventListener('mouseup', () => {
        if (!resizing) return;
        resizing = false;
        S.save('bide_size', { w: root.offsetWidth, h: root.offsetHeight });
        if (window.__bide_monaco) window.__bide_monaco.layout();
    });

    // ─── Window controls ───────────────────────────────────────────────────────
    document.getElementById('bide_close').addEventListener('click', () => { root.classList.add('hidden'); restoreBtn.style.display = 'block'; });
    document.getElementById('bide_min').addEventListener('click',   () => { root.classList.add('hidden'); restoreBtn.style.display = 'block'; });

    let maximized = false, prevRect = {};
    document.getElementById('bide_max').addEventListener('click', () => {
        if (!maximized) {
            prevRect = { left: root.style.left, top: root.style.top, width: root.style.width, height: root.style.height };
            Object.assign(root.style, { left:'0', top:'0', width:'100vw', height:'100vh', borderRadius:'0' });
        } else {
            Object.assign(root.style, { left: prevRect.left, top: prevRect.top, width: prevRect.width, height: prevRect.height, borderRadius: '8px' });
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

    } // end initIDE

})();
