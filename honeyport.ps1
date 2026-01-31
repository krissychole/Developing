# --- TEAM IP CAPTURE ---
Write-Host "`n=== CCDC TEAM WHITELISTING ===" -ForegroundColor Cyan
$ScorebotIPs = Read-Host "Enter Scoring Engine IPs (comma-separated)"
$WhiteTeam   = Read-Host "Enter White Team / Admin IPs (comma-separated)"
$GoldTeam    = Read-Host "Enter Gold Team / Infrastructure IPs (comma-separated)"

# Combine all "Friendly" IPs into one list
$FriendlyIPs = ($ScorebotIPs + "," + $WhiteTeam + "," + $GoldTeam).Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

Write-Host "`n=== SERVICE CONFIGURATION ===" -ForegroundColor Cyan
$ProdPorts     = 80, 443, 3389  # Critical ports to keep open for Friendlies
$HoneypotPorts = 21, 23, 25, 4444 # Bait ports for the Red Team
$BadServices   = "RemoteRegistry", "Spooler", "WSearch"

# --- 1. DYNAMIC SAFETY CHECK ---
# Grab your current IP so you don't kick yourself out of your own session
$MyIPs = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" }).IPAddress
foreach ($ip in $MyIPs) {
    netsh advfirewall firewall add rule name="SAFETY_LOCAL_MGMT" dir=in action=allow remoteip=$ip
    Write-Host "[+] Safety rule added for your current connection: $ip" -ForegroundColor Green
}

# --- 2. ALLOW FRIENDLY TEAMS TO PROD PORTS ---
Write-Host "[-] Configuring access for Scorebot, White, and Gold teams..." -ForegroundColor Yellow
foreach ($ip in $FriendlyIPs) {
    foreach ($port in $ProdPorts) {
        netsh advfirewall firewall add rule name="ALLOW_TEAM_$port" dir=in action=allow protocol=TCP localport=$port remoteip=$ip
    }
}

# --- 3. OPEN HONEYPOT BAIT PORTS ---
# These are open to EVERYONE so Red Team falls into the trap
foreach ($hport in $HoneypotPorts) {
    netsh advfirewall firewall add rule name="HONEYPOT_BAIT_$hport" dir=in action=allow protocol=TCP localport=$hport remoteip=any
}
Write-Host "[!] Honeypot ports opened for Red Team bait." -ForegroundColor Magenta

# --- 4. DISABLE SERVICES ---
foreach ($svc in $BadServices) {
    if (Get-Service $svc -ErrorAction SilentlyContinue) {
        Stop-Service $svc -Force -Confirm:$false -ErrorAction SilentlyContinue
        Set-Service $svc -StartupType Disabled
        Write-Host "[x] Disabled service: $svc" -ForegroundColor Gray
    }
}

# --- 5. THE SCORCHED EARTH POLICY ---
# This blocks everything that wasn't explicitly allowed above
Write-Host "[-] Activating Global Block (All other traffic)..." -ForegroundColor Red
netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound

Write-Host "`n=== HARDENING COMPLETE ===" -ForegroundColor Cyan
Write-Host "Scorebot/White/Gold can access: $ProdPorts"
Write-Host "Red Team is being funneled to: $HoneypotPorts"