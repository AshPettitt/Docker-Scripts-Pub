#!/bin/bash

# Script variables
TERRAGRUNT_VERSION=v0.44.4

# Update Ubuntu
apt-get update \
&& apt-get upgrade \
&& apt-get dist-upgrade

# Set Locale and TimeZone
echo 'tzdata tzdata/Areas select Europe' | debconf-set-selections \
&& echo 'tzdata tzdata/Zones/Europe select London' | debconf-set-selections \
&& DEBIAN_FRONTEND=noninteractive apt-get install tzdata -y

# Create Directory Structure
mkdir repo

# Install pre-reqs
apt-get install gnupg -y \
&& apt-get install software-properties-common -y \
&& apt-get install curl -y \
&& apt-get install wget -y \
&& apt-get install apt-transport-https -y \
&& apt-get install ca-certificates -y \
&& apt-get install jq -y

# Install Terraform and Packer
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - \
&& apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
&& apt-get update -y \
&& apt-get install terraform -y \
&& apt-get install packer -y

# Install Terragrunt
mkdir -p /ci/terragrunt-${TERRAGRUNT_VERSION}/ \
&& wget -nv -O /ci/terragrunt-${TERRAGRUNT_VERSION}/terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 \
&& chmod u+x /ci/terragrunt-${TERRAGRUNT_VERSION}/terragrunt \
&& cp /ci/terragrunt-${TERRAGRUNT_VERSION}/terragrunt /usr/local/bin \
&& rm -rf /ci

# Install Ansible
apt-add-repository ppa:ansible/ansible -y \
&& apt-get update -y \
&& apt-get install python3-pip -y \
&& apt-get update -y \
&& pip3 install ansible \
&& pip3 install pywinrm \
&& pip3 install pywinrm[credssp] --upgrade cryptography

# Install PowerShell
wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb \
&& dpkg -i packages-microsoft-prod.deb \
&& add-apt-repository universe \
&& apt-get update -y \
&& apt-get install -y powershell

# Install PowerShell Modules
pwsh -Command Install-Module -Name Az -Scope AllUsers -Repository PSGallery -Force

# Install git
apt-get install git -y

# Configure git branch for shell
echo -e "git_branch() {\n  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'\n}" >> ~/.bashrc \
&& echo 'export PS1="\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\u@\h:\w \[\033[00;32m\]\$(git_branch)\[\033[00m\]\$ "' >> ~/.bashrc

# Install kubectl
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg \
&& echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list \
&& apt-get update -y \
&& apt-get install kubectl -y

# Install krew
( set -x; cd "$(mktemp -d)" \
&& OS="$(uname | tr '[:upper:]' '[:lower:]')" \
&& ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" \
&& curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz" \
&& tar zxvf krew.tar.gz \
&& KREW=./krew-"${OS}_${ARCH}" \
&& "$KREW" install krew )
echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"'  >> ~/.bashrc \
&& export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH" \
&& kubectl krew update

# Install Helm
curl https://baltocdn.com/helm/signing.asc | apt-key add - \
&& echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list \
&& apt-get update -y \
&& apt-get install helm -y

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install AWS CLI
apt-get install awscli -y \
&& pip3 install awsume \
&& pip3 install awsume-console-plugin

# Install go
apt-get install golang-go -y

# Install user tools
apt-get install nano -y \
&& apt-get install tree -y \
&& apt-get install vim -y \
&& apt-get install iputils-ping -y \
&& apt-get install traceroute -y

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

# Refresh terminal
source ~/.bashrc
