# Author: Aaron Sprouse (Modified for interactive prompts)
Import-Module ActiveDirectory

# --- PROMPTS ---
Write-Host "Enter users to exclude (comma-separated). Example: krbtgt,gold-team,scoring"
$excludeInput = Read-Host "Excluded Users"
$excludedUsers = $excludeInput -split "," | ForEach-Object { $_.Trim() }

$defaultPassword = Read-Host "Enter the NEW password to apply to all users"
$safeModeInput = Read-Host "Enable SAFE MODE? (yes/no)"
$safeMode = $safeModeInput -match "^(yes|y)$"

$outputFile = "affectedUsers.csv"

# --- OUTPUT FILE HANDLING ---
if (Test-Path $outputFile) {
    Remove-Item $outputFile -Force
}
if ($safeMode) {
    Add-Content -Path $outputFile -Value "SAFE MODE ENABLED; NO CHANGES MADE"
}

# --- GET USERS ---
$allUsers = Get-ADUser -Filter * -Properties SamAccountName

foreach ($user in $allUsers) {

    if ($excludedUsers -contains $user.SamAccountName) {
        Write-Host "Skipping excluded user: $($user.SamAccountName)"
        continue
    }

    if ($safeMode) {
        Write-Host "Would reset password for: $($user.SamAccountName)"
    } else {
        try {
            Set-ADAccountPassword -Identity $user.SamAccountName `
                -NewPassword (ConvertTo-SecureString -AsPlainText $defaultPassword -Force)

            Write-Host "Password reset for: $($user.SamAccountName)"
        }
        catch {
            Write-Warning "Failed to reset password for: $($user.SamAccountName)"
        }
    }

    Add-Content -Path $outputFile -Value "$($user.SamAccountName)::$defaultPassword"
}

# --- FINAL STATUS ---
if ($safeMode) {
    Write-Host "SAFE MODE ON. No passwords were changed. Expected changes written to $outputFile"
} else {
    Write-Host "SAFE MODE OFF. Passwords reset for all applicable users. Output written to $outputFile"
}