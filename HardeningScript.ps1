# 1. CONFIGURATION VARIABLES
$RDPPORT = 39123
$AllowedCompetitionIPs = @("10.10.10.1/32", "10.10.10.20-10.10.10.25", "192.168.1.0/24")
$InboundTCPPorts  = @(80, 443, 1433)
$InboundUDPPorts  = @()
$OutboundTCPPorts = @(80, 443, 587)
$OutboundUDPPorts = @(53, 123)

Write-Host "--- A. WIPING ALL RULES AND LOCKING DOWN ---" -ForegroundColor Red

# Delete all existing rules and set default "Deny All" policy
netsh advfirewall firewall delete rule name=all
netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound

# 2. WHITELIST INBOUND (Scoring & Management)
Write-Host "--- B. WHITELISTING INBOUND ACCESS ---" -ForegroundColor Cyan
$ips = $AllowedCompetitionIPs -join ","

# Administrative RDP (Safety First)
netsh advfirewall firewall add rule name="MGMT-RDP-In" dir=in localport=$RDPPORT protocol=tcp action=allow remoteip=$ips enable=yes

# Service Inbound
if ($InboundTCPPorts.Count -gt 0) {
    $ports = $InboundTCPPorts -join ","
    netsh advfirewall firewall add rule name="SRV-Inbound-TCP" dir=in action=allow protocol=TCP localport=$ports remoteip=$ips enable=yes
}

# 3. WHITELIST OUTBOUND (Core Functionality)
Write-Host "--- C. WHITELISTING OUTBOUND CORE ---" -ForegroundColor Cyan

# Outbound TCP (HTTP/HTTPS/Email)
foreach ($port in $OutboundTCPPorts) {
    netsh advfirewall firewall add rule name="ALLOW-Outbound-TCP-$port" dir=out action=allow protocol=TCP remoteport=$port enable=yes
}

# Outbound UDP (DNS/NTP)
foreach ($port in $OutboundUDPPorts) {
    netsh advfirewall firewall add rule name="ALLOW-Outbound-UDP-$port" dir=out action=allow protocol=UDP remoteport=$port enable=yes
}

# 4. FINAL ENFORCEMENT & SAFETY CHECK
Write-Host "--- D. FINAL ENFORCEMENT & SAFETY CHECK ---" -ForegroundColor Yellow
netsh advfirewall set allprofiles state ON

# Verify the RDP rule exists before ending the session
$check = Get-NetFirewallRule -DisplayName "MGMT-RDP-In" -ErrorAction SilentlyContinue
if ($check.Enabled -eq "True") {
    Write-Host "SUCCESS: Firewall is active and Management RDP rule is applied." -ForegroundColor Green
}
else {
    Write-Host "WARNING: RDP Rule check failed! Verify settings immediately." -ForegroundColor White -BackgroundColor Red
}

Write-Host "--- SCRIPT COMPLETE. SYSTEM HARDENED. ---"