#Import-Module ActiveDirectory
$ADusers= Get-ADUser -Filter * -SearchBase "DC=contoso,DC=com" -Properties thumbnailPhoto | Where-Object {$_.thumbnailPhoto}
foreach ($ADuser in $ADusers) {
$name = "C:\Users\jeremy\Scripts\Get-O365UserPhotos\adphotos\" + $ADuser.SamAccountName + ".jpg"
$ADuser.thumbnailPhoto | Set-Content $name -Encoding byte
}
