#!/bin/sh
set -e

THEME=default
PLUGINS=""
ZSHRC_APPEND=""

while getopts ":t:p:a:" opt; do
    case ${opt} in
        t)  THEME=$OPTARG
            ;;
        p)  PLUGINS="${PLUGINS}$OPTARG "
            ;;
        a)  ZSHRC_APPEND="$ZSHRC_APPEND\n$OPTARG"
            ;;
        \?)
            echo "Invalid option: $OPTARG" 1>&2
            ;;
        :)
            echo "Invalid option: $OPTARG requires an argument" 1>&2
            ;;
    esac
done
shift $((OPTIND -1))

echo
echo "Installing Oh-My-Zsh with:"
echo "  THEME   = $THEME"
echo "  PLUGINS = $PLUGINS"
echo

check_dist() {
    (
        . /etc/os-release
        echo $ID
    )
}

check_version() {
    (
        . /etc/os-release
        echo $VERSION_ID
    )
}

install_dependencies() {
    DIST=`check_dist`
    VERSION=`check_version`
    echo "###### Installing dependencies for $DIST"

    if [ "`id -u`" = "0" ]; then
        Sudo=''
    elif which sudo; then
        Sudo='sudo'
    else
        echo "WARNING: 'sudo' command not found. Skipping the installation of dependencies. "
        echo "If this fails, you need to do one of these options:"
        echo "   1) Install 'sudo' before calling this script"
        echo "OR"
        echo "   2) Install the required dependencies: git curl zsh"
        return
    fi

    case $DIST in
        alpine)
            $Sudo apk add --update --no-cache git curl zsh
        ;;
        centos | amzn)
            $Sudo yum update -y
            $Sudo yum install -y git curl
            $Sudo yum install -y ncurses-compat-libs # this is required for AMZN Linux (ref: https://github.com/emqx/emqx/issues/2503)
            $Sudo curl http://mirror.ghettoforge.org/distributions/gf/el/7/plus/x86_64/zsh-5.1-1.gf.el7.x86_64.rpm > zsh-5.1-1.gf.el7.x86_64.rpm
            $Sudo rpm -i zsh-5.1-1.gf.el7.x86_64.rpm
            $Sudo rm zsh-5.1-1.gf.el7.x86_64.rpm
        ;;
        *)
            $Sudo apt-get update
            $Sudo apt-get -y install git curl zsh locales
            if [ "$VERSION" != "14.04" ]; then
                $Sudo apt-get -y install locales-all
            fi
            $Sudo locale-gen en_US.UTF-8
    esac
}

zshrc_template() {
    _HOME=$1;
    _THEME=$2; shift; shift
    _PLUGINS=$*;

    if [ "$_THEME" = "default" ]; then
        _THEME="powerlevel10k/powerlevel10k"
    fi

    cat <<EOM
export LANG='en_US.UTF-8'
export LANGUAGE='en_US:en'
export LC_ALL='en_US.UTF-8'
export TERM=xterm
export TERM=xterm-256color

##### Zsh/Oh-my-Zsh Configuration
export ZSH="$_HOME/.oh-my-zsh"

ZSH_THEME="${_THEME}"
plugins=($_PLUGINS)

EOM
    printf "$ZSHRC_APPEND"
    printf "\nsource \$ZSH/oh-my-zsh.sh\n"
}

zsh_config() {
    cat <<EOM
# NEOFETCH and MOTD
neofetch
cat /etc/motd

# AWScli Auto Complete
complete -C '/usr/local/bin/aws_completer' aws

# Disable Shared History - https://stackoverflow.com/a/24876841
unsetopt share_history

# Uncomment the following line if pasting URLs and other text is messed up.
DISABLE_MAGIC_FUNCTIONS="true"

# Patch paste slowness - https://gist.github.com/magicdude4eva/2d4748f8ef3e6bf7b1591964c201c1ab?permalink_comment_id=3669084#gistcomment-3669084 | https://github.com/zsh-users/zsh-syntax-highlighting/issues/295#issuecomment-214581607
zstyle ':bracketed-paste-magic' active-widgets '.self-*'

# Kubectl
alias k=kubectl
complete -F __start_kubectl k
source <(kubectl completion zsh)

# Restore ctrl-w Behaviour
export WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'

# Terraform
tfswitch -u

EOM
}

powerline10k_config() {
    cat <<EOM
#POWERLEVEL9K_SHORTEN_STRATEGY="truncate_to_last"
#POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(user dir vcs status)
#POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()
#POWERLEVEL9K_STATUS_OK=false
#POWERLEVEL9K_STATUS_CROSS=true

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

EOM
}

aws_config() {
    cat <<EOM
[default]
region = us-east-1
cli_pager =
EOM
}

install_dependencies

cd /tmp

# Install On-My-Zsh
if [ ! -d $HOME/.oh-my-zsh ]; then
    sh -c "$(curl https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" --unattended
fi

# Generate plugin list
plugin_list=""
for plugin in $PLUGINS; do
    if [ "`echo $plugin | grep -E '^http.*'`" != "" ]; then
        plugin_name=`basename $plugin`
        git clone $plugin $HOME/.oh-my-zsh/custom/plugins/$plugin_name
    else
        plugin_name=$plugin
    fi
    plugin_list="${plugin_list}$plugin_name "
done

# Handle themes
if [ "`echo $THEME | grep -E '^http.*'`" != "" ]; then
    theme_repo=`basename $THEME`
    THEME_DIR="$HOME/.oh-my-zsh/custom/themes/$theme_repo"
    git clone $THEME $THEME_DIR
    theme_name=`cd $THEME_DIR; ls *.zsh-theme | head -1`
    theme_name="${theme_name%.zsh-theme}"
    THEME="$theme_repo/$theme_name"
fi

# Generate .zshrc
zshrc_template "$HOME" "$THEME" "$plugin_list" > $HOME/.zshrc

# Install powerlevel10k if no other theme was specified
if [ "$THEME" = "default" ]; then
    git clone https://github.com/romkatv/powerlevel10k $HOME/.oh-my-zsh/custom/themes/powerlevel10k
    zsh_config >> $HOME/.zshrc
    powerline10k_config >> $HOME/.zshrc
fi
mkdir $HOME/.aws
aws_config >> $HOME/.aws/config

# Patch Path! :)
echo PATH=$PATH:~/Utils:~/go/bin:${KREW_ROOT:-$HOME/.krew}/bin >> $HOME/.zshrc