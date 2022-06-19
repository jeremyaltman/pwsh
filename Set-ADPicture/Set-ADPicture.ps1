<#
.SYNOPSIS
Set-ADPicture.ps1
v18.0913
Jeremy.Altman@santanna.net
.DESCRIPTION
This script downloads and sets the Active Directory profile photograph and sets it as your profile picture in Windows.
If no picture exists in AD, choose ses-defaultuser.jpg in \\ses4energy.com\NETLOGON
#>

[CmdletBinding(SupportsShouldProcess=$true)]Param()
function Test-Null($InputObject) { return !([bool]$InputObject) }

# Get sid and photo for current user
$user = ([ADSISearcher]"(&(objectCategory=User)(SAMAccountName=$env:username))").FindOne().Properties
$user_photo = $user.thumbnailphoto
$user_sid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value

# Continue if an image was returned
If ((Test-Null $user_photo) -eq $false) {
    Write-Verbose "Photo exists in Active Directory."
}
# If no image was found in profile, use generic logo.
Else {
    Write-Verbose "No photo found in Active Directory for $env:username, using the default image instead"
    $user_photo = [byte[]](Get-Content "$env:ALLUSERSPROFILE\Santanna\scripts\Set-ADPicture\ses-defaultuser.jpg" -Encoding byte)
}

# Set up image sizes and base path
$image_sizes = @(32, 40, 48, 96, 192, 200, 240, 448)
$image_mask = "Image{0}.jpg"
$image_base = "C:\ProgramData\AccountPictures"

# Set up registry
$reg_base = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AccountPicture\Users\{0}"
$reg_key = [string]::format($reg_base, $user_sid)
$reg_value_mask = "Image{0}"
If ((Test-Path -Path $reg_key) -eq $false) { New-Item -Path $reg_key } 

# Save images, set reg keys
Try {
    ForEach ($size in $image_sizes) {
        # Create hidden directory, if it doesn't exist
        $dir = $image_base + "\" + $user_sid
        If ((Test-Path -Path $dir) -eq $false) { $(mkdir $dir).Attributes = "Hidden" }

        # Save photo to disk, overwrite existing files
        $file_name = ([string]::format($image_mask, $size))
        $path = $dir + "\" + $file_name
        Write-Verbose "  saving: $file_name"
        $user_photo | Set-Content -Path $path -Encoding Byte -Force

        # Save the path in registry, overwrite existing entries
        $name = [string]::format($reg_value_mask, $size)
        $value = New-ItemProperty -Path $reg_key -Name $name -Value $path -Force
    }
}
Catch {
    Write-Error "Cannot update profile picture for $env:username."
    Write-Error "Check prompt elevation and permissions to files/registry."
}


