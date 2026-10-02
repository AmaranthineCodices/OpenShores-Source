<?php
header('Content-Type: text/html; charset=UTF-8');
header('Cache-Control: no-store');
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="/styles.css">
    <script src="/server-status.js" defer></script>
    <title>OpenShores</title>
</head>
<body>
    <main>
        <h1>OpenShores</h1>
        <div class="home-panels">
            <section>
                <h2>Server status</h2>
                <div id="statusdiv" class="live-panel" aria-busy="true">
                    <button type="button" id="refresh-status" class="refresh-button" aria-controls="status-content" aria-label="Refresh status" title="Refresh status" disabled>
                        <img src="/images/refresh.png" alt="" width="24" height="24">
                    </button>
                    <div id="status-content" aria-live="polite">Loading server status...</div>
                </div>
                <div id="status-message" role="status"></div>
                <noscript><p>JavaScript is required to refresh status here. <a href="/server-status.php">View server status</a>.</p></noscript>
                <div id="links">
                    <a href="/standings">Empire standings</a><br>
                    <a href="/avatars">Avatars</a><br>
                    <a href="/register">Register account</a><br>
                    <a href="/reset">Reset password</a><br>
                    <a href="/emailchange">Change E-mail address</a><br>
                    <a href="/passchange">Change password</a><br>
                </div>
            </section>
            <section>
                <h2>Galactic chat</h2>
                <div id="chatdiv" class="live-panel" aria-busy="true">
                    <button type="button" id="refresh-chat" class="refresh-button" aria-controls="chat-content" aria-label="Refresh galactic chat" title="Refresh galactic chat" disabled>
                        <img src="/images/refresh.png" alt="" width="24" height="24">
                    </button>
                    <div id="chat-content" role="region" aria-label="Galactic chat messages" aria-live="polite" tabindex="0">Loading galactic chat...</div>
                </div>
                <div id="chat-message" role="status"></div>
                <p>Public messages from approximately the last five minutes.</p>
                <noscript><p><a href="/galactic.php">View galactic chat</a>.</p></noscript>
            </section>
        </div>
        <p id="server-version"></p>
    </main>
</body>
</html>
