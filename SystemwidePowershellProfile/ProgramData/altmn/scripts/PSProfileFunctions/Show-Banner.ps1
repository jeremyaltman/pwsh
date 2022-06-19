# This script is inspired by and uses code butchered from a now defunct module named OhMyPsh
# There are PLENTY of opportunities to vastly optimize this code to be more efficient, but it
# was easier to just grab parts of OhMyPsh and cobble them together to get this to work for my needs.

# v2108.11: Jeremy Altman
# Massive kudos to Zachary Loeber for the inspiration and code ripped from https://github.com/zloeber/OhMyPsh


Function Test-OMPConsoleHasANSI {
    <#
    .EXTERNALHELP OhMyPsh-help.xml
    .LINK
        https://github.com/zloeber/OhMyPsh/tree/master/release/0.0.7/docs/Functions/Test-OMPConsoleHasANSI.md
    #>

    # Powershell ISE don't support ANSI, and this test will print ugly chars
    if (!($null -eq $host.PrivateData)) {
        if($host.PrivateData.ToString() -eq 'Microsoft.PowerShell.Host.ISE.ISEOptions') {
            return $false
        }
    }

    # To test is console supports ANSI, we will print an ANSI code
    # and check if cursor postion has changed. If it has, ANSI is not
    # supported
    $oldPos = $host.UI.RawUI.CursorPosition.X

    Write-Host -NoNewline "$([char](27))[0m" -ForegroundColor ($host.UI.RawUI.BackgroundColor);

    $pos = $host.UI.RawUI.CursorPosition.X

    if($pos -eq $oldPos) {
        return $true
    }
    else {
        # If ANSI is not supported, let's clean up ugly ANSI escapes
        Write-Host -NoNewLine ("`b" * 4)
        return $false
    }
}

function GET-OMPOSPlatform {
    <#
    .EXTERNALHELP OhMyPsh-help.xml
    .LINK
        https://github.com/zloeber/OhMyPsh/tree/master/release/0.0.7/docs/Functions/Get-OMPOSPlatform.md
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [Switch]$IncludeLinuxDetails
    )
    begin {
        if ($script:ThisModuleLoaded -eq $true) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    }
    process {}
    end {
        #$ThisIsCoreCLR = if ($IsCoreCLR) {$True} else {$False}
        $ThisIsLinux = if ($IsLinux) {$True} else {$False} #$Runtime::IsOSPlatform($OSPlatform::Linux)
        $ThisIsOSX = if ($IsOSX) {$True} else {$False} #$Runtime::IsOSPlatform($OSPlatform::OSX)
        $ThisIsWindows = if ($IsWindows) {$True} else {$False} #$Runtime::IsOSPlatform($OSPlatform::Windows)

        if (-not ($ThisIsLinux -or $ThisIsOSX)) {
            $ThisIsWindows = $true
        }

        if ($ThisIsLinux) {
            if ($IncludeLinuxDetails) {
                $LinuxInfo = Get-Content /etc/os-release | ConvertFrom-StringData
                $IsUbuntu = $LinuxInfo.ID -match 'ubuntu'
                if ($IsUbuntu -and $LinuxInfo.VERSION_ID -match '14.04') {
                    return 'Ubuntu 14.04'
                }
                if ($IsUbuntu -and $LinuxInfo.VERSION_ID -match '16.04') {
                    return 'Ubuntu 16.04'
                }
                if ($LinuxInfo.ID -match 'centos' -and $LinuxInfo.VERSION_ID -match '7') {
                    return 'CentOS'
                }
            }
            return 'Linux'
        }
        elseif ($ThisIsOSX) {
            return 'OSX'
        }
        elseif ($ThisIsWindows) {
            return 'Windows'
        }
        else {
            return 'Unknown'
        }
        Write-Verbose "$($FunctionName): End."
    }
}

