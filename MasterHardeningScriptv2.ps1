# --- CONFIGURATION SECTION ---
Write-Host "`n=== CONFIGURE ALLOWED IPs ===" -ForegroundColor Cyan
Write-Host "Enter allowed IPs (Scorebot, Admin IPs). Comma-separated."
$ipInput = Read-Host "Allowed IPs"
$allowedIPs = $ipInput -split "," | ForEach-Object { $_.Trim() }

Write-Host "`n=== CONFIGURE PRODUCTION PORTS ===" -ForegroundColor Cyan
Write-Host "Enter ports for active services (e.g., 80, 443, 3389)."
$portInput = Read-Host "Allowed Ports"
$allowedPorts = $portInput -split "," | ForEach-Object { $_.Trim() }

Write-Host "`n=== CONFIGURE HONEYPOT BAIT PORTS ===" -ForegroundColor Cyan
Write-Host "Which ports will the Honeypot listen on? (e.g., 21, 23, 4444)"
$hpInput = Read-Host "Honeypot Ports"
$honeypotPorts = $hpInput -split "," | ForEach-Object { $_.Trim() }

Write-Host "`n=== CONFIGURE SERVICES TO DISABLE ===" -ForegroundColor Cyan
Write-Host "Example: DNS, RemoteRegistry, Spooler (Do NOT list LanmanServer if using 443)"
$svcInput = Read-Host "Services to disable"
$servicesToDisable = $svcInput -split "," | ForEach-Object { $_.Trim() }

# --- 1. SAFETY CHECK: PREVENT LOCKOUT ---
Write-Host "`n[-] Running Safety Check..." -ForegroundColor Yellow
$currentIPs = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" }).IPAddress
foreach ($ip in $currentIPs) {
    netsh advfirewall firewall add rule name="MGMT_Safety_LocalIP" dir=in action=allow remoteip=$ip
    Write-Host "  [+] Permanent Allow rule created for your current IP: $ip" -ForegroundColor Green
}

# --- 2. APPLY PRODUCTION ALLOW RULES ---
Write-Host "[-] Applying Production Service rules..." -ForegroundColor Yellow
foreach ($ip in $allowedIPs) {
    foreach ($port in $allowedPorts) {
        netsh advfirewall firewall add rule name="PROD_ALLOW_$port`_$ip" dir=in action=allow protocol=TCP localport=$port remoteip=$ip
    }
}

# --- 3. APPLY HONEYPOT HOLE-PUNCHING ---
Write-Host "[-] Opening Honeypot ports to EVERYONE (The Bait)..." -ForegroundColor Yellow
foreach ($hPort in $honeypotPorts) {
    # We allow 'any' because if we restrict it to allowedIPs, Red Team won't be able to hit it!
    netsh advfirewall firewall add rule name="HONEYPOT_BAIT_$hPort" dir=in action=allow protocol=TCP localport=$hPort remoteip=any
    Write-Host "  [!] Port $hPort is now open to all traffic for the Honeypot script." -ForegroundColor Magenta
}

# --- 4. DISABLE SERVICES ---
Write-Host "[-] Disabling selected services..." -ForegroundColor Yellow
foreach ($svc in $servicesToDisable) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc -StartupType Disabled
        Write-Host "  [x] Service $svc stopped and disabled." -ForegroundColor Gray
    }
}

# --- 5. ENFORCE GLOBAL BLOCK ---
Write-Host "[-] Slamming the door: Setting default inbound policy to BLOCK..." -ForegroundColor Red
netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound

Write-Host "`n=== HARDENING COMPLETE ===" -ForegroundColor Green
Write-Host "Production ports 80/443/RDP are restricted to your list."
Write-Host "Honeypot ports are open to everyone to catch scanners."