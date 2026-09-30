<#
    One-shot setup for a fresh Windows machine.

    Installs AutoHotkey v2, applies the Cmd/Ctrl swap to the registry and
    registers the scheduled task that starts the hotkey script at logon.

    Run it from the repository folder:
        powershell -ExecutionPolicy Bypass -File setup.ps1

    It asks for administrator rights itself (registry + scheduled task need them).
#>

$ErrorActionPreference = 'Stop'

# --- elevate if needed -----------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal] `
            [Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Asking for administrator rights..." -ForegroundColor Cyan
    Start-Process powershell -Verb RunAs -Wait -ArgumentList `
        '-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`""
    exit
}

$root = $PSScriptRoot

# --- 1. AutoHotkey v2 ------------------------------------------------------
$exe = 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
if (Test-Path $exe) {
    Write-Host "[1/3] AutoHotkey v2 already installed." -ForegroundColor Green
} else {
    Write-Host "[1/3] Installing AutoHotkey v2..." -ForegroundColor Cyan
    winget install --id AutoHotkey.AutoHotkey --source winget `
                   --accept-package-agreements --accept-source-agreements | Out-Null
    if (-not (Test-Path $exe)) { throw "AutoHotkey v2 not found at $exe after install." }
}

# --- 2. Cmd/Ctrl swap ------------------------------------------------------
Write-Host "[2/3] Writing the Cmd/Ctrl swap to the registry..." -ForegroundColor Cyan
$map = [byte[]](
    0,0,0,0, 0,0,0,0,
    3,0,0,0,
    0x1d,0x00, 0x5b,0xe0,
    0x5b,0xe0, 0x1d,0x00,
    0,0,0,0
)
$key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
Set-ItemProperty -Path $key -Name 'Scancode Map' -Value $map -Type Binary

# --- 3. scheduled task -----------------------------------------------------
Write-Host "[3/3] Registering the scheduled task..." -ForegroundColor Cyan
$script = Join-Path $root 'mac-klavesnice.ahk'
if (-not (Test-Path $script)) { throw "Script not found: $script" }

$name = 'Mac klavesnice (AHK)'
$user = "$env:USERDOMAIN\$env:USERNAME"
$action  = New-ScheduledTaskAction -Execute $exe -Argument ('"' + $script + '"')
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $user
$princ   = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest
$set     = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
                                        -ExecutionTimeLimit ([TimeSpan]::Zero) -StartWhenAvailable
Register-ScheduledTask -TaskName $name -Action $action -Trigger $trigger `
                       -Principal $princ -Settings $set -Force | Out-Null

Write-Host ""
Write-Host "Done. Two things left:" -ForegroundColor Green
Write-Host "  1. Disable PowerToys Keyboard Manager if you use PowerToys," -ForegroundColor Yellow
Write-Host "     otherwise Cmd/Ctrl get swapped twice." -ForegroundColor Yellow
Write-Host "  2. REBOOT - the Scancode Map only takes effect after a restart." -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to close"
