#!/bin/bash

set -e

BLINKING_BLUE="\033[1;5;34m"
BOLD="\033[1m"
DISTRO=""
FIRA_CODE_VERSION="6.2"
GOLANG_VERSION="1.20"
GREEN="\033[1;32m"
NODE_VERSION="v16.20.0"
NVM_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh"
RESET="\033[0m"
GITHUB="git@github.com"
YES_OR_NO="(${GREEN}y${RESET}/${GREEN}n${RESET})"

########################################################################################
usage() {
  echo "Usage: ${0} [COMMAND]..."
  echo "Setup dev environment thingies."
  echo ""
  echo "Arguments are space separated and are as follows:"
  echo "  all         Install everything"
  echo "  cinnamon    Install Cinnamon desktop"
  echo "  deps        Install dependencies"
  echo "  dotfiles    Install dotfiles"
  echo "  fonts       Install fonts"
  echo "  git         Install Git"
  echo "  gnome       Install Gnome desktop"
  echo "  golang      Install Golang"
  echo "  gradle      Install Gradle"
  echo "  java        Install and setup Java and Maven"
  echo "  kotlin      Install Kotlin"
  echo "  nodejs      Install NodeJS"
  echo "  python      Install Python"
  echo "  snapd       Install Snapd"
  echo "  vscode      Install VSCode and extensions"
  echo "  webdev      Setup firewall for webdev"
  echo "  xfce        Install Xfce desktop"
  echo ""
  exit 1
}

########################################################################################
# Create .Xclients file.
create_xclients() {
  if [ -d $HOME/.Xclients ]; then
    echo "$HOME/.Xclients file already exists."
  else
    mkdir $HOME/.Xclients
    chmod +x $HOME/.Xclients
  fi
}

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
      openssl-devel xz xz-devel libffi-devel findutils tk-devel epel-release terminator firefox \
      java-1.8.0-openjdk java-1.8.0-openjdk-devel java-11-openjdk java-11-openjdk-devel maven \
      xorg-x11-xauth -y
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    # sudo yum check-update
  fi
}

########################################################################################
# Install dotfiles and set up VSCode config files.
install_dotfiles() {
  # Install dotfiles.
  if [ -d $HOME/.git ]; then
    echo "Dotfiles already installed."
  else
    echo "Installing dotfiles..."
    git clone --bare ${GITHUB}:iopuckoi/dotfiles.git $HOME/.git
    git config core.bare false
  fi
  echo "==============================================================================="

  # Setup VSCode configuration files.
  if [ ! -d $HOME/.config/Code/User ]; then
    echo "Creating VSCode config directory..."
    mkdir -p $HOME/.config/Code/User
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
  echo "==============================================================================="
}

########################################################################################
# Install and setup any fonts.
install_fonts() {
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
  echo "==============================================================================="
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
      fi
    fi
  else
    echo "Git is already installed : ${RESPONSE}"
  fi
  echo "==============================================================================="
}

########################################################################################
# Install Golang.
install_golang() {
  RESPONSE=$(go version 2>/dev/null  || echo "Not found")
  REPLY="X"
  MATCH="Not found"
  if [[ $RESPONSE =~ $MATCH ]]; then
    while [[ $REPLY =~ ^[^YyNn]$ ]] || [[ -z $REPLY ]]; do
      read -p "$(echo -e "Golang is not installed.  Install now ${YES_OR_NO}? :  ")" -n 1 -r
      echo
    done

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "Installing Golang..."
      sudo snap install go --channel=$GOLANG_VERSION/stable --classic
      echo -e "${BLINKING_BLUE}# Make sure the following are in your rc file:${RESET}"
      echo
      echo -e "${GREEN}export GOROOT=/var/lib/snapd/snap/go/current${RESET}"
      echo -e "${GREEN}export GOPATH=/path/to/go/packages${RESET}"
      echo -e "${GREEN}PATH=\$PATH:\$GOROOT/bin:\$GOPATH${RESET}"
    fi
  else
    echo "Golang is already installed : ${RESPONSE}"
  fi
  echo "==============================================================================="
}

########################################################################################
# Install gradle.
install_gradle() {
  RESPONSE=$(gradle -v 2>/dev/null  || echo "Not found")
  REPLY="X"
  MATCH="Not found"
  if [[ $RESPONSE =~ $MATCH ]]; then
    while [[ $REPLY =~ ^[^YyNn]$ ]] || [[ -z $REPLY ]]; do
      read -p "$(echo -e "Gradle is not installed.  Install now ${YES_OR_NO}? :  ")" -n 1 -r
      echo
    done

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "Installing gradle..."
      sudo snap install gradle --classic
      echo -e "${BLINKING_BLUE}# Make sure the following are in your rc file:${RESET}"
      echo
      echo -e "${GREEN}export GRADLE_HOME=/var/lib/snapd/snap/gradle/current/opt/gradle${RESET}"
      echo -e "${GREEN}PATH=\$PATH:\$GRADLE_HOME/bin${RESET}"
    fi
  else
    echo "Gradle is already installed : ${RESPONSE}"
  fi
  echo "==============================================================================="
}

