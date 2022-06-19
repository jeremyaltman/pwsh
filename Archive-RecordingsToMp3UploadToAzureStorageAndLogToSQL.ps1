#Requires -version 5.1
#Requires -Assembly WinSCPnet.dll
# #Requires -RunAsAdministrator
#Requires -PSEdition Desktop
$ScriptVersion = "20.1009"

<#
.SYNOPSIS
  Archives 8x8 Virtual Contact Center Recordings for regulatory compliance.
.DESCRIPTION
  Recordings are downloaded in wav format from the VCC FTPes server, reencoded into mp3 format and uploaded to Azure Blob Storage.
  Metadata is written to a table in SQL Server.
.NOTES
  This script is designed to run as a scheduled task.
.NOTES
  Version:        20.1003
  Author:         Jeremy Altman
  Creation Date:  9.18.2020
  Purpose/Change: Initial script development
  
.EXAMPLE
  powershell.exe -noprofile -file C:\SES\scripts\Archive-VccRecordings.ps1
#>



$Path = "C:\SES\VCC"
$username = "redacted"
$password = ConvertTo-SecureString "redacted" -AsPlainText -Force
$vccCreds = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)
$sqlInstance = "redacted"
$sqlDatabase = "redacted"
$sqlSchema = "redacted"
$sqlTable = "redacted"
$sqlUsername = "redacted"
$sqlPassword = ConvertTo-SecureString "redacted" -AsPlainText -Force
$sqlCreds = New-Object System.Management.Automation.PSCredential -ArgumentList ($sqlUsername, $sqlPassword)
$subscriptionId = "00000000-0000-0000-0000-000000000000"
$storageAccountRG = "Storage-v2-Tier-Cool_group"
$storageAccountName = "coolstorage"
$storageContainerName = "recordings"

$propertyTranslation = @(
    @{ Name = 'CALL_TYPE'; Expression = { $_.'CALL TYPE' } }
    @{ Name = 'START_TIME'; Expression = { $_.'START TIME' -as [datetime] } }
    @{ Name = 'STOP_TIME'; Expression = { $_.'STOP TIME' -as [datetime] } }
    @{ Name = 'AGENT_NAME'; Expression = { $_.'AGENT NAME' } }
    @{ Name = 'CUSTOMER_NUMBER'; Expression = { $_.'CUSTOMER NUMBER' } }
    @{ Name = 'PHONE_CHANNEL'; Expression = { $_.'PHONE CHANNEL' } }
    @{ Name = 'CALLED_NUMBER'; Expression = { $_.'CALLED NUMBER' } }
    @{ Name = 'CASEID'; Expression = { $_.'CASEID' -as [int32] } }
    @{ Name = 'DURATION'; Expression = { $_.'DURATION' -as [int32] } }
    @{ Name = 'FILENAME'; Expression = { $_.'FILENAME' } }
    @{ Name = 'DIRECTORY'; Expression = { $_.'DIRECTORY' } }
    @{ Name = 'ACCOUNT_NUMBER'; Expression = { $_.'ACCOUNT NUMBER' } }
    @{ Name = 'START_TIME_UTC'; Expression = { $_.'START TIME UTC' -as [datetime] } }
    @{ Name = 'STOP_TIME_UTC'; Expression = { $_.'STOP TIME UTC' -as [datetime] } }
    @{ Name = 'QUEUE'; Expression = { $_.'QUEUE' } }
    @{ Name = 'QUEUE_NAME'; Expression = { $_.'QUEUE NAME' } }
    @{ Name = 'TRANS_ID'; Expression = { $_.'TRANS ID' } }
    @{ Name = 'EXT_VAR1'; Expression = { $_.'EXT VAR1' } }
    @{ Name = 'EXT_VAR2'; Expression = { $_.'EXT VAR2' } }
    @{ Name = 'OUT_DIAL_CODE'; Expression = { $_.'OUT DIAL CODE' } }
    @{ Name = 'WRAP_UP_CODE'; Expression = { $_.'WRAP UP CODE' } }
)

$EnableNotification = $false
$SMTPServer = "contoso-com.mail.protection.outlook.com"
$SMTPServerPort = "25"
$EmailFrom = "do-not-reply@contoso.com"
$EmailTo = "jeremy@contoso.com"
$EmailSubject = "VCC Recordings Processing and Retention Job"

