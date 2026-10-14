# users.ps1 : local user and group administration on Windows, end to end.
# Run from an ADMINISTRATOR PowerShell:
#   powershell -ExecutionPolicy Bypass -File scripts\users.ps1
# Creates a test user, adds it to a group, disables it, re-enables it, removes it.
# Every step is followed by the command that proves it happened.
$ErrorActionPreference = "Stop"
$name = "labtest"
function Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

Section "Before: does $name exist?"
Get-LocalUser -Name $name -ErrorAction SilentlyContinue | Format-Table Name, Enabled

Section "Create user (useradd)"
# random 16-character password; never printed
$chars = [char[]]"ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#%"
$plain = -join ((1..16) | ForEach-Object { $chars | Get-Random })
$pw = ConvertTo-SecureString $plain -AsPlainText -Force
New-LocalUser -Name $name -Password $pw -FullName "Lab Test" -Description "temporary test account" -PasswordNeverExpires:$false | Out-Null
Get-LocalUser -Name $name | Format-Table Name, Enabled, Description

Section "Add to group Users (usermod -aG)"
Add-LocalGroupMember -Group "Users" -Member $name
Get-LocalGroupMember -Group "Users" | Where-Object Name -like "*\$name" | Format-Table Name, PrincipalSource

Section "Disable (usermod -L)"
Disable-LocalUser -Name $name
Get-LocalUser -Name $name | Format-Table Name, Enabled

Section "Re-enable (usermod -U)"
Enable-LocalUser -Name $name
Get-LocalUser -Name $name | Format-Table Name, Enabled

Section "Remove (userdel)"
Remove-LocalUser -Name $name
if (Get-LocalUser -Name $name -ErrorAction SilentlyContinue) { Write-Host "STILL EXISTS" -ForegroundColor Red } else { "removed" }
