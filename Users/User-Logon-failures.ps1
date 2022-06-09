#REQUIRES -Version 5.1

# because "get-azureadauditsigninlogs" is not recognized as the name of a cmdlet
# had to close all powershell sessions (including closing vscode) open an elevated terminal and run
# Install-Module -Name AzureADPreview -RequiredVersion 2.0.2.105 -allowclobber -Force
# AND THEN CLOSE ALL TERMINAL WINDOWS
# then in vscode terminal Run "import-module azureadpreview" then run the script

# Install necessary modules
# install-module -name MSOnline -Scope CurrentUser
# install-module -name AzureAD -Scope CurrentUser

Import-Module .\myFunctions\get-SgCustomers
Import-Module .\myFunctions\search-SgTenants
Import-module AzureADPreview

$DateTime = (Get-Date).ToString('yyyy-MM-dd__HH-mm-ss__ K')

try {
    Get-MsolDomain -ErrorAction Stop | Out-Null
}
catch {
    Connect-MsolService
}

try {
    Get-AzureADCurrentSessionInfo -ErrorAction Stop | Out-Null
}
catch { 
    Connect-AzureAD
}


# The following variable is used in multiple imported modules: ignore warning that it's not used.
$inputCustomerPartial = Read-Host "Enter a part of the customer name that will uniquely identify them: "

findCustomerTenantID

$SearchResults = searchAllTenants

searchResultsOne

Connect-AzureAD -tenantid $SearchResults.TenantId

$azureLogonFailures = Get-AzureADAuditSignInLogs -Filter "status/errorCode ne 0"

$finalList = @()

foreach ($record in $azureLogonFailures){
    # foreach ($authProcessDetail in $record.AuthenticationProcessingDetails){

    # }
    $finalList += ,[PSCustomObject]@{
        CreatedDateTime         = $record.CreatedDateTime
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
        Status                  = $record.Status
        DeviceDetails           = $record.DeviceDetail
        MfaDetail               = $record.MfaDetail
        CorrelationId           = $record.CorrelationId
    }
}

$finalList = $finalList | Sort-Object -Property @{Expression = "CreatedDateTime"; Descending = $true}

$RootDirPath = "C:\rootpath\exports\azuread\"
$CompanyNameSimplified = ($SearchResults.Name).trim()
$CompanyNameSimplified = $CompanyNameSimplified.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
$DateTime = $DateTime.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
$ZipFile = $RootDirPath + $CompanyNameSimplified + "-azuread-users-Logon-Failures-" + $DateTime + ".zip"
$Export = $RootDirPath + $CompanyNameSimplified +  "-azuread-users-Logon-Failures-" + $DateTime + ".csv"

new-item -ItemType Directory -force -path $rootDirPath
$finalList | Sort-Object -Property DisplayName | Export-Csv -Path $Export -NoTypeInformation

# final clean-up and deliverable
Compress-Archive -Force -path $Export -DestinationPath $ZipFile
Remove-Item $Export