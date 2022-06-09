#REQUIRES -Version 5.1

# Install necessary modules
install-module -name MSOnline -Scope CurrentUser
install-module -name AzureAD -Scope CurrentUser

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

Import-Module .\myFunctions\get-SgCustomers
Import-Module .\myFunctions\search-SgTenants

# The following variable is used in multiple imported modules: ignore warning that it's not used.
$inputCustomerPartial = Read-Host "Enter a part of the customer name that will uniquely identify them: "

findCustomerTenantID

$SearchResults = searchAllTenants

searchResultsOne

$ReportUsers = @()
$ReportAggregate = @()

Connect-AzureAD -tenantid $SearchResults.TenantId

$currentSession = Get-AzureADCurrentSessionInfo
$currentSessionDomain = $currentSession.TenantDomain

$Skus = Get-AzureADSubscribedSku | Select-Object Sku*, ConsumedUnits , PrepaidUnits
ForEach ($Sku in $Skus) {
    Write-Host "Processing license holders for: " $Sku.SkuPartNumber
    $SkuUsers = Get-AzureADUser -All $True | Where-Object {$_.AssignedLicenses -Match $Sku.SkuId}
        ForEach ($User in $SkuUsers) {
            $ReportUsers  += ,[PSCustomObject] @{
            User                = $User.DisplayName
            CompanyDomainName   = $currentSessionDomain
            UPN                 = $User.UserPrincipalName
            Department          = $User.Department
            Country             = $User.Country
            SKU                 = $Sku.SkuId
            SKUName             = $Sku.SkuPartNumber} 
        }
    }

foreach ($Sku in $Skus) {
        Write-Host "Processing aggregates for: " $sku.SkuPartNumber
        $ReportAggregate += ,[PSCustomObject]@{
            CompanyDomainName   = $currentSessionDomain
            SKU                 = $Sku.SkuId
            SKUName             = $Sku.SkuPartNumber
            SKULicenseUsed      = $Sku.ConsumedUnits
            SKULicensePrepaid   = $Sku.PrepaidUnits.Enabled
        }
}

$RootDirPath = "C:\rootpath\exports\azuread\"
$CompanyNameSimplified = ($SearchResults.Name).trim()
$CompanyNameSimplified = $CompanyNameSimplified.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
$DateTime = $DateTime.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
$ZipFile = $RootDirPath + $CompanyNameSimplified + "-azuread-user-Licenses-" + $DateTime + ".zip"
$LicensedUsersExport = $RootDirPath + $CompanyNameSimplified + "-azuread-Licenses-perUser-" + $DateTime + ".csv"
$LicenseAggregateExport = $RootDirPath + $CompanyNameSimplified + "-azuread-Licenses-AggregateUsage-" + $DateTime + ".csv"
$ReportUsers | Sort-Object User | Export-Csv -Path $LicensedUsersExport -NoTypeInformation
$ReportAggregate | Sort-Object SKUName| Export-Csv -Path $LicenseAggregateExport -NoTypeInformation

# final clean-up and deliverable
Compress-Archive -Force -path $LicensedUsersExport,$LicenseAggregateExport -DestinationPath $ZipFile
Remove-Item $LicensedUsersExport , $LicenseAggregateExport