#!/bin/bash
set -e

echo "Detecting distro..."
source /etc/os-release

if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
    sudo apt update
    sudo apt install -y git zsh tmux curl build-essential
elif [[ "$ID" == "rocky" || "$ID" == "centos" ]]; then
    sudo dnf install -y git zsh tmux curl gcc gcc-c++
else
    echo "Unsupported distro"
    exit 1
fi

echo "Linking config files..."

ln -sf $(pwd)/shell/.zshrc ~/.zshrc
ln -sf $(pwd)/git/.gitconfig ~/.gitconfig

echo "Setting zsh as default shell..."
chsh -s $(which zsh)

echo "Done."

