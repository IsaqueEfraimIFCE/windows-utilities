# Sets static public DNS (Cloudflare & Google) on Wi-Fi
$log = Join-Path $PSScriptRoot 'dns-apply-log.txt'
"[{0}] Applying DNS..." -f (Get-Date -Format 'HH:mm:ss') | Out-File $log -Encoding utf8
try {
    Set-DnsClientServerAddress -InterfaceAlias 'Wi-Fi' -ServerAddresses ('1.1.1.1','8.8.8.8') -ErrorAction Stop
    "[{0}] OK DNS set to 1.1.1.1, 8.8.8.8" -f (Get-Date -Format 'HH:mm:ss') | Out-File $log -Append -Encoding utf8
} catch {
    "[{0}] ERR DNS: $($_.Exception.Message)" -f (Get-Date -Format 'HH:mm:ss') | Out-File $log -Append -Encoding utf8
}
try {
    Clear-DnsClientCache
    "[{0}] OK DNS cache cleared" -f (Get-Date -Format 'HH:mm:ss') | Out-File $log -Append -Encoding utf8
} catch {
    "[{0}] ERR flush: $($_.Exception.Message)" -f (Get-Date -Format 'HH:mm:ss') | Out-File $log -Append -Encoding utf8
}
