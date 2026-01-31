for ($i = 1; $i -le 254; $i++) {
    $ip = "192.168.119.$i"
    $ping = Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue
    if ($ping) {
        Write-Host "$ip is up" -ForegroundColor Green
    } else {
        Write-Host "$ip is down" -ForegroundColor DarkGray
    }
}