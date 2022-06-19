#Requires -Version 2.0

Param(
    [switch] $Override = $false
)

<#
.SYNOPSIS
                                      .
                                    .o8
    .oooo.o  .oooo.   ooo. .oo.   .o888oo  .oooo.   ooo. .oo.   ooo. .oo.    .oooo.
    d88(  "8 `P  )88b  `888P"Y88b    888   `P  )88b  `888P"Y88b  `888P"Y88b  `P  )88b
    `"Y88b.   .oP"888   888   888    888    .oP"888   888   888   888   888   .oP"888
    o.  )88b d8(  888   888   888    888 . d8(  888   888   888   888   888  d8(  888
    8""888P' `Y888""8o o888o o888o   "888" `Y888""8o o888o o888o o888o o888o `Y888""8o


.DESCRIPTION
This script will update this computer's computer object in Active Directory with the computer's model and serial numbers.
The script will post the following information to the following Active Directory attributes:
    · Computer Model Number (comment)
    · Serial Number (serialNumber)
    · User's Display Name · Model Number · Serial Number (description)
    * It will also update the computer infomation text in system properties

.EXAMPLE
Just run this script without any parameters in the users context, typically run via a group policy login script.

.NOTES
NAME: Update-ADComputerDescription.ps1
VERSION: 220526
AUTHOR: Jeremy Altman <jeremy.altman@santanna.net>
#>

Import-Module -Name Storage

$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
If ($osInfo.ProductType -ne 1) {
    Write-Host "Warning: Script is running on a server." -ForegroundColor Red
    Break
}

Clear-Host
$wqlQuery = "Select IdentifyingNumber,Name,SKUNumber,UUID,Vendor,Version from Win32_ComputerSystemProduct"
$totalMemory = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum /1GB
#$totalMemory = [math]::round((Get-CimInstance -ClassName Win32_ComputerSystem).totalphysicalmemory /1GB)
#$totalMemory = (Get-CimInstance -ClassName Win32_PhysicalMemory -Property Capacity).Capacity/1GB
$totalDiskSpace = [math]::round((Get-Disk -Number 0).Size/1000000000)

$wqlObjectSet = Get-WmiObject -namespace "ROOT\CIMV2"  -Impersonation 3  -Query $wqlQuery
if ($null -eq $wqlObjectSet) {
    Write-Host "WMI Object not found..." -ForegroundColor Red
    return;
}

if (@($wqlObjectSet).Count -gt 0) {
    foreach ($objWMIClass in $wqlObjectSet) {
        If ($objWMIClass.Vendor -eq "LENOVO") {
            $model = $objWMIClass.Version
        }
        Else {
            $model = $objWMIClass.Name
        }

        $searcher = new-object System.DirectoryServices.DirectorySearcher
        $searcher.filter = "(&(ObjectClass=computer)(Name=$env:computername))"
        $find = $searcher.FindOne()
        $thispc = $find.GetDirectoryEntry()

        $searcher.filter = "(&(ObjectClass=user)(samAccountName=$env:username))"
        $find = $searcher.FindOne()
        $me = $find.GetDirectoryEntry()

        $NewADComputerInfoDescription = "$($me.DisplayName) · $($model.Trim()) · $($objWMIClass.IdentifyingNumber.Trim()) [$($totalMemory)G/$($totalDiskSpace)G]"

        Write-Host "

          d888888o.           .8.          b.             8 8888888 8888888888   .8.          b.             8 b.             8          .8.
        .``8888:' ``88.        .888.         888o.          8       8 8888        .888.         888o.          8 888o.          8         .888.
        8.``8888.   Y8       :88888.        Y88888o.       8       8 8888       :88888.        Y88888o.       8 Y88888o.       8        :88888.
        ``8.``8888.          . ``88888.       .``Y888888o.    8       8 8888      . ``88888.       .``Y888888o.    8 .``Y888888o.    8       . ``88888.
         ``8.``8888.        .8. ``88888.      8o. ``Y888888o. 8       8 8888     .8. ``88888.      8o. ``Y888888o. 8 8o. ``Y888888o. 8      .8. ``88888.
          ``8.``8888.      .8``8. ``88888.     8``Y8o. ``Y88888o8       8 8888    .8``8. ``88888.     8``Y8o. ``Y88888o8 8``Y8o. ``Y88888o8     .8``8. ``88888.
           ``8.``8888.    .8' ``8. ``88888.    8   ``Y8o. ``Y8888       8 8888   .8' ``8. ``88888.    8   ``Y8o. ``Y8888 8   ``Y8o. ``Y8888    .8' ``8. ``88888.
       8b   ``8.``8888.  .8'   ``8. ``88888.   8      ``Y8o. ``Y8       8 8888  .8'   ``8. ``88888.   8      ``Y8o. ``Y8 8      ``Y8o. ``Y8   .8'   ``8. ``88888.
       ``8b.  ;8.``8888 .888888888. ``88888.  8         ``Y8o.``       8 8888 .888888888. ``88888.  8         ``Y8o.`` 8         ``Y8o.``  .888888888. ``88888.
        ``Y8888P ,88P'.8'       ``8. ``88888. 8            ``Yo       8 8888.8'       ``8. ``88888. 8            ``Yo 8            ``Yo .8'       ``8. ``88888.
     " -ForegroundColor Blue
        Write-Host "     ------------------------------------------------------------------------------------------------------------------------------------------------`n" -ForegroundColor White
        Write-Host "     S  A  N  T  A  N  N  A      E  N  E  R  G  Y      S  E  R  V  I  C  E  S   ·   I  N  F  O  R  M  A  T  I  O  N      T  E  C  H  N  O  L  O  G  Y`n" -ForegroundColor Blue
        Write-Host "     ------------------------------------------------------------------------------------------------------------------------------------------------`n" -ForegroundColor White
        Write-Host "              Current User: ......  " -NoNewline -ForegroundColor Gray
        Write-Host $($me.DisplayName) -ForegroundColor White
        Write-Host "              Username: ..........  " -NoNewline -ForegroundColor Gray
        Write-Host $env:USERDOMAIN\$env:USERNAME -ForegroundColor White
        Write-Host "              Computer Name: .....  " -NoNewline -ForegroundColor Gray
        Write-Host $env:COMPUTERNAME"."$env:USERDNSDOMAIN -ForegroundColor White
        Write-Host "              Logon Server: ......  " -NoNewline -ForegroundColor Gray
        Write-Host $env:LOGONSERVER -ForegroundColor White
        Write-Host "              PC Vendor: .........  " -NoNewline -ForegroundColor Gray
        Write-Host $objWMIClass.Vendor -ForegroundColor White
        Write-Host "              PC Model: ..........  " -NoNewline -ForegroundColor Gray
        Write-Host $model.Trim() -ForegroundColor White
        Write-Host "              PC Serial Number: ..  " -NoNewline -ForegroundColor Gray
        Write-Host $objWMIClass.IdentifyingNumber.Trim() -ForegroundColor White
        Write-Host "              Total Memory: ......  " -NoNewline -ForegroundColor Gray
        Write-Host "$($totalMemory) GB" -ForegroundColor White
        Write-Host "              Total Disk Space: ..  " -NoNewline -ForegroundColor Gray
        Write-Host "$($totalDiskSpace) GB" -ForegroundColor White
        Write-Host "              Description: .......  " -NoNewline -ForegroundColor Gray
        Write-Host $NewADComputerInfoDescription
        Write-Host "              UUID: ..............  " -NoNewline -ForegroundColor Gray
        Write-Host $objWMIClass.UUID -ForegroundColor White
        Write-Host "`n" -ForegroundColor White

        if ((([adsisearcher]"(samaccountname=$env:USERNAME)").FindOne().Properties.memberof -match "CN=Domain Admins,CN=Users,DC=santanna,DC=net") -and ($Override -eq $false)) {
            Write-Host "Warning: Script was invoked under the context of a member of the Domain Admin group. Values have not been updated in Active Directory!" -ForegroundColor Red
            Write-Host "Please rerun this script with the" -NoNewline -ForegroundColor DarkRed
            Write-Host " -Override " -NoNewline -ForegroundColor Gray
            Write-Host "parameter if you wish to bypass this limitation and update the AD object: $($env:COMPUTERNAME).`n" -ForegroundColor DarkRed
        }
        else {
            $thispc.InvokeSet("ManagedBy", $($me.DistinguishedName))
            $thispc.InvokeSet("serialNumber", $objWMIClass.IdentifyingNumber.Trim())
            $thispc.InvokeSet("info", $model.Trim())
            $thispc.InvokeSet("Description", $NewADComputerInfoDescription)
            $thispc.SetInfo()

            $computerDescription = "$($model.Trim()) · $($objWMIClass.IdentifyingNumber.Trim()) · Property of Santanna Energy Services"
            $registryPath = "HKLM:\System\CurrentControlSet\Services\lanmanserver\Parameters"
            $registryKeyName = "srvcomment"
            New-ItemProperty -Path $registryPath -Name $registryKeyName -Value $computerDescription -PropertyType String -Force | Out-Null
        }
    }
}
else {
    Write-Host "Error querying WMI object." -ForegroundColor Red
}




# SIG # Begin signature block
# MIIcSQYJKoZIhvcNAQcCoIIcOjCCHDYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCmEOOz3IpkqTAv
# nrqkA3g7v4NMrB70JuUShvZqXd6FDaCCFi8wggbsMIIE1KADAgECAhAwD2+s3WaY
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
# Aoa6Ke60WgCxjKvj+QrJVF3UuWp0nr1Irpgwggb2MIIE3qADAgECAhEAkDl/mtJK
# OhPyvZFfCDipQzANBgkqhkiG9w0BAQwFADB9MQswCQYDVQQGEwJHQjEbMBkGA1UE
# CBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQK
# Ew9TZWN0aWdvIExpbWl0ZWQxJTAjBgNVBAMTHFNlY3RpZ28gUlNBIFRpbWUgU3Rh
# bXBpbmcgQ0EwHhcNMjIwNTExMDAwMDAwWhcNMzMwODEwMjM1OTU5WjBqMQswCQYD
# VQQGEwJHQjETMBEGA1UECBMKTWFuY2hlc3RlcjEYMBYGA1UEChMPU2VjdGlnbyBM
# aW1pdGVkMSwwKgYDVQQDDCNTZWN0aWdvIFJTQSBUaW1lIFN0YW1waW5nIFNpZ25l
# ciAjMzCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAJCycT954dS5ihfM
# w5fCkJRy7Vo6bwFDf3NaKJ8kfKA1QAb6lK8KoYO2E+RLFQZeaoogNHF7uyWtP1sK
# pB8vbH0uYVHQjFk3PqZd8R5dgLbYH2DjzRJqiB/G/hjLk0NWesfOA9YAZChWIrFL
# GdLwlslEHzldnLCW7VpJjX5y5ENrf8mgP2xKrdUAT70KuIPFvZgsB3YBcEXew/BC
# aer/JswDRB8WKOFqdLacRfq2Os6U0R+9jGWq/fzDPOgNnDhm1fx9HptZjJFaQldV
# UBYNS3Ry7qAqMfwmAjT5ZBtZ/eM61Oi4QSl0AT8N4BN3KxE8+z3N0Ofhl1tV9yoD
# bdXNYtrOnB786nB95n1LaM5aKWHToFwls6UnaKNY/fUta8pfZMdrKAzarHhB3pLv
# D8Xsq98tbxpUUWwzs41ZYOff6Bcio3lBYs/8e/OS2q7gPE8PWsxu3x+8Iq+3OBCa
# NKcL//4dXqTz7hY4Kz+sdpRBnWQd+oD9AOH++DrUw167aU1ymeXxMi1R+mGtTeom
# jm38qUiYPvJGDWmxt270BdtBBcYYwFDk+K3+rGNhR5G8RrVGU2zF9OGGJ5OEOWx1
# 4B0MelmLLsv0ZCxCR/RUWIU35cdpp9Ili5a/xq3gvbE39x/fQnuq6xzp6z1a3fjS
# kNVJmjodgxpXfxwBws4cfcz7lhXFAgMBAAGjggGCMIIBfjAfBgNVHSMEGDAWgBQa
# ofhhGSAPw0F3RSiO0TVfBhIEVTAdBgNVHQ4EFgQUJS5oPGuaKyQUqR+i3yY6zxSm
# 8eAwDgYDVR0PAQH/BAQDAgbAMAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYI
# KwYBBQUHAwgwSgYDVR0gBEMwQTA1BgwrBgEEAbIxAQIBAwgwJTAjBggrBgEFBQcC
# ARYXaHR0cHM6Ly9zZWN0aWdvLmNvbS9DUFMwCAYGZ4EMAQQCMEQGA1UdHwQ9MDsw
# OaA3oDWGM2h0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1JTQVRpbWVTdGFt
# cGluZ0NBLmNybDB0BggrBgEFBQcBAQRoMGYwPwYIKwYBBQUHMAKGM2h0dHA6Ly9j
# cnQuc2VjdGlnby5jb20vU2VjdGlnb1JTQVRpbWVTdGFtcGluZ0NBLmNydDAjBggr
# BgEFBQcwAYYXaHR0cDovL29jc3Auc2VjdGlnby5jb20wDQYJKoZIhvcNAQEMBQAD
# ggIBAHPa7Whyy8K5QKExu7QDoy0UeyTntFsVfajp/a3Rkg18PTagadnzmjDarGnW
# dFckP34PPNn1w3klbCbojWiTzvF3iTl/qAQF2jTDFOqfCFSr/8R+lmwr05TrtGzg
# RU0ssvc7O1q1wfvXiXVtmHJy9vcHKPPTstDrGb4VLHjvzUWgAOT4BHa7V8WQvndU
# kHSeC09NxKoTj5evATUry5sReOny+YkEPE7jghJi67REDHVBwg80uIidyCLxE2rb
# GC9ueK3EBbTohAiTB/l9g/5omDTkd+WxzoyUbNsDbSgFR36bLvBk+9ukAzEQfBr7
# PBmA0QtwuVVfR745ZM632iNUMuNGsjLY0imGyRVdgJWvAvu00S6dOHw14A8c7RtH
# SJwialWC2fK6CGUD5fEp80iKCQFMpnnyorYamZTrlyjhvn0boXztVoCm9CIzkOSE
# U/wq+sCnl6jqtY16zuTgS6Ezqwt2oNVpFreOZr9f+h/EqH+noUgUkQ2C/L1Nme3J
# 5mw2/ndDmbhpLXxhL+2jsEn+W75pJJH/k/xXaZJL2QU/bYZy06LQwGTSOkLBGgP7
# 0O2aIbg/r6ayUVTVTMXKHxKNV8Y57Vz/7J8mdq1kZmfoqjDg0q23fbFqQSduA4qj
# dOCKCYJuv+P2t7yeCykYaIGhnD9uFllLFAkJmuauv2AV3Yb1MIIIQTCCBimgAwIB
# AgITXgAAAnEYIQUuPzecwAAAAAACcTANBgkqhkiG9w0BAQsFADBXMRMwEQYKCZIm
# iZPyLGQBGRYDbmV0MRgwFgYKCZImiZPyLGQBGRYIc2FudGFubmExJjAkBgNVBAMT
# HVNhbnRhbm5hIEVuZXJneSBFbnRlcnByaXNlIENBMB4XDTIyMDIyMTA1MTM0N1oX
# DTI0MDIyMTA1MjM0N1owgbgxEzARBgoJkiaJk/IsZAEZFgNuZXQxGDAWBgoJkiaJ
# k/IsZAEZFghzYW50YW5uYTERMA8GA1UECxMIQWNjb3VudHMxEDAOBgNVBAsTB01h
# bmFnZWQxHzAdBgNVBAsTFkluZm9ybWF0aW9uIFRlY2hub2xvZ3kxFjAUBgNVBAMT
# DUplcmVteSBBbHRtYW4xKTAnBgkqhkiG9w0BCQEWGmplcmVteS5hbHRtYW5Ac2Fu
# dGFubmEubmV0MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv5GDFsPs
# n//DHga9kldV/7rxyyYyjPXeqW2OIXNB4fKOnx6R7+cNIJg3tgNLzRnEXS/onEpz
# sl1cjpjY8GNw30E4g1Dddqx+1L3BJ2DpgX0HXsESUjydHeMpbRaB7u+nMGay/Nn6
# kjGZr/bwSiZEZZayKQmJRQR0sIPflbcz2WZsNOwYXYwLqfO0EylCImv+OELjKBG6
# rxJ/nTsqBqVULTSu2TuFj8vML6PbLmh2aQL7EJUjVlOqZUaKpC76xGQ61cXraDOG
# qlIBiwDDnM0qKPnx6W1apDaMod+esWuZWoFXD6fNv0LjxdDqCWQxVJ4oE/BYFpYV
# j53dp0wo/BzxvQIDAQABo4IDojCCA54wPgYJKwYBBAGCNxUHBDEwLwYnKwYBBAGC
# NxUIh8nVfoXVgDCGrZU9hNqOcoTlwzeBcYWw8gCG5d8WAgFlAgECMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMA4GA1UdDwEB/wQEAwIHgDAbBgkrBgEEAYI3FQoEDjAMMAoG
# CCsGAQUFBwMDMB0GA1UdDgQWBBRDRcql5cs2bJNni3qriVt9zetaajAfBgNVHSME
# GDAWgBTQ0fdPnYbVp81TMoe0aEb6lSF5sTCCATAGA1UdHwSCAScwggEjMIIBH6CC
# ARugggEXhoHKbGRhcDovLy9DTj1TYW50YW5uYSUyMEVuZXJneSUyMEVudGVycHJp
# c2UlMjBDQSxDTj1DUllQVE8sQ049Q0RQLENOPVB1YmxpYyUyMEtleSUyMFNlcnZp
# Y2VzLENOPVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9c2FudGFubmEsREM9
# bmV0P2NlcnRpZmljYXRlUmV2b2NhdGlvbkxpc3Q/YmFzZT9vYmplY3RDbGFzcz1j
# UkxEaXN0cmlidXRpb25Qb2ludIZIaHR0cDovL3BraS5zYW50YW5uYS5uZXQvQ2Vy
# dERhdGEvU2FudGFubmElMjBFbmVyZ3klMjBFbnRlcnByaXNlJTIwQ0EuY3JsMIIB
# bQYIKwYBBQUHAQEEggFfMIIBWzCBwwYIKwYBBQUHMAKGgbZsZGFwOi8vL0NOPVNh
# bnRhbm5hJTIwRW5lcmd5JTIwRW50ZXJwcmlzZSUyMENBLENOPUFJQSxDTj1QdWJs
# aWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9u
# LERDPXNhbnRhbm5hLERDPW5ldD9jQUNlcnRpZmljYXRlP2Jhc2U/b2JqZWN0Q2xh
# c3M9Y2VydGlmaWNhdGlvbkF1dGhvcml0eTBoBggrBgEFBQcwAoZcaHR0cDovL3Br
# aS5zYW50YW5uYS5uZXQvQ2VydERhdGEvQ1JZUFRPLnNhbnRhbm5hLm5ldF9TYW50
# YW5uYSUyMEVuZXJneSUyMEVudGVycHJpc2UlMjBDQS5jcnQwKQYIKwYBBQUHMAGG
# HWh0dHA6Ly9vY3NwLnNhbnRhbm5hLm5ldC9vY3NwMDUGA1UdEQQuMCygKgYKKwYB
# BAGCNxQCA6AcDBpqZXJlbXkuYWx0bWFuQHNhbnRhbm5hLm5ldDANBgkqhkiG9w0B
# AQsFAAOCAgEAcdVFzi4p4pRkChV0dq+k1XWR2+u6D3bTRroqCYPxpFSEm4/6/in3
# yymhzvHYjc5yKXy3jBRB0eXsEDvIA/avVpUYSHFxubTwQdNp6JGKRZ/4cHcwyLCG
# b2ecFImXaCKecj00GIfw8Fpj28T68nn8eIgD/LC289jGeelEF423vnAj4cOXbszs
# L7+Gt8EE9t0MVjzxWbahG7S0XGSXeSSyo4M/lUM8fEHZcbYztMZE9tF1SGGIwlV+
# /6xyOiYAKzSQF5KWWzBJ8dEot4mhvTmlkvRYG6lLKY5siUaEtg8gtV+M2ELcZo+H
# nfSmgl2JDf/JMXllMrVte7xzhI5DbbHaBSeR4s8cfKUfH8kBenM3NgKx7crV0vNu
# ussGv3nkr3U9VTI3v7WRDNdIR/kjVk4KD1MKjji/EPXv35jj0yj8hgf9G8IxtVar
# 1QEH5YoIe/RwDoTnLRoPECRMgvnp7MQMUzooR4Izqhyvou4eUEGYOB5evK+YiQPf
# srGGye7/klJPx+HuABR+3fmYb7PEAGrcPDfVYxml2Gg0P7ONfRtp3CYlmlc104wd
# rO5dJInIn4O5RqSuwTIstH6sgDKmhrLg2SUjytVMqgqsBtphrHz7JnO228DhH/ZF
# nNN8VwSnv8ac6sSrS/WYAy0Mu+pxcucKhLZQJe9ATfKacNUV3IPgtdUxggVwMIIF
# bAIBATBuMFcxEzARBgoJkiaJk/IsZAEZFgNuZXQxGDAWBgoJkiaJk/IsZAEZFghz
# YW50YW5uYTEmMCQGA1UEAxMdU2FudGFubmEgRW5lcmd5IEVudGVycHJpc2UgQ0EC
# E14AAAJxGCEFLj83nMAAAAAAAnEwDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGC
# NwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgJcTw8tvp
# J8kGt3VRpAEVO5x2jD4afpRXTVbnVRoxzyEwDQYJKoZIhvcNAQEBBQAEggEAMkuN
# 1UbFb2JFRw3lwHBXKbahYOQAhEZmpBCSUaEOF+88ADJaL8+WJ928hGd7kx6HZeR2
# 4yWUd4SNWd4/PBH3P7x0Y75LH1EbaBTcUdCwLSp5ziJpNz2BDjaJNvE32vClqukz
# I/qaeNdtVKscWZnnXgILyjz08RKd3s1FHJlz0vViwOgpFjYW9ojDAkRuxexKiKPj
# BBlpgQvokChRTBRCIkUbYrQf9wHlQVR8JL4oaNd6M3H+xkl8U00A+y2OBHxAH5wi
# 5yGodoly0f+4nIl5iwwxu9ZBDy5y7Da/LaS3zNZTbJXfl5pg4fqkfyKIix80ww/D
# 370gIgQMu6eXJTNc/KGCA0wwggNIBgkqhkiG9w0BCQYxggM5MIIDNQIBATCBkjB9
# MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYD
# VQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJTAjBgNVBAMT
# HFNlY3RpZ28gUlNBIFRpbWUgU3RhbXBpbmcgQ0ECEQCQOX+a0ko6E/K9kV8IOKlD
# MA0GCWCGSAFlAwQCAgUAoHkwGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkq
# hkiG9w0BCQUxDxcNMjIwNjE3MTAyODIwWjA/BgkqhkiG9w0BCQQxMgQwTbizI4K9
# CUBBGiafZp5v6EtpdohKhfA46xmx2FUiIcU3pM/Cmle/UVmLvoO45BltMA0GCSqG
# SIb3DQEBAQUABIICAEqSfplXFUQmRCcabWpP/sId9xXLrvUZ/lSPIyGyc/iS2DtR
# TKF1CUdmTZc4LCUezJWM/0DRxNAkPYGXX/ckE5aFitpEj8iix0mNluCmS2yWL0eY
# PqHUt62OX31jVjGAwpvXmXX/oQW1BPIYb4EaQvKiDTuhHnLsmHoGgAb6E35rF/Tl
# /fgRk0eCAoPvwTEUtMBA/Hv19Fb14a1yoAHBabTuERXLYL0TSLSxP+ENuwxKuIr4
# qLQ7Iic7iSYY/Gs4HLjA+zpDc4K6bfmV6awYWdo1NKeQJ9XimJa0CqsFtCU3DvKM
# 5X5C+YjU5/+UIGL4gvK28K+BgxT0M6kOYWVV/5zZfTlJDfVqE7POwftqXZ19t/X5
# oy41aa2hYmfJ+L/mJIhl3YgzHNt4c7kiJdGckBQylG9bhpsT6mvNGbm+KEBvikMn
# XGhsODFELT5TUy8Y2D2GBW49XyuVcHQd0wupF1mPHMgUTQMJT8VwnhPnhfwmU41K
# uq1ajpiYWe4uF1RvJVtnURr6igNPjevu4nK66Ta2ALZoq53iMzInIZEr3iCss+jJ
# BSdUzxLOT8Ibq7QN1Dn9mmXzLwQGs5XpddWpYjsoPGS7iw6feoNGXnYy+fVDURJG
# is7QHZxEj/Pdk9P3kzyHVR7i4nmPyZ1FN959uUvPabWtqjZx8KdtGmjTt+6O
# SIG # End signature block
