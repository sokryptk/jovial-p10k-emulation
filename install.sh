#!/usr/bin/env zsh

S_USER=root
S_HOME="$HOME"
# cat install.zsh  | bash -s $USER
if [[ -n $1 ]]; then 
    S_USER="$1"
    S_HOME=`sudo -u "$S_USER" -i echo '$HOME'`
fi

is_command() { command -v $@ &> /dev/null; }

install_via_manager() {
    echo "+ install_via_manager $@"

    local packages=( $@ )
    local package

    for package in ${packages[@]}; do
        (sudo -u $S_USER -i brew install ${package}) || \
            apt install -y ${package} || \
            apt-get install -y ${package} || \
            yum -y install ${package} || \
            pacman -S --noconfirm --needed ${package}
    done
}

install_zsh() {
    echo '+ install_zsh'

    # other ref: https://unix.stackexchange.com/questions/136423/making-zsh-default-shell-without-root-access?answertab=active#tab-top
    if [[ -z ${ZSH_VERSION} ]]; then
        if is_command zsh || install_via_manager zsh; then
            echo "+ chsh to zsh"
            chsh -s `command -v zsh` $S_USER
            return 0
        else
            echo "ERROR, plz install zsh manual."
            return 1
        fi
    fi
}

install_ohmyzsh() {
    echo '+ install_ohmyzsh'

    if [[ ! -d ${S_HOME}/.oh-my-zsh && (-z ${ZSH} || -z ${ZSH_CUSTOM}) ]]; then
        echo "this theme base on oh-my-zsh, now will install it!" >&2
        install_via_manager git
        curl -fsSL -H 'Cache-Control: no-cache' install.ohmyz.sh | sudo -u $S_USER -i sh
    fi
    export ZSH=${S_HOME}/.oh-my-zsh
}

install_p10k() {
    if [[ ! -d ${S_HOME}/powerlevel10k ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${S_HOME}/powerlevel10k
    fi
    
    if ! grep -q "source ~/powerlevel10k/powerlevel10k.zsh-theme" "${S_HOME}/.zshrc"; then
        sh -c "echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> ${S_HOME}/.zshrc"
    fi
}

install_zsh_plugins() {
    echo '+ install_zsh_plugins'

    local plugin_dir="${ZSH_CUSTOM:-"${S_HOME}/.oh-my-zsh/custom"}/plugins"

    install_via_manager git autojump terminal-notifier source-highlight

    if [[ ! -e ${plugin_dir}/zsh-autosuggestions ]]; then
        echo '+ install zsh-autosuggestions'
        sudo -u $S_USER -i git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "${plugin_dir}/zsh-autosuggestions"
    fi

    if [[ ! -e ${plugin_dir}/zsh-syntax-highlighting ]]; then
        echo '+ install zsh-syntax-highlighting'
        sudo -u $S_USER -i git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${plugin_dir}/zsh-syntax-highlighting"
    fi

    if [[ ! -e ${plugin_dir}/zsh-history-enquirer ]]; then
        echo '+ install zsh-history-enquirer'
        curl -sSL -H 'Cache-Control: no-cache' https://github.com/zthxxx/zsh-history-enquirer/raw/master/scripts/installer.zsh | sudo -u $S_USER -i zsh
    fi

    local plugins=(
        git
        autojump
        urltools
        bgnotify
        zsh-autosuggestions
        zsh-syntax-highlighting
        zsh-history-enquirer
        command-not-found

        # TODO: case "$OSTYPE" in (darwin*)
        osx
    )

    local plugin_str="${plugins[@]}"
    plugin_str="\n  ${plugin_str// /\\n  }\n"
    perl -0i -pe "s/^plugins=\(.*?\) *$/plugins=(${plugin_str})/gms" ${S_HOME}/.zshrc
}

preference_zsh() {
    echo '+ preference_zsh'

    if is_command brew; then
        perl -i -pe "s/.*HOMEBREW_NO_AUTO_UPDATE.*//gms" ${S_HOME}/.zshrc
        echo "export HOMEBREW_NO_AUTO_UPDATE=true" >> ${S_HOME}/.zshrc
    fi
    install_zsh_plugins
}

install_theme() {
    echo "+ install p10k-jovial"

    wget -q https://raw.githubusercontent.com/krypticallusion/jovial-p10k-emulation/master/p10k.zsh -O ${S_HOME}/.p10k.zsh

    if ! grep -q "Powerlevel10k instant prompt" "${S_HOME}/.zshrc"; then
        echo "$( echo 'fi' | cat - ${S_HOME}/.zshrc )" > ${S_HOME}/.zshrc
        echo "$( echo 'source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"' | cat - ${S_HOME}/.zshrc )" > ${S_HOME}/.zshrc
        echo "$( echo 'if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then' | cat - ${S_HOME}/.zshrc )" > ${S_HOME}/.zshrc
        echo "$( echo '# confirmations, etc.) must go above this block; everything else may go below.' | cat - ${S_HOME}/.zshrc )" > ${S_HOME}/.zshrc
        echo "$( echo '# Initialization code that may require console input (password prompts, [y/n]' | cat - ${S_HOME}/.zshrc )" > ${S_HOME}/.zshrc
        echo "$( echo '# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.' | cat - ${S_HOME}/.zshrc )" > ${S_HOME}/.zshrc
    fi

    if ! grep -q "POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true" "${S_HOME}/.zshrc"; then
        echo "POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true" >> ${S_HOME}/.zshrc
    fi

    if ! grep -q "p10k configure" "${S_HOME}/.zshrc"; then
        echo "# To customize prompt, run 'p10k configure' or edit ~/.p10k.zsh." >> ${S_HOME}/.zshrc
        echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> ${S_HOME}/.zshrc
    fi
}

(install_zsh && install_ohmyzsh && install_p10k) || exit 1

install_theme
preference_zsh