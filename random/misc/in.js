// ==UserScript==
// @name         Instagram Media Expander
// @namespace    http://tampermonkey.net/
// @version      5.1
// @description  Expand Instagram videos and images — Feed, Reels, Stories, Explore
// @author       Me
// @match        https://www.instagram.com/*
// @grant        GM_addStyle
// @grant        GM_download
// ==/UserScript==

(function () {
    'use strict';

    // ─── Styles ──────────────────────────────────────────────────────────────

    GM_addStyle(`
        .ige-btn {
            position: absolute;
            bottom: 8px;
            right: 8px;
            z-index: 9000;
            display: flex;
            gap: 4px;
            pointer-events: none;
        }
        .ige-btn button {
            pointer-events: all;
            background: rgba(0,0,0,0.65);
            color: #fff;
            border: none;
            border-radius: 6px;
            padding: 5px 8px;
            font-size: 16px;
            cursor: pointer;
            line-height: 1;
            backdrop-filter: blur(4px);
            transition: background 0.15s;
        }
        .ige-btn button:hover { background: rgba(0,0,0,0.9); }

        .ige-overlay {
            position: fixed;
            inset: 0;
            background: rgba(0,0,0,0.93);
            z-index: 99999;
            display: flex;
            align-items: center;
            justify-content: center;
            animation: igeFadeIn 0.15s ease;
        }
        @keyframes igeFadeIn { from { opacity: 0 } to { opacity: 1 } }

        .ige-overlay-media {
            max-width: 100vw;
            max-height: 100vh;
            object-fit: contain;
        }

        .ige-controls {
            position: fixed;
            top: 12px;
            right: 14px;
            z-index: 100000;
            display: flex;
            gap: 8px;
        }
        .ige-controls button {
            background: rgba(255,255,255,0.12);
            color: #fff;
            border: none;
            border-radius: 8px;
            padding: 7px 12px;
            font-size: 18px;
            cursor: pointer;
            backdrop-filter: blur(6px);
            transition: background 0.15s;
            line-height: 1;
        }
        .ige-controls button:hover { background: rgba(255,255,255,0.28); }

        .ige-toast {
            position: fixed;
            bottom: 24px;
            left: 50%;
            transform: translateX(-50%);
            z-index: 100001;
            background: rgba(255,255,255,0.15);
            color: #fff;
            padding: 8px 18px;
            border-radius: 20px;
            font-size: 13px;
            backdrop-filter: blur(8px);
            animation: igeToastIn 0.2s ease;
            pointer-events: none;
        }
        @keyframes igeToastIn {
            from { opacity:0; transform:translateX(-50%) translateY(8px) }
            to   { opacity:1; transform:translateX(-50%) translateY(0) }
        }
    `);

    // ─── State ───────────────────────────────────────────────────────────────

    const processed = new WeakSet();
    let activeOverlay = null;

    // ─── Utilities ───────────────────────────────────────────────────────────

    function debounce(fn, ms) {
        let t;
        return (...args) => { clearTimeout(t); t = setTimeout(() => fn(...args), ms); };
    }

    function toast(msg, duration = 2500) {
        const el = document.createElement('div');
        el.className = 'ige-toast';
        el.textContent = msg;
        document.body.appendChild(el);
        setTimeout(() => el.remove(), duration);
    }

    // Walk up DOM to find the nearest positioned ancestor we can attach to
    function findPositionedAncestor(el) {
        let node = el.parentElement;
        while (node && node !== document.body) {
            const pos = getComputedStyle(node).position;
            if (pos !== 'static') return node;
            node = node.parentElement;
        }
        return el.parentElement; // fallback — force position below
    }

    // ─── Src resolution ──────────────────────────────────────────────────────

    function resolveImgSrc(img) {
        if (img.srcset) {
            const best = img.srcset.split(',')
                .map(s => s.trim().split(/\s+/))
                .filter(p => p.length >= 2)
                .map(([url, w]) => ({ url, w: parseFloat(w) }))
                .sort((a, b) => b.w - a.w)[0];
            if (best) return best.url;
        }
        return img.src || img.dataset.src || img.dataset.lazySrc || '';
    }

    function resolveVideoSrc(video) {
        if (video.src && !video.src.startsWith('blob:')) return video.src;
        // blob: is fine too — use it
        if (video.src) return video.src;
        const source = video.querySelector('source[src]');
        if (source) return source.src;
        return '';
    }

    // ─── Download ────────────────────────────────────────────────────────────

    function downloadMedia(src, isVideo) {
        const ext  = isVideo ? 'mp4' : 'jpg';
        const name = `instagram_${Date.now()}.${ext}`;
        try {
            GM_download({ url: src, name, onerror: () => toast('⚠ Download failed — right-click to save') });
            toast('⬇ Downloading…');
        } catch {
            toast('⚠ Download failed — right-click to save');
        }
    }

    // ─── Overlay ─────────────────────────────────────────────────────────────

    function openOverlay(el) {
        if (!el.isConnected) {
            const live = document.querySelector('video');
            if (live) el = live;
            else { toast('⚠ Media no longer in DOM'); return; }
        }

        if (activeOverlay) closeOverlay();

        const isVideo = el.tagName === 'VIDEO';
        const src     = isVideo ? resolveVideoSrc(el) : resolveImgSrc(el);
        if (!isVideo && !src) { toast('⚠ Could not resolve media URL'); return; }

        const overlay = document.createElement('div');
        overlay.className = 'ige-overlay';

        let media;
        if (isVideo) {
            // ── Reuse the original video element — blob: URLs can't be cloned ──
            media = el;

            // Save restore info
            const originalParent      = el.parentElement;
            const originalNextSibling = el.nextSibling;
            const originalStyle       = el.getAttribute('style') || '';
            const originalControls    = el.controls;

            overlay._restore = () => {
                el.controls = originalControls;
                el.setAttribute('style', originalStyle);
                if (originalNextSibling) originalParent.insertBefore(el, originalNextSibling);
                else originalParent.appendChild(el);
            };

            el.controls = true;
            el.style.cssText = 'width:100vw !important; height:100vh !important; max-width:100vw !important; max-height:100vh !important; object-fit:contain !important;';

            // Arrow key seeking
            function onArrow(e) {
                if (!activeOverlay) return;
                if (e.key === 'ArrowRight') el.currentTime = Math.min(el.duration || Infinity, el.currentTime + 5);
                if (e.key === 'ArrowLeft')  el.currentTime = Math.max(0, el.currentTime - 5);
            }
            document.addEventListener('keydown', onArrow);
            overlay._arrowHandler = onArrow;
        } else {
            media = document.createElement('img');
            media.src = src;
            media.className = 'ige-overlay-media';
            media.draggable = false;
        }

        // Controls
        const controls = document.createElement('div');
        controls.className = 'ige-controls';

        const dlBtn = document.createElement('button');
        dlBtn.title = 'Download';
        dlBtn.textContent = '⬇';
        dlBtn.onclick = () => downloadMedia(src || resolveVideoSrc(el), isVideo);

        const closeBtn = document.createElement('button');
        closeBtn.title = 'Close (Esc)';
        closeBtn.textContent = '✕';
        closeBtn.onclick = closeOverlay;

        controls.appendChild(dlBtn);
        controls.appendChild(closeBtn);
        overlay.appendChild(media);
        overlay.appendChild(controls);
        document.body.appendChild(overlay);
        activeOverlay = overlay;

        overlay.addEventListener('click', e => { if (e.target === overlay) closeOverlay(); });
        document.addEventListener('keydown', onEsc);
    }
    function closeOverlay() {
        if (!activeOverlay) return;
        if (activeOverlay._arrowHandler) document.removeEventListener('keydown', activeOverlay._arrowHandler);
        if (activeOverlay._restore) activeOverlay._restore();
        activeOverlay.remove();
        activeOverlay = null;
        document.removeEventListener('keydown', onEsc);
    }
    // ─── Button injection ────────────────────────────────────────────────────

    function addButtons(el) {
        if (processed.has(el)) return;
        processed.add(el);

        const anchor = findPositionedAncestor(el);
        if (!anchor) return;

        // Force positioning if needed so the absolute button shows up
        if (getComputedStyle(anchor).position === 'static') {
            anchor.style.position = 'relative';
        }

        const bar = document.createElement('div');
        bar.className = 'ige-btn';

        const expandBtn = document.createElement('button');
        expandBtn.textContent = '⛶';
        expandBtn.title = 'Expand';
        expandBtn.onclick = e => {
            e.stopPropagation();
            e.preventDefault();
            openOverlay(el);
        };

        bar.appendChild(expandBtn);
        anchor.appendChild(bar);
    }

    // ─── Scanning ────────────────────────────────────────────────────────────

    function scanMedia() {
        // ── Videos: no size gate, covers Reels, Stories, Feed ──
        document.querySelectorAll('video').forEach(v => {
            if (!processed.has(v)) addButtons(v);
        });

        // ── Images: skip avatars / icons ──
        document.querySelectorAll('img').forEach(img => {
            if (processed.has(img)) return;
            // Use rendered size as fallback when naturalWidth isn't loaded yet
            const w = img.naturalWidth  || img.offsetWidth  || 0;
            const h = img.naturalHeight || img.offsetHeight || 0;
            if (w > 180 && h > 180) addButtons(img);
        });
    }

    // ─── Observer ────────────────────────────────────────────────────────────

    const debouncedScan = debounce(scanMedia, 150);

    const observer = new MutationObserver(mutations => {
        // Quick check: did any new nodes land that might be media containers?
        const relevant = mutations.some(m =>
            [...m.addedNodes].some(n =>
                n.nodeType === 1 && (
                    n.tagName === 'VIDEO' ||
                    n.tagName === 'IMG'   ||
                    n.querySelector?.('video, img')
                )
            )
        );
        if (relevant) debouncedScan();
    });

    observer.observe(document.body, { childList: true, subtree: true });

    // Staggered initial scans — Reels SPA content can take a while
    setTimeout(scanMedia, 800);
    setTimeout(scanMedia, 2000);
    setTimeout(scanMedia, 4000);

})();