########################################################################################
# Setup Java and Javac.
install_java() {
  if [[ "$DISTRO" == "CENTOS" ]]; then
    echo "Installing Java and Maven..."
    sudo yum install java-1.8.0-openjdk java-1.8.0-openjdk-devel java-11-openjdk \
      java-11-openjdk-devel maven -y
    echo "Setting up Java..."
    echo "Configure java alternatives..."
    sudo alternatives --config java
    echo "Configure javac alternatives..."
    sudo alternatives --config javac
    echo "==============================================================================="

    { echo -e "${BLINKING_BLUE}# Make sure the following are in your rc file:${RESET}"
      echo
      echo -e "${GREEN}export JAVA_HOME=\$(dirname \$(dirname \$(readlink \$(readlink \$(which javac)))))${RESET}"
      echo -e "${GREEN}export CLASSPATH=.:\$JAVA_HOME/jre/lib:\$JAVA_HOME/lib:\$JAVA_HOME/lib/tools.jar${RESET}"
      echo -e "${GREEN}export M2_HOME=/opt/maven${RESET}"
      echo -e "${GREEN}export MAVEN_HOME=/opt/maven${RESET}"
      echo -e "${GREEN}export PATH=\$PATH:\$M2_HOME/bin:\$JAVA_HOME/bin${RESET}"
    } >&2
  fi
}

########################################################################################
# Install kotlin.
install_kotlin() {
  RESPONSE=$(kotlin -version 2>/dev/null  || echo "Not found")
  REPLY="X"
  MATCH="Not found"
  if [[ $RESPONSE =~ $MATCH ]]; then
    while [[ $REPLY =~ ^[^YyNn]$ ]] || [[ -z $REPLY ]]; do
      read -p "$(echo -e "Kotlin is not installed.  Install now ${YES_OR_NO}? :  ")" -n 1 -r
      echo
    done

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "Installing kotlin..."
      sudo snap install kotlin --classic
      echo -e "${BLINKING_BLUE}# Make sure the following are in your rc file:${RESET}"
      echo
      echo -e "${GREEN}export KOTLIN_HOME=/var/lib/snapd/snap/kotlin/current${RESET}"
      echo -e "${GREEN}PATH=\$PATH:\$KOTLIN_HOME/bin${RESET}"
    fi
  else
    echo "Kotlin is already installed : ${RESPONSE}"
  fi
  echo "==============================================================================="
}

########################################################################################
# Install nvm and nodejs.
install_nodejs() {
  if [ -d $HOME/.nvm ]; then
    echo "Nvm already installed."
  else
    echo "Installing nvm..."
    wget -qO- $NVM_URL | bash
    source $HOME/.bashrc
    nvm install $NODE_VERSION
    nvm use node
    nvm alias default node
  fi
  echo "==============================================================================="
}

########################################################################################
# Install pyenv.
install_pyenv() {
  if [ -d $HOME/dev/penv ]; then
    echo "Penv already installed."
  else
    echo "Installing penv..."
    git clone ${GITHUB}:iopuckoi/penv.git $HOME/dev/penv
  fi
  echo "Setting up pyenv..."
  $HOME/dev/penv setup
  echo "==============================================================================="
}

########################################################################################
# Install snapd.
install_snapd() {
  RESPONSE=$(snap version 2>/dev/null  || echo "Not found")
  REPLY="X"
  MATCH="Not found"
  if [[ $RESPONSE =~ $MATCH ]]; then
    echo "Installing and setting up snapd..."
    sudo yum install snapd -y
    sudo systemctl enable --now snapd.socket
    sudo ln -s /var/lib/snapd/snap /snap
    echo ""
  else
    echo "Snapd is already installed : ${RESPONSE}"
  fi
  echo "==============================================================================="
}

########################################################################################
# Install VSCode.
install_vscode() {
  RESPONSE=$(which code 2>/dev/null  || echo "Not found")
  REPLY="X"
  MATCH="Not found"
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
            --install-extension vscjava.vscode-gradle \
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
    fi
  else
    echo "VSCode is already installed : ${RESPONSE}"
  fi
  echo "==============================================================================="
}

########################################################################################
# Setup dev directory.
setup_dev() {
  # Setup development directory.
  if [ -d $HOME/dev ]; then
    echo "Dev directory already exists."
  else
    echo "Creating dev directory..."
    mkdir $HOME/dev
  fi
  echo "==============================================================================="

  install_git

  install_dotfiles

  install_fonts

  install_vscode

  install_snapd

  configure_java

  install_gradle

  install_kotlin

  install_pyenv

  install_nodejs
}

########################################################################################
# Setup Cinnamon desktop.
setup_cinnamon() {
  if [[ "$DISTRO" == "CENTOS" ]]; then
    sudo yum install epel-release -y
    sudo yum groupinstall "Server with GUI" -y
    sudo yum groupinstall "Xfce" -y
    sudo systemctl set-default graphical.target
    sudo systemctl start graphical.target

    create_xclients

    RESPONSE=$(grep cinnamon $HOME/.Xclients)
    REPLY="X"
    MATCH="cinnamon"
    if [[ $RESPONSE =~ $MATCH ]]; then
      echo "cinnamon" >> $HOME/.Xclients
    fi

    setup_xrdp
  fi
}

########################################################################################
# Setup Gnome desktop.
setup_gnome() {
  if [[ "$DISTRO" == "CENTOS" ]]; then
    sudo yum groupinstall "GNOME Desktop" "Graphical Administration Tools"
    sudo systemctl set-default graphical.target
    sudo systemctl start graphical.target

    create_xclients

    RESPONSE=$(grep gnome-session $HOME/.Xclients)
    REPLY="X"
    MATCH="gnome-session"
    if [[ $RESPONSE =~ $MATCH ]]; then
      echo "gnome-session" >> $HOME/.Xclients
    fi

    setup_xrdp
  fi
}

########################################################################################
# Setup firewall for webdev.
setup_webdev() {
  if [[ "$DISTRO" == "CENTOS" ]]; then
    sudo firewall-cmd --permanent --add-port=8080/tcp
    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --reload
    sudo systemctl restart firewalld
    sudo systemctl status firewalld
  fi
}

########################################################################################
# Setup Xfce desktop.
setup_xfce() {
  if [[ "$DISTRO" == "CENTOS" ]]; then
    sudo yum install epel-release -y
    sudo yum groupinstall "Server with GUI" -y
    sudo yum install cinnamon -y
    sudo systemctl set-default graphical.target
    sudo systemctl start graphical.target

    create_xclients

    RESPONSE=$(grep startxfce4 $HOME/.Xclients)
    REPLY="X"
    MATCH="startxfce4"
    if [[ $RESPONSE =~ $MATCH ]]; then
      echo "startxfce4" >> $HOME/.Xclients
    fi

    setup_xrdp
  fi
}

########################################################################################
# Setup Xrdp.
setup_xrdp() {
  if [[ "$DISTRO" == "CENTOS" ]]; then
    RESPONSE=$(systemctl status xrdp)
    REPLY="X"
    MATCH="Unit xrdp.service could not be found."
    if [[ $RESPONSE =~ $MATCH ]]; then
      echo "Installing xrdp..."
      sudo yum install xrdp -y
      sudo systemctl enable xrdp
      sudo systemctl start xrdp
    else
      echo "xrdp already installed, restarting the service..."
      sudo systemctl restart xrdp
    fi

    # Setup firewall rules to allow RDP connections.
    sudo firewall-cmd --permanent --add-port=3389/tcp
    sudo firewall-cmd --reload
    sudo systemctl restart firewalld
    sudo systemctl status firewalld
  fi
}

########################################################################################
# Main entrypoint.
if [ $# -eq 0 ]; then
  usage
  exit 1
fi

get_distro

case $1 in
    all)
        install_deps
        setup_dev
        ;;
    cinnamon)
        setup_cinnamon
        ;;
    deps)
        install_deps
        ;;
    dotfiles)
        install_dotfiles
        ;;
    fonts)
        install_fonts
        ;;
    git)
        install_git
        ;;
    gnome)
        setup_gnome
        ;;
    golang)
        install_golang
        ;;
    gradle)
        install_gradle
        ;;
    java)
        install_java
        ;;
    kotlin)
        install_kotlin
        ;;
    nodejs)
        install_nodejs
        ;;
    pyenv)
        install_pyenv
        ;;
    snapd)
        install_snapd
        ;;
    vscode)
        install_vscode
        ;;
    webdev)
        setup_webdev
        ;;
    xfce)
        setup_xfce
        ;;
    *)
        echo -e "Unknown argument: $1"
        usage
        exit
esac