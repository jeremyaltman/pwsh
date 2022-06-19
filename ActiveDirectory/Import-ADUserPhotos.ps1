$O365Pictures = Get-ChildItem -Path ".\photos"
# | Select-Object Name
$TotalPictures = $O365Pictures.Count
$i = 1 
ForEach ($O365Picture in $O365Pictures) {
    # s.BaseName | ForEach-Object {
    $ID = $O365Picture.BaseName
    # $O365Pic = $_.Name
    Write-Progress -activity "Processing $ID" -status "$i out of $TotalPictures completed"
    Set-ADUser -Identity $ID -Replace @{thumbnailPhoto=([byte[]](Get-Content $O365Picture.FullName -Encoding byte))}
    $i++
}