# SIG # Begin signature block
# MIILDwYJKoZIhvcNAQcCoIILADCCCvwCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDzvLZJVXsBB9jC
# DvlhYkHfTzHCnW0Ye0FMvKDkobQtE6CCCEUwgghBMIIGKaADAgECAhNeAAACcRgh
# BS4/N5zAAAAAAAJxMA0GCSqGSIb3DQEBCwUAMFcxEzARBgoJkiaJk/IsZAEZFgNu
# ZXQxGDAWBgoJkiaJk/IsZAEZFghzYW50YW5uYTEmMCQGA1UEAxMdU2FudGFubmEg
# RW5lcmd5IEVudGVycHJpc2UgQ0EwHhcNMjIwMjIxMDUxMzQ3WhcNMjQwMjIxMDUy
# MzQ3WjCBuDETMBEGCgmSJomT8ixkARkWA25ldDEYMBYGCgmSJomT8ixkARkWCHNh
# bnRhbm5hMREwDwYDVQQLEwhBY2NvdW50czEQMA4GA1UECxMHTWFuYWdlZDEfMB0G
# A1UECxMWSW5mb3JtYXRpb24gVGVjaG5vbG9neTEWMBQGA1UEAxMNSmVyZW15IEFs
# dG1hbjEpMCcGCSqGSIb3DQEJARYaamVyZW15LmFsdG1hbkBzYW50YW5uYS5uZXQw
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC/kYMWw+yf/8MeBr2SV1X/
# uvHLJjKM9d6pbY4hc0Hh8o6fHpHv5w0gmDe2A0vNGcRdL+icSnOyXVyOmNjwY3Df
# QTiDUN12rH7UvcEnYOmBfQdewRJSPJ0d4yltFoHu76cwZrL82fqSMZmv9vBKJkRl
# lrIpCYlFBHSwg9+VtzPZZmw07BhdjAup87QTKUIia/44QuMoEbqvEn+dOyoGpVQt
# NK7ZO4WPy8wvo9suaHZpAvsQlSNWU6plRoqkLvrEZDrVxetoM4aqUgGLAMOczSoo
# +fHpbVqkNoyh356xa5lagVcPp82/QuPF0OoJZDFUnigT8FgWlhWPnd2nTCj8HPG9
# AgMBAAGjggOiMIIDnjA+BgkrBgEEAYI3FQcEMTAvBicrBgEEAYI3FQiHydV+hdWA
# MIatlT2E2o5yhOXDN4FxhbDyAIbl3xYCAWUCAQIwEwYDVR0lBAwwCgYIKwYBBQUH
# AwMwDgYDVR0PAQH/BAQDAgeAMBsGCSsGAQQBgjcVCgQOMAwwCgYIKwYBBQUHAwMw
# HQYDVR0OBBYEFENFyqXlyzZsk2eLequJW33N61pqMB8GA1UdIwQYMBaAFNDR90+d
# htWnzVMyh7RoRvqVIXmxMIIBMAYDVR0fBIIBJzCCASMwggEfoIIBG6CCAReGgcps
# ZGFwOi8vL0NOPVNhbnRhbm5hJTIwRW5lcmd5JTIwRW50ZXJwcmlzZSUyMENBLENO
# PUNSWVBUTyxDTj1DRFAsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2Vy
# dmljZXMsQ049Q29uZmlndXJhdGlvbixEQz1zYW50YW5uYSxEQz1uZXQ/Y2VydGlm
# aWNhdGVSZXZvY2F0aW9uTGlzdD9iYXNlP29iamVjdENsYXNzPWNSTERpc3RyaWJ1
# dGlvblBvaW50hkhodHRwOi8vcGtpLnNhbnRhbm5hLm5ldC9DZXJ0RGF0YS9TYW50
# YW5uYSUyMEVuZXJneSUyMEVudGVycHJpc2UlMjBDQS5jcmwwggFtBggrBgEFBQcB
# AQSCAV8wggFbMIHDBggrBgEFBQcwAoaBtmxkYXA6Ly8vQ049U2FudGFubmElMjBF
# bmVyZ3klMjBFbnRlcnByaXNlJTIwQ0EsQ049QUlBLENOPVB1YmxpYyUyMEtleSUy
# MFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9c2FudGFu
# bmEsREM9bmV0P2NBQ2VydGlmaWNhdGU/YmFzZT9vYmplY3RDbGFzcz1jZXJ0aWZp
# Y2F0aW9uQXV0aG9yaXR5MGgGCCsGAQUFBzAChlxodHRwOi8vcGtpLnNhbnRhbm5h
# Lm5ldC9DZXJ0RGF0YS9DUllQVE8uc2FudGFubmEubmV0X1NhbnRhbm5hJTIwRW5l
# cmd5JTIwRW50ZXJwcmlzZSUyMENBLmNydDApBggrBgEFBQcwAYYdaHR0cDovL29j
# c3Auc2FudGFubmEubmV0L29jc3AwNQYDVR0RBC4wLKAqBgorBgEEAYI3FAIDoBwM
# GmplcmVteS5hbHRtYW5Ac2FudGFubmEubmV0MA0GCSqGSIb3DQEBCwUAA4ICAQBx
# 1UXOLinilGQKFXR2r6TVdZHb67oPdtNGuioJg/GkVISbj/r+KffLKaHO8diNznIp
# fLeMFEHR5ewQO8gD9q9WlRhIcXG5tPBB02nokYpFn/hwdzDIsIZvZ5wUiZdoIp5y
# PTQYh/DwWmPbxPryefx4iAP8sLbz2MZ56UQXjbe+cCPhw5duzOwvv4a3wQT23QxW
# PPFZtqEbtLRcZJd5JLKjgz+VQzx8QdlxtjO0xkT20XVIYYjCVX7/rHI6JgArNJAX
# kpZbMEnx0Si3iaG9OaWS9FgbqUspjmyJRoS2DyC1X4zYQtxmj4ed9KaCXYkN/8kx
# eWUytW17vHOEjkNtsdoFJ5Hizxx8pR8fyQF6czc2ArHtytXS8266ywa/eeSvdT1V
# Mje/tZEM10hH+SNWTgoPUwqOOL8Q9e/fmOPTKPyGB/0bwjG1VqvVAQfligh79HAO
# hOctGg8QJEyC+ensxAxTOihHgjOqHK+i7h5QQZg4Hl68r5iJA9+ysYbJ7v+SUk/H
# 4e4AFH7d+Zhvs8QAatw8N9VjGaXYaDQ/s419G2ncJiWaVzXTjB2s7l0kicifg7lG
# pK7BMiy0fqyAMqaGsuDZJSPK1UyqCqwG2mGsfPsmc7bbwOEf9kWc03xXBKe/xpzq
# xKtL9ZgDLQy76nFy5wqEtlAl70BN8ppw1RXcg+C11TGCAiAwggIcAgEBMG4wVzET
# MBEGCgmSJomT8ixkARkWA25ldDEYMBYGCgmSJomT8ixkARkWCHNhbnRhbm5hMSYw
# JAYDVQQDEx1TYW50YW5uYSBFbmVyZ3kgRW50ZXJwcmlzZSBDQQITXgAAAnEYIQUu
# PzecwAAAAAACcTANBglghkgBZQMEAgEFAKCBhDAYBgorBgEEAYI3AgEMMQowCKAC
# gAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsx
# DjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCDZRSEtC1vIB2uzpIcF0ctB
# 9HDor+7WlxVqzw7gDfjJ2TANBgkqhkiG9w0BAQEFAASCAQCxgSstH0bDY+NC+lTw
# n+0mTm7HkGuWc1jAgiKY8clCzbphL/9fIyIUIrVEXv7MRCkcsd/vM76kxGzqz+G2
# tBjZCcV7vUBvXzWxvNsGcx/O7K+LTqMxZ2cox7XyLvwHgzHmkOAvP3QUErzCHBwI
# TcksOL1zWJdsWEWH1Z8K4k+duqZ5miHFOLL4BxnJ1VOIxQvMLYVc06vAQiN1BGBW
# kflsuXatNR+K++WGBJcb1CCkMGG/fBd8FE+Q6eKgl7fT+58KAL6UAVBtoZqPmY4X
# lZU0mxTHMBvxvAO5HOeiA2OmYdrPuwMZ8UK84q96y/sk7ooNMnk6qcjPRJCk5iBX
# u1hL
# SIG # End signature block
