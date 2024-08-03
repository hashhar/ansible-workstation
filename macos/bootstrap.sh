#!/bin/bash

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
brew install python
/usr/local/bin/python3 -m pip install --user ansible paramiko
export PATH="$HOME/Library/Python/3.8/bin:$PATH"
ansible-galaxy install -r requirements.yml

ansible-playbook -i inventory -K main.yml
