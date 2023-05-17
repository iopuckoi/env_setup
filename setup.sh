#!/bin/bash

set -e

BLINKING_BLUE="\033[1;5;34m"
BOLD="\033[1m"
DISTRO=""
GREEN="\033[1;32m"
RESET="\033[0m"
GITHUB="git@github.com"
YES_OR_NO="(${GREEN}y${RESET}/${GREEN}n${RESET})"

########################################################################################
# Get Linux distribution.
get_distro() {
  CENTOS_MATCH="CentOS Linux"
  RESPONSE=$(hostnamectl | grep "Operating System")
  if [[ $RESPONSE =~ $CENTOS_MATCH ]]; then
    DISTRO="CENTOS"
  fi
}

########################################################################################
# Install and setup dependencies.
install_deps() {
  if [[ "$DISTRO" == "CENTOS" ]]; then
    sudo yum groupinstall "Development Tools" -y
    sudo yum install zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel \
      openssl-devel xz xz-devel libffi-devel findutils tk-devel epel-release -y
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo yum check-update
  fi
}

########################################################################################
# Install and setup git.
install_git() {
  RESPONSE=$(git --version)
  REPLY="X"
  MATCH="command not found"
  if [[ $RESPONSE =~ $MATCH ]]; then
    while [[ $REPLY =~ ^[^YyNn]$ ]] || [[ -z $REPLY ]]; do
      read -p "$(echo -e "Git is not installed.  Install now ${YES_OR_NO}? :  ")" -n 1 -r
      echo
    done

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "Installing git..."
      sudo yum install git
      echo
    fi
  else
    echo "Git is already installed : ${RESPONSE}"
  fi
}

########################################################################################
# Setup dev directory.
setup_dev() {
  if [ -d $HOME/.git ]; then
    echo "Dotfiles already installed."
  else
    echo "Installing dotfiles..."
    git clone --bare ${GITHUB}:iopuckoi/dotfiles.git $HOME/.git
    git config core.bare false
    echo
  fi

  RESPONSE=$(which code)
  REPLY="X"
  MATCH="no code in"
  if [[ $RESPONSE =~ $MATCH ]]; then
    echo "Installing VSCode..."
    sudo yum install code -y
    echo ""
  else
    echo "VSCode is already installed : ${RESPONSE}"
  fi

  if [ ! -d $HOME/.config/Code/User ]; then
    echo "Creating VSCode config directory..."
    mkdir -p $HOME/.config/Code/User
    echo ""
  fi
  echo "Creating symlinks for VSCode config files..."
  ln -s $HOME/VSCode/keybindings.json $HOME/.config/Code/User/keybindings.json
  ln -s $HOME/VSCode/tasks.json $HOME/.config/Code/User/tasks.json
  ln -s $HOME/VSCode/settings.json $HOME/.config/Code/User/settings.json
  ln -s $HOME/VSCode/workspace_settings.json $HOME/.config/Code/User/workspace_settings.json
  echo ""

  if [ -d $HOME/dev ]; then
    echo "Dev directory already exists."
  else
    echo "Creating dev directory..."
    mkdir $HOME/dev
    echo ""
  fi

  RESPONSE=$(snap version)
  REPLY="X"
  MATCH="command not found"
  if [[ $RESPONSE =~ $MATCH ]]; then
    echo "Installing and setting up snapd..."
    sudo yum install snapd -y
    sudo systemctl enable --now snapd.socket
    sudo ln -s /var/lib/snapd/snap /snap
    echo ""
  else
    echo "Snapd is already installed : ${RESPONSE}"
  fi

  echo "Setting up Java..."
  sudo yum install java-1.8.0-openjdk java-1.8.0-openjdk-devel java-11-openjdk java-11-openjdk-devel -y
  echo "Configure java alternatives..."
  sudo alternatives --config java
  echo "Configure javac alternatives..."
  sudo alternatives --config javac
  echo ""

  RESPONSE=$(kotlin -version)
  REPLY="X"
  MATCH="command not found"
  if [[ $RESPONSE =~ $MATCH ]]; then
    while [[ $REPLY =~ ^[^YyNn]$ ]] || [[ -z $REPLY ]]; do
      read -p "$(echo -e "Kotlin is not installed.  Install now ${YES_OR_NO}? :  ")" -n 1 -r
      echo
    done

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "Installing kotlin..."
      sudo snap install kotlin --classic
      echo ""
    fi
  else
    echo "Kotlin is already installed : ${RESPONSE}"
  fi

  if [ -d $HOME/dev/penv ]; then
    echo "Penv already installed."
  else
    echo "Installing penv..."
    git clone ${GITHUB}:iopuckoi/penv.git $HOME/dev/penv
    echo "Setting up pyenv..."
    $HOME/dev/penv setup
    echo ""
  fi
}

get_distro

install_deps

install_git

setup_dev




########################################################################################
# Main entrypoint.
# if [ $# -eq 0 ]; then
#   usage
#   exit 1
# fi

# case $1 in
#     create)
#         create
#         ;;
#     remove)
#         remove
#         ;;
#     setup)
#         setup
#         ;;
#     update)
#         update
#         ;;
#     *)
#         echo -e "Unknown argument: $1"
#         usage
#         exit
# esac