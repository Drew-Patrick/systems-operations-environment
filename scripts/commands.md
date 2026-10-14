# Linux to PowerShell: the commands used in this repo

| Task | Linux (bash) | Windows (PowerShell) |
|---|---|---|
| Change folder | `cd /srv/data` | `Set-Location C:\srv\data` (`cd` works too) |
| List files, with details and hidden | `ls -la` | `Get-ChildItem -Force` (`ls`, `dir` work too) |
| Show a file | `cat file.txt` | `Get-Content file.txt` (`cat` works too) |
| Follow a log as it grows | `tail -f app.log` | `Get-Content app.log -Wait -Tail 20` |
| Search text | `grep -i error app.log` | `Select-String -Pattern error app.log` |
| Search recursively | `grep -r "needle" .` | `Get-ChildItem -Recurse \| Select-String needle` |
| Running processes | `ps aux` | `Get-Process` |
| Kill a process | `kill <pid>` | `Stop-Process -Id <pid>` |
| Find a file by name | `find / -name "*.conf"` | `Get-ChildItem C:\ -Recurse -Filter *.conf` |
| Disk usage per filesystem | `df -h` | `Get-PSDrive -PSProvider FileSystem` |
| Size of a folder | `du -sh dir` | `(Get-ChildItem dir -Recurse \| Measure-Object Length -Sum).Sum` |
| My IP addresses | `ip a` | `Get-NetIPConfiguration` (`ipconfig`) |
| Routing table | `ip route` | `Get-NetRoute` (`route print`) |
| Ping | `ping -c 3 host` | `Test-Connection host -Count 3` |
| Trace the path | `traceroute host` / `tracepath host` | `Test-NetConnection host -TraceRoute` (`tracert`) |
| Look up a name | `nslookup host` / `dig host` | `Resolve-DnsName host` (`nslookup`) |
| Is a port open | `nc -zv host 2222` | `Test-NetConnection host -Port 2222` |
| What is listening | `ss -tlnp` | `Get-NetTCPConnection -State Listen` (`netstat -ano`) |
| Service status | `systemctl status sshd` | `Get-Service sshd` |
| Start / stop / restart a service | `systemctl restart sshd` | `Restart-Service sshd` |
| Service logs | `journalctl -u sshd -n 50` | `Get-WinEvent -LogName System -MaxEvents 50` |
| Scheduled jobs | `systemctl list-timers` | `Get-ScheduledTask` |
| Run as administrator | `sudo cmd` | open PowerShell "Run as administrator" |
| Permissions on a file | `ls -l`, `chmod 600 f` | `Get-Acl f`, `icacls f` |
| Create a user | `useradd name` | `New-LocalUser name` |
| Add user to group | `usermod -aG wheel name` | `Add-LocalGroupMember -Group Administrators -Member name` |
| Disable a user | `usermod -L name` | `Disable-LocalUser name` |
| Remove a user | `userdel name` | `Remove-LocalUser name` |
| Change password | `passwd name` | `Set-LocalUser name -Password (Read-Host -AsSecureString)` |
| Environment variables | `env`, `echo $HOME` | `Get-ChildItem Env:`, `$env:USERPROFILE` |
| Where is a command | `which ssh` | `Get-Command ssh` |
| Help for a command | `man ssh`, `ssh --help` | `Get-Help Get-Service -Full` |
| Exit code of last command | `echo $?` | `$LASTEXITCODE` (external) / `$?` (true/false) |
| Reboot | `sudo reboot` | `Restart-Computer` |

Notes
- Many Linux names (`ls`, `cat`, `cd`, `ps`) exist in PowerShell as aliases for the longer verb-noun commands. The alias is fine interactively; scripts should use the full name.
- PowerShell commands return objects, not text. `| Format-Table`, `| Select-Object`, and `| Where-Object` replace most of what `grep`, `awk`, and `cut` do on Linux.
- Linux is case-sensitive for file names; Windows is not.
