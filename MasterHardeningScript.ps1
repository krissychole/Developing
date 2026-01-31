# --- AUTOMATED CONFIGURATION (Edit these before running) ---
$ScorebotIPs   = "10.10.10.10", "10.10.10.11" # <--- REPLACE WITH ACTUAL SCOREBOT IPs
$AdminSubnet   = "192.168.1.0/24"             # <--- REPLACE WITH YOUR ADMIN SUBNET
$ProdPorts     = 80, 445, 3389                # Ports you want to keep ALIVE
$HoneypotPorts = 21, 23, 25, 4444             # Ports for your bait script
$BadServices   = "RemoteRegistry", "Spooler", "WSearch" # Add more as needed

Write-Host "--- STARTING AUTOMATED HARDENING ---" -ForegroundColor Cyan

# 1. DYNAMIC SAFETY CHECK (Finds your current IP so you don't lock yourself out)
$MyIPs = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" }).IPAddress
foreach ($ip in $MyIPs) {
    netsh advfirewall firewall add rule name="SAFETY_LOCAL_MGMT" dir=in action=allow remoteip=$ip
    Write-Host "[+] Safety rule added for current session: $ip" -ForegroundColor Green
}

# 2. ALLOW SCOREBOT & ADMINS TO PROD PORTS (80/445)
$ManagementIPs = $ScorebotIPs + $AdminSubnet
foreach ($ip in $ManagementIPs) {
    foreach ($port in $ProdPorts) {
        netsh advfirewall firewall add rule name="PROD_ALLOW_$port" dir=in action=allow protocol=TCP localport=$port remoteip=$ip
    }
}
Write-Host "[+] Production ports (80/445/3389) secured to Scorebot/Admin only." -ForegroundColor Green

# 3. OPEN HONEYPOT PORTS TO THE WORLD
foreach ($hport in $HoneypotPorts) {
    netsh advfirewall firewall add rule name="HONEYPOT_BAIT_$hport" dir=in action=allow protocol=TCP localport=$hport remoteip=any
}
Write-Host "[!] Honeypot ports opened for Red Team bait." -ForegroundColor Magenta

# 4. DISABLE SERVICES (Excluding LanmanServer to keep 445 alive)
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