# ais-sync-pattern-la-std-vnet

Deploy a Logic App synchronous pattern VNET isolated in a App Service Environment exposed via Front Door and API Management.

To setup API Management with Azure Front Door, you can use this [deployment script](https://github.com/Azure/azure-quickstart-templates/tree/master/quickstarts/microsoft.network/front-door-api-management).

I also used [this blog](https://techcommunity.microsoft.com/t5/azure-paas-blog/integrate-azure-front-door-with-azure-api-management/ba-p/2654925) to get more insights on the process.

To also enable a Web Application Firewall (WAF) in Front Door, I used [this](https://docs.microsoft.com/en-us/azure/web-application-firewall/afds/waf-front-door-create-portal) guide.

In my journey I ran into some networking related issue's. When you are deploying APIM in external mode, everything routes through the VNET. So, this means you still have to open some ports in the Network Security Groups attached to the APIM Subnet, in order to get API Management running appropiattely. Here is a [link](https://docs.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet?tabs=stv2#control-plane-ip-addresses) which tells you which ports to open.

## Architecture

## Prerequisites

* Install Visual Studio Code [Visual Studio Code](https://code.visualstudio.com/download)
* Install Azure Logic Apps (Standard) Extension for VSCode [Azure Logic Apps (Standard)](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurelogicapps)
* Install Azurite Extension for VSCode [Azurite](https://marketplace.visualstudio.com/items?itemName=Azurite.azurite)
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

## Setup

<<<<<<< HEAD
=======
* Using Ngrok to expose port 7071 accessible over the internet

```ps1
ngrok http -host-header=localhost 7071
```

have to create nuget project for deployment
>>>>>>> 7f59943c692064c07fd834b0951d6f85e82aff96
