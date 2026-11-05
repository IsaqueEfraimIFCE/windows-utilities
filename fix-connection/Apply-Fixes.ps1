# Connection fixes for DESKTOP-NQ4FCHO - generated 2026-09-13
# Run elevated. Every change is reversible; see Rollback.ps1.
$ErrorActionPreference = 'Continue'
$log = Join-Path $PSScriptRoot 'apply-log.txt'
function Log($m) { $line = "[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $m; Write-Host $line; Add-Content -Path $log -Value $line -Encoding utf8 }

Log "=== Applying connection fixes ==="

# 1. DNS: router resolver stalled 6.9s on google.com. Use public resolvers.
try {
  Set-DnsClientServerAddress -InterfaceAlias 'Wi-Fi' -ServerAddresses ('1.1.1.1','8.8.8.8') -ErrorAction Stop
  Log "OK  DNS -> 1.1.1.1, 8.8.8.8 on Wi-Fi"
} catch { Log "ERR DNS: $($_.Exception.Message)" }

try { Clear-DnsClientCache; Log "OK  DNS cache flushed" } catch { Log "ERR flush: $($_.Exception.Message)" }

# 2. NlaSvc stopped -> network mis-categorized as Public
try {
  Set-Service -Name NlaSvc -StartupType Automatic -ErrorAction Stop
  Start-Service -Name NlaSvc -ErrorAction Stop
  Log "OK  NlaSvc -> Automatic + started"
} catch { Log "ERR NlaSvc: $($_.Exception.Message)" }

# 3. Home Wi-Fi should be Private, not Public
try {
  Set-NetConnectionProfile -InterfaceAlias 'Wi-Fi' -NetworkCategory Private -ErrorAction Stop
  Log "OK  Wi-Fi profile -> Private"
} catch { Log "ERR profile: $($_.Exception.Message)" }

# 4. Dead Tailscale tunnel outranks Wi-Fi (metric 5 vs 50). Demote it.
foreach ($af in @('IPv4','IPv6')) {
  try {
    Set-NetIPInterface -InterfaceAlias 'Tailscale' -AddressFamily $af -InterfaceMetric 9000 -ErrorAction Stop
    Log "OK  Tailscale $af metric -> 9000"
  } catch { Log "ERR Tailscale $af metric: $($_.Exception.Message)" }
}

# 5. Realtek 8821CE power management. Get-NetAdapterPowerManagement errors (Win32 31),
#    so write *PnPCapabilities=24 directly (disables 'turn off to save power').
try {
  $base = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'
  $hit = Get-ChildItem $base -ErrorAction Stop | Where-Object {
    (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DriverDesc -match '8821CE'
  }
  if ($hit) {
    foreach ($k in $hit) {
      Set-ItemProperty -Path $k.PSPath -Name '*PnPCapabilities' -Value 24 -Type DWord -ErrorAction Stop
      Log "OK  *PnPCapabilities=24 set on $($k.PSChildName) (applies after reboot)"
    }
  } else { Log "WARN no 8821CE class key found" }
} catch { Log "ERR PnPCapabilities: $($_.Exception.Message)" }

# 6. Wireless adapter power saving -> Maximum Performance (AC and battery)
$subWifi = '19cbb8fa-5279-450e-9fac-8a3d5fedd0c1'
$setPwr  = '12bbebe6-58d6-4636-95bb-3217ef867c1a'
try {
  powercfg /setacvalueindex SCHEME_CURRENT $subWifi $setPwr 0 2>&1 | Out-Null
  powercfg /setdcvalueindex SCHEME_CURRENT $subWifi $setPwr 0 2>&1 | Out-Null
  powercfg /setactive SCHEME_CURRENT 2>&1 | Out-Null
  Log "OK  Wireless power saving -> Maximum Performance (AC + DC)"
} catch { Log "ERR powercfg: $($_.Exception.Message)" }

# 7. Path MTU to the internet measured at 1480 (gateway accepts 1500, so the
#    narrowing is upstream/ISP). Interface still says 1500 -> PMTUD black-hole,
#    which makes large transfers stall while pings look perfect.
foreach ($af in @('IPv4','IPv6')) {
  try {
    Set-NetIPInterface -InterfaceAlias 'Wi-Fi' -AddressFamily $af -NlMtuBytes 1480 -ErrorAction Stop
    Log "OK  Wi-Fi $af MTU -> 1480"
  } catch { Log "ERR Wi-Fi $af MTU: $($_.Exception.Message)" }
}

Log "=== Done. Review apply-log.txt ==="
