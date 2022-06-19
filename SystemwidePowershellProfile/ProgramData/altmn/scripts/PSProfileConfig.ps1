# System-wide, combined, all-user PowerShell Profile
# Runs for all users in both Windows PowerShell and PowerShell Core
# Created by: Jeremy Altman
# Version: 2206-19

## Detect if we are running PowerShell without a console.
$_ISCONSOLE = $TRUE
try {
    [System.Console]::Clear()
}
catch {
    $_ISCONSOLE = $FALSE
}

# Everything in this block is only relevant in a console. This keeps nonconsole based powershell sessions clean.
if ($_ISCONSOLE) {
  # Write-Host "Please wait, initializing PowerShell profile.."
    try {
        Add-Type -Assembly PresentationCore, WindowsBase
        ##  Check SHIFT state ASAP at startup so we can use that to control verbosity :)
        if ([System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::LeftShift) -or [System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::RightShift)) {
            $VerbosePreference = "Continue"
        }
        ##  Check CTRL state ASAP at startup so we can use that to bypass startup scripts!
        if ([System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::LeftCtrl) -or [System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::RightCtrl)) {
            break
        }
    }
    catch {
        # Maybe this is a non-windows host?
    }

    ## Set the profile directory variable for possible use later
    Set-Variable ProfileDir (Split-Path $MyInvocation.MyCommand.Path -Parent) -Scope Global -Option AllScope, Constant -ErrorAction SilentlyContinue

    # Start only if we are in a console
    if ($Host.Name -eq 'ConsoleHost') {

        $Path = "$env:ALLUSERSPROFILE\altmn\Scripts\PSProfileFunctions"
        Get-ChildItem -Path $Path -Filter *.ps1 | ForEach-Object {
            . $_.FullName
        }
        
        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            ### Windows PowerShell 5.1 Only!
        }

        if ($PSVersionTable.PSEdition -eq 'Core') {
            ### PowerShell Core 7+ Only!
        }

        Set-Location $env:USERPROFILE

    }
}

