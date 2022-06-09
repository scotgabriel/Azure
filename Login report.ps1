# Install-Module -Name AzureADPreview -force -Scope CurrentUser

Connect-AzureAD
$TimeRange = (Get-Date).AddDays(-8).ToString("yyyy-MM-dd")
$RawAuditLogs = get-azureadauditsigninlogs -Filter "createdDateTime gt $TimeRange"
$CustomerLogonAuditLogs = $RawAuditLogs | Where-Object {$_.UserPrincipalName -ne "admin@companyname.onmicrosoft.com"}
$CustomerFacingAuditLogs = $CustomerLogonAuditLogs | Select-Object CreatedDateTime, UserPrincipalName, IpAddress, ClientAppUsed, IsInteractive, status

$DateTime = (Get-Date).ToString('yyyy-MM-dd HH_mm_ss K')

$finalList = @()

foreach ($item in $CustomerFacingAuditLogs) {
    $CurrentStatusErrorCode = $item.Status.ErrorCode
    $CurrentStatusFailureReason = $item.Status.FailureReason
    $CurrentStatusAdditionalDetails = $item.Status.AdditionalDetails
    
    $finalList += ,[PSCustomObject]@{
        CreatedDateTime         = $item.CreatedDateTime
        UserPrincipalName       = $item.UserPrincipalName
        IpAddress               = $item.IpAddress
        ClientAppUsed           = $item.ClientAppUsed
        IsInteractive           = $item.IsInteractive
        StatusErrorCode         = $CurrentStatusErrorCode
        StatusFailureReason     = $CurrentStatusFailureReason
        StatusAdditionalDetails = $CurrentStatusAdditionalDetails        
    }
}

$RootDirPath = "C:\rootpath\exports\azuread\"
$DateTime = $DateTime.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
$ZipFile = $RootDirPath + "-azuread-SignInLogs-" + $DateTime + ".zip"
$AzureADSignInLogs = $RootDirPath + "-azuread-users-MFAstatus-" + $DateTime + ".csv"

new-item -ItemType Directory -force -path $rootDirPath
$finalList | Sort-Object -Property UserPrincipalName, createdDateTime | Export-Csv -Path $AzureADSignInLogs -NoTypeInformation

# final clean-up and deliverable
Compress-Archive -Force -path $AzureADSignInLogs -DestinationPath $ZipFile
Remove-Item $AzureADSignInLogs
