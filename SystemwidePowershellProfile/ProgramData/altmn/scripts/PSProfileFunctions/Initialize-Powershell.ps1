if (!(Test-Path -Path "$env:ALLUSERSPROFILE\altmn")) {
    New-Item -Path "$env:ALLUSERSPROFILE\altmn" -ItemType Directory -Force | Out-Null
}

if (!(Test-Path -Path "$env:ALLUSERSPROFILE\altmn\PowerShell-$($PSVersionTable.PSEdition).Initialized")) {
    Write-Host "Configuring first run defaults for package management.."
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    #Install-PackageProvider -Name "NuGet" -RequiredVersion "2.8.5.216" -Force -Scope CurrentUser
    New-Item -Path "$env:ALLUSERSPROFILE\altmn" -Name "PowerShell-$($PSVersionTable.PSEdition).Initialized" -ItemType File -Value (Get-Date -Format "yyyyMM-dd.HHmm") -Force | Out-Null
}

if ($PSVersionTable.PSEdition -eq 'Desktop') {
    ### Windows PowerShell 5.1 Only!
}

if ($PSVersionTable.PSEdition -eq 'Core') {
    ### PowerShell Core 7+ Only!
}

$RequiredMinimumPSReadLineVersion = [version]"2.2.0"
if ((Get-Module PSReadLine).Version -gt $RequiredMinimumPSReadLineVersion) {
    Set-PSReadLineOption -MaximumHistoryCount 1024 -HistoryNoDuplicates -PredictionSource History -PredictionViewStyle ListView
} else {
    Write-Verbose "PSReadLine module update required!"
    Set-PSReadLineOption -MaximumHistoryCount 1024 -HistoryNoDuplicates
}

