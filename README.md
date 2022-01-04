# ais-sync-pattern-la-std-vnet

Deploy a Logic App synchronous pattern VNET isolated in a App Service Environment exposed via Front Door and API Management.

## Prerequisites

* Install Visual Studio Code [Visual Studio Code](https://code.visualstudio.com/download)
* Install Azure Function Core Tools [Azure Functions Core Tools](https://github.com/Azure/azure-functions-core-tools) - (x64 is needed for debugging)
* Install Azure Logic Apps (Standard) Extension for VSCode [Azure Logic Apps (Standard)](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurelogicapps)
* Install Azurite Extension for VSCode [Azurite](https://marketplace.visualstudio.com/items?itemName=Azurite.azurite)
* Install ngrok

```ps1
 choco install ngrok
```

## Setup

* Using Ngrok to expose port 7071 accessible over the internet

```ps1
ngrok http -host-header=localhost 7071
```

have to create nuget project for deployment