$Domains = $null
# Get all SMTP domains used in Exchange Online.
$Domains = Get-Mailbox -ResultSize Unlimited | `
    Select-Object EmailAddresses -ExpandProperty EmailAddresses | `
    Where-Object { $_ -like "smtp*"} | `
    ForEach-Object { ($_ -split "@")[1] } | `
    Sort-Object -Unique

# comment out this line if pulling from online
# $Domains = 'contoso.com'

# Verify DKIM DMARC and MX records.
Write-Output "-------- DKIM DMARC and MX DNS Records Report --------"
Write-Output ""

$Result = foreach ($Domain in $Domains) {
    Write-Output "---------------------- $Domain ----------------------"
    Write-Output "DKIM Selector 1 CNAME Record:"
    nslookup -q=cname selector1._domainkey.$Domain | Select-String "canonical name"
    Write-Output ""
    Write-Output "DKIM Selector 2 CNAME Record:"
    nslookup -q=cname selector2._domainkey.$Domain | Select-String "canonical name"
    Write-Output ""
    Write-Output "DMARC TXT Record:"
    (nslookup -q=txt _dmarc.$Domain | Select-String "DMARC1") -replace "`t", ""
    Write-Output ""
    Write-Output "SPF TXT Record:"
    (nslookup -q=txt $Domain | Select-String "spf1") -replace "`t", " "
    Write-Output ""
    Write-Output "MX records:"
    (nslookup -q=mx $Domain) -replace "`tinternet address", ""
    Write-Output "-----------------------------------------------------"
    Write-Output ""
    Write-Output ""
}
$Result #| Clip