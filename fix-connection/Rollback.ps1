# Reverts everything Apply-Fixes.ps1 changed, back to the BEFORE-snapshot.txt values.
# Run elevated.
$ErrorActionPreference = 'Continue'
function Log($m) { Write-Host ("[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $m) }

Log "=== Rolling back connection fixes ==="

# 1. DNS back to DHCP-supplied (was 192.168.0.1 from the router)
try { Set-DnsClientServerAddress -InterfaceAlias 'Wi-Fi' -ResetServerAddresses -ErrorAction Stop; Log "OK  DNS -> DHCP (192.168.0.1)" }
catch { Log "ERR DNS: $($_.Exception.Message)" }

# 2. NlaSvc back to Manual
try { Set-Service -Name NlaSvc -StartupType Manual -ErrorAction Stop; Log "OK  NlaSvc -> Manual" }
catch { Log "ERR NlaSvc: $($_.Exception.Message)" }

# 3. Wi-Fi profile back to Public
try { Set-NetConnectionProfile -InterfaceAlias 'Wi-Fi' -NetworkCategory Public -ErrorAction Stop; Log "OK  Wi-Fi profile -> Public" }
catch { Log "ERR profile: $($_.Exception.Message)" }

# 4. Tailscale metric back to 5
foreach ($af in @('IPv4','IPv6')) {
  try { Set-NetIPInterface -InterfaceAlias 'Tailscale' -AddressFamily $af -InterfaceMetric 5 -ErrorAction Stop; Log "OK  Tailscale $af metric -> 5" }
  catch { Log "ERR Tailscale ${af}: $($_.Exception.Message)" }
}

# 5. Remove the *PnPCapabilities override (restores Windows default power behaviour)
try {
  $base = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'
  Get-ChildItem $base -ErrorAction Stop | Where-Object {
    (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DriverDesc -match '8821CE'
  } | ForEach-Object {
    Remove-ItemProperty -Path $_.PSPath -Name '*PnPCapabilities' -ErrorAction SilentlyContinue
    Log "OK  *PnPCapabilities removed from $($_.PSChildName)"
  }
} catch { Log "ERR PnPCapabilities: $($_.Exception.Message)" }

# 6. Wireless power saving back to Medium Power Saving (Windows default = 2)
$subWifi = '19cbb8fa-5279-450e-9fac-8a3d5fedd0c1'
$setPwr  = '12bbebe6-58d6-4636-95bb-3217ef867c1a'
powercfg /setacvalueindex SCHEME_CURRENT $subWifi $setPwr 2 2>&1 | Out-Null
powercfg /setdcvalueindex SCHEME_CURRENT $subWifi $setPwr 2 2>&1 | Out-Null
powercfg /setactive SCHEME_CURRENT 2>&1 | Out-Null
Log "OK  Wireless power saving -> Medium (default)"

# 7. MTU back to 1500
foreach ($af in @('IPv4','IPv6')) {
  try { Set-NetIPInterface -InterfaceAlias 'Wi-Fi' -AddressFamily $af -NlMtuBytes 1500 -ErrorAction Stop; Log "OK  Wi-Fi $af MTU -> 1500" }
  catch { Log "ERR Wi-Fi $af MTU: $($_.Exception.Message)" }
}

Log "=== Rollback complete ==="
