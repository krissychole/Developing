<#
.SYNOPSIS
    Resets Windows Firewall to default settings and ensures RDP access.
    
.DESCRIPTION
    This script is intended for emergency use to restore network connectivity 
    by resetting all firewall policies to Windows defaults, allowing outbound 
    traffic, and ensuring Remote Desktop (RDP) rules are enabled.
    
.NOTES
    Compatible with: Windows Server 2016, 2019, 2022, 2025 and Windows 10/11.
    Requires: Administrative Privileges.
#>

# Ensure script is running with Admin privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as an Administrator."
    exit 1
}

Write-Host "`n!!! EMERGENCY ROLLBACK INITIATED !!!" -ForegroundColor White -BackgroundColor Red 

try {
    # 1. Reset all policies to Windows Defaults 
    Write-Host "[-] Resetting firewall to factory defaults..." -ForegroundColor Yellow
    netsh advfirewall reset

    # 2. Ensure Inbound is Blocked (Default) but Outbound is Allowed (Default) 
    Write-Host "[-] Setting default policies (Block Inbound / Allow Outbound)..." -ForegroundColor Yellow
    netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound

    # 3. Ensure Firewall is still ON (to keep some protection) 
    Write-Host "[-] Ensuring Firewall is ENABLED..." -ForegroundColor Yellow
    netsh advfirewall set allprofiles state on

    # 4. Re-enable standard RDP just in case of lockout 
    Write-Host "[-] Enabling Remote Desktop rules..." -ForegroundColor Yellow
    netsh advfirewall firewall set rule group="remote desktop" new enable=Yes

    Write-Host "`nRollback complete. System is in default Windows state." -ForegroundColor Green
}
catch {
    Write-Error "An error occurred during the rollback process: $($_.Exception.Message)"
}