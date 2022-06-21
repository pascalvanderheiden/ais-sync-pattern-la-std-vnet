param ($subscriptionId, $deploymentNameBuild, $deploymentNameRelease, $namePrefix, $workflowName, $apiName, $apiPath)

Write-Host "Setting the paramaters:"
$location = "West Europe"
$resourceGroup = "$namePrefix-rg"
$buildBicepPath = ".\deploy\build\main.bicep"
$releaseBicepPath = ".\deploy\release\$workflowName-deploy-api.bicep"
$logicAppName = "$namePrefix-la"
$appInsightsName = "$namePrefix-ai"
$workflowPath = ".\$workflowName"
$destinationPath = ".\deploy\release\$workflowName-deploy.zip"
$apimNameValueSig = "$workflowName-sig"
$frontDoorIdNamedValue = "$namePrefix-fd-id"

Write-Host "Subscription id: "$subscriptionId
Write-Host "Deployment Name Build: "$deploymentNameBuild
Write-Host "Deployment Name Release: "$deploymentNameRelease
Write-Host "Resource Group: "$resourceGroup
Write-Host "Location: "$location
Write-Host "Build by Bicep File: "$buildBicepPath
Write-Host "Release by Bicep File: "$releaseBicepPath
Write-Host "Logic App Name: "$logicAppName
Write-Host "Application Insights Name: "$appInsightsName 
Write-Host "Workflow Name: "$workflowName
Write-Host "Workflow directory: "$workflowPath
Write-Host "Output Path Workflow deployment: "$destinationPath
Write-Host "API Name: "$apiName
Write-Host "API Path: "$apiPath

Write-Host "Login to Azure:"
Connect-AzAccount
Set-AzContext -Subscription $subscriptionId

Write-Host "Deploy Infrastructure as Code:"
New-AzSubscriptionDeployment -name $deploymentNameBuild -namePrefix $namePrefix -location $location -TemplateFile $buildBicepPath

Write-Host "Retrieve API Management Instance Name:"
$apimName = az apim list --resource-group $resourceGroup --subscription $subscriptionId --query "[].{Name:name}" -o tsv
Write-Host $apimName

Write-Host "Retrieve Storage Account Name & Key Name:"
$storageAccountName = az storage account list -g $resourceGroup --subscription $subscriptionId --query "[].{Name:name}" -o tsv
$storageKey = az storage account keys list -g $resourceGroup -n $storageAccountName --query "[0].{Name:value}" -o tsv
Write-Host $storageAccountName

#Write-Host "Release Workflow to Logic App:"
#$compress = @{
#    Path = $workflowPath, ".\host.json"
#    CompressionLevel = "Fastest"
#    DestinationPath = $destinationPath
#}
#Compress-Archive @compress

#az logicapp deployment source config-zip --name $logicAppName --resourcegroup $resourceGroup --subscription $subscriptionId --src $destinationPath
az storage file upload --account-name $storageAccountName --account-key $storageKey --share-name $logicAppName --path "site/wwwroot/host.json" --source ".\host.json"
#az storage file upload --account-name $storageAccountName --account-key $storageKey --share-name $logicAppName --path "site/wwwroot/connections.json" --source ".\connections.json"
az storage directory create --account-name $storageAccountName --account-key $storageKey --name "site/wwwroot/$workflowName" --share-name $logicAppName
az storage file upload --account-name $storageAccountName --account-key $storageKey --share-name $logicAppName --path "site/wwwroot/$workflowName/workflow.json" --source ".\$workflowName\workflow.json"

Write-Host "Retrieve SAS Key and store in API Management as Named Value:"
.\deploy\release\get-saskey-from-logic-app.ps1 -subscriptionId $subscriptionId -resourceGroup $resourceGroup -logicAppName $logicAppName -workflowName $workflowName -apimName $apimName -apimNamedValueSig $apimNameValueSig

Write-Host "Release API definition to API Management:"
New-AzResourceGroupDeployment -Name $deploymentNameRelease -ResourceGroupName $resourceGroup -apimName $apimName -appInsightsName $appInsightsName -logicAppName $logicAppName -workflowName $workflowName -workflowSigNamedValue $apimNameValueSig -frontDoorIdNamedValue $frontDoorIdNamedValue -apiName $apiName -apiPath $apiPath -TemplateFile $releaseBicepPath