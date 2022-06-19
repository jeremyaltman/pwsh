﻿Write-Host "Enter the email address you are searching for (example:nate@get-msol.com): " -ForegroundColor DarkGreen -BackgroundColor Black -NoNewline
$Address = Read-Host 
$Address = "smtp:" + $Address
write-host "Searching deleted users for the email address specified" -ForegroundColor DarkGreen -BackgroundColor Black
$DeletedOwners = Get-MSOLUser -All -ReturnDeletedUsers | Where-Object { $_.ProxyAddresses -like $Address }
If ($null -eq $DeletedOwners) {
    write-host "The address does not belong to a deleted user, now searching non-deleted items" -ForegroundColor DarkGreen -BackgroundColor Black
}
ELse {
    write-host "The address you are looking for is assigned to deleted object(s) named" $DeletedOwners.DisplayName -ForegroundColor DarkGreen -BackgroundColor Black
    write-host "Now continuiing search of non-deleted items (it may be assigned to multiple owners)" -ForegroundColor DarkGreen -BackgroundColor Black
}
write-host "Searching all mailboxes for the email address specified" -ForegroundColor DarkGreen -BackgroundColor Black
$MailboxOwners = Get-Mailbox -ResultSize Unlimited | Where-Object { $_.EmailAddresses -like $Address }
If ($null -eq $MailboxOwners) {
    Write-Host "Address does not belong to a mailbox, now checking groups" -ForegroundColor DarkGreen -BackgroundColor Black
    $GroupOwners = Get-DistributionGroup -ResultSize Unlimited | Where-Object { $_.EmailAddresses -like $Address }
    If ($null -eq $GroupOwners) {
        Write-Host "Address does not belong to a group, now checking mail enabled users" -ForegroundColor DarkGreen -BackgroundColor Black
        $MailUserOwner = Get-MailUser -ResultSize Unlimited | Where-Object { $_.EmailAddresses -like $Address }
        If ($null -eq $MailUserOwner) {
            Write-Host "Address does not belong to a mail enabled user, now checking contacts. This is your last shot" -ForegroundColor DarkGreen -BackgroundColor Black
            $ContactOwner = Get-MailContact -ResultSize Unlimited | Where-Object { $_.EmailAddresses -like $Address }
            If ($null -eq $ContactOwner) {
                Write-Host "Sorry, we did not find that email address on your tenant" -ForegroundColor DarkRed -BackgroundColor Black
            }
            Else {
                Write-Host "The email address belongs to a mail contact named " $ContactOwners.DisplayName -ForegroundColor DarkGreen -BackgroundColor Black
                Write-Host "Press any key to spit out the details" -ForegroundColor DarkGreen -BackgroundColor Black
                $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                $ContactOwner | Format-List
            }
            
        }
        Else {
            Write-Host "The email address belongs to a mail enabeld user named " $MailUserOwner.DisplayName -ForegroundColor DarkGreen -BackgroundColor Black
            Write-Host "Press any key to spit out the details" -ForegroundColor DarkGreen -BackgroundColor Black
            $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            $MailUserOwner | Format-List
        }
    }
    Else {
        Write-Host "The email address belongs to a group named " $GroupOwners.DisplayName -ForegroundColor DarkGreen -BackgroundColor Black
        Write-Host "Press any key to spit out the details" -ForegroundColor DarkGreen -BackgroundColor Black
        $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        $GroupOwner | Format-List
    }
}
Else {
    Write-Host "The email address belongs to a mailbox named " $MailboxOwners.DisplayName -ForegroundColor DarkGreen -BackgroundColor Black
    Write-Host "Press any key to spit out the details" -ForegroundColor DarkGreen -BackgroundColor Black
    $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $MailboxOwners | Format-List
}


