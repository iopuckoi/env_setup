#!/bin/bash

set -e

BLINKING_BLUE="\033[1;5;34m"
BOLD="\033[1m"
DISTRO=""
FIRA_CODE_VERSION="6.2"
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
    # sudo yum check-update
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
      if [[ "$DISTRO" == "CENTOS" ]]; then
        echo "Installing git..."
        sudo yum install git
        echo
      fi
    fi
  else
    echo "Git is already installed : ${RESPONSE}"
  fi
}

########################################################################################
# Setup dev directory.
setup_dev() {
  # Install Git.
  if [ -d $HOME/.git ]; then
    echo "Dotfiles already installed."
  else
    echo "Installing dotfiles..."
    git clone --bare ${GITHUB}:iopuckoi/dotfiles.git $HOME/.git
    git config core.bare false
    echo
  fi

  # Install FiraCode fonts.
  echo "Installing FiraCode..."
  fonts_dir="${HOME}/.local/share/fonts"
  if [ ! -d "${fonts_dir}" ]; then
      echo "mkdir -p $fonts_dir"
      mkdir -p "${fonts_dir}"
  else
      echo "Found fonts dir : $fonts_dir"
  fi

  zip=Fira_Code_v${FIRA_CODE_VERSION}.zip
  curl --fail --location --show-error https://github.com/tonsky/FiraCode/releases/download/${FIRA_CODE_VERSION}/${zip} --output ${zip}
  unzip -o -q -d ${fonts_dir} ${zip}
  rm ${zip}

  echo "Updating font cache..."
  fc-cache -f

  # Install and setup VSCode.
  RESPONSE=$(which code)
  REPLY="X"
  MATCH="no code in"
  if [[ $RESPONSE =~ $MATCH ]]; then
    if [[ "$DISTRO" == "CENTOS" ]]; then
      echo "Installing VSCode..."
      sudo yum install code -y
      # Install all extensions in VSCode...
      code \
            # General extensions
            --install-extension aaron-bond.better-comments \
            --install-extension Atishay-Jain.All-Autocomplete \
            --install-extension christian-kohler.path-intellisense \
            --install-extension DotJoshJohnson.xml \
            --install-extension esbenp.prettier-vscode \
            --install-extension formulahendry.code-runner \
            --install-extension GrapeCity.gc-excelviewer \
            --install-extension Gruntfuggly.todo-tree \
            --install-extension michelemelluso.code-beautifier \
            --install-extension mikestead.dotenv \
            --install-extension njpwerner.autodocstring \
            --install-extension oderwat.indent-rainbow \
            --install-extension shardulm94.trailing-spaces \
            --install-extension VisualStudioExptTeam.intellicode-api-usage-examples \
            --install-extension VisualStudioExptTeam.vscodeintellicode \
            # Java extensions
            --install-extension redhat.java \
            --install-extension vscjava.vscode-java-debug \
            --install-extension vscjava.vscode-java-dependency \
            --install-extension vscjava.vscode-java-pack \
            --install-extension vscjava.vscode-java-test \
            --install-extension vscjava.vscode-maven \
            --install-extension yzhang.markdown-all-in-one \
            # Javascript & HTML/CSS extensions
            --install-extension christian-kohler.npm-intellisense \
            --install-extension dbaeumer.vscode-eslint \
            --install-extension dsznajder.es7-react-js-snippets \
            --install-extension ecmel.vscode-html-css \
            --install-extension pranaygp.vscode-css-peek \
            --install-extension Zignd.html-css-class-completion \
            # Keybindings and Icons extensions
            --install-extension emmanuelbeziat.vscode-great-icons \
            --install-extension k--kato.intellij-idea-keybindings \
            --install-extension ms-vscode.atom-keybindings \
            --install-extension ms-vscode.vs-keybindings \
            --install-extension ShaneLiesegang.vscode-simple-icons-rev \
            # Kotlin extensions
            --install-extension esafirm.kotlin-formatter \
            --install-extension fwcd.kotlin \
            --install-extension mathiasfrohlich.Kotlin \
            # Python extensions
            --install-extension KevinRose.vsc-python-indent \
            --install-extension magicstack.MagicPython \
            --install-extension ms-python.python \
            --install-extension ms-python.vscode-pylance \
            --install-extension njqdev.vscode-python-typehint \
            # Themes
            --install-extension daylerees.rainglow \
            --install-extension johnpapa.winteriscoming

      echo ""
    fi
  else
    echo "VSCode is already installed : ${RESPONSE}"
  fi

  if [ ! -d $HOME/.config/Code/User ]; then
    echo "Creating VSCode config directory..."
    mkdir -p $HOME/.config/Code/User
    echo ""
  fi
  echo "Creating symlinks for VSCode config files..."
  if [ ! -f $HOME/.config/Code/User/keybindings.json ]; then
    ln -s $HOME/VSCode/keybindings.json $HOME/.config/Code/User/keybindings.json
  fi
  if [ ! -f $HOME/.config/Code/User/tasks.json ]; then
    ln -s $HOME/VSCode/tasks.json $HOME/.config/Code/User/tasks.json
  fi
  if [ ! -f $HOME/.config/Code/User/settings.json ]; then
    ln -s $HOME/VSCode/settings.json $HOME/.config/Code/User/settings.json
  fi
  if [ ! -f $HOME/.config/Code/User/workspace_settings.json ]; then
    ln -s $HOME/VSCode/workspace_settings.json $HOME/.config/Code/User/workspace_settings.json
  fi
  echo ""

  # Setup development directory.
  if [ -d $HOME/dev ]; then
    echo "Dev directory already exists."
  else
    echo "Creating dev directory..."
    mkdir $HOME/dev
    echo ""
  fi

  # Install snapd.
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

  # Setup Java and Javac.
  echo "Setting up Java..."
  sudo yum install java-1.8.0-openjdk java-1.8.0-openjdk-devel java-11-openjdk java-11-openjdk-devel -y
  echo "Configure java alternatives..."
  sudo alternatives --config java
  echo "Configure javac alternatives..."
  sudo alternatives --config javac
  echo ""

  # Install Kotlin.
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

  # Setup pyenv.
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