function Get-OMPIPAddress {
    <#
    .EXTERNALHELP OhMyPsh-help.xml
    .LINK
        https://github.com/zloeber/OhMyPsh/tree/master/release/0.0.7/docs/Functions/Get-OMPIPAddress.md
    #>
    [CmdletBinding()]
    param(
    )
    begin {
        if ($script:ThisModuleLoaded -eq $true) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    }
    process {
    }
    end {
        # Retreive IP address informaton from dot net core only functions (should run on both linux and windows properly)
         # Retreive IP address informaton from dot net core only functions (should run on both linux and windows properly)
         $TAPAdapterIndex = (Get-NetAdapter -InterfaceDescription "TAP-Windows Adapter V9" -ErrorAction SilentlyContinue).ifIndex
         $NetworkAddresses = Get-NetIPAddress -AddressFamily IPv4 -Type Unicast -ErrorAction SilentlyContinue | Where-Object { ($_.InterfaceIndex -ne $TAPAdapterIndex) -and ($_.IPAddress -notlike '127.*') -and ($_.IPAddress -notlike '169.*') }
         #$NetworkInterfaces = @([System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | Where-Object {($_.OperationalStatus -eq 'Up')})
         #$NetworkInterfaces | Foreach-Object {
         $NetworkAddresses | Foreach-Object {
             New-Object PSObject -Property @{
                 IP     = $_.IPAddress
                 Prefix = $_.PrefixLength
             }
        }
        Write-Verbose "$($FunctionName): End."
    }
}

function Get-VpnIPAddress {
    [CmdletBinding()]
    param(
    )
    begin {
        if ($script:ThisModuleLoaded -eq $true) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    }
    process {
    }
    end {
        $TAPAdapter = Get-NetAdapter -InterfaceDescription "TAP-Windows Adapter V9" -ErrorAction SilentlyContinue
        if (!($null -eq $TAPAdapter)){
            $TAPAdapterIndex = $TAPAdapter.ifIndex
            (Get-NetIPAddress -PrefixOrigin Dhcp -AddressFamily IPv4 -InterfaceIndex $TAPAdapterIndex -ErrorAction SilentlyContinue).IPAddress
        }
        Write-Verbose "$($FunctionName): End."
    }
}

function Get-OMPSystemUpTime {
    <#
    .EXTERNALHELP OhMyPsh-help.xml
    .LINK
        https://github.com/zloeber/OhMyPsh/tree/master/release/0.0.7/docs/Functions/Get-OMPSystemUpTime.md
    #>

    [CmdletBinding()]
    param(
        [switch]$FromSleep
    )
    begin {
        if ($script:ThisModuleLoaded -eq $true) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
        function Test-EventLogSource {
            param(
                [Parameter(Mandatory = $true)]
                [string] $SourceName
            )
            try {
                [System.Diagnostics.EventLog]::SourceExists($SourceName)
            }
            catch {
                $false
            }
        }
    }
    process {}
    end {
        switch ( Get-OMPOSPlatform -ErrorVariable null ) {
            'Linux' {
                # Add me!
            }
            'OSX' {
                # Add me!
            }
            Default {
                if (-not $FromSleep) {
                    #$os = Get-WmiObject win32_OperatingSystem 
                    #$uptime = (Get-Date) - [Management.ManagementDateTimeConverter]::ToDateTime($os.lastbootuptime)
                    $uptime = (Get-Date) - (Get-CimInstance -ClassName CIM_OperatingSystem).LastBootUpTime
                }
                elseif (Test-EventLogSource 'Microsoft-Windows-Power-Troubleshooter') {
                    try {
                        $LastPowerEvent = (Get-EventLog -LogName system -Source 'Microsoft-Windows-Power-Troubleshooter' -Newest 1 -ErrorAction:Stop).TimeGenerated
                    }
                    catch {
                        $error.Clear()
                    }
                    if ($null -ne $LastPowerEvent) {
                        $Uptime = ( (Get-Date) - $LastPowerEvent )
                    }
                }
                if ($null -ne $Uptime) {
                    $Display = "" + $Uptime.Days + " days / " + $Uptime.Hours + " hours / " + $Uptime.Minutes + " minutes"
                    Write-Output $Display
                }
            }
        }
        Write-Verbose "$($FunctionName): End."
    }
}

