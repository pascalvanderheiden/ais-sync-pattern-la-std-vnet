param ($subscriptionId, $deploymentNameBuild, $deploymentNameRelease, $namePrefix, $workflowName, $apiName, $apiPath)

Write-Host "Setting the paramaters:"
$location = "West Europe"
$resourceGroup = "$namePrefix-rg"
$buildBicepPath = ".\deploy\build\main.bicep"
$releaseBicepPath = ".\deploy\release\$workflowName-deploy-api.bicep"
$logicAppName = "$namePrefix-la"
$workflowPath = ".\$workflowName"
$destinationPath = ".\deploy\release\$workflowName-deploy.zip"
$apimNameValueSig = "$workflowName-sig"
Write-Host "Subscription id: "$subscriptionId
Write-Host "Deployment Name Build: "$deploymentNameBuild
Write-Host "Deployment Name Release: "$deploymentNameRelease
Write-Host "Resource Group: "$resourceGroup
Write-Host "Location: "$location
Write-Host "Build by Bicep File: "$buildBicepPath
Write-Host "Release by Bicep File: "$releaseBicepPath
Write-Host "Logic App Name: "$logicAppName
Write-Host "Workflow Name: "$workflowName
Write-Host "Workflow directory: "$workflowPath
Write-Host "Output Path Workflow deployment: "$destinationPath
Write-Host "API Name: "$apiName
Write-Host "API Path: "$apiPath


Write-Host "Login to Azure:"
Connect-AzAccount
Set-AzContext -Subscription $subscriptionId

Write-Host "Deploy Infrastructure as Code:"
New-AzSubscriptionDeployment -name $deploymentNameBuild -namePrefix $namePrefix -Location $location -TemplateFile $buildBicepPath

Write-Host "Retrieve API Management Instance Name:"
$apimName = az apim list --resource-group $resourceGroup --subscription $subscriptionId --query "[].{Name:name}" -o tsv
Write-Host $apimName

Write-Host "Package workflow:"
$compress = @{
    Path = $workflowPath, ".\connections.json", ".\host.json"
    CompressionLevel = "Fastest"
    DestinationPath = $destinationPath
}
Compress-Archive @compress

# werk niet.
Write-Host "Release Workflow to Logic App:"
az logicapp deployment source config-zip --name $logicAppName --resource-group $resourceGroup --subscription $subscriptionId --src $destinationPath

Write-Host "Retrieve SAS Key and store in API Management as Named Value:"
.\deploy\release\get-saskey-from-logic-app.ps1 -subscriptionId $subscriptionId -resourceGroup $resourceGroup -logicAppName $logicAppName -workflowName $workflowName -apimName $apimName -apimNamedValueSig $apimNameValueSig

Write-Host "Release API definition to API Management:"
New-AzResourceGroupDeployment -Name $deploymentNameRelease -ResourceGroupName $resourceGroup -apimName $apimName -logicAppName $logicAppName -workflowName $workflowName -workflowSigNamedValue $apimNameValueSig -apiName $apiName -apiPath $apiPath -TemplateFile $releaseBicepPath -AsJob