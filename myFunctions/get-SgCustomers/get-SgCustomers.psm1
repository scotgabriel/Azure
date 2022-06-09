function findCustomerTenantID {
    $CustomerSearch = Get-MsolPartnerContract | where-object {$_.Name -match $inputCustomerPartial }
    return $CustomerSearch
}