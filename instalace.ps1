<#
    Registers a scheduled task that runs mac-klavesnice.ahk at logon
    with the highest privileges.

    Elevation is needed so that the hotkeys also work in windows running
    as administrator (Task Manager, installers).

    Run as administrator:
        powershell -ExecutionPolicy Bypass -File instalace.ps1
#>

$ErrorActionPreference = 'Stop'

$exe = 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
if (-not (Test-Path $exe)) { throw "AutoHotkey v2 not found: $exe" }

$script = Join-Path $PSScriptRoot 'mac-klavesnice.ahk'
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

Write-Host "Task '$name' registered." -ForegroundColor Green
Write-Host "Remember to remove any shortcut from the Startup folder," -ForegroundColor Yellow
Write-Host "otherwise the script would run twice." -ForegroundColor Yellow
