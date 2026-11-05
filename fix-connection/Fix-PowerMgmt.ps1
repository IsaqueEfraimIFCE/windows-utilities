# Disables "allow the computer to turn off this device to save power" for the
# Realtek 8821CE, whose Get-NetAdapterPowerManagement WMI class is broken (Win32 31).
$out = Join-Path $PSScriptRoot 'regfix-log.txt'
$key = 'HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0000'
$psKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0000'

$lines = @()
$lines += "target: $key"

# Attempt 1: reg.exe
$r = & reg.exe add $key /v '*PnPCapabilities' /t REG_DWORD /d 24 /f 2>&1
$lines += "reg.exe exit=$LASTEXITCODE output=$($r -join ' ')"

# Attempt 2: .NET registry API with explicit write access (works when the
# PowerShell provider is blocked by key ACLs)
if ((Get-ItemProperty $psKey -ErrorAction SilentlyContinue).'*PnPCapabilities' -eq $null) {
  try {
    $sub = 'SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0000'
    $hive = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine','Default')
    $k = $hive.OpenSubKey($sub, $true)
    if ($k) { $k.SetValue('*PnPCapabilities', 24, 'DWord'); $k.Close(); $lines += ".NET SetValue: OK" }
    else { $lines += ".NET OpenSubKey returned null" }
  } catch { $lines += ".NET SetValue ERR: $($_.Exception.Message)" }
}

$final = (Get-ItemProperty $psKey -ErrorAction SilentlyContinue).'*PnPCapabilities'
$lines += "final value: " + $(if ($null -ne $final) { $final } else { '<not set>' })
$lines | Set-Content -Path $out -Encoding utf8
