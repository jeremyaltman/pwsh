function Get-Fortune {
    <#
    .SYNOPSIS
        Display a short quote
    .DESCRIPTION
        Display a short quote from a file which defaults to: 'C:\ProgramData\Santanna\etc\fortune-cookies.txt') but can be changed with parameter -Path.
    .NOTES
        # Sample wisdom.txt file with 3 entries. Each 'fortune' is delimited by a line consisting of just the pct sign
        # The last fortune in the file should NOT be terminated with a pct sign
        %
        This too will pass.
           - Attar
        %
        Don't think, just do.
           - Horace
        %
        Time is money.
           - Benjamin Franklin
    .OUTPUTS
        [string]
    .PARAMETER Path
        A path to a filename containing the fortunes. Defaults to: ((Split-Path -path $env:ALLUSERSPROFILE)+'\Santanna\etc\fortune-cookies.txt')
        Aliased to 'FileName' and 'Fortune'
    .PARAMETER Delimiter
        Indicates delimiter between the individual fortunes. Defaults to "`n%`n" (newline percent newline)
    .LINK
        Get-Content
        Get-Random
        Split-Path
     
        todo put wisdom.txt in module and default path to it
    #>
    
    #region Parameter
    [CmdletBinding(ConfirmImpact = 'None')]
    [OutputType('string')]
    Param(
        [Alias('FileName', 'Fortune')]
        [string] $Path = "$env:ALLUSERSPROFILE\Santanna\etc\fortune-cookies.txt",
        [string] $Delimiter = "`n%`n",
        [switch] $Speak
    )
    #endregion Parameter
    
    begin {
        Write-Verbose -Message "Starting [$($MyInvocation.Mycommand)]"
        Write-Verbose -Message "Using fortune file [$Path]"
    }
    
    process {
        if (Test-Path -Path $Path) {
            Write-Verbose -Message "Using [$path] for fortune file"
            Write-Verbose -Message "Delimiter [$Delimiter]"
            $Fortune = (Get-Content -Raw -Path $path) -replace "`r`n", "`n" -split $Delimiter | Get-Random
            if ($Speak) {
                $Fortune
                $Fortune | Invoke-Speak
            }
            else {
                $Fortune
                Write-Output ""
            }
        }
        else {
            Write-Error -Message "ERROR: File [$Path] does not exist."
        }
    }
    
    end {
        Write-Verbose -Message "Ending [$($MyInvocation.Mycommand)]"
    }
    
}

Set-Alias -Name 'Fortune' -Value 'Get-Fortune'

Get-Fortune


