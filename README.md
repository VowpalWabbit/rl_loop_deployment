# RL Loop Deployment

This guide provides step-by-step instructions to deploy the RL Loop in Azure.

## Prerequisites

Before you begin, ensure you have the following:
- An active Azure subscription ([or create one](https://azure.microsoft.com/en-us/free/))
- [Azure CLI installed](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Bicep CLI installed](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli) (can be installed via Azure CLI)
- Docker
    rl_loop is in the process of releasing to open-source along with an official Docker repository. In the interim, you will need to load an image into your own repository.
    - Install the [Docker Engine](https://docs.docker.com/engine/install/)
    - Create a container registry (eg. [Docker Hub](https://app.docker.com/signup) or an [Azure Container Registry](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-get-started-portal?tabs=azure-cli))

## Setup

1. **Login to Azure:**

    ```powershell
    az login
    ```

2. **Install Bicep CLI (if not already installed - [Bicep CLI Install Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli))**

    ```powershell
    az bicep install
    ```

3. **Clone the repository:**

    ```powershell
    git clone https://github.com/VowpalWabbit/rl_loop_deployment.git
    cd rl_loop_deployment/deploy
    ```

4. **Load the rl_loop image ([located here](https://github.com/VowpalWabbit/rl_loop_image)) to a container registry**

    Load `rl_loop_image.tar` to a container registry such as Docker Hub or an Azure Container Registry. The procedure for both is similar.

    **Docker Hub**
    ```powershell
    docker load -i rl_loop_image.tar
    docker tag personalizerstandaloneintegrationtest.azurecr.io/personalizerstandalone:<version-tag> <myname-or-organization>/rl_loop:latest
    docker login
    docker push <myname-or-organization>/rl_loop:latest
    ```

    **Azure Container Registry**
    ```powershell
    docker load -i rl_loop_image.tar
    docker tag personalizerstandaloneintegrationtest.azurecr.io/personalizerstandalone:<version-tag> <my-acr>.azurecr.io/rl_loop:latest
    az login
    az acr login --name <my-acr>
    az acr show --name <my-acr> --query loginServer --output table
    docker push <my-acr>.azurecr.io/rl_loop:latest
    ```

## Deployment Steps

1. **Create a Resource Group:**

    Create a resource group if needed (exmaple below).

    ```powershell
    az group create --name myResourceGroup --location eastus
    ```

2. **Image Repository Access**

    Depending on the image source, there are three options for authenticating with the image repository:

    **Credentials via Managed Identity**

    Using managed identity by setting the registry object in the container's configuration as follows (see sample.bicepparam):

    ```
    // set the mainConfig.registry object in the bicepparam file
    registry: {
        host: 'acrhost.io', // e.g., docker.io, myacr.azurecr.io, etc.
        credentials: {
            type: 'managedIdentity',
            username: 'identity',
            password: null
        }
    }
    ```

    **Credentials via a Key Vault ([how to create a Key Vault?](https://learn.microsoft.com/en-us/azure/key-vault/general/quick-create-portal))**

    Use a Key Vault by setting the registry object for the container's configuration as follows (see sample.biceparam):

    ```
    
    // get the secrets from the key vault in the bicepparam file
    param kvImageRegistryUsername = getSecret('mysubscriptionid', 'myresourcegroup', 'keyvaultname', 'imageRegistryUsername')
    param kvImageRegistryPassword = getSecret('mysubscriptionid', 'myresourcegroup', 'keyvaultname', 'imageRegistryPassword')

    ...

    // set the mainConfig.registry object in the bicepparam file
    registry: {
        host: 'acrhost.io', // e.g., docker.io, myacr.azurecr.io, etc.
        credentials: {
            type: 'keyVault'
        }
    }
    ```

    **Credentials via Username/Password**

    Using explicity username and password by setting the registry object in the container's configuration as follows (see sample.biceparam):

    <span style="color:yellow">Note: this method is not recommended</span>

    ```
    // set the mainConfig.registry object in the bicepparam file
    registry: {
        host: 'acrhost.io', // e.g., docker.io, myacr.azurecr.io, etc.
        credentials: {
            type: 'usernamePassword',
            username: 'myusername',
            password: 'mypassword'
        }
    }
    ```

3. **Deploy the RL Loop using Bicep:**

   See the deployment [readme](deploy/README.md) for more information on how to customize your deployment.

    ```powershell
    az deployment group create --resource-group myResourceGroup --name sample_loop  --rollback-on-error --parameters sample.bicepparam
    ```

4. **Verify Deployment:**

    Check the Azure portal to ensure all resources are deployed correctly.

## Post-Deployment

1. **Access the Application:**

    Navigate to the deployed container application in the resource group. The container for the sample deployment is called `sample_loopcg`.

2. **Monitor and Manage:**

    Use Azure Portal to monitor the performance and manage the resources.

3. **Use [rl_sim](#running-rl_sim-against-your-loop) to simulate training:**

## Running rl_sim against your loop

   The details building rl_sim are located in project [reinforcement_learning](https://github.com/VowpalWabbit/reinforcement_learning/tree/master#rl-client-library).

1. Build [reinforcement_learning](https://github.com/VowpalWabbit/reinforcement_learning/tree/master#rl-client-library)
2. Setup your rl_sim settings

   ```powershell
   ./generate-rl-sim-config.ps1 -appId sample_loop -resourceGroupName myResourceGroup -configFilename rl-sim-config.json
   ```   

3. Run rl_sim
   After building [reinforcement_learning](https://github.com/VowpalWabbit/reinforcement_learning/tree/master#rl-client-library) execute the r_rim_cpp simulator.  This file is located in the following path.

   ```
   reinforcement_learning/build/binaries/Debug
   or
   reinforcement_learning/build/binaries/Release
   ```

   ```powershell
   rl_sim_cpp.out.exe -j ./rl-sim-config.json
   ```   

## Cleanup

To clean up resources resulting from the provided Bicep scripts, use the `az` command to remove all resources with the specified deployment tag as follows.

Note: The deployment tag is specified during deployment as an optional parameter (see `sample.bicepparam`).

   ```powershell
   az resource list --resource-group rg_test_rl_loop --query "[?tags.deploymentGroupName=='sample_loop'].id" -o tsv | % { az resource delete --ids $_ }
   ```   

## Troubleshooting

- **Common Issues:**

  - Ensure all prerequisites are met.
  - Verify Azure CLI and Bicep CLI are up to date.
  - Check for any error messages in the deployment output.

- **Useful Commands:**

  - To view deployment logs:
    ```powershell
    az deployment group show --resource-group myResourceGroup --name sample_loop
    ```

## Additional Resources

- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
