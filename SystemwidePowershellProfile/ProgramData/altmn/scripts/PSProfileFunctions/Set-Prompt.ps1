<#
.DESCRIPTION
    Installs oh-my-posh prompt theming framework into Windows PowerShell, PowerShell Core, and Clink (cmd.exe).

.NOTES
    Jeremy.Altman
    Version 2022.05.19

    This script is called automatically by PSProfileFunctions.ps1 on startup of a PowerShell console.
    For best results, use Windows Terminal with a powerline/nerd font patched font, like 'Mesla LGM NF'

    Visit https://ohmyposh.dev/docs to RTFM for further information and customization instructions.

.EXAMPLE
    View available installed oh-my-posh prompt themes: 
        Get-PoshThemes

    Change the theme (example theme: ys):
        oh-my-posh init --config $env:POSH_THEMES_PATH\ys.omp.json | Invoke-Expression

    Save theme and activate system-wide:
        oh-my-posh config export --output $env:LOCALAPPDATA\oh-my-posh\config.omp.json
#>

if (!(Test-Path "$env:LOCALAPPDATA\Programs\oh-my-posh\bin\oh-my-posh.exe" -ErrorAction SilentlyContinue)) {
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1'))
} 

$OhMyClink = "$env:LOCALAPPDATA\clink\oh-my-posh.lua"
if (!(Test-Path $OhMyClink -ErrorAction SilentlyContinue)) {
    New-Item -Path $OhMyClink -Force | Out-Null
    Set-Content -Value 'load(io.popen(''oh-my-posh init cmd''):read("*a"))()' -Path $OhMyClink -Force
}

Get-InstalledModule -Name oh-my-posh -AllVersions -ErrorAction SilentlyContinue | Uninstall-Module -Force

$shell = "pwsh"
if ($PSVersionTable.PSEdition -eq 'Desktop') { $shell = "powershell" }
& "$env:LOCALAPPDATA\Programs\oh-my-posh\bin\oh-my-posh.exe" init $shell --config "$env:LOCALAPPDATA\oh-my-posh\config.omp.json" | Invoke-Expression

