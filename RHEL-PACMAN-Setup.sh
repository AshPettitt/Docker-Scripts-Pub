#!/bin/bash

# Install yum-utils
yum -y install yum-utils

# Install dev tools
dnf groups mark install "Development Tools"
dnf groupinstall "Development Tools"

# Install homebrew
curl -fsSL -o brew-install.sh https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
/bin/bash brew-install.sh

# Add the MS repo
curl https://packages.microsoft.com/config/rhel/8/prod.repo | tee /etc/yum.repos.d/microsoft.repo

# Add the hashicorp repo
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

# Add gh cli repo
yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo

# Add the kubernetes repo
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Add the docker repo
cat <<EOF > /etc/yum.repos.d/docker.repo
[docker-ce-stable]
name=Docker CE Stable
baseurl=https://download.docker.com/linux/centos/8/x86_64/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF

# Add azure-cli repo
rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/azure-cli.repo

# Upgrade the image
dnf -y upgrade

# Install all the needed tools
dnf -y install \
net-tools \
bind-utils \
wget \
curl \
sudo \
unzip \
python3.9 \
azure-cli \
openssl \
git \
vim \
iputils \
procps-ng \
powershell \
terraform \
kubectl \
jq \
lttng-ust \
openssl-libs \
krb5-libs \
zlib \
libicu \
gh \
nodejs \
docker-ce \
docker-ce-cli \
containerd.io

# Install packer
version=$(yum info packer | grep Version | cut -d : -f2 | sed 's/ //g')
curl -o "packer_${version}_linux_amd64.zip" -L "https://releases.hashicorp.com/packer/${version}/packer_${version}_linux_amd64.zip"
unzip "packer_${version}_linux_amd64.zip"
chmod +x packer
mv packer /usr/local/bin/
rm -f "packer_${version}_linux_amd64.zip"

# Install Terragrunt
brew install terragrunt

# Install HELM
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Install krew
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)
echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"'  >> ~/.bashrc
source ~/.bashrc
kubectl krew update
kubectl krew install access-matrix blame config-registry get-all images ingress-nginx outdated podevents pod-inspect popeye psp-util rbac-tool rbac-view resource-capacity resource-snapshot resource-versions service-tree ssh-jump status tail unused-volumes view-allocations viewnode view-secret whoami who-can

# Install the aks-preview extension
az extension add --name aks-preview

# Install wheel
pip3.9 install --no-cache-dir wheel

# Install python packages
pip3.9 install --install --upgrade \
setuptools \
pip \
virtualenv \
wheel \
cryptography

pip3.9 install \
pywinrm \
pywinrm[credssp] \
ansible
ansible-galaxy collection install azure.azcollection
pip3.9 install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements-azure.txt

# Remove all downloaded packages
dnf -y clean all

# Install the PowerShell Az module
pwsh -Command "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; Install-Module -Name Az -Scope AllUsers -Force -Verbose"

# Install VSCODE Extensions
echo Do you want to install Visual Studio Code Extensions [y/n]?
read varcode

if [ $varcode == "y" ]
then
  code --install-extension alefragnani.project-manager
  code --install-extension bencoleman.armview
  code --install-extension codezombiech.gitignore
  code --install-extension donjayamanne.git-extension-pack
  code --install-extension donjayamanne.githistory
  code --install-extension eamodio.gitlens
  code --install-extension GitHub.vscode-pull-request-github
  code --install-extension hashicorp.terraform
  code --install-extension ms-azure-devops.azure-pipelines
  code --install-extension ms-azuretools.vscode-azureappservice
  code --install-extension ms-azuretools.vscode-azurefunctions
  code --install-extension ms-azuretools.vscode-azureresourcegroups
  code --install-extension ms-azuretools.vscode-azurestorage
  code --install-extension ms-azuretools.vscode-azurevirtualmachines
  code --install-extension ms-azuretools.vscode-bicep
  code --install-extension ms-azuretools.vscode-cosmosdb
  code --install-extension ms-azuretools.vscode-docker
  code --install-extension ms-dotnettools.vscode-dotnet-runtime
  code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
  code --install-extension ms-vscode.azure-account
  code --install-extension ms-vscode.azurecli
  code --install-extension ms-vscode.vscode-node-azure-pack
  code --install-extension msazurermtools.azurerm-vscode-tools
  code --install-extension redhat.vscode-yaml
  code --install-extension ziyasal.vscode-open-in-github
fi

# Git global config
echo Do you want to configure git global user settings [y/n]?
read vargit

if [ $vargit != "y" ]
then
  exit 0
fi

echo Enter your name for git config
read varname
echo Enter your email address for git config
read varemail

git config --global --add user.name "$varname"
git config --global --add user.email "$varemail"

# Configure git branch for shell
echo -e "git_branch() {\n  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'\n}" >> ~/.bashrc
echo 'export PS1="\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\u@\h:\w \[\033[00;32m\]\$(git_branch)\[\033[00m\]\$ "' >> ~/.bashrc

# Create the code directory
mkdir code

# Refresh terminal
source ~/.bashrc
