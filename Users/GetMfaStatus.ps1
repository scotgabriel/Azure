[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $licensed
)

$DateTime = (Get-Date).ToString('yyyy-MM-dd__HH-mm-ss__K')

Connect-MsolService

$CompanyName = (Get-MsolCompanyInformation).DisplayName

$AdminUsers = Get-MsolRole -ErrorAction Stop | ForEach-Object {Get-MsolRoleMember -RoleObjectId $_.ObjectID} | Where-Object {$null -ne $_.EmailAddress} | Select-Object EmailAddress -Unique | Sort-Object EmailAddress

$maxResults = 10000

if ($licensed -eq "ALL"){
    $ExportFileNamePart = "-AzureAD-MfaStatus-All-"
    $AllUsers = Get-MsolUser -MaxResults $maxResults
}elseif ($licensed -eq "NO") {
    $ExportFileNamePart = "-AzureAD-MfaStatus-NOTlicensed-"
    $AllUsers = Get-MsolUser -MaxResults $maxResults | Where-Object {$_.IsLicensed -eq $false}
}elseif ($licensed -eq "YES") {
    $ExportFileNamePart = "-AzureAD-MfaStatus-Licensed-"
    $AllUsers = Get-MsolUser -MaxResults $maxResults | Where-Object {$_.IsLicensed -eq $true}
}else {
    $ExportFileNamePart = "-AzureAD-MfaStatus-Licensed-"
    $AllUsers = Get-MsolUser -MaxResults $maxResults | Where-Object {$_.IsLicensed -eq $true}
}

$finalList = @()

foreach ($User in $AllUsers) {
    
    if ($AdminUsers -match $User.UserPrincipalName){
        $isAdmin = $true
    } else {
        $isAdmin = $false
    }
    if ($user.StrongAuthenticationMethods){
        $MfaEnabled = $true
    } else {
        $MfaEnabled = $false
    }
    if ($user.StrongAuthenticationRequirements){
        $MFAEnforced = $true
    } else {
        $MFAEnforced = $false
    }
    
    $MFAMethod = ""
    $MFAMethod = $user.StrongAuthenticationMethods | Where-Object {$_.ISDefault -eq $true} | Select-Object -ExpandProperty MethodType

    if ($user.StrongAuthenticationUserDetails.PhoneNumber){
        $MFAPhone = $user.StrongAuthenticationUserDetails.PhoneNumber
    } else {
        $MFAPhone = ""
    }

    $finalList += ,[PSCustomObject]@{
        DisplayName         = $User.DisplayName
        UserPrincipalName   = $User.UserPrincipalName
        isAdmin             = $isAdmin
        MFAEnabled          = $MfaEnabled
        MFAEnforced         = $MFAEnforced
        MFAMethod           = $MFAMethod
        MFAPhone            = $MFAPhone
    }
}

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