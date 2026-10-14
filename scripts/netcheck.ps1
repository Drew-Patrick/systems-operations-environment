# netcheck.ps1 : basic network diagnostics from a Windows host.
# Usage:  powershell -ExecutionPolicy Bypass -File scripts\netcheck.ps1 [-Target github.com] [-Port 443]
# Each section answers one question, in the order a troubleshooter asks them.
param(
    [string]$Target = "github.com",
    [int]$Port = 443
)

$ErrorActionPreference = "Continue"
function Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

Section "1. My addresses (ip a)"
Get-NetIPConfiguration | Where-Object { $_.IPv4Address } |
    Select-Object InterfaceAlias, @{n="IPv4";e={$_.IPv4Address.IPAddress}},
                  @{n="Gateway";e={$_.IPv4DefaultGateway.NextHop}},
                  @{n="DNS";e={($_.DNSServer | Where-Object AddressFamily -eq 2).ServerAddresses -join ","}} |
    Format-Table -AutoSize

Section "2. My routes (ip route), IPv4 default and connected only"
Get-NetRoute -AddressFamily IPv4 | Where-Object { $_.DestinationPrefix -eq "0.0.0.0/0" -or $_.NextHop -eq "0.0.0.0" } |
    Sort-Object RouteMetric | Select-Object DestinationPrefix, NextHop, InterfaceAlias, RouteMetric -First 8 |
    Format-Table -AutoSize

Section "3. Name resolution (nslookup $Target)"
try { Resolve-DnsName $Target -Type A -ErrorAction Stop | Select-Object Name, IPAddress | Format-Table -AutoSize }
catch { Write-Host "DNS FAILED: $($_.Exception.Message)" -ForegroundColor Red }

Section "4. Reachability (ping $Target)"
$p = Test-Connection $Target -Count 3 -ErrorAction SilentlyContinue
if ($p) { $p | Format-Table -AutoSize } else { Write-Host "PING FAILED or blocked" -ForegroundColor Red }

Section "5. Port check (nc -zv $Target $Port)"
$t = Test-NetConnection $Target -Port $Port -WarningAction SilentlyContinue
"{0}:{1}  TcpTestSucceeded={2}  RemoteAddress={3}" -f $Target, $Port, $t.TcpTestSucceeded, $t.RemoteAddress

Section "6. Path (traceroute $Target), first 10 hops"
$tr = Test-NetConnection $Target -TraceRoute -Hops 10 -WarningAction SilentlyContinue
$i = 1; foreach ($h in $tr.TraceRoute) { "{0,2}: {1}" -f $i, $h; $i++ }

Section "7. What is listening here (ss -tlnp)"
Get-NetTCPConnection -State Listen |
    Select-Object LocalAddress, LocalPort, @{n="Process";e={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}} |
    Sort-Object LocalPort -Unique | Format-Table -AutoSize
