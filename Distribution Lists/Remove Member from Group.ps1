# Check for required modules
#Requires -Version 5.1
#Requires -Modules @{ ModuleName="MSOnline"; ModuleVersion="1.1" }
#Requires -Modules @{ ModuleName="ExchangeOnlineManagement"; ModuleVersion="3.1" }

# Generic Variables I like to set in all scripts
$DateTime = (Get-Date).ToString('yyyy-MM-dd__HH-mm-ss__ K')

# This should be replaced with text-file call
$CustomerName = "Acme Corp"
$CustomerDistributionListName = "admin"
$CustomerDLMemberToRemove = "jdoe"

# See if we are already connected to MSOL by running an arbitrary command within a connected session, else "connect"
try {
	Get-MsolDomain -ErrorAction Stop
}
catch {
	Write-Host "There is a credential prompt outside of this terminal session... validate and return here. (1 of up to 2)"
	Connect-MsolService
}

# Download all Customer Tenant Objects
$AllCustomers = Get-MsolPartnerContract

# Select the specific Customer Object we're modifying
$CustomerTenant = $allCustomers | Where-object Name -EQ $CustomerName

# Download all Groups from the Tenant
$CustomerAllDistributionLists = Get-MSOLGroup -TenantId $CustomerTenant.TenantId

# Select the DL object we want to modify
$CustomerDistributionList = $CustomerAllDistributionLists | Where-Object DisplayName -EQ $CustomerDistributionListName

# See if we are already connected to Exchange Online by running an arbitrary command within a connected session, else "connect"
try {
	Get-ConnectionInformation -ErrorAction Stop | Out-Null
}
catch {
	Write-Host "There is a credential prompt outside of this terminal session... validate and return here. (2 of 2)"
	Connect-ExchangeOnline -DelegatedOrganization $CustomerTenant.TenantId
}

# Download Group Membership
$CustomerAllGroupMembers = Get-DistributionGroupMember -ResultSize Unlimited -Identity $CustomerDistributionList.DisplayName

# Save groupmembership to text file with timestamp in name (this is a pre-change backup)
##### Code here ######
##### Code here ######
##### Code here ######
##### Code here ######

# How many entries are in this list
Write-Host "Current Member count (including other Groups): " $CustomerAllGroupMembers.Count

# Validate they are a member before removing (sanity check)
If ($CustomerAllGroupMembers -match $CustomerDLMemberToRemove) {
	# Remove Specified Member(s) from the DL
	Write-Host "They are a member, removing them now."
	##### Code here ######
	##### Code here ######
	##### Code here ######
	##### Code here ######
	Write-Host "Rechecking to make sure entry was removed."
	Write-Host "Current Member count (including other Groups): " $CustomerAllGroupMembers.Count
	$CustomerAllGroupMembers = Get-DistributionGroupMember -ResultSize Unlimited -Identity $CustomerDistributionList.DisplayName
	If ($CustomerAllGroupMembers -match $CustomerDLMemberToRemove) {
		Write-Host "Script is failing to remove entry!!!!!"
	}
	else {
		Write-Host "Remove was successful."
	}
}
else {
	Write-Host "They already aren't a member, please double check your inputs."
}

# # Clear your connections to online services
# ## MSOnline
# [Microsoft.Online.Administration.Automation.ConnectMsolService]::ClearUserSessionState()
# ## ExchangeOnline
# Disconnect-ExchangeOnline
