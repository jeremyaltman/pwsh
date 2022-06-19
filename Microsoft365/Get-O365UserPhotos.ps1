$Result = @()
$allUsers = Get-Mailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited
$totalusers = $allUsers.Count
$i = 1 
$allUsers | ForEach-Object {
    $user = $_
    Write-Progress -activity "Processing $user" -status "$i out of $totalusers completed"
    $photoObj = Get-Userphoto -identity $user.UserPrincipalName -ErrorAction SilentlyContinue
    $hasPhoto = $false
    if ($photoObj.PictureData -ne $null) {
        $hasPhoto = $true
        $data = Get-UserPhoto -Identity $user.UserPrincipalName
        if ($user.Alias -ne $null) {
            $savePhotoAs = '.\photos\' + $user.Alias + '.jpg'
            Write-Host $savePhotoAs
            $data.PictureData | Set-Content $savePhotoAs -Encoding Byte
        }
        if ($user.Alias -eq $null) {
            Write-Host 'Error: ' + $user.UserPrincipalName + ' does not have an alias set!'
        }
    }
    $Result += New-Object PSObject -property @{ 
        UserName          = $user.DisplayName
        UserPrincipalName = $user.UserPrincipalName
        HasProfilePicture = $hasPhoto
    }
    $i++
}
$Result | Export-CSV ".\office-365-users-photo-status.csv" -NoTypeInformation -Encoding UTF8