##################################################################
#                   Email formatting
##################################################################

$style = "<font face=tahoma><h3>$EmailSubject Log</h3></font>"
$style = $style + "<style>BODY{font-family: Tahoma; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style>"

###############################################################################################################
# !!! DO NOT EDIT ANYTHING BELOW THIS LINE. ALL CONFIGURABLE PARAMETERS ARE STORED IN THE VARIABLES ABOVE !!! #
###############################################################################################################

$LogFile = "$Path\logs\Archive-VccRecordings_" + (Get-Date -Format yyyyMMdd-HHmmss) + ".log"
if (!(Test-Path -Path "$Path\logs")) { 
    New-Item -ItemType Directory -Force -Path "$Path\logs" | Out-Null
}
Start-Transcript -Path $LogFile -Force -IncludeInvocationHeader

Clear-Host

$MessageBody = @()
Write-Host "
.________.______  .______  _____._.______  .______  .______  .______       ._______.______  ._______.______  ._____   ____   ____
|    ___/:      \ :      \ \__ _:|:      \ :      \ :      \ :      \      : .____/:      \ : .____/: __   \ :_ ___\  \   \_/   /
|___    \|   .   ||       |  |  :||   .   ||       ||       ||   .   |     | : _/\ |       || : _/\ |  \____||   |___  \___ ___/
|       /|   :   ||   |   |  |   ||   :   ||   |   ||   |   ||   :   |     |   /  \|   |   ||   /  \|   :  \ |   /  |    |   |
|__:___/ |___|   ||___|   |  |   ||___|   ||___|   ||___|   ||___|   |     |_.: __/|___|   ||_.: __/|   |___\|. __  |    |___|
   :         |___|    |___|  |___|    |___|    |___|    |___|    |___|        :/       |___|   :/   |___|     :/ |. |
                                                                                                              :   :/" -ForegroundColor Blue
Write-Host "    S   E   R   V   I   C   E   S       :       I   T       I   N   F   R   A   T   R   U   C   T   U   R   E" -ForegroundColor White -NoNewline
Write-Host "     : `n" -ForegroundColor Blue

Write-Host "`nScript  : "  -ForegroundColor Blue -NoNewLine
Write-Host "Archive-VccRecordings.ps1" -ForegroundColor White
Write-Host "Version : "  -ForegroundColor Blue -NoNewLine
Write-Host "v$ScriptVersion" -ForegroundColor White -NoNewline
Write-Host "  [ non-production ]" -ForegroundColor Red
Write-Host "Author  : "  -ForegroundColor Blue -NoNewLine
Write-Host "Jeremy Altman  [ jeremy.altman@contoso.com ]`n" -ForegroundColor White

Function Install-ModuleIfNotInstalled(
    [string] [Parameter(Mandatory = $true)] $moduleName,
    [string] $minimalVersion
) {
    $module = Get-Module -Name $moduleName -ListAvailable |`
        Where-Object { $null -eq $minimalVersion -or $minimalVersion -ge $_.Version } |`
        Select-Object -Last 1
    if ($null -ne $module) {
        Write-Verbose ('Module {0} (v{1}) is available.' -f $moduleName, $module.Version)
    }
    else {
        Import-Module -Name 'PowershellGet'
        $installedModule = Get-InstalledModule -Name $moduleName -ErrorAction SilentlyContinue
        if ($null -ne $installedModule) {
            Write-Verbose ('Module [{0}] (v {1}) is installed.' -f $moduleName, $installedModule.Version)
        }
        if ($null -eq $installedModule -or ($null -ne $minimalVersion -and $installedModule.Version -lt $minimalVersion)) {
            Write-Verbose ('Module {0} min.vers {1}: not installed; check if nuget v2.8.5.201 or later is installed.' -f $moduleName, $minimalVersion)
            #First check if package provider NuGet is installed. Incase an older version is installed the required version is installed explicitly
            if ((Get-PackageProvider -Name NuGet -Force).Version -lt '2.8.5.201') {
                Write-Warning ('Module {0} min.vers {1}: Install nuget!' -f $moduleName, $minimalVersion)
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force
            }        
            $optionalArgs = New-Object -TypeName Hashtable
            if ($null -ne $minimalVersion) {
                $optionalArgs['RequiredVersion'] = $minimalVersion
            }  
            Write-Warning ('Install module {0} (version [{1}]) within scope of the current user.' -f $moduleName, $minimalVersion)
            Install-Module -Name $moduleName @optionalArgs -Scope CurrentUser -Force -Verbose
        } 
    }
}

