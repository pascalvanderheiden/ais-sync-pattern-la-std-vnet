# ais-sync-pattern-la-std-vnet

Deploy a Logic App synchronous pattern VNET isolated in a App Service Environment exposed via Front Door and API Management. This deployment can be done by Github Actions or Azure DevOps.

To setup API Management with Azure Front Door, I used this [deployment script](https://github.com/Azure/azure-quickstart-templates/tree/master/quickstarts/microsoft.network/front-door-api-management).

I also used [this blog](https://techcommunity.microsoft.com/t5/azure-paas-blog/integrate-azure-front-door-with-azure-api-management/ba-p/2654925) to get more insights on the process.

To also enable a Web Application Firewall (WAF) in Front Door, I used [this](https://docs.microsoft.com/en-us/azure/web-application-firewall/afds/waf-front-door-create-portal) guide.

In my journey I ran into some networking related issue's. When you are deploying APIM in external mode, everything routes through the VNET. So, this means you still have to open some ports in the Network Security Groups attached to the APIM Subnet, in order to get API Management running appropiattely. Here is a [link](https://docs.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet?tabs=stv2#control-plane-ip-addresses) which tells you which ports to open.

For deployment I choose to do it all in Bicep templates. I haven't done a lot with Bicep yet, so it's about time I do. I got most of my examples from [here](https://github.com/Azure/bicep/tree/main/docs/examples).

For deploying the Logic App (Standard) via [Github Actions](https://github.com/Azure/logicapps/tree/master/github-sample).
For deploying the Logic App (Standard) via [Azure DevOps](https://github.com/Azure/logicapps/tree/master/azure-devops-sample).

## Architecture

![ais-dapr-apim](docs/images/arch.png)

## Prerequisites

* Install [Visual Studio Code](https://code.visualstudio.com/download)
* Install [Azure Logic Apps (Standard)](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurelogicapps) Extension for Visual Studio Code.
* Install [Azurite](https://marketplace.visualstudio.com/items?itemName=Azurite.azurite) Extension for Visual Studio Code.
* Install [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) Extension for Visual Studio Code.
* Install Chocolatey (package manager)

```ps1
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

* Install Azure Function Core Tools (x64 is needed for debugging)

```ps1
choco install azure-functions-core-tools-3 --params "'/x64'"
```

* Install .NET Core SDK

```ps1
choco install dotnetcore-sdk --params "'/x64'"
```

* Install Bicep CLI

```ps1
choco install bicep
```

* Install Az Module in PowerShell

```ps1
Install-Module -Name Az -AllowClobber -Scope CurrentUser
```

* Install Logic App Azure Cli extensions

```ps1
az extension add --name logic
az extension add --yes --source "https://aka.ms/logicapp-latest-py2.py3-none-any.whl"
```

## Deploy Manually

* Git Clone the repository

```ps1
git clone https://github.com/pascalvanderheiden/ais-sync-pattern-la-std-vnet.git
```

* Connect with Azure and set the Subscription to deploy resources to.

```ps1
Connect-AzAccount
Set-AzContext -Subscription "xxxx-xxxx-xxxx-xxxx"
```

* Deploy Azure services (refer to the location of the master.bicep file)

```ps1
New-AzSubscriptionDeployment -name "<deployment_name>" -namePrefix "<project_prefix>" -Location "West Europe" -TemplateFile "<path-to-bicep>" -AsJob
```

* Check on the status of the deployment

```ps1
Get-AzSubscriptionDeployment -Name "<deployment_name>"
```

* Create and deploy your local developed Logic App to Azure
Now everything is setup & ready to create your first workflow. In order to follow an agile development process I use [Visual Studio Code to create my Logic Apps (Standard)](https://docs.microsoft.com/en-us/azure/logic-apps/create-single-tenant-workflows-visual-studio-code) and I use Github to sync, share, deploy & collaborate my code.
I've already prepared a simpel request and response workflow in this repository. Which we can deploy via Visual Studio Code or the Az Cli. 

![ais-dapr-apim](docs/images/logic-app-designer.png)

Because I prepared this solution already for a DevOps approach, I will use the CLI.

First we need to Zip the Logic App project files (in this project I don't have any connections.json, so you can leave that one out)

```ps1
$compress = @{
  Path = ".\<workflow_folder>", ".\connections.json", ".\host.json"
  CompressionLevel = "Fastest"
  DestinationPath = ".\deploy\release\<name of workflow>-deploy.zip"
}
Compress-Archive @compress
```

Now we can deploy it to Azure.

```ps1
az logicapp deployment source config-zip --name "<logicapp_name>" --resource-group "<resource_group>" --subscription "<subscription_id>" --src "\deploy\release\<name of workflow>-deploy.zip"
```

## Deploy via Github Actions

## Deploy via Azure DevOps
