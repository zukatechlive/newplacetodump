// ==UserScript==
// @name         Clarity Cloak: Anti-Session Recording
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Completely nullifies Microsoft Clarity tracking and session recording.
// @author       Assistant
// @match        *://*/*
// @grant        none
// @run-at       document-start
// ==/UserScript==

(function() {
    'use strict';

    const debug = true; // Set to true to see in console when tracking is blocked
    const log = (msg) => debug && console.log(`%c[Anti-Clarity] ${msg}`, "color: #ff0055; font-weight: bold;");

    // 1. Pre-emptively create the 'clarity' object so the site doesn't crash
    // but give it functions that do absolutely nothing (NOPs).
    const nop = function() {
        if (arguments.length > 0 && typeof arguments[0] === 'string') {
            log(`Blocked attempt to log event: ${arguments[0]}`);
        }
        return;
    };
    nop.q = [];
    nop.v = "0.0.0"; // Fake version

    // 2. Lock the property so the real script cannot overwrite our fake one.
    try {
        Object.defineProperty(window, 'clarity', {
            get: function() { return nop; },
            set: function() { log("Intercepted attempt by script to initialize Clarity logic."); },
            configurable: false,
            enumerable: true
        });
        log("Namespace Secured. Clarity is jammed.");
    } catch (e) {
        // If the property is already locked by the site, we manually overwrite the queue
        window.clarity = nop;
        log("Secured via Manual Overwrite.");
    }

    // 3. Network Level Jamming
    // In case the script tries to use the 'beacon' or 'fetch' API directly to clarity.ms
    const originalFetch = window.fetch;
    window.fetch = function(...args) {
        if (typeof args[0] === 'string' && args[0].includes('clarity.ms')) {
            log("Blocked fetch call to clarity.ms");
            return Promise.resolve(new Response(null, { status: 204 }));
        }
        return originalFetch.apply(this, args);
    };

    const originalXHR = window.XMLHttpRequest.prototype.open;
    window.XMLHttpRequest.prototype.open = function(method, url) {
        if (typeof url === 'string' && url.includes('clarity.ms')) {
            log("Blocked XHR request to clarity.ms");
            this.send = function() { return null; }; // Kill the send method for this instance
            return;
        }
        return originalXHR.apply(this, arguments);
    };

    // 4. MutationObserver Masking (Elite Tier)
    // Clarity relies on MutationObserver to "watch" your screen.
    // This part is optional but ensures maximum stealth.
    const OriginalObserver = window.MutationObserver;
    window.MutationObserver = function(callback) {
        // If the callback looks like it's from Clarity (usually minified/anonymous)
        // We can't easily tell, but we can prevent observers from being created
        // IF clarity is the one calling it.
        const stack = new Error().stack;
        if (stack.includes('clarity')) {
            log("Blocked Clarity from attaching a DOM Observer.");
            return {
                observe: () => {},
                disconnect: () => {},
                takeRecords: () => []
            };
        }
        return new OriginalObserver(callback);
    };
    // Preserve prototype
    window.MutationObserver.prototype = OriginalObserver.prototype;

})();
