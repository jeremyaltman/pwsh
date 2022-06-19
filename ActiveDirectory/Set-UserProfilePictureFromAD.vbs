'
' Title:  Set-ADPicture.vbs
' Author: Jeremy Altman
' Modified: 2018-09-13
'
On Error Resume Next
command = "powershell.exe -Noninteractive -ExecutionPolicy Bypass -Noprofile -File Set-UserProfilePictureFromAD.ps1"
set shell = CreateObject("WScript.Shell")
shell.Run command,0