# SIG # Begin signature block
# MIIcWgYJKoZIhvcNAQcCoIIcSzCCHEcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBVMqh+x/ymYpA2
# VKzgMR8yCus38Pr/sv11ok629UfIjqCCFkAwggbsMIIE1KADAgECAhAwD2+s3WaY
# dHypRjaneC25MA0GCSqGSIb3DQEBDAUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKTmV3IEplcnNleTEUMBIGA1UEBxMLSmVyc2V5IENpdHkxHjAcBgNVBAoTFVRo
# ZSBVU0VSVFJVU1QgTmV0d29yazEuMCwGA1UEAxMlVVNFUlRydXN0IFJTQSBDZXJ0
# aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xOTA1MDIwMDAwMDBaFw0zODAxMTgyMzU5
# NTlaMH0xCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIx
# EDAOBgNVBAcTB1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDElMCMG
# A1UEAxMcU2VjdGlnbyBSU0EgVGltZSBTdGFtcGluZyBDQTCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBAMgbAa/ZLH6ImX0BmD8gkL2cgCFUk7nPoD5T77Na
# wHbWGgSlzkeDtevEzEk0y/NFZbn5p2QWJgn71TJSeS7JY8ITm7aGPwEFkmZvIavV
# cRB5h/RGKs3EWsnb111JTXJWD9zJ41OYOioe/M5YSdO/8zm7uaQjQqzQFcN/nqJc
# 1zjxFrJw06PE37PFcqwuCnf8DZRSt/wflXMkPQEovA8NT7ORAY5unSd1VdEXOzQh
# e5cBlK9/gM/REQpXhMl/VuC9RpyCvpSdv7QgsGB+uE31DT/b0OqFjIpWcdEtlEzI
# jDzTFKKcvSb/01Mgx2Bpm1gKVPQF5/0xrPnIhRfHuCkZpCkvRuPd25Ffnz82Pg4w
# ZytGtzWvlr7aTGDMqLufDRTUGMQwmHSCIc9iVrUhcxIe/arKCFiHd6QV6xlV/9A5
# VC0m7kUaOm/N14Tw1/AoxU9kgwLU++Le8bwCKPRt2ieKBtKWh97oaw7wW33pdmmT
# IBxKlyx3GSuTlZicl57rjsF4VsZEJd8GEpoGLZ8DXv2DolNnyrH6jaFkyYiSWcuo
# RsDJ8qb/fVfbEnb6ikEk1Bv8cqUUotStQxykSYtBORQDHin6G6UirqXDTYLQjdpr
# t9v3GEBXc/Bxo/tKfUU2wfeNgvq5yQ1TgH36tjlYMu9vGFCJ10+dM70atZ2h3pVB
# eqeDAgMBAAGjggFaMIIBVjAfBgNVHSMEGDAWgBRTeb9aqitKz1SA4dibwJ3ysgNm
# yzAdBgNVHQ4EFgQUGqH4YRkgD8NBd0UojtE1XwYSBFUwDgYDVR0PAQH/BAQDAgGG
# MBIGA1UdEwEB/wQIMAYBAf8CAQAwEwYDVR0lBAwwCgYIKwYBBQUHAwgwEQYDVR0g
# BAowCDAGBgRVHSAAMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9jcmwudXNlcnRy
# dXN0LmNvbS9VU0VSVHJ1c3RSU0FDZXJ0aWZpY2F0aW9uQXV0aG9yaXR5LmNybDB2
# BggrBgEFBQcBAQRqMGgwPwYIKwYBBQUHMAKGM2h0dHA6Ly9jcnQudXNlcnRydXN0
# LmNvbS9VU0VSVHJ1c3RSU0FBZGRUcnVzdENBLmNydDAlBggrBgEFBQcwAYYZaHR0
# cDovL29jc3AudXNlcnRydXN0LmNvbTANBgkqhkiG9w0BAQwFAAOCAgEAbVSBpTNd
# FuG1U4GRdd8DejILLSWEEbKw2yp9KgX1vDsn9FqguUlZkClsYcu1UNviffmfAO9A
# w63T4uRW+VhBz/FC5RB9/7B0H4/GXAn5M17qoBwmWFzztBEP1dXD4rzVWHi/SHbh
# RGdtj7BDEA+N5Pk4Yr8TAcWFo0zFzLJTMJWk1vSWVgi4zVx/AZa+clJqO0I3fBZ4
# OZOTlJux3LJtQW1nzclvkD1/RXLBGyPWwlWEZuSzxWYG9vPWS16toytCiiGS/qhv
# WiVwYoFzY16gu9jc10rTPa+DBjgSHSSHLeT8AtY+dwS8BDa153fLnC6NIxi5o8JH
# HfBd1qFzVwVomqfJN2Udvuq82EKDQwWli6YJ/9GhlKZOqj0J9QVst9JkWtgqIsJL
# nfE5XkzeSD2bNJaaCV+O/fexUpHOP4n2HKG1qXUfcb9bQ11lPVCBbqvw0NP8srMf
# tpmWJvQ8eYtcZMzN7iea5aDADHKHwW5NWtMe6vBE5jJvHOsXTpTDeGUgOw9Bqh/p
# oUGd/rG4oGUqNODeqPk85sEwu8CgYyz8XBYAqNDEf+oRnR4GxqZtMl20OAkrSQeq
# /eww2vGnL8+3/frQo4TZJ577AWZ3uVYQ4SBuxq6x+ba6yDVdM3aO8XwgDCp3rrWi
# Aoa6Ke60WgCxjKvj+QrJVF3UuWp0nr1IrpgwggcHMIIE76ADAgECAhEAjHegAI/0
# 0bDGPZ86SIONazANBgkqhkiG9w0BAQwFADB9MQswCQYDVQQGEwJHQjEbMBkGA1UE
# CBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQK
# Ew9TZWN0aWdvIExpbWl0ZWQxJTAjBgNVBAMTHFNlY3RpZ28gUlNBIFRpbWUgU3Rh
# bXBpbmcgQ0EwHhcNMjAxMDIzMDAwMDAwWhcNMzIwMTIyMjM1OTU5WjCBhDELMAkG
# A1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMH
# U2FsZm9yZDEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSwwKgYDVQQDDCNTZWN0
# aWdvIFJTQSBUaW1lIFN0YW1waW5nIFNpZ25lciAjMjCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBAJGHSyyLwfEeoJ7TB8YBylKwvnl5XQlmBi0vNX27wPsn
# 2kJqWRslTOrvQNaafjLIaoF9tFw+VhCBNToiNoz7+CAph6x00BtivD9khwJf78WA
# 7wYc3F5Ok4e4mt5MB06FzHDFDXvsw9njl+nLGdtWRWzuSyBsyT5s/fCb8Sj4kZmq
# /FrBmoIgOrfv59a4JUnCORuHgTnLw7c6zZ9QBB8amaSAAk0dBahV021SgIPmbkil
# X8GJWGCK7/GszYdjGI50y4SHQWljgbz2H6p818FBzq2rdosggNQtlQeNx/ULFx6a
# 5daZaVHHTqadKW/neZMNMmNTrszGKYogwWDG8gIsxPnIIt/5J4Khg1HCvMmCGiGE
# spe81K9EHJaCIpUqhVSu8f0+SXR0/I6uP6Vy9MNaAapQpYt2lRtm6+/a35Qu2Rrr
# TCd9TAX3+CNdxFfIJgV6/IEjX1QJOCpi1arK3+3PU6sf9kSc1ZlZxVZkW/eOUg9m
# /Jg/RAYTZG7p4RVgUKWx7M+46MkLvsWE990Kndq8KWw9Vu2/eGe2W8heFBy5r4Qt
# d6L3OZU3b05/HMY8BNYxxX7vPehRfnGtJHQbLNz5fKrvwnZJaGLVi/UD3759jg82
# dUZbk3bEg+6CviyuNxLxvFbD5K1Dw7dmll6UMvqg9quJUPrOoPMIgRrRRKfM97gx
# AgMBAAGjggF4MIIBdDAfBgNVHSMEGDAWgBQaofhhGSAPw0F3RSiO0TVfBhIEVTAd
# BgNVHQ4EFgQUaXU3e7udNUJOv1fTmtufAdGu3tAwDgYDVR0PAQH/BAQDAgbAMAwG
# A1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwQAYDVR0gBDkwNzA1
# BgwrBgEEAbIxAQIBAwgwJTAjBggrBgEFBQcCARYXaHR0cHM6Ly9zZWN0aWdvLmNv
# bS9DUFMwRAYDVR0fBD0wOzA5oDegNYYzaHR0cDovL2NybC5zZWN0aWdvLmNvbS9T
# ZWN0aWdvUlNBVGltZVN0YW1waW5nQ0EuY3JsMHQGCCsGAQUFBwEBBGgwZjA/Bggr
# BgEFBQcwAoYzaHR0cDovL2NydC5zZWN0aWdvLmNvbS9TZWN0aWdvUlNBVGltZVN0
# YW1waW5nQ0EuY3J0MCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0aWdvLmNv
# bTANBgkqhkiG9w0BAQwFAAOCAgEASgN4kEIz7Hsagwk2M5hVu51ABjBrRWrxlA4Z
# UP9bJV474TnEW7rplZA3N73f+2Ts5YK3lcxXVXBLTvSoh90ihaZXu7ghJ9SgKjGU
# igchnoq9pxr1AhXLRFCZjOw+ugN3poICkMIuk6m+ITR1Y7ngLQ/PATfLjaL6uFqa
# rqF6nhOTGVWPCZAu3+qIFxbradbhJb1FCJeA11QgKE/Ke7OzpdIAsGA0ZcTjxcOl
# 5LqFqnpp23WkPnlomjaLQ6421GFyPA6FYg2gXnDbZC8Bx8GhxySUo7I8brJeotD6
# qNG4JRwW5sDVf2gaxGUpNSotiLzqrnTWgufAiLjhT3jwXMrAQFzCn9UyHCzaPKw2
# 9wZSmqNAMBewKRaZyaq3iEn36AslM7U/ba+fXwpW3xKxw+7OkXfoIBPpXCTH6kQL
# SuYThBxN6w21uIagMKeLoZ+0LMzAFiPJkeVCA0uAzuRN5ioBPsBehaAkoRdA1dvb
# 55gQpPHqGRuAVPpHieiYgal1wA7f0GiUeaGgno62t0Jmy9nZay9N2N4+Mh4g5Oyc
# TUKNncczmYI3RNQmKSZAjngvue76L/Hxj/5QuHjdFJbeHA5wsCqFarFsaOkq5BAr
# biH903ydN+QqBtbD8ddo408HeYEIE/6yZF7psTzm0Hgjsgks4iZivzupl1HMx0Qy
# gbKvz98wgghBMIIGKaADAgECAhNeAAACcRghBS4/N5zAAAAAAAJxMA0GCSqGSIb3
# DQEBCwUAMFcxEzARBgoJkiaJk/IsZAEZFgNuZXQxGDAWBgoJkiaJk/IsZAEZFghz
# YW50YW5uYTEmMCQGA1UEAxMdU2FudGFubmEgRW5lcmd5IEVudGVycHJpc2UgQ0Ew
# HhcNMjIwMjIxMDUxMzQ3WhcNMjQwMjIxMDUyMzQ3WjCBuDETMBEGCgmSJomT8ixk
# ARkWA25ldDEYMBYGCgmSJomT8ixkARkWCHNhbnRhbm5hMREwDwYDVQQLEwhBY2Nv
# dW50czEQMA4GA1UECxMHTWFuYWdlZDEfMB0GA1UECxMWSW5mb3JtYXRpb24gVGVj
# aG5vbG9neTEWMBQGA1UEAxMNSmVyZW15IEFsdG1hbjEpMCcGCSqGSIb3DQEJARYa
# amVyZW15LmFsdG1hbkBzYW50YW5uYS5uZXQwggEiMA0GCSqGSIb3DQEBAQUAA4IB
# DwAwggEKAoIBAQC/kYMWw+yf/8MeBr2SV1X/uvHLJjKM9d6pbY4hc0Hh8o6fHpHv
# 5w0gmDe2A0vNGcRdL+icSnOyXVyOmNjwY3DfQTiDUN12rH7UvcEnYOmBfQdewRJS
# PJ0d4yltFoHu76cwZrL82fqSMZmv9vBKJkRllrIpCYlFBHSwg9+VtzPZZmw07Bhd
# jAup87QTKUIia/44QuMoEbqvEn+dOyoGpVQtNK7ZO4WPy8wvo9suaHZpAvsQlSNW
# U6plRoqkLvrEZDrVxetoM4aqUgGLAMOczSoo+fHpbVqkNoyh356xa5lagVcPp82/
# QuPF0OoJZDFUnigT8FgWlhWPnd2nTCj8HPG9AgMBAAGjggOiMIIDnjA+BgkrBgEE
# AYI3FQcEMTAvBicrBgEEAYI3FQiHydV+hdWAMIatlT2E2o5yhOXDN4FxhbDyAIbl
# 3xYCAWUCAQIwEwYDVR0lBAwwCgYIKwYBBQUHAwMwDgYDVR0PAQH/BAQDAgeAMBsG
# CSsGAQQBgjcVCgQOMAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFENFyqXlyzZsk2eL
# equJW33N61pqMB8GA1UdIwQYMBaAFNDR90+dhtWnzVMyh7RoRvqVIXmxMIIBMAYD
# VR0fBIIBJzCCASMwggEfoIIBG6CCAReGgcpsZGFwOi8vL0NOPVNhbnRhbm5hJTIw
# RW5lcmd5JTIwRW50ZXJwcmlzZSUyMENBLENOPUNSWVBUTyxDTj1DRFAsQ049UHVi
# bGljJTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJhdGlv
# bixEQz1zYW50YW5uYSxEQz1uZXQ/Y2VydGlmaWNhdGVSZXZvY2F0aW9uTGlzdD9i
# YXNlP29iamVjdENsYXNzPWNSTERpc3RyaWJ1dGlvblBvaW50hkhodHRwOi8vcGtp
# LnNhbnRhbm5hLm5ldC9DZXJ0RGF0YS9TYW50YW5uYSUyMEVuZXJneSUyMEVudGVy
# cHJpc2UlMjBDQS5jcmwwggFtBggrBgEFBQcBAQSCAV8wggFbMIHDBggrBgEFBQcw
# AoaBtmxkYXA6Ly8vQ049U2FudGFubmElMjBFbmVyZ3klMjBFbnRlcnByaXNlJTIw
# Q0EsQ049QUlBLENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2Vz
# LENOPUNvbmZpZ3VyYXRpb24sREM9c2FudGFubmEsREM9bmV0P2NBQ2VydGlmaWNh
# dGU/YmFzZT9vYmplY3RDbGFzcz1jZXJ0aWZpY2F0aW9uQXV0aG9yaXR5MGgGCCsG
# AQUFBzAChlxodHRwOi8vcGtpLnNhbnRhbm5hLm5ldC9DZXJ0RGF0YS9DUllQVE8u
# c2FudGFubmEubmV0X1NhbnRhbm5hJTIwRW5lcmd5JTIwRW50ZXJwcmlzZSUyMENB
# LmNydDApBggrBgEFBQcwAYYdaHR0cDovL29jc3Auc2FudGFubmEubmV0L29jc3Aw
# NQYDVR0RBC4wLKAqBgorBgEEAYI3FAIDoBwMGmplcmVteS5hbHRtYW5Ac2FudGFu
# bmEubmV0MA0GCSqGSIb3DQEBCwUAA4ICAQBx1UXOLinilGQKFXR2r6TVdZHb67oP
# dtNGuioJg/GkVISbj/r+KffLKaHO8diNznIpfLeMFEHR5ewQO8gD9q9WlRhIcXG5
# tPBB02nokYpFn/hwdzDIsIZvZ5wUiZdoIp5yPTQYh/DwWmPbxPryefx4iAP8sLbz
# 2MZ56UQXjbe+cCPhw5duzOwvv4a3wQT23QxWPPFZtqEbtLRcZJd5JLKjgz+VQzx8
# QdlxtjO0xkT20XVIYYjCVX7/rHI6JgArNJAXkpZbMEnx0Si3iaG9OaWS9FgbqUsp
# jmyJRoS2DyC1X4zYQtxmj4ed9KaCXYkN/8kxeWUytW17vHOEjkNtsdoFJ5Hizxx8
# pR8fyQF6czc2ArHtytXS8266ywa/eeSvdT1VMje/tZEM10hH+SNWTgoPUwqOOL8Q
# 9e/fmOPTKPyGB/0bwjG1VqvVAQfligh79HAOhOctGg8QJEyC+ensxAxTOihHgjOq
# HK+i7h5QQZg4Hl68r5iJA9+ysYbJ7v+SUk/H4e4AFH7d+Zhvs8QAatw8N9VjGaXY
# aDQ/s419G2ncJiWaVzXTjB2s7l0kicifg7lGpK7BMiy0fqyAMqaGsuDZJSPK1Uyq
# CqwG2mGsfPsmc7bbwOEf9kWc03xXBKe/xpzqxKtL9ZgDLQy76nFy5wqEtlAl70BN
# 8ppw1RXcg+C11TGCBXAwggVsAgEBMG4wVzETMBEGCgmSJomT8ixkARkWA25ldDEY
# MBYGCgmSJomT8ixkARkWCHNhbnRhbm5hMSYwJAYDVQQDEx1TYW50YW5uYSBFbmVy
# Z3kgRW50ZXJwcmlzZSBDQQITXgAAAnEYIQUuPzecwAAAAAACcTANBglghkgBZQME
# AgEFAKCBhDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEM
# BgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqG
# SIb3DQEJBDEiBCA6mru4fLN5CI296in3uUz+dKKovxhxyUe8cXMh9z9bVjANBgkq
# hkiG9w0BAQEFAASCAQBoOW2VlVOQ1+RkiLljk2IEGE8Yz25zyGX6ycYpOwi9SL0K
# mdbtcx3ShKdh4JXdKuhmjNctZzhulSb4EZyavYEKqh5wvzd/EF1gDQVYbMCJI2x+
# KvFPprqeqKAOqL573+Yf/oZWRPsHdh06uZ79kGeoah4ExdXXlxsLa4J4FZu03JVc
# 1Cf9jx1i4Qc5bOER+Axnt7qA8K8AgEmzFMKpQ4BBhGayEKGPGccQBXFQeqKsEici
# fOe8WXLYPnDhZWSL2ltuoPtNRWJbD/qsNGCQTsSsZ5L6zQleh1OSA1vrx0GU/k7a
# AXZjmAJmqzkmDp2PIEX4ZrZ3kwaa9mW9tsRrYN9HoYIDTDCCA0gGCSqGSIb3DQEJ
# BjGCAzkwggM1AgEBMIGSMH0xCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVy
# IE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28g
# TGltaXRlZDElMCMGA1UEAxMcU2VjdGlnbyBSU0EgVGltZSBTdGFtcGluZyBDQQIR
# AIx3oACP9NGwxj2fOkiDjWswDQYJYIZIAWUDBAICBQCgeTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMjAzMjgyMjQwMjdaMD8GCSqG
# SIb3DQEJBDEyBDCCaLJU4FA8a0gdCyn+HVKLWh9GOZIrBotzC3nnrN8tB5cNAt8f
# sTmzlcE6HQEX/mUwDQYJKoZIhvcNAQEBBQAEggIACbSOdUoevfcYQflFqmVwAV3w
# VKALg5XOQ7BlT3kFQrWcsJGuulLFMSSef+ZAhvXBjS/8q+qnBAmbtFbIxfUd8/ZE
# ODN4jo1bxnkhP9PT1K17hU7KCmPcu0JA+kKX8gwWabqWRl40ect6x1M5ZGc3rOaO
# mxWAwQeBbmImcwke+Dab4+qfT/jxxYSvi094HTf67Ht1Fo+j8hNcVenc1ebuse6W
# ZdOxPqzgb60ALcLjH7s5GqoPmqmEg5WqU7wWN/OdSLMFif8PUj9zn40TBvHQPNWF
# Ch+0Yvs3Eyysk2OEIYa2iAHP5BK83OCgr+plZCtfeOMAR5uHDjFRtg1OPs2BBARt
# dOYRw0ESjYOAedWvr82FipQvR3Z05rxN03SD6ptPw2fe7pfdy1noyIGbaRE3BDNU
# NRyCxAe6f6DLAt9OXQFDsEEWtb2bdfmUrF3LUvAfqV121LNR9q42nIbPJi/ruNGc
# trsSebo/8HFAmA2AriEVYRJS//dEQjY061TC7wZRviREGyx3d3kkThFX9hXvkWNC
# C6nBLUERAl8F1PJSfSbvZiavahTJQj1e7ovc3o9EkCoKtE0W43U8FYZWfhiz5mqk
# VhKxvNANtyUrg09VgvWtUS6SKAyfYWD5KFiXnrUOyNY+Lhz+AhQFcX+Dc5joxv4g
# eAiExRBokN9+R9jO4r8=
# SIG # End signature block
