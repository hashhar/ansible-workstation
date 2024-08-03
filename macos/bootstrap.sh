#!/bin/bash

set -euo pipefail

if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi
brew install python
python3 -m venv venv
. venv/bin/activate
pip install ansible paramiko
ansible-galaxy install -r requirements.yml

ansible-playbook -i inventory -K main.yml

# Change user's SHELL to brew managed zsh
#sudo dscl . -create /Users/$USER UserShell /usr/local/bin/zsh

# Enable docker completion
#etc=/Applications/Docker.app/Contents/Resources/etc
#ln -s $etc/docker.zsh-completion /usr/local/share/zsh/site-functions/_docker
#ln -s $etc/docker-compose.zsh-completion /usr/local/share/zsh/site-functions/_docker-compose

# Set computer name (as done via System Preferences → Sharing)
sudo scutil --set ComputerName "argon"
sudo scutil --set HostName "argon"
sudo scutil --set LocalHostName "argon"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "argon"
