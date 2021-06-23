# For this project I'm working on Ubuntu 20.04 Windows WSL. 
# This setup file assumes you are using the same setup although it should work on other debian/ubuntu based distros

sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl, zip

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
sudo apt install bash-completion -y
source /usr/share/bash-completion/bash_completion
echo 'source <(kubectl completion bash)' >>~/.bashrc
kubectl completion bash > kubectl
sudo mv kubectl /etc/bash_completion.d/kubectl

# Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform
terraform -install-autocomplete
terraform init

# Ansible
sudo apt install ansible -y

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip


