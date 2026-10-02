'use strict';

(() => {
    async function fetchHtml(url) {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 45000);
        try {
            const response = await fetch(url, { cache: 'no-store', signal: controller.signal });
            if (!response.ok) {
                throw new Error('Request failed');
            }
            const html = await response.text();
            if (!html.trim()) {
                throw new Error('Response was empty');
            }
            return html;
        } finally {
            clearTimeout(timeout);
        }
    }

    function setupPanel(panelId, contentId, buttonId, messageId, url, label, unavailable) {
        const panel = document.getElementById(panelId);
        const content = document.getElementById(contentId);
        const button = document.getElementById(buttonId);
        const message = document.getElementById(messageId);
        let refreshing = false;
        let hasContent = false;

        async function refresh() {
            if (refreshing) {
                return;
            }
            refreshing = true;
            button.disabled = true;
            button.setAttribute('aria-label', 'Refreshing...');
            button.title = 'Refreshing...';
            panel.setAttribute('aria-busy', 'true');
            message.textContent = '';
            try {
                content.innerHTML = await fetchHtml(url);
                hasContent = true;
            } catch (error) {
                if (!hasContent) {
                    content.textContent = unavailable;
                }
                message.textContent = hasContent
                    ? 'Refresh failed. Showing the previous result; please try again.'
                    : 'Refresh failed. Please try again.';
            } finally {
                refreshing = false;
                button.disabled = false;
                button.setAttribute('aria-label', label);
                button.title = label;
                panel.setAttribute('aria-busy', 'false');
            }
        }

        button.addEventListener('click', refresh);
        refresh();
    }

    setupPanel('statusdiv', 'status-content', 'refresh-status', 'status-message',
        '/server-status.php', 'Refresh status', 'Server status could not be loaded.');
    setupPanel('chatdiv', 'chat-content', 'refresh-chat', 'chat-message',
        '/galactic.php', 'Refresh galactic chat', 'Galactic chat could not be loaded.');

    const version = document.getElementById('server-version');
    fetchHtml('/server-status.php?version=1').then(html => {
        version.innerHTML = html;
    }).catch(() => {
        version.textContent = 'Version info failed to load!';
    });
})();
