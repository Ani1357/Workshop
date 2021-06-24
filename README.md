### Workshop

## Tasks:

1-Use Terraform to deploy infrastructure in Azure/AWS ( Linux Images, 3 VMs)

2-Deploy and Configure A Kubernetes Cluster 1Master-2Worker using Ansible ( do NOT use the kubernetes service provided by the cloud provider). Deploy this cluster within the provisioned infrastructure with Terraform. Run the Ansible role during Terraform Run

3-Install and Configure Jenkins inside Kubernetes using Helm

4- Build a CI/CD Pipeline in Jenkins via Jenkinsfile for deploying a “Hello Word” Java Application inside the Kubernetes Cluster

# Prerequisites:

1- Install Terraform

2- Install Ansible

3- Configure AWS credentials (The TF script uses $HOME/.aws/credentials to retrive credentials)

4- Generate a ssh keypair (will use the public key inside the TF script)

* you can run the setup.sh script to install ansible and aws-cli