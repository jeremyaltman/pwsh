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
AUTHOR: Jeremy Altman
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

        Write-Host "Current User: ......  " -NoNewline -ForegroundColor Gray
        Write-Host $($me.DisplayName) -ForegroundColor White
        Write-Host "Username: ..........  " -NoNewline -ForegroundColor Gray
        Write-Host $env:USERDOMAIN\$env:USERNAME -ForegroundColor White
        Write-Host "Computer Name: .....  " -NoNewline -ForegroundColor Gray
        Write-Host $env:COMPUTERNAME"."$env:USERDNSDOMAIN -ForegroundColor White
        Write-Host "Logon Server: ......  " -NoNewline -ForegroundColor Gray
        Write-Host $env:LOGONSERVER -ForegroundColor White
        Write-Host "PC Vendor: .........  " -NoNewline -ForegroundColor Gray
        Write-Host $objWMIClass.Vendor -ForegroundColor White
        Write-Host "PC Model: ..........  " -NoNewline -ForegroundColor Gray
        Write-Host $model.Trim() -ForegroundColor White
        Write-Host "PC Serial Number: ..  " -NoNewline -ForegroundColor Gray
        Write-Host $objWMIClass.IdentifyingNumber.Trim() -ForegroundColor White
        Write-Host "Total Memory: ......  " -NoNewline -ForegroundColor Gray
        Write-Host "$($totalMemory) GB" -ForegroundColor White
        Write-Host "Total Disk Space: ..  " -NoNewline -ForegroundColor Gray
        Write-Host "$($totalDiskSpace) GB" -ForegroundColor White
        Write-Host "Description: .......  " -NoNewline -ForegroundColor Gray
        Write-Host $NewADComputerInfoDescription
        Write-Host "UUID: ..............  " -NoNewline -ForegroundColor Gray
        Write-Host $objWMIClass.UUID -ForegroundColor White
        Write-Host "`n" -ForegroundColor White

        if ((([adsisearcher]"(samaccountname=$env:USERNAME)").FindOne().Properties.memberof -match "CN=Domain Admins,CN=Users,DC=contoso,DC=com") -and ($Override -eq $false)) {
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