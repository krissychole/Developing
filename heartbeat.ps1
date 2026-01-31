$TargetPorts = 80, 443
$CheckInterval = 10 # Seconds

Write-Host "=== WEB SERVICE HEARTBEAT ===" -ForegroundColor Cyan
Write-Host "Monitoring Ports 80 and 443 on localhost..."

while($true) {
    foreach ($port in $TargetPorts) {
        $check = Test-NetConnection -ComputerName localhost -Port $port -InformationLevel Quiet
        $time = Get-Date -Format "HH:mm:ss"

        if ($check) {
            Write-Host "[$time] PORT $port : UP" -ForegroundColor Green
        } else {
            Write-Host "[$time] PORT $port : DOWN! CHECK SERVICES/FIREWALL!" -ForegroundColor Red -BackgroundColor Black
            [System.Media.SystemSounds]::Exclamation.Play() # Sound alert
        }
    }
    Start-Sleep -Seconds $CheckInterval
}