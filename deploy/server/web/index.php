<?php
header('Content-Type: text/html; charset=UTF-8');
header('Cache-Control: no-store');
set_time_limit(45);

function serverStatus(string $label, string $flag): void
{
    $program = '/opt/openshores/bin/AuServerStatus';
    $output = [];
    $exitCode = 1;

    if (is_executable($program)) {
        // Only the fixed flags below are accepted; no request data enters this command.
        exec('/usr/bin/timeout --kill-after=1s 12s ' . escapeshellarg($program)
            . ' ' . escapeshellarg($flag), $output, $exitCode);
    }

    if ($exitCode === 0 && count($output) > 0) {
        // AuServerStatus produces the HTML fragment, not HTTP headers.
        echo implode("\n", $output);
    } else {
        echo '<b>' . htmlspecialchars($label, ENT_QUOTES, 'UTF-8') . '</b><br>';
        echo ($exitCode === 124 || $exitCode === 137)
            ? 'Status request timed out.'
            : 'Status unavailable.';
        error_log('AuServerStatus ' . $flag . ' failed with exit code ' . $exitCode);
    }
}
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>OpenShores</title>
</head>
<body>
    <main>
        <h1>OpenShores</h1>
        <h2>Server status</h2>
        <p>Reload this page to check again.</p>
        <section><?php serverStatus('Login Servers', '-l'); ?></section>
        <hr>
        <section><?php serverStatus('Mail Servers', '-m'); ?></section>
        <hr>
        <section><?php serverStatus('Scene Servers', '-g'); ?></section>
    </main>
</body>
</html>