function Out-DataTable {
    [CmdletBinding()]
    [OutputType([System.Data.DataTable])]
    param(
        [Parameter( Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [PSObject[]]$InputObject,

        [string[]]$NonNullable = @()
    )

    Begin {
        $dt = New-Object Data.datatable  
        $First = $true 

        function Get-ODTType {
            param($type)

            $types = @(
                'System.Boolean',
                'System.Byte[]',
                'System.Byte',
                'System.Char',
                'System.Datetime',
                'System.Decimal',
                'System.Double',
                'System.Guid',
                'System.Int16',
                'System.Int32',
                'System.Int64',
                'System.Single',
                'System.UInt16',
                'System.UInt32',
                'System.UInt64')

            if ( $types -contains $type ) { Write-Output "$type" }
            else { Write-Output 'System.String' }
        } #Get-Type
    }
    Process {
        foreach ($Object in $InputObject) {
            $DR = $DT.NewRow()  
            foreach ($Property in $Object.PsObject.Properties) {
                $Name = $Property.Name
                $Value = $Property.Value
                
                #RCM: what if the first property is not reflective of all the properties? Unlikely, but...
                if ($First) {
                    $Col = New-Object Data.DataColumn  
                    $Col.ColumnName = $Name  
                    
                    #If it's not DBNull or Null, get the type
                    if ($Value -isnot [System.DBNull] -and $null -ne $Value) { $Col.DataType = [System.Type]::GetType( $(Get-ODTType $property.TypeNameOfValue) ) }
                    
                    #Set it to nonnullable if specified
                    if ($NonNullable -contains $Name ) { $col.AllowDBNull = $false }
                    try { $DT.Columns.Add($Col) }
                    catch { Write-Error "Could not add column $($Col | Out-String) for property '$Name' with value '$Value' and type '$($Value.GetType().FullName)':`n$_" }
                }                
                Try {
                    #Handle arrays and nulls
                    if ($property.GetType().IsArray) { $DR.Item($Name) = $Value | ConvertTo-XML -As String -NoTypeInformation -Depth 1 }
                    elseif ($null -eq $Value) { $DR.Item($Name) = [DBNull]::Value }
                    else { $DR.Item($Name) = $Value }
                }
                Catch { Write-Error "Could not add property '$Name' with value '$Value' and type '$($Value.GetType().FullName)'"; continue }
                #Did we get a null or dbnull for a non-nullable item? let the user know.
                if ($NonNullable -contains $Name -and ($Value -is [System.DBNull] -or $null -eq $Value)) {
                    write-verbose "NonNullable property '$Name' with null value found: $($object | out-string)"
                }
            } 
            Try { $DT.Rows.Add($DR) }
            Catch { Write-Error "Failed to add row '$($DR | Out-String)':`n$_" }
            $First = $false
        }
    } 
    End { Write-Output @(, $dt) }
}

#########################################################################
# End of functions. Load modules and begin processing.
#########################################################################

Install-ModuleIfNotInstalled 'AudioWorks.Commands' '1.0.0'
Install-ModuleIfNotInstalled 'SqlServer' '21.1.18226'
Install-ModuleIfNotInstalled 'WinSCP' '5.17.7.0'
Install-ModuleIfNotInstalled 'Az.Accounts' '1.9.4'
Install-ModuleIfNotInstalled 'Az.Storage' '2.6.0'

# Check for stored Azure AD credentials, prompt for and store if not found.
if (!(Test-Path "${env:\APPDATA}\${env:USERNAME}-${env:COMPUTERNAME}-creds.xml")) {
    Write-Host "The username and password you enter will be securely cached.." -ForegroundColor Yellow
    $RawCredential = Get-Credential -Message "Enter credential to cache for Azure Storage Account"
    $RawCredential | Export-CliXml -Path "${env:\APPDATA}\${env:USERNAME}-${env:COMPUTERNAME}-creds.xml"
    Write-Host "Your credential has been stored at ${env:\APPDATA}\${env:USERNAME}-${env:COMPUTERNAME}-creds.xml"
}

# Connect to Azure
$O365Credential = Import-Clixml "${env:\APPDATA}\${env:USERNAME}-${env:COMPUTERNAME}-creds.xml"
Connect-AzAccount -Credential $O365Credential
Select-AzSubscription -SubscriptionId $SubscriptionId
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $storageAccountRG -AccountName $storageAccountName).Value[0]
$destinationContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

# Establish FTP connection to VCC server
$sessionOption = New-WinSCPSessionOption `
    -HostName vcc-ftps-us2.8x8.com `
    -TlsHostCertificateFingerprint "28:ab:b5:2d:dc:60:e7:30:c4:f3:79:c4:ca:23:1d:7c:2c:82:8b:ed" `
    -Protocol Ftp `
    -Credential $vccCreds `
    -FtpSecure Explicit `
    -PortNumber 21 `
    -ErrorAction Stop

########################################################################################################################################################################################

# Initiate connection to VCC FTP Server
$Stoploop = $false
[int]$Retrycount = "10"
Write-Host "Opening session with VCC FTP server..."
do {
    try {
        $session = New-WinSCPSession -SessionOption $sessionOption -ErrorAction Stop
        $TransferOptions = New-WinSCPTransferOption `
            -OverwriteMode Resume `
            -PreserveTimestamp $true `
            -TransferMode Automatic 
        Write-Host "FTP session established."
        $Stoploop = $true
    }
    catch {
        if ($Retrycount -lt 1) {
            Write-Host "Could not establish session with VCC FTP after $Retrycount retrys."
            exit
            $Stoploop = $true
        }
        else {
            Write-Host "Could not establish session, retrying in 30 seconds..."
            Start-Sleep -Seconds 30
            $Retrycount = $Retrycount - 1
        }
    }
}
while ($Stoploop -eq $false)

