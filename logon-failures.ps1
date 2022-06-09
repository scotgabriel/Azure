# Script must be run by a user that has an Azure P1 license or better

# If you get "get-azureadauditsigninlogs is not recognized as the name of a cmdlet" I
# had to close all powershell sessions (including closing vscode) open an elevated terminal and run
# Install-Module -Name AzureADPreview -RequiredVersion 2.0.2.105 -allowclobber -Force
# AND THEN CLOSE ALL TERMINAL WINDOWS
# then in vscode terminal Run "import-module azureadpreview" then run the script

$DateTime = (Get-Date).ToString('yyyy-MM-dd__HH-mm-ss__K')
$ExportFileNamePart = "-Azure-LogonFailures-"

Connect-AzureAD

$CompanyName = (Get-AzureADTenantDetail).DisplayName

# $azureLogonFailures = Get-AzureADAuditSignInLogs -Filter "status/errorCode ne 0"
$allLogonEvents = Get-AzureADAuditSignInLogs

$finalList = @()

foreach ($record in $allLogonEvents){

    $finalList += ,[PSCustomObject]@{
        CreatedDateTime         = $record.CreatedDateTime
        ErrorCode               = $record.Status.ErrorCode
        Status                  = $record.Status
        DisplayName             = $record.UserDisplayName
        AppDisplayName          = $record.AppDisplayName
        ClientAppUsed           = $record.ClientAppUsed
        ResourceDisplayName     = $record.ResourceDisplayName
        Location                = $record.Location
        UserPrincipalName       = $record.UserPrincipalName
        UserId                  = $record.UserId
        IPAddress               = $record.IpAddress
        AuthProcessDetails01    = $record.AuthenticationProcessingDetails.Value
        AuthProcessDetails02    = $record.AuthenticationProcessingDetails.Value
        AuthProcessDetails03    = $record.AuthenticationProcessingDetails.Value
        AuthProcessDetails04    = $record.AuthenticationProcessingDetails.Value
        ConditionalAccessStatus = $record.ConditionalAccessStatus
        AppliedCAP              = $record.AppliedConditionalAccessPolicies.Value
        IsInteractive           = $record.IsInteractive
        DeviceDetails           = $record.DeviceDetail
        MfaDetail               = $record.MfaDetail
        CorrelationId           = $record.CorrelationId
    }
}

$finalList = $finalList | Sort-Object -Property @{Expression = "CreatedDateTime"; Descending = $true}

$RootDirPath = "C:\rootpath\exports\"
$CompanyNameSimplified = ($CompanyName).trim()
$CompanyNameSimplified = $CompanyNameSimplified.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
$DateTime = $DateTime.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
$ZipFile = $RootDirPath + $CompanyNameSimplified + $ExportFileNamePart + $DateTime + ".zip"
$MfaExport = $RootDirPath + $CompanyNameSimplified +  $ExportFileNamePart + $DateTime + ".csv"

new-item -ItemType Directory -force -path $rootDirPath
$finalList | Sort-Object -Property DisplayName | Export-Csv -Path $MfaExport -NoTypeInformation

# final clean-up and deliverable
Compress-Archive -Force -path $MfaExport -DestinationPath $ZipFile
Remove-Item $MfaExport