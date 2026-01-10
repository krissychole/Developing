# Download and install Google Chrome (Enterprise 64‑bit)

$chromeURL = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"
$destination = "$env:TEMP\chrome.msi"

Invoke-WebRequest -Uri $chromeURL -OutFile $destination
Start-Process msiexec.exe -ArgumentList "/i `"$destination`" /qn /norestart" -Wait