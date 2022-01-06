# ais-sync-pattern-la-std-vnet

Deploy a Logic App synchronous pattern VNET isolated in a App Service Environment exposed via Front Door and API Management. This deployment can be done by Github Actions or Azure DevOps.

To setup API Management with Azure Front Door, I used this [deployment script](https://github.com/Azure/azure-quickstart-templates/tree/master/quickstarts/microsoft.network/front-door-api-management).

I also used [this blog](https://techcommunity.microsoft.com/t5/azure-paas-blog/integrate-azure-front-door-with-azure-api-management/ba-p/2654925) to get more insights on the process.

To also enable a Web Application Firewall (WAF) in Front Door, I used [this](https://docs.microsoft.com/en-us/azure/web-application-firewall/afds/waf-front-door-create-portal) guide.

In my journey I ran into some networking related issue's. When you are deploying APIM in external mode, everything routes through the VNET. So, this means you still have to open some ports in the Network Security Groups attached to the APIM Subnet, in order to get API Management running appropiattely. Here is a [link](https://docs.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet?tabs=stv2#control-plane-ip-addresses) which tells you which ports to open.

For deployment I choose to do it all in Bicep templates. I haven't done a lot with Bicep yet, so it's about time I do. I got most of my examples from [here](https://github.com/Azure/bicep/tree/main/docs/examples). 

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

* Deploy Azure services

```ps1
New-AzSubscriptionDeployment -namePrefix "<project_prefix>" -Location "West Europe" -TemplateFile "<path-to-bicep>"
```

## Deploy via Github Actions

## Deploy via Azure DevOps
