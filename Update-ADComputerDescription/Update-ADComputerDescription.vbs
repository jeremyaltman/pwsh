'
' Title:  Update-ADComputerDescription.vbs
' Author: Jeremy Altman <jeremy.altman@santanna.net>
' Modified: 2022-03-28: Updated path from C:\SES to C:\ProgramData\Santanna
' Modified: 2022-06-14: Changed from Windows PowerShell to PowerShell Core 7.x
'
On Error Resume Next
command = "pwsh.exe -NonInteractive -ExecutionPolicy Bypass -NoProfile -File C:\ProgramData\Santanna\scripts\Update-ADComputerDescription\Update-ADComputerDescription.ps1"
set shell = CreateObject("WScript.Shell")
shell.Run command,0