'
' Title:  Set-ADPicture.vbs
' Author: Jeremy Altman <jeremy.altman@santanna.net>
' Modified: 2018-09-13: Initial version
' Modified: 2022-03-28: Updated path from \\ses4energy.com\NETLOGON\ to C:\ProgramData\Santanna\scripts\Set-ADPicture\
'
On Error Resume Next
command = "powershell.exe -Noninteractive -ExecutionPolicy Bypass -Noprofile -File C:\ProgramData\Santanna\scripts\Set-ADPicture\Set-ADPicture.ps1"
set shell = CreateObject("WScript.Shell")
shell.Run command,0