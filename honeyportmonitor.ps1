Write-Host "=== HONEYPORT LIVE MONITOR ===" -ForegroundColor Cyan
Write-Host "Watching for Red Team activity... (Ctrl+C to stop)`n"

# Check if the log exists first
if (!(Get-EventLog -List | Where-Object { $_.Log -eq "HoneyPort" })) {
    Write-Warning "HoneyPort log not found. Start the Honeypot script first!"
}

# Real-time monitoring loop
Get-WinEvent -LogName HoneyPort -Oldest | Select-Object -Last 10 # Show last 10 hits
while($true) {
    Get-WinEvent -LogName HoneyPort -MaxEvents 5 | ForEach-Object {
        $color = "White"
        if ($_.Message -like "*BLOCKED*") { $color = "Red" }
        if ($_.Message -like "*Whitelisted*") { $color = "Green" }
        
        Write-Host "[$($_.TimeCreated)] - $($_.Message)" -ForegroundColor $color
    }
    Start-Sleep -Seconds 3
    # Clear screen occasionally to keep it tidy if you prefer, or just let it roll
}