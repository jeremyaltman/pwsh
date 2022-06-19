function Update-AllModules {
    <#
    .SYNOPSIS
    Updates all modules from the PowerShell gallery.
    .DESCRIPTION
    Updates all local modules that originated from the PowerShell gallery.
    Removes all old versions of the modules.
    .PARAMETER ExcludedModules
    Array of modules to exclude from updating.
    .PARAMETER SkipMajorVersion
    Skip major version updates to account for breaking changes.
    .PARAMETER KeepOldModuleVersions
    Array of modules to keep the old versions of.
    .PARAMETER ExcludedModulesforRemoval
    Array of modules to exclude from removing old versions of.
    The Az module is excluded by default.
    .EXAMPLE
    Update-AllModules -excludedModulesforRemoval 'Az'
    #>
    [cmdletbinding(SupportsShouldProcess = $true)]
    param (
        [parameter()]
        [array]$ExcludedModules = @(),
        [parameter()]
        [switch]$SkipMajorVersion,
        [parameter()]
        [switch]$KeepOldModuleVersions,
        [parameter()]
        [array]$ExcludedModulesforRemoval = @("Az")
    )
    # Get all installed modules that have a newer version available
    Write-Verbose "Checking all installed modules for available updates."
    $CurrentModules = Get-InstalledModule | Where-Object { $ExcludedModules -notcontains $_.Name -and $_.repository -eq "PSGallery" }

    # Walk through the Installed modules and check if there is a newer version
    $CurrentModules | ForEach-Object {
        Write-Verbose "Checking $($_.Name)"
        Try {
            $GalleryModule = Find-Module -Name $_.Name -Repository PSGallery -ErrorAction Stop
        }
        Catch {
            Write-Error "Module $($_.Name) not found in gallery $_"
            $GalleryModule = $null
        }
        if ($GalleryModule.Version -gt $_.Version) {
            if ($SkipMajorVersion -and $GalleryModule.Version.Split('.')[0] -gt $_.Version.Split('.')[0]) {
                Write-Warning "Skipping major version update for module $($_.Name). Galleryversion: $($GalleryModule.Version), local version $($_.Version)"
            }
            else {
                Write-Verbose "$($_.Name) will be updated. Galleryversion: $($GalleryModule.Version), local version $($_.Version)"
                try {
                    if ($PSCmdlet.ShouldProcess(
                        ("Module {0} will be updated to version {1}" -f $_.Name, $GalleryModule.Version),
                            $_.Name,
                            "Update-Module"
                        )
                    ) {
                        Update-Module $_.Name -ErrorAction Stop -Force
                        Write-Verbose "$($_.Name)  has been updated"
                    }
                }
                Catch {
                    Write-Error "$($_.Name) failed: $_ "
                    continue

                }
                if ($KeepOldModuleVersions -ne $true) {
                    Write-Verbose "Removing old module $($_.Name)"
                    if ($ExcludedModulesforRemoval -contains $_.Name) {
                        Write-Verbose "$($allversions.count) versions of this module found [ $($module.name) ]"
                        Write-Verbose "Please check this manually as removing the module can cause instabillity."
                    }
                    else {
                        try {
                            if ($PSCmdlet.ShouldProcess(
                                ("Old versions will be uninstalled for module {0}" -f $_.Name),
                                    $_.Name,
                                    "Uninstall-Module"
                                )
                            ) {
                                Get-InstalledModule -Name $_.Name -AllVersions `
                                | Where-Object { $_.version -ne $GalleryModule.Version } `
                                | Uninstall-Module -Force -ErrorAction Stop
                                Write-Verbose "Old versions of $($_.Name) have been removed"
                            }
                        }
                        catch {
                            Write-Error "Uninstalling old module $($_.Name) failed: $_"
                        }
                    }
                }
            }
        }
        elseif ($null -ne $GalleryModule) {
            Write-Verbose "$($_.Name) is up to date"
        }
    }
}

Update-AllModules
# SIG # Begin signature block
# MIILDwYJKoZIhvcNAQcCoIILADCCCvwCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDAHDLxjmEoQsxq
# qa5klQ1DLbJn7UisvS/55jYsDUG3HKCCCEUwgghBMIIGKaADAgECAhNeAAACcRgh
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
# DjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCDW5ecJyhQXxpHj+EyFlZAj
# GOPcXxXAvyzPguF1k13T4zANBgkqhkiG9w0BAQEFAASCAQCU1xjQXbC7Bndty9Iu
# Pp2KZ8QMUKxsRlx0KoSS2Zy6lRiCa9ck+5MdCAeSHRyA+/S+QqsIYtsQCCOMQlmV
# S2N9roc2R1b637WiYWQ1E3u4/LXxqwEpJZfoSdtmD+Evqob79zeqXR5ZIzbt8aqJ
# RMLGfwT5AiPXsjakcd+M5eN8VrxC8R0urmPAmI57SlQHt0mJZlqCZnoF2gG7hRRN
# JNYnDWUZdVkT8xUuaW7gXl59w2vIv+u1bjxalmX2Alw7pCpvtXj4RFDLZgsG+yWZ
# hMm360qAuQqeB1HAym7vk7ZX496bHfRMbaqTUIXZvAB0Kx/mae+GCy4z4nG/Lrp4
# 0Usd
# SIG # End signature block