########################################################################################################################################################################################

# Get list of folders written in the last X days from the VCC FTP
$FtpFolder1 = Get-WinSCPChildItem -Filter S*  | Where-Object { $_.Name -eq "S" + (Get-Date -Format yyyyMMdd) }
$FtpFolder2 = Get-WinSCPChildItem -Filter S*  | Where-Object { $_.Name -eq "S" + (Get-Date (Get-Date).addDays(-1) -Format yyyyMMdd) }
$FtpFolder3 = Get-WinSCPChildItem -Filter S*  | Where-Object { $_.Name -eq "S" + (Get-Date (Get-Date).addDays(-2) -Format yyyyMMdd) }
$FtpFolder4 = Get-WinSCPChildItem -Filter S*  | Where-Object { $_.Name -eq "S" + (Get-Date (Get-Date).addDays(-3) -Format yyyyMMdd) }
$FtpFolder5 = Get-WinSCPChildItem -Filter S*  | Where-Object { $_.Name -eq "S" + (Get-Date (Get-Date).addDays(-4) -Format yyyyMMdd) }

$FtpFolders = @()
$FtpFolders += $FtpFolder1
$FtpFolders += $FtpFolder2
$FtpFolders += $FtpFolder3
$FtpFolders += $FtpFolder4
$FtpFolders += $FtpFolder5

$MissingFiles = @()

#FtpFolders = Get-WinSCPChildItem -Filter S*  | Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-41) }

