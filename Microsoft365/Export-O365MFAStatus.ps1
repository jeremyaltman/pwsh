# .\export_office_365_users_mfa_status.ps1  -OutputFile "C:\Reports\o365-users-mfa-status.csv"
#       
#   -OutputFile  - Optional - File path to save the Output CSV file
#
# NOTE: If you don't pass an output file path, it will save the output file in your powershell working directory (".\office-365-users-without-photo.csv").


#Accept input parameters
Param(
    [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $true)]
    [string] $OutputFile
)

#Set default output file path if not passed.
if ([string]::IsNullOrEmpty($OutputFile) -eq $true) {
    $OutputFile = ".\enabled-licensed-o365-users-mfa-status.csv"
}

$Result = @()
$users = Get-MsolUser -EnabledFilter EnabledOnly -All | Where-Object { $_.isLicensed -eq $true }
$users | ForEach-Object {
    $user = $_
    if ($user.StrongAuthenticationRequirements.State -ne $null) {
        $mfaStatus = $user.StrongAuthenticationRequirements.State
    }
    else {
        $mfaStatus = "Disabled" 
    }

    $Result += New-Object PSObject -property @{
        UserName          = $user.DisplayName
        UserPrincipalName = $user.UserPrincipalName
        MFAStatus         = $mfaStatus
    }
}
#Export user details to CSV.
$Result | Export-CSV $OutputFile -NoTypeInformation -Encoding UTF8
Write-Host "Report exported successfully" -ForegroundColor Yellow