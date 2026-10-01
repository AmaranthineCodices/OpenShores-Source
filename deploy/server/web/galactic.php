<?php
header('Content-Type: text/html; charset=UTF-8');
header('Cache-Control: no-store');
set_time_limit(20);

$output = [];
$exitCode = 1;
$messages = null;
$program = '/opt/openshores/bin/AuServerStatus';
if (is_executable($program)) {
    exec('/usr/bin/timeout --kill-after=1s 12s ' . escapeshellarg($program)
        . ' -c', $output, $exitCode);
}
if ($exitCode === 0) {
    $decoded = json_decode(implode("\n", $output));
    if (is_array($decoded)) {
        $messages = $decoded;
        foreach ($messages as $message) {
            if (!is_object($message)
                || !isset($message->posted, $message->galaxy, $message->broadcast, $message->sender, $message->text)
                || !is_string($message->posted) || !is_string($message->galaxy)
                || !is_bool($message->broadcast) || !is_string($message->sender) || !is_string($message->text)) {
                $messages = null;
                break;
            }
        }
    }
}
if ($messages === null) {
    http_response_code(503);
    error_log('Galactic chat query failed; AuServerStatus exit code ' . $exitCode);
} else {
    usort($messages, static function ($a, $b) {
        return strcmp($a->posted, $b->posted);
    });
}
function chatText(string $text): string
{
    return htmlspecialchars($text, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="/styles.css">
    <title>Galactic chat - OpenShores</title>
</head>
<body>
    <main>
        <h1>Galactic chat</h1>
        <p>Public messages from approximately the last five minutes. Reload to check again.</p>
        <?php if ($messages === null): ?>
            <p>Galactic chat is unavailable. Please try again shortly.</p>
        <?php elseif (count($messages) === 0): ?>
            <p>No recent chatter.</p>
        <?php else: ?>
            <div id="chatdiv">
                <ol class="chat-messages">
                    <?php foreach ($messages as $message): ?>
                        <li class="chat-message<?= $message->broadcast ? ' chat-broadcast' : '' ?>">
                            <div class="chat-meta">
                                <time datetime="<?= chatText($message->posted) ?>"><?= chatText(str_replace(['T', 'Z'], [' ', ' UTC'], $message->posted)) ?></time>
                                &middot; <?= chatText($message->galaxy) ?>
                            </div>
                            <span id="sender"><?= chatText($message->sender) ?></span>
                            <p class="chat-text"><?= chatText($message->text) ?></p>
                        </li>
                    <?php endforeach; ?>
                </ol>
            </div>
        <?php endif; ?>
        <p><a href="/">Home</a></p>
    </main>
</body>
</html>
