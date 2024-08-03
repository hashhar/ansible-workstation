#!/bin/bash

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
brew install python
/usr/local/bin/python3 -m pip install --user ansible paramiko
export PATH="$HOME/Library/Python/3.8/bin:$PATH"
ansible-galaxy install -r requirements.yml

ansible-playbook -i inventory -K main.yml

# TODO
# Launchctl increase openfiles limit
# via plist

# Change user's SHELL to brew managed zsh
sudo dscl . -create /Users/$USER UserShell /usr/local/bin/zsh

# Enable docker completion
etc=/Applications/Docker.app/Contents/Resources/etc
ln -s $etc/docker.zsh-completion /usr/local/share/zsh/site-functions/_docker
ln -s $etc/docker-compose.zsh-completion /usr/local/share/zsh/site-functions/_docker-compose

# Set computer name (as done via System Preferences → Sharing)
sudo scutil --set ComputerName "radon"
sudo scutil --set HostName "radon"
sudo scutil --set LocalHostName "radon"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "radon"

# Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.Finder AppleShowAllFiles -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Apple Music song change notifications
defaults write com.apple.Music userWantsPlaybackNotifications -bool true
