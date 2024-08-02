<#
.SYNOPSIS
   This script generates a rl_sim configuration file for a given application id and resource group name.

.DESCRIPTION
   This script generates a rl_sim configuration file for a given application id and resource group name.
   The configuration file is written to the specified file name.

   This script assumes that the eventhub and storage resources are already created in the specified resource group.

.PARAMETER appId
   The application id supplied in the deployment script.

.PARAMETER resourceGroupName
   The resource group name where the eventhub and storage resources are located.

.PARAMETER configFilename
   The name of the rl_sim configuration file to generate.

.EXAMPLE
   generate-rl-sim-config.ps1 -appId "myapp" -resourceGroupName "myrg" -configFilename "rl_sim_config.json"
#>
param(
   [Parameter(Mandatory=$true, HelpMessage="the application id supplied in the deployment script")]
   [string]$appId,

   [Parameter(Mandatory=$true, HelpMessage="the resource group name where the eventhub and storage resources are located")]
   [string]$resourceGroupName,

   [Parameter(Mandatory=$true, HelpMessage="the name of the configuration file to generate")]
   [string]$configFilename
)

$activity = "Generating rl_sim config for $appId"
$eventhubname = $appId + "eh"
Write-Progress -Activity $activity -Status "pulling parameters from resource group $resourceGroupName" -PercentComplete 0
$ehEndpoint = az eventhubs namespace authorization-rule keys list --resource-group $resourceGroupName --namespace-name $eventhubname --name RootManageSharedAccessKey --query primaryConnectionString --output tsv

Write-Progress -Activity $activity -Status "writing file $configFilename..." -PercentComplete 90
$rlSimConfig = @"
{
   "ApplicationID": "$appId",
   "IsExplorationEnabled": true,
   "InitialExplorationEpsilon": 1.0,
   "EventHubInteractionConnectionString": "$ehEndpoint;EntityPath=interaction",
   "EventHubObservationConnectionString": "$ehEndpoint;EntityPath=observation",
   "model.vw.initial_command_line": "--cb_explore_adf --epsilon 0.2 --power_t 0 -l 0.001 --cb_type ips -q ::",
   "protocol.version": 2,
   "model.source": "FILE_MODEL_DATA"
}
"@

$rlSimConfig | Out-File -FilePath $configFilename -Encoding ascii
Write-Output "Generated rl_sim config file: $configFilename"
Get-Content $configFilename
