[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = "https://1.na.dl.wireshark.org/win64/Wireshark-latest-x64.exe"
$output = "$env:TEMP\WiresharkInstaller.exe"

Invoke-WebRequest -Uri $url -OutFile $output
Write-Host "Installing Wireshark & Npcap..." -ForegroundColor Green
# /S for Wireshark silent install
Start-Process -FilePath $output -ArgumentList "/S" -Wait
Remove-Item $output