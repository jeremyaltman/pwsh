<#
    .SYNOPSIS
    Applies a specified wallpaper to the current user's desktop
       
    .PARAMETER Image
    Provide the full/exact path to the image

    .PARAMETER Style
    Provide wallpaper style (Example: Fill, Fit, Stretch, Tile, Center, or Span)

    .PARAMETER Random
    Chooses a random weekly wallpaper
  
    .EXAMPLE
    Set-WallPaper.ps1
    Set-Wallpaper.ps1 -Image "C:\ProgramData\Santanna\etc\wallpapers\01.png" -Style Stretch
    Set-WallPaper.ps1 -Style Span
    Set-WallPaper.ps1 -Random

    .NOTES
    Created by Jeremy.Altman@santannaenergy.com
    2022.06.02: Initial Version
    2022.06.03: Set default wallpaper if no parameters supplied to the current week number, with the Fill style
    2022.06.04: Added -Random parameter to choose a random weekly wallpaper
    2022.06.13: Added -Override parameter and check for membership in the "GPO Wallpaper Exemption Users" security group
  
#>

param (
    [parameter(Position = 0, Mandatory = $false)]
    # Provide path to image
    [string]$Image = "C:\ProgramData\Santanna\etc\wallpapers\$(Get-Date -UFormat %V).png",
    # Provide wallpaper style that you would like applied
    [parameter(Position = 1, Mandatory = $false)]
    [ValidateSet('Fill', 'Fit', 'Stretch', 'Tile', 'Center', 'Span')]
    [string]$Style = "Fill",
    [switch]$Random = $false,
    [switch]$Override = $false
)

$WallpaperStyle = Switch ($Style) {
    "Fill" { "10" }
    "Fit" { "6" }
    "Stretch" { "2" }
    "Tile" { "0" }
    "Center" { "0" }
    "Span" { "22" }
}

if ($Style -eq "Tile") {
    New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -PropertyType String -Value $WallpaperStyle -Force | Out-Null
    New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -PropertyType String -Value 1 -Force | Out-Null
}
else {
    New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -PropertyType String -Value $WallpaperStyle -Force | Out-Null
    New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -PropertyType String -Value 0 -Force | Out-Null
}

if ($Random -eq $true) {
    $Image = "C:\ProgramData\Santanna\etc\wallpapers\$((Get-Random -Minimum 01 -Maximum 53).ToString('00')).png"
}

if ((([adsisearcher]"(samaccountname=$env:USERNAME)").FindOne().Properties.memberof -match "CN=GPO Wallpaper Exemption Users,OU=GPO Filters,OU=Groups,DC=santanna,DC=net") -and ($Override -eq $false)) {
    Write-Host "Warning: Script was invoked under the context of a member of" -ForegroundColor Red -NoNewline
    Write-Host " GPO Wallpaper Exemption Users " -ForegroundColor White -NoNewline
    Write-Host "so the default exemption wallpaper will be applied instead.`n" -ForegroundColor Red
    Write-Host "Please rerun this script with the" -NoNewline -ForegroundColor DarkRed
    Write-Host " -Override " -NoNewline -ForegroundColor Gray
    Write-Host "parameter if you wish to bypass this limitation and apply the weekly SES wallpaper.`n" -ForegroundColor DarkRed

    # Apply default SES exemption wallpaper
    $Image = "C:\ProgramData\Santanna\etc\wallpapers\exempt.png"
}

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
  
public class Params
{
    [DllImport("User32.dll",CharSet=CharSet.Unicode)]
    public static extern int SystemParametersInfo (Int32 uAction,
                                                   Int32 uParam,
                                                   String lpvParam,
                                                   Int32 fuWinIni);
}
"@

Write-Host "Applying wallpaper: $Image"

$SPI_SETDESKWALLPAPER = 0x0014
$UpdateIniFile = 0x01
$SendChangeEvent = 0x02
  
$fWinIni = $UpdateIniFile -bor $SendChangeEvent
  
#$ret = [Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $Image, $fWinIni)
[Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $Image, $fWinIni)



# SIG # Begin signature block
# MIILDwYJKoZIhvcNAQcCoIILADCCCvwCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBQUOSg/DRWYSca
# +vCzPWrL3A8IiJPI+dgDOf+/sXD+BaCCCEUwgghBMIIGKaADAgECAhNeAAACcRgh
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
# DjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCDX0m/Juaz1DQmmptg8EtxX
# MADWGk8Kd2RGzIFhWNMsczANBgkqhkiG9w0BAQEFAASCAQC+3J3px+bDIt03PbAE
# oVPQ163/U1CHrgU+t7vdJNUpucfnlR0BGbLo2ZxDE+B/SEQnOsXFW6Mcy9IdezqE
# +6CfVyDTf9n00EZvgdqsHoMYgS7sdLsIwBMs+T24J6hoMWC+h1byxnokDysjvdKU
# yriTWmCM4OhZrs7fN6M7vmmzRD7skz9eisVh6lfMjkqf95UUz/a32OlRLOL3mdhU
# qqRRC1Li+W5ulsqbH38UWnnBr0dAYjSXde3mCtIsOPl0Z75ua2OURDeT4J57UQu9
# I4GToQqQ9LB0HmuFfDV37j+VPibj0sKxvQ4PjTVP++lkSpMEMGeo7q6IaR/FVwi3
# W3Zn
# SIG # End signature block
