#!/bin/bash

set -euo pipefail

if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi
if ! command -v python &>/dev/null; then
    brew install python
fi
python3 -m venv venv
. venv/bin/activate
pip install ansible paramiko
ansible-galaxy install -r requirements.yml

ansible-playbook -i inventory -K main.yml

# Change user's SHELL to brew managed zsh
sudo dscl . -create /Users/$USER UserShell /opt/homebrew/bin/zsh
