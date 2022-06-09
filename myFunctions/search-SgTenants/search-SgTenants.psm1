function searchAllTenants {
    Clear-Host
    $CustomerSearchResults = findCustomerTenantID $inputCustomerPartial
    return $CustomerSearchResults
}

function searchResultsOne {
    if ($SearchResults.Count -gt 1){
        Clear-Host
        write-output "`n***** More than one result********** `n"
        write-output $SearchResults.name
        write-output "`n***** Search criteria must be unique to ONE customer *****"
        Start-Sleep 5
        exit
    } elseif ($SearchResults.Count -eq 0) {
        Clear-Host
        Write-Output "`n***** No results found for *****`n"
        Start-Sleep 5
    } else {
        Clear-Host
        Write-Output "Found one result: $($SearchResults.Name) `n processing...."
        Start-Sleep 2
    }
}