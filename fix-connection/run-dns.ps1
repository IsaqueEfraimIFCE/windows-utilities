$path = "C:\Users\Isaque\Desktop\fix-connection\Set-DNS.ps1"
$errs = $null; [void][System.Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$errs)
if ($errs.Count) { "PARSE ERRORS:"; $errs | ForEach-Object { $_.Message }; exit 1 } else { "syntax OK" }

$out = "C:\Users\Isaque\Desktop\fix-connection\dns-apply-log.txt"
if (Test-Path $out) { Remove-Item $out -Force }

try {
    $p = Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$path`"") -Verb RunAs -Wait -PassThru -ErrorAction Stop
    "elevated exit: $($p.ExitCode)"
} catch {
    "LAUNCH FAILED: $($_.Exception.Message)"
}

"--- dns-apply-log.txt ---"
if (Test-Path $out) { Get-Content $out } else { "no log" }
