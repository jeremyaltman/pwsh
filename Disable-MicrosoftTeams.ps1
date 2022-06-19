
#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

# Kill all running instances
&taskkill /im Teams* /F

Remove-ItemProperty -LiteralPath HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -Name com.squirrel.Teams.Teams
$path = 'C:\Users\'+$env:USERNAME+'\Appdata\Roaming\Microsoft\Teams\desktop-config.json'
$config = Get-Content -Path $path
$config.Replace('"openAtLogin":true','"openAtLogin":false') | Out-File $path