function Test-OMPIsElevated {
    <#
    .EXTERNALHELP OhMyPsh-help.xml
    .LINK
        https://github.com/zloeber/OhMyPsh/tree/master/release/0.0.7/docs/Functions/Test-OMPIsElevated.md
    #>

    [CmdletBinding()]
    param(
    )
    begin {
        if ($script:ThisModuleLoaded -eq $true) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    }
    process {
    }
    end {
        switch ( Get-OMPOSPlatform -ErrorVariable null ) {
            'Linux' {
                # Add me!
            }
            'OSX' {
                # Add me!
            }
            Default {
                if (([System.Environment]::OSVersion.Version.Major -gt 5) -and ((New-object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
                    return $true
                }
                else {
                    return $false
                }
            }
        }
        Write-Verbose "$($FunctionName): End."
    }
}

function Global:Write-SessionBannerToHost {
    [CmdletBinding()]
    param(
        [int]$Spacer = 1,
        [switch]$AttemptAutoFit
    )
    Begin {
        $HasANSI = if (Test-OMPConsoleHasANSI) {$true} else {$false}
        $Spaces = (' ' * $Spacer)
        $OSPlatform = Get-OMPOSPlatform -ErrorVariable null

        if ($AttemptAutoFit) {
            try {
                $IP = @(Get-OMPIPAddress)[0]
                if ([string]::isnullorempty($IP)) {
                    $IPAddress = 'IP: Offline'
                }
                else {
                    $IPAddress = "IP: $(@($IP.IP)[0])/$($IP.Prefix)"
                }
                if ([string]::isnullorempty($VPN)) {
                    $VpnIPAddress = 'VPN: Offline'
                }
                else {
                    $VpnIPAddress = "VPN: $(@($VPN.IPAddress)[0])"
                }
            }
            catch {
                $IPAddress = 'IP: NA'
                $VpnIPAddress = 'VPN: NA'
            }

            $PSExecPolicy = "Exec Pol: $(Get-ExecutionPolicy)"
            $PSVersion = "PS Ver: $($PSVersionTable.PSVersion.Major)"
            $CompName = "Computer: $($env:COMPUTERNAME)"
            $UserDomain = "Domain: $($env:UserDomain)"
            $LogonServer = "Logon Sever: $($env:LOGONSERVER -replace '\\')"
            $UserName = "User: $($env:UserName)"
            $UptimeBoot = "Uptime (hardware boot): $(Get-OMPSystemUptime)"
            $UptimeResume = Get-OMPSystemUptime -FromSleep
            if ($UptimeResume) {
                $UptimeResume = "Uptime (system resume): $($UptimeResume)"
            }
        }
        else {
            # Collect all the banner data
            try {
                $IP = @(Get-OMPIPAddress)[0]
                if ([string]::isnullorempty($IP)) {
                    $IPAddress = 'Offline'
                }
                else {
                    $IPAddress = "$(@($IP.IP)[0])/$($IP.Prefix)"
                }
            }
            catch {
                $IPAddress = 'NA'
            }

            try {
                $VPN = Get-VpnIPAddress
                if ([string]::isnullorempty($VPN)) {
                    $VpnIPAddress = 'Offline'
                }
                else {
                    $VpnIPAddress = "$VPN"
                }
            }
            catch {
                $VpnIPAddress = 'NA'
            }

            $OSPlatform = Get-OMPOSPlatform -ErrorVariable null
            $PSExecPolicy = Get-ExecutionPolicy
            $PSVersion = $PSVersionTable.PSVersion.Major
            $CompName = $env:COMPUTERNAME
            $UserDomain = $env:UserDomain
            $LogonServer = $env:LOGONSERVER -replace '\\'
            $UserName = $env:UserName
            $UptimeBoot = Get-OMPSystemUptime
            $UptimeResume = Get-OMPSystemUptime -FromSleep
        }

        $PSProcessElevated = 'TRUE'
        if ($OSPlatform -eq 'Windows') {
            if (Test-OMPIsElevated) {
                $PSProcessElevated = 'TRUE'
            }
            else {
                $PSProcessElevated = 'FALSE'
            }
        }
        else {
            # Code to determine if you are a root user or not...
        }

        if ($AttemptAutoFit) {
            $PSProcessElevated = "Elevated: $($PSProcessElevated)"
        }
    }

    Process {}
    End {
        if ($AttemptAutoFit -or (-not $HasANSI)) {
            Write-Host ("{0,-25}$($Spaces)" -f $IPAddress) -noNewline
            Write-Host ("{0,-25}$($Spaces)" -f $UserDomain) -noNewline
            Write-Host ("{0,-25}$($Spaces)" -f $LogonServer) -noNewline
            Write-Host ("{0,-25}$($Spaces)" -f $PSExecPolicy)

            Write-Host ("{0,-25}$($Spaces)" -f $VpnIPAddress) -noNewline
            Write-Host ("{0,-25}$($Spaces)" -f $CompName) -noNewline
            Write-Host ("{0,-25}$($Spaces)" -f $UserName) -noNewline
            Write-Host ("{0,-25}$($Spaces)" -f $PSVersion)
            Write-Host
            Write-Host $UptimeBoot
            if ($UptimeResume) {
                Write-Host $UptimeResume
            }
        }
        else {
            Write-Host "Dom:" -ForegroundColor Green  -nonewline
            Write-Host $UserDomain -ForegroundColor Cyan  -nonewline
            Write-Host "$Spaces|$Spaces" -ForegroundColor White  -nonewline

            Write-Host "Host:"-ForegroundColor Green  -nonewline
            Write-Host $CompName -ForegroundColor Cyan  -nonewline
            Write-Host "$Spaces|$Spaces" -ForegroundColor White  -nonewline

            Write-Host "Logon Svr:" -ForegroundColor Green -nonewline
            Write-Host $LogonServer -ForegroundColor Cyan

            Write-Host "PS:" -ForegroundColor Green -nonewline
            Write-Host $PSVersion -ForegroundColor Cyan  -nonewline
            Write-Host "$Spaces|$Spaces" -ForegroundColor White -nonewline

            Write-Host "Elevated:" -ForegroundColor Green -nonewline
            if ($PSProcessElevated -eq 'TRUE') {
                Write-Host $PSProcessElevated -ForegroundColor Red -nonewline
            }
            else {
                Write-Host $PSProcessElevated -ForegroundColor Cyan -nonewline
            }
            Write-Host "$Spaces|$Spaces" -ForegroundColor White  -nonewline

            Write-Host "Execution Policy:" -ForegroundColor Green -nonewline
            Write-Host $PSExecPolicy -ForegroundColor Cyan

            # Line 2
            Write-Host "User:" -ForegroundColor Green  -nonewline
            Write-Host $UserName -ForegroundColor Cyan  -nonewline
            Write-Host "$Spaces|$Spaces" -ForegroundColor White  -nonewline

            Write-Host "IP:" -ForegroundColor Green  -nonewline
            Write-Host $IPAddress -ForegroundColor Cyan -nonewline
            Write-Host "$Spaces|$Spaces" -ForegroundColor White -nonewline

            Write-Host "VPN:" -ForegroundColor Green -nonewline
            Write-Host $VpnIPAddress -ForegroundColor Cyan

            Write-Host

            # Line 3
            Write-Host "Uptime (hardware boot): " -nonewline -ForegroundColor Green
            Write-Host $UptimeBoot -ForegroundColor Cyan

            # Line 4
            if ($UptimeResume) {
                Write-Host "Uptime (system resume): " -nonewline -ForegroundColor Green
                Write-Host $UptimeResume -ForegroundColor Cyan
            }
        }
    }
}

Set-Alias -Name Show-Banner -Value Write-SessionBannerToHost
Write-SessionBannerToHost
Write-Host ""