'
' Title:  Update-ADComputerDescription.vbs
' Author: Jeremy Altman <jeremy.altman@santanna.net>
' Modified: 2022-06-02: Initial Version
'
On Error Resume Next
command = "powershell.exe -Noninteractive -ExecutionPolicy Bypass -NoProfile -File C:\ProgramData\Santanna\scripts\Set-Wallpaper\Set-Wallpaper.ps1"
set shell = CreateObject("WScript.Shell")
shell.Run command,0