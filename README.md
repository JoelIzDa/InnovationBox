# Azure: InnovationBox
A standardized Azure-based test environment, known as the “Innobox”, is being developed and offered as a service product within an existing enterprise cloud infrastructure. It is designed to provide internal departments with a preconfigured environment for testing purposes, limited to a maximum usage period of six months. This time constraint is defined as an organisational guideline and is included in the service description. It is not technically enforced but serves to clarify that the environment is not intended for long-term or productive use.

The Innobox enables users to evaluate and experiment with various Azure services such as those available through the Azure Marketplace in a secure and isolated environment. The infrastructure is deployed entirely through Infrastructure as Code (IaC), ensuring consistency, automation, and scalability across all deployments.

This offering aims to lower the barrier to entry for cloud adoption by allowing departments to explore Azure technologies in a low-risk setting. At the same time, it reduces the likelihood of costly project failures caused by unmet expectations or insufficient understanding of cloud capabilities.

The test environment is introduced within a complex and growing cloud ecosystem comprising multiple tenants and over 200 Azure subscriptions, expanding at a rate of approximately 100 subscriptions per year. Throughout this landscape, security and compliance are treated as critical priorities, and all solutions are developed in alignment with established governance and regulatory standards.

## Resource Architecture
The architecture consists of two main components: the on-premises environment and the Azure cloud environment. Within the on-premises Active Directory (App CI), users are assigned to a security group which defines who is entitled to access the Innobox environment. These permissions are automatically applied during deployment via the central DevOps pipeline (ibox-pipeline.yml). This pipeline is triggered by any code changes, and it orchestrates the deployment process using the Azure Resource Manager (ARM) and Bicep templates to provision the required resources.

The deployment assumes that certain core resources—marked as (existing)—are already present in the environment. This design choice was made to preserve the integrity of the customer’s predefined network infrastructure, which is typically provisioned during the initial subscription setup based on organisational standards. Only the subnet is newly created during the deployment, as it is considered a customer-specific configuration that may vary between use cases.

The deployed environment includes a minimal Azure Virtual Desktop (AVD) setup with predefined parameters to provide a functional starting point for customers. These parameters can be modified at any time, allowing customers to adapt the setup to their individual needs.


![Alt text of the image](https://github.com/JoelIzDa/InnovationBox/blob/main/images/plan.png)

## Dynamic Configuration
The entire deployment process is designed with full parameterisation to allow flexible and reusable configurations across different environments. All parameters are centrally managed in a config.json file, which defines both default and environment-specific settings.

Examples:

- The parameter "vmSize" is consistent across all environments (e.g. Development, Integration, Production).

- The parameter "addressPrefix" varies by environment, as each environment may require a different IP address range within the virtual network.

This modular design enables rapid adaptation to new use cases without requiring changes to the core pipeline or templates.

## Pipeline Tasks
The central DevOps pipeline is built to support deployments across multiple environments. The target environment is automatically selected based on the Git branch that triggers the pipeline (e.g. dev, int, or prd). The pipeline is divided into two main stages: Build and Deploy, each comprising a set of well-defined tasks executed sequentially.

### Task: Load Parameters
A PowerShell task that reads configuration values from the config.json file and sets them as environment variables for use in later steps. This ensures that all templates and scripts operate with consistent and dynamically loaded settings.

### Task: Register Encryption Feature
This PowerShell task enables the encryption at host feature within the Azure subscription. This feature must be registered before any virtual machines can be deployed with encryption enabled.

![Alt text of the image](https://github.com/JoelIzDa/InnovationBox/blob/main/images/encryption-at-host-comparison.jpg)

### Task: Deploy Resource Groups
An Azure CLI task that creates the workload resource group where the main components will be deployed. The network resource group is referenced as existing since it was created during the initial subscription setup and is reused here.

### Task: Deploy Network and Workload Resources
An Azure CLI task that sequentially deploys all infrastructure components, including virtual machines, network interfaces, and associated resources. Output variables (e.g. VM names, IP addresses) are passed to the next stage for further processing.

### Task: Hostpool Join
A PowerShell task that registers the deployed VM as a session host in the AVD host pool. It sends a PowerShell script to the VM, which installs the AVD agent and boot loader. A registration token is generated during this process and passed to the VM to complete the registration securely.

### Task: Host Configuration
A PowerShell task that updates the display name of the session host and enables the Start VM on Connect feature. This feature allows users to automatically power on the VM when initiating a remote desktop connection, eliminating the need to manually start the machine in the Azure portal.

### Task: Deployment Infos
The final task generates a detailed deployment summary, including the VM's IP address and other key resource information. This summary serves as a quick reference for verification and documentation purposes.


![Alt text of the image](https://github.com/JoelIzDa/InnovationBox/blob/main/images/DeploymentOverview.png)
