# RL Loop Deployment

This guide provides step-by-step instructions to deploy the RL Loop in Azure.

## Prerequisites

Before you begin, ensure you have the following:

- An active Azure subscription ([or create one](https://azure.microsoft.com/en-us/free/))
- [Azure CLI installed](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Bicep CLI installed](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli) (can be installed via Azure CLI)

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
    git clone https://github.com/your-repo/rl_loop_deployment.git
    cd rl_loop_deployment/deploy
    ```

## Deployment Steps

1. **Create a Resource Group:**
    Create a resource group if needed (exmaple below).

    ```powershell
    az group create --name myResourceGroup --location eastus
    ```

2. **Image Repository Access**
    Depending on the image source, there are two options for connecting to the image repository:

    - Managed Identity Access
    If using managed identity, set the registry object in the container's configuration as follows (see sample.biceparam):

    ```json
    registry: {
        host: 'acrhost.io', // e.g., docker.io, myacr.azurecr.io, etc.
        credentials: {
            isManagedIdentity: true,
            username: null,
            password: null
        }
    }
    ```

    - Username/Password
    If using a username and password, set the registry object in the container's configuration as follows (see sample.biceparam):

    ```json
    registry: {
        host: 'acrhost.io', // e.g., docker.io, myacr.azurecr.io, etc.
        credentials: {
            isManagedIdentity: false,
            username: 'myusername',
            password: 'mypassword'
        }
    }
    ```

    It is recommended that the password not be supplied directly in the params file. One option is to pass an additional parameter via the command line where the password can be pulled from a [key vault](https://learn.microsoft.com/en-us/azure/key-vault/general/quick-create-portal) as follows:

    ```powershell
    az deployment group create --resource-group myResourceGroup --name sample_loop \
        --parameters sample.bicepparam \
        --parameters acr_secret=$(az keyvault secret show --name image --vault-name kv-rl-loop --query value -o tsv)
    ```
3. **Deploy the RL Loop using Bicep:**
   See the deployment [readme](deploy/README.md) for more information on how to customize your deployment.

    ```powershell
    az deployment group create --resource-group myResourceGroup --name sample_loop --parameters sample.bicepparam
    ```

4. **Verify Deployment:**

    Check the Azure portal to ensure all resources are deployed correctly.

## Post-Deployment

1. **Access the Application:**

    Navigate to the deployed container application in the resource group. The container for the sample deployment is called `sample_loopcg`.

2. **Monitor and Manage:**

    Use Azure Portal to monitor the performance and manage the resources.

3. **Use [rl_sim](#running-rl_sim-against-your-loop) to simulate training:**

## Running rl_sim agaist your loop

   The detals building rl_sim are locating in project [reinforcement_learning](https://github.com/VowpalWabbit/reinforcement_learning/tree/master#rl-client-library).

1. Build [reinforcement_learning](https://github.com/VowpalWabbit/reinforcement_learning/tree/master#rl-client-library)
2. Setup your rl_sim settings

   ```powershell
   todo: add description here
   ```   

3. Run rl_sim

   ```powershell
   todo: add description here
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