foreach ($Folder in $FtpFolders) {

    # Initialize or clear out $Metadata PSObject
    $Metadata = $null

    $sqlQueryFileCount = @"
    DECLARE @directory NVARCHAR(max)
    SET @directory = '$Folder'
    SELECT 
        count(distinct filename) as [count]
    FROM [$sqlInstance].[$sqlDatabase].[$sqlSchema].[$sqlTable]
    WHERE DIRECTORY = @directory
"@

    $sqlFileCount = (Invoke-Sqlcmd `
            -Query $SqlQueryFileCount `
            -ServerInstance $sqlInstance `
            -Database $sqlDatabase `
            -Credential $sqlCreds `
            -OutputSqlErrors $true).Count

    Write-Output "`n$Folder`: Processing new folder from VCC..."
    $CsvFile = $Folder.Name.Replace("S", "I") + "_version2.csv"
    $RemoteCsvFileCount = (Get-WinSCPChildItem -WinSCPSession $session -Path $Folder -Filter $CsvFile).Count
    #$RemoteCsvFileCount = (Get-WinSCPChildItem -WinSCPSession $session -Path $Folder -Filter '*_version2.csv').Count
    if ($RemoteCsvFileCount -eq "1") {
        if (!(Test-Path -Path "$Path\$Folder")) { 
            New-Item -ItemType Directory -Force -Path "$Path\$Folder" | Out-Null
        }
        # Obtain and import daily/folder metadata from VCC
        $MetadataCSV = Get-WinSCPChildItem -Path $Folder -Filter $CsvFile -ErrorAction SilentlyContinue -WinSCPSession $session # | Out-Null
        #$MetadataCSV = Get-WinSCPChildItem -Path $Folder -Filter '*_version2.csv' -ErrorAction SilentlyContinue -WinSCPSession $session # | Out-Null
        if (Test-WinSCPPath -Path "$Folder\$MetadataCSV" -WinSCPSession $session) {
            Receive-WinSCPItem `
                -WinSCPSession $session `
                -RemotePath "$Folder\$MetadataCSV" `
                -LocalPath "$Path\$Folder\" `
                -TransferOptions $TransferOptions
        }
        $LocalMetadataCSV = Get-ChildItem -Path "$Path\$Folder" -Filter $CsvFile -Force -ErrorAction SilentlyContinue
        $Metadata = Import-Csv -Path $LocalMetadataCSV.FullName | Select-Object -Property $propertyTranslation
    }
    else { 
        Write-Output " - Metadata not available on server, gadzooks!"
        continue
    }

    $RemoteWavFiles = (Get-WinSCPChildItem -WinSCPSession $session -Path $Folder -Filter '*.wav')
    $RemoteWavFileCount = $RemoteWavFiles.Count
    $LocalMp3FileCount = (Get-ChildItem -Path "$Path\$Folder" -Filter '*.mp3').Count
    $BlobFileCount = (Get-AzStorageBlob -Container $storageContainerName -Context $destinationContext -Prefix $Folder).Count
    $LocalMetadataCSV = Get-ChildItem -Path "$Path\$Folder" -Filter '*_version2.csv' -Force -ErrorAction SilentlyContinue
    if ($null -ne $LocalMetadataCSV) {
        $Metadata = Import-Csv -Path $LocalMetadataCSV.FullName | Select-Object -Property $propertyTranslation
        Write-Output " - $($Metadata.Count) metadata records in CSV"
    }
    Write-Output " - $RemoteWavFileCount wav files on VCC FTP server"
    Write-Output " - $LocalMp3FileCount mp3 files locally cached"
    Write-Output " - $BlobFileCount files in Azure Blob storage container"
    if ($null -ne $sqlFileCount) {
        Write-Output " - $sqlFileCount records in SQL for folder"
    }
    
    if ($RemoteWavFileCount -eq 0) {
        Write-Output " - No recordings found in VCC under $Folder!"
        continue
    }

    if ($($Metadata.Count) -ne $RemoteWavFileCount) {
        Write-Host " - WARNING: Remote FTP Server Metadata is inconsistent with files on FTP server in $Folder!!" # -ForegroundColor Red
        $LostFiles = Compare-Object -ReferenceObject $Metadata.FILENAME -DifferenceObject $RemoteWavFiles.Name
        Add-Content -Path "$Path\missingfiles.txt" -Value $LostFiles
        foreach ($LostFile in $LostFiles) {
            Write-Host "  "($LostFile).SideIndicator " " ($LostFile).InputObject -ForegroundColor Red
            $MissingFiles += $LostFile.InputObject
        }
    }

    if (($BlobFileCount -eq $sqlFileCount) -and ($BlobFileCount -eq $($Metadata).Count)) {
        Write-Output " - Folder has been processed successfully"
        if (Get-ChildItem -Path "$Path\$Folder" -Include ('*.mp3', '*.wav')) {
            Write-Output " - Deleting locally cached recordings.."
            Remove-Item -Path "$Path\$Folder\*" -Include *.mp3, *.wav -Force
        }
        continue
    }

    # If there are not more files in Azure Blob Storage than VCC FTP and there are less local mp3 files than waves on VCC FTP
    if (($BlobFileCount -ne $($Metadata.Count) -and
            $BlobFileCount -ne $RemoteWavFileCount) -or
        ($sqlFileCount -ne $($Metadata.Count) -and
            $sqlFileCount -ne $RemoteWavFileCount)) {

        # Loop through each record in daily/folder metadata
        $Metadata | ForEach-Object {
            # Change filename from wav to mp3 via string replace
            $mp3Filename = $($_.FILENAME).Replace("wav", "mp3")          
            $RecordingFilename = $($_.FILENAME)
            $SourceFile = "$Path\$Folder\$mp3Filename"
            $Blob = "$Folder\$mp3Filename"

            # Record manipulations, rename to mp3 and set datatypes of fields
            $_.FILENAME = $($_.FILENAME).Replace("wav", "mp3")
            $_.START_TIME = [datetime]$_.START_TIME
            $_.START_TIME_UTC = [datetime]$_.START_TIME_UTC
            $_.STOP_TIME = [datetime]$_.STOP_TIME
            $_.STOP_TIME_UTC = [datetime]$_.STOP_TIME_UTC
            $_.CASEID = [int32]$_.CASEID
            $_.DURATION = [int32]$_.DURATION
        
            # Check if mp3 file is already in blob storage
            $blobExists = Get-AzStorageBlob `
                -Blob $Blob `
                -Container $storageContainerName `
                -Context $destinationContext `
                -ErrorAction Ignore

            if ($null -eq $blobExists) {

                # If mp3 file does not exist in path
                if (!(Test-Path -Path "$Path\$Folder\$mp3Filename")) {
                    # No mp3 found, check for wav file in path, and download if it doesn't exist
                    if (!(Test-Path -Path "$Path\$Folder\$RecordingFilename")) {
                        try {
                            Receive-WinSCPItem `
                                -WinSCPSession $session `
                                -RemotePath "$($_.DIRECTORY)/$RecordingFilename" `
                                -LocalPath "$Path\$Folder" `
                                -TransferOptions $TransferOptions `
                                -ErrorAction SilentlyContinue `
                                -ErrorVariable $RecordingError
                        }
                        catch {
                            Write-Output $RecordingError
                            Get-Member $RecordingError
                            pause
                        }
                        ###########################################################################################################################################################################################################
                            
                        # Convert wav file to mp3
                        Get-AudioFile -Path "$Path\$Folder\$RecordingFilename" | Export-AudioFile LameMP3 "$Path\$Folder" | Out-Null
                        # Delete wav file
                        Remove-Item -Path "$Path\$Folder\$RecordingFilename"
                    }
                }
            
                if ($_.CALL_TYPE -eq "Outbound") { $CustomerTeleNumber = $_.CALLED_NUMBER }
                else { $CustomerTeleNumber = $_.CUSTOMER_NUMBER }
                if ($null -eq $_.OUT_DIAL_CODE) { $_.OUT_DIAL_CODE = "N/A" }
                if ($null -eq $_.WRAP_UP_CODE) { $_.WRAP_UP_CODE = "N/A" }
                    
                $BlobMetadata = @{
                    "call_type"           = $_.CALL_TYPE;
                    "called_number"       = $_.CALLED_NUMBER;
                    "customer_number"     = $_.CUSTOMER_NUMBER;
                    "customer_telenumber" = $CustomerTeleNumber;
                    "agent_name"          = $_.AGENT_NAME;
                    "start_time"          = $_.START_TIME;
                    "start_time_utc"      = $_.START_TIME_UTC;
                    "stop_time"           = $_.STOP_TIME;
                    "stop_time_utc"       = $_.STOP_TIME_UTC;
                    "phone_channel"       = $_.PHONE_CHANNEL;
                    "case_id"             = $_.CASEID;
                    "duration"            = $_.DURATION;
                    "account_number"      = $_.ACCOUNT_NUMBER;
                    "queue"               = $_.QUEUE;
                    "queue_name"          = $_.QUEUE_NAME;
                    "trans_id"            = $_.TRANS_ID;
                    "ext_var1"            = $_.EXT_VAR1;
                    "ext_var2"            = $_.EXT_VAR2
                }
                
                # Upload mp3 file to blob storage
                Set-AzStorageBlobContent -File $SourceFile `
                    -Metadata $BlobMetadata `
                    -Container $storageContainerName `
                    -Blob $Blob `
                    -Context $destinationContext `
                    -StandardBlobTier Cool `
                    -ErrorAction Ignore `
                    -Force

                # Delete mp3 file once uploaded to blob storage
                Remove-Item -Path $SourceFile -Force
            }

            $sqlQueryFileExists = @"
                DECLARE @filename NVARCHAR(max)
                SET @filename = '$mp3Filename'
                SELECT 
                    case when count(FILENAME) <> 0 then 'yes' else 'no' end
                FROM [$sqlInstance].[$sqlDatabase].[$sqlSchema].[$sqlTable]
                WHERE FILENAME = @filename
"@
            $sqlFileExists = (Invoke-Sqlcmd `
                    -Query $sqlQueryFileExists `
                    -ServerInstance $sqlInstance `
                    -Database $sqlDatabase `
                    -Credential $sqlCreds `
                    -OutputSqlErrors $true).Column1

            if ($sqlFileExists -ne "yes") {
                $_ | Format-Table
                $_ | Out-DataTable | Write-SqlTableData `
                    -ServerInstance $sqlInstance `
                    -DatabaseName $sqlDatabase `
                    -SchemaName $sqlSchema `
                    -TableName $sqlTable `
                    -Credential $sqlCreds `
                    -Force
            }
        }
    
        if ($null -ne $Metadata) {
        
            # Export updated metadata to new CSV and write to SQL table
            $MetadataLocation = "$Path\metadata"
            if (!(Test-Path -Path $MetadataLocation)) {
                New-Item -ItemType Directory -Force -Path $MetadataLocation | Out-Null
            }
            if (!(Test-Path -Path "$MetadataLocation\$Folder.csv")) {
                $Metadata | Export-Csv -Path "$MetadataLocation\$Folder.csv" -NoTypeInformation
            }
            
            # Check if metadata file is already in blob storage
            $blobMetadataExists = Get-AzStorageBlob `
                -Blob "metadata\$Folder.csv" `
                -Container $storageContainerName `
                -Context $destinationContext `
                -ErrorAction Ignore
            
            # Upload metadata file to blob storage
            if (-not $blobMetadataExists) {
                Set-AzStorageBlobContent -File "$MetadataLocation\$Folder.csv" `
                    -Container $storageContainerName `
                    -Blob "metadata\$Folder.csv" `
                    -Context $destinationContext `
                    -StandardBlobTier Cool `
                    -ErrorAction Ignore
            }
            
            $MessageBody += $Metadata
        }
    }
} # Loop back to next folder.

# Close and release the WinSCP session object.
Remove-WinSCPSession -WinSCPSession $session

if ($null -ne $MissingFiles) {
    $EnableNotification = $true
    $MessageBody += $MissingFiles
    Write-Output "The following files are missing on VCC:`n$MissingFiles"
    $DateStamp = Get-Date -Format g
    $Footer = "<P><B>$DateStamp</B>"
}

Stop-Transcript

if ($EnableNotification -eq $true) {
    Send-MailMessage -Body ($message | Out-String) `
        -From $EmailFrom `
        -To $EmailTo `
        -Subject $EmailSubject `
        -SmtpServer $SMTPServer `
        -Port $SMTPServerPort `
        -Attachments $LogFile

    $Message = New-Object System.Net.Mail.MailMessage $EmailFrom, $EmailTo
    $Message.Subject = $EmailSubject
    $Message.Body = Get-Content $LogFile
    $Message.IsBodyHTML = $True
    $Message.Body = $MessageBody | ConvertTo-Html -head $style -PostContent $Footer | Out-String
    $Message.Attachments.Add($LogFile)
    $Message.IsBodyHtml = $false
    $SMTP = New-Object Net.Mail.SmtpClient($SMTPServer , $SMTPServerPort)
    $SMTP.Send($Message)

}