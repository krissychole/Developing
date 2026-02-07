# --- AUTOMATED CONFIGURATION (Team 12 - SECCDC 2026) ---
# Whitelisting the Scoring Subnet and the Specific Scorebot IP [cite: 247, 249]
$ScorebotIPs   = "10.250.250.10", "10.250.250.11", "169.254.169.254" 

# Your Jump Machine/Admin Subnet and the required Gateway/Artifact range [cite: 234, 246, 247]
$AdminSubnet   = "10.250.250.0/24", "10.250.112.0/24" 

# Standard ports for functional service checks listed in the packet [cite: 155-183]
$ProdPorts     = 21, 22, 53, 80, 88, 110, 389, 443, 445, 636, 995, 3389, 5985, 5986 

# Common bait ports that are NOT on the scored service list
$HoneypotPorts = 23, 25, 4444, 8080, 1433 

# Non-critical services to disable (BTA and LanmanServer excluded) [cite: 188, 202]
$BadServices   = "RemoteRegistry", "Spooler", "WSearch", "MapsBroker", "SensorService"

Write-Host "--- STARTING AUTOMATED HARDENING FOR TEAM 12 ---" -ForegroundColor Cyan

# 1. DYNAMIC SAFETY CHECK
$MyIPs = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" }).IPAddress
foreach ($ip in $MyIPs) {
    netsh advfirewall firewall add rule name="SAFETY_LOCAL_MGMT" dir=in action=allow remoteip=$ip
    Write-Host "[+] Safety rule added for current session: $ip" -ForegroundColor Green
}

# 2. ALLOW SCOREBOT & ADMINS TO PROD PORTS
$ManagementIPs = $ScorebotIPs + $AdminSubnet
foreach ($ip in $ManagementIPs) {
    foreach ($port in $ProdPorts) {
        netsh advfirewall firewall add rule name="PROD_ALLOW_$port" dir=in action=allow protocol=TCP localport=$port remoteip=$ip
    }
}
# Special Rule: Allow ICMP (Ping) for scoring heartbeat checks [cite: 153]
netsh advfirewall firewall add rule name="ALLOW_ICMP_IN" dir=in action=allow protocol=icmpv4 remoteip=$ScorebotIPs
Write-Host "[+] Production ports and ICMP secured to Scorebot/Admin only." -ForegroundColor Green

# 3. OPEN HONEYPOT PORTS TO THE WORLD
foreach ($hport in $HoneypotPorts) {
    netsh advfirewall firewall add rule name="HONEYPOT_BAIT_$hport" dir=in action=allow protocol=TCP localport=$hport remoteip=any
}
Write-Host "[!] Honeypot ports opened for Red Team bait." -ForegroundColor Magenta

# 4. DISABLE SERVICES
foreach ($svc in $BadServices) {
    if (Get-Service $svc -ErrorAction SilentlyContinue) {
        Stop-Service $svc -Force -Confirm:$false -ErrorAction SilentlyContinue
        Set-Service $svc -StartupType Disabled
        Write-Host "[x] Disabled service: $svc" -ForegroundColor Gray
    }
}

# 5. THE SCORCHED EARTH POLICY
Write-Host "[-] Activating Global Block..." -ForegroundColor Red
netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound

Write-Host "--- HARDENING COMPLETE ---" -ForegroundColor Cyan
Write-Host "REMINDER: Do NOT stop the BTA service or modify alexisj!" [cite_start]-ForegroundColor Yellow [cite: 189, 250]