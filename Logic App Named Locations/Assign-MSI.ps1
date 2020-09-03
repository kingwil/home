Connect-AzureAD

#Object ID of the Logic App MSI
$managedIdentityId = "<guid>" 

# MS Graph API object ID
$msGraph = Get-AzureADServicePrincipal -Filter "AppID eq '00000003-0000-0000-c000-000000000000'"

#Policy.Read.All permission
$roleId = $msGraph.AppRoles| Where-Object {$_.value -eq "Policy.Read.All"}


New-AzureADServiceAppRoleAssignment -ObjectId $managedIdentityId -PrincipalId $managedIdentityId -ResourceId $msGraph.ObjectId -Id $roleId.Id