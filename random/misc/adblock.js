// ==UserScript==
// @name         Payload Neutralizer: Stealth Ad-Killer
// @namespace    Callum.Exploits.Privacy
// @version      1.1
// @description  Intercepts and poisons ad-delivery payloads and anti-adblock detection.
// @author       Callum
// @match        *://*/*
// @run-at       document-start
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    const log = (msg) => console.log(`%c[Neutralizer] %c${msg}`, 'color: #ff0055; font-weight: bold;', 'color: #ffffff;');

    // 1. Poisoning Anti-Adblock Detectors
    // We create the objects they look for so they think we're "compliant"
    const mockObjects = [
        'adsbygoogle', 'ga', 'google_analytics', 'pixel', 'fbq', 'adBlockerDetected'
    ];

    mockObjects.forEach(obj => {
        if (!window[obj]) {
            window[obj] = new Proxy({}, {
                get: (target, prop) => {
                    if (prop === 'push') return () => {}; // Prevent errors on .push()
                    return undefined;
                }
            });
        }
    });

    // 2. Network Proxy: The Heart of the Neutralizer
    // We intercept fetch and XHR to return empty "Success" responses for ads
    const adKeywords = [
        'doubleclick', 'adservice', 'analytics', 'telemetry', 'track',
        'adnxs', 'amazon-adsystem', 'popads', 'propellerads'
    ];

    const isAd = (url) => adKeywords.some(keyword => url.includes(keyword));

    // Intercept Fetch
    const originalFetch = window.fetch;
    window.fetch = async (...args) => {
        const url = args[0]?.url || args[0];
        if (typeof url === 'string' && isAd(url)) {
            log(`Intercepted Fetch Payload: ${url}`);
            return new Response('', { status: 200, statusText: 'OK' });
        }
        return originalFetch(...args);
    };

    // Intercept XMLHttpRequest
    const originalOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function(method, url) {
        if (isAd(url)) {
            log(`Intercepted XHR Payload: ${url}`);
            this.isAdRequest = true;
        }
        return originalOpen.apply(this, arguments);
    };

    const originalSend = XMLHttpRequest.prototype.send;
    XMLHttpRequest.prototype.send = function() {
        if (this.isAdRequest) {
            // Force a fake successful completion
            Object.defineProperty(this, 'readyState', { value: 4 });
            Object.defineProperty(this, 'status', { value: 200 });
            Object.defineProperty(this, 'responseText', { value: '' });
            this.dispatchEvent(new Event('load'));
            return;
        }
        return originalSend.apply(this, arguments);
    };

    // 3. WebSocket Filtering
    // Prevents "live-streaming" ads/telemetry
    const OriginalWebSocket = window.WebSocket;
    window.WebSocket = function(url, protocols) {
        if (isAd(url)) {
            log(`Blocked WebSocket Hijack: ${url}`);
            return {
                send: () => {},
                close: () => {},
                addEventListener: () => {},
                readyState: 3 // Closed
            };
        }
        return new OriginalWebSocket(url, protocols);
    };

    // 4. DOM Sentinel
    // Watches for injected ad-wrappers and nukes them before render
    const sentinel = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
            mutation.addedNodes.forEach((node) => {
                if (node.nodeType === 1) { // Element Node
                    // Check for common ad-wrapper traits
                    const isSuspicious =
                        node.tagName === 'IFRAME' && (isAd(node.src) || !node.src) ||
                        node.id?.toLowerCase().includes('ad-') ||
                        node.className?.toString().toLowerCase().includes('sponsor');

                    if (isSuspicious) {
                        node.style.display = 'none'; // Stealth hide
                        node.remove(); // Nuke
                    }
                }
            });
        });
    });

    sentinel.observe(document.documentElement, {
        childList: true,
        subtree: true
    });

    // 5. Script-Injection Protection
    // Hooks the appendChild method to prevent dynamic script loading from ad domains
    const originalAppend = Element.prototype.appendChild;
    Element.prototype.appendChild = function(element) {
        if (element.tagName === 'SCRIPT' && element.src && isAd(element.src)) {
            log(`Blocked Dynamic Script Injection: ${element.src}`);
            const dummy = document.createElement('script');
            return originalAppend.call(this, dummy);
        }
        return originalAppend.apply(this, arguments);
    };

    log("Payload Neutralizer Online. No more forced noise.");
})();
