Write-Host "`n=== CONFIGURE ALLOWED IPs ==="
Write-Host "Enter allowed IPs or ranges (comma-separated)."
Write-Host "Example: 10.10.0.0/16,192.168.1.50"
$ipInput = Read-Host "Allowed IPs"
$allowedIPs = $ipInput -split "," | ForEach-Object { $_.Trim() }

Write-Host "`n=== CONFIGURE ALLOWED PORTS ==="
Write-Host "Enter allowed inbound TCP ports (comma-separated)."
Write-Host "Example: 3389,22,443"
$portInput = Read-Host "Allowed Ports"
$allowedPorts = $portInput -split "," | ForEach-Object { $_.Trim() }

Write-Host "`n=== CONFIGURE SERVICES TO DISABLE ==="
Write-Host "Enter service names to stop and disable (comma-separated)."
Write-Host "Example: LanmanServer,DNS,RemoteRegistry,Spooler"
$svcInput = Read-Host "Services to disable"
$servicesToDisable = $svcInput -split "," | ForEach-Object { $_.Trim() }


# --- APPLY ALLOW-LIST RULES ---
Write-Host "`n[-] Applying inbound allow rules..." -ForegroundColor Yellow

# Allow each port from each allowed IP
foreach ($ip in $allowedIPs) {
    foreach ($port in $allowedPorts) {
        Write-Host "Allowing TCP $port from $ip"
        netsh advfirewall firewall add rule `
            name="ALLOW_$port`_$ip" `
            dir=in action=allow protocol=TCP localport=$port remoteip=$ip
    }
}

# Block everything else inbound
Write-Host "[-] Blocking all other inbound traffic..." -ForegroundColor Yellow
netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound


# --- DISABLE SERVICES ---
Write-Host "`n[-] Disabling selected services..." -ForegroundColor Yellow

foreach ($svc in $servicesToDisable) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue

    if ($null -eq $service) {
        Write-Host "Service not found: $svc" -ForegroundColor Yellow
        continue
    }

    Write-Host "Stopping service: $svc" -ForegroundColor Cyan
    Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue

    Write-Host "Disabling service: $svc" -ForegroundColor Cyan
    Set-Service -Name $svc -StartupType Disabled

    Write-Host "Service processed: $svc`n" -ForegroundColor Green
}