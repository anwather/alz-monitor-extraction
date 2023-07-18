Param($TenantId, $Location)

(Get-Content ./assets/mg-structure.json) -replace '""', "`"$tenantId`"" | Set-Content ./assets/mg-structure.json

./assets/deploy-ManagementGroupStructure.ps1 -TenantId $TenantId -Location $Location

$gs = @"
{
    "pacOwnerId": "4f5222f0-6677-4987-8de6-6fbc97ab631f",
    "managedIdentityLocations": {
        "*": "$Location"
    },
    "globalNotScopes": {
        "*": [
            "/resourceGroupPatterns/excluded-rg*"
        ]
    },
    "pacEnvironments": [
        {
            "pacSelector": "alz-monitor",
            "cloud": "AzureCloud",
            "tenantId": "$tenantId",
            "deploymentRootScope": "/providers/Microsoft.Management/managementGroups/alz"
        }
    ]
}
"@

New-EPACDefinitionFolder -DefinitionsRootFolder Definitions

$gs | Out-File ./Definitions/global-settings.jsonc

git clone https://github.com/Azure/alz-monitor.git tmp

Copy-Item ./tmp/src/scripts/Start-ALZMonitorCleanup.ps1 ./assets/Start-ALZMonitorCleanup.ps1

$pseudoRootManagementGroup = "alz"
$identityManagementGroup = "alz-monitor-identity"
$managementManagementGroup = "alz-monitor-management"
$connectivityManagementGroup = "alz-monitor-connectivity"
$LZManagementGroup = "alz-monitor-lzones"

#Deploy policy definitions
New-AzManagementGroupDeployment -ManagementGroupId $pseudoRootManagementGroup -Location $Location -TemplateFile ./tmp/infra-as-code/bicep/deploy_dine_policies.bicep

Start-Sleep -Seconds 180
  
#Deploy policy initiatives, wait approximately 1-2 minutes after deploying policies to ensure that there are no errors when creating initiatives
New-AzManagementGroupDeployment -ManagementGroupId $pseudoRootManagementGroup -Location $Location -TemplateFile ./tmp/src/resources/Microsoft.Authorization/policySetDefinitions/ALZ-MonitorConnectivity.json
New-AzManagementGroupDeployment -ManagementGroupId $pseudoRootManagementGroup -Location $Location -TemplateFile ./tmp/src/resources/Microsoft.Authorization/policySetDefinitions/ALZ-MonitorIdentity.json
New-AzManagementGroupDeployment -ManagementGroupId $pseudoRootManagementGroup -Location $Location -TemplateFile ./tmp/src/resources/Microsoft.Authorization/policySetDefinitions/ALZ-MonitorManagement.json
New-AzManagementGroupDeployment -ManagementGroupId $pseudoRootManagementGroup -Location $Location -TemplateFile ./tmp/src/resources/Microsoft.Authorization/policySetDefinitions/ALZ-MonitorLandingZone.json
New-AzManagementGroupDeployment -ManagementGroupId $pseudoRootManagementGroup -Location $Location -TemplateFile ./tmp/src/resources/Microsoft.Authorization/policySetDefinitions/ALZ-MonitorServiceHealth.json

Start-Sleep -Seconds 180

#Assign Policy Initiatives, wait approximately 1-2 minutes after deploying initiatives policies to ensure that there are no errors when assigning them
New-AzManagementGroupDeployment -ManagementGroupId $identityManagementGroup -Location $Location -TemplateFile ./tmp/infra-as-code/bicep/assign_initiatives_identity.bicep -TemplateParameterFile ./tmp/infra-as-code/bicep/parameters-complete-identity.json
New-AzManagementGroupDeployment -ManagementGroupId $managementManagementGroup -Location $Location -TemplateFile ./tmp/infra-as-code/bicep/assign_initiatives_management.bicep -TemplateParameterFile ./tmp/infra-as-code/bicep/parameters-complete-management.json
New-AzManagementGroupDeployment -ManagementGroupId $connectivityManagementGroup -Location $Location -TemplateFile ./tmp/infra-as-code/bicep/assign_initiatives_connectivity.bicep -TemplateParameterFile ./tmp/infra-as-code/bicep/parameters-complete-connectivity.json
New-AzManagementGroupDeployment -ManagementGroupId $LZManagementGroup -Location $Location -TemplateFile ./tmp/infra-as-code/bicep/assign_initiatives_landingzones.bicep -TemplateParameterFile ./tmp/infra-as-code/bicep/parameters-complete-landingzones.json
New-AzManagementGroupDeployment -ManagementGroupId $pseudoRootManagementGroup -Location $Location -TemplateFile ./tmp/infra-as-code/bicep/assign_initiatives_servicehealth.bicep -TemplateParameterFile ./tmp/infra-as-code/bicep/parameters-complete-servicehealth.json

Start-Sleep -Seconds 180

Remove-Item -Path tmp -Recurse -Force

Export-AzPolicyResources -DefinitionsRootFolder ./Definitions -OutputFolder Output

Copy-Item ./Output/Definitions/policyDefinitions ./Definitions -Force -Recurse
Copy-Item ./Output/Definitions/policySetDefinitions ./Definitions -Force -Recurse
Copy-Item ./Output/Definitions/policyAssignments ./Definitions -Force -Recurse

Remove-Item -Path Output -Recurse -Force

Remove-Item -Path ./Definitions/global-settings.jsonc -Force

## Remove managed identity parts

## Fix missing displaynames in the policy set definitions

./assets/Start-ALZMonitorCleanup.ps1 -Force

Remove-Item -Path ./assets/Start-ALZMonitorCleanup.ps1 -Force





