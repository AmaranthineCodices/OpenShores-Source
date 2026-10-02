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

function getVersion(string $flag)
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
            echo "Version info failed to load!";
        }
    }

if (($_GET['version'] ?? null) === '1') {
    getVersion('-v');
    exit;
}
?>
<section><?php serverStatus('Login Servers', '-l'); ?></section>
<hr>
<section><?php serverStatus('Mail Servers', '-m'); ?></section>
<hr>
<section><?php serverStatus('Scene Servers', '-g'); ?></section>
