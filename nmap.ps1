[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Define download URL and temp path
$nmapUrl = "https://nmap.org/dist/nmap-7.95-setup.exe"
$nmapInstaller = "$env:TEMP\nmap-setup.exe"

# Download the installer
Write-Host "Downloading Zenmap/Nmap installer..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $nmapUrl -OutFile $nmapInstaller

# Launch installer interactively
Write-Host "Launching Zenmap/Nmap installer..." -ForegroundColor Green
Start-Process -FilePath $nmapInstaller -Wait

# Clean up
Remove-Item $nmapInstaller
Write-Host "Installer removed from temp directory." -ForegroundColor Gray