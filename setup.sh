#!/usr/bin/env bash

use_fish=false
use_bash=true

# Install some stuff before others!
important_casks=(
  1password
  alfred
  dropbox
  google-chrome
  tunnelblick
  visual-studio-code
)

casks=(
  # evernote #MAS
  # java
  # steam #WIN
  # telegram #MAS
  firefox
  font-eb-garamond
  font-input
  font-open-sans
  font-open-sans-condensed
  font-source-code-pro
  google-drive-file-stream
  slack
  spotify
  transmit
  transmission
)

brews=(
  awscli
  fish
  fzf
  git
  mackup
  mas
  node
  openssl
  python
  python3
  ruby
  wget
  yarn
)

mas=(
  # 497799835 Xcode (11.1)
  405580712 #StuffIt Expander (15.0.7)
  406056744 #Evernote (7.13)
  407963104 #Pixelmator (3.8.6)
  409183694 #Keynote (9.2)
  409201541 #Pages (8.2)
  409203825 #Numbers (6.2)
  441258766 #Magnet (2.4.4)
  747648890 #Telegram (5.7)
)

gems=(
  # bundler
)

npms=(
  npx
  serverless
  standard
)

vscode=(
  bierner.github-markdown-preview
  bierner.markdown-checkbox
  bierner.markdown-emoji
  bierner.markdown-preview-github-styles
  bungcip.better-toml
  chenxsan.vscode-standardjs
  orta.vscode-jest
  tyriar.sort-lines
)

git_email='pal@subtree.se'
git_configs=(
  "branch.autoSetupRebase always"
  "color.ui auto"
  "core.autocrlf input"
  "credential.helper osxkeychain"
  "merge.ff false"
  "pull.rebase true"
  "push.default simple"
  "rebase.autostash true"
  "rerere.autoUpdate true"
  "rerere.enabled true"
  "user.email ${git_email}"
  "user.name Pål Brattberg"
)

fonts=(
  font-asap
  font-eb-garamond
  font-fira-code
  font-input
  font-open-sans
  font-open-sans-condensed
  font-source-code-pro
  font-trebuchet-ms
)

######################################## End of app list ########################################
set +e
set -x

function prompt {
  if [[ -z "${CI}" ]]; then
    read -p "Hit Enter to $1 ..."
  fi
}

function install {
  cmd=$1
  shift
  for pkg in "$@";
  do
    exec="$cmd $pkg"
    #prompt "Execute: $exec"
    if ${exec} ; then
      echo "Installed $pkg"
    else
      echo "Failed to execute: $exec"
      if [[ ! -z "${CI}" ]]; then
        exit 1
      fi
    fi
  done
}

function brew_install_or_upgrade {
  if brew ls --versions "$1" >/dev/null; then
    if (brew outdated | grep "$1" > /dev/null); then 
      echo "Upgrading already installed package $1 ..."
      brew upgrade "$1"
    else 
      echo "Latest $1 is already installed"
    fi
  else
    brew install "$1"
  fi
}

if [[ -z "${CI}" ]]; then
  sudo -v # Ask for the administrator password upfront
  # Keep-alive: update existing `sudo` time stamp until script has finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

if test ! "$(command -v brew)"; then
  prompt "Install Homebrew"
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  if [[ -z "${CI}" ]]; then
    prompt "Update Homebrew"
    brew update
    brew upgrade
    brew doctor
  fi
fi
export HOMEBREW_NO_AUTO_UPDATE=1

echo "Install important software ..."
brew tap homebrew/cask-versions
install 'brew cask install' "${important_casks[@]}"

prompt "Install packages"
install 'brew_install_or_upgrade' "${brews[@]}"
#brew link --overwrite ruby

prompt "Set git defaults"
for config in "${git_configs[@]}"
do
  git config --global ${config}
done

if [ "$use_bash" = true ]
then
  prompt "Upgrade bash"
  brew install bash bash-completion2 fzf
  sudo bash -c "echo $(brew --prefix)/bin/bash >> /private/etc/shells"
  #sudo chsh -s "$(brew --prefix)"/bin/bash
  # Install https://github.com/twolfson/sexy-bash-prompt
  touch ~/.bash_profile #see https://github.com/twolfson/sexy-bash-prompt/issues/51
  (cd /tmp && git clone --depth 1 --config core.autocrlf=false https://github.com/twolfson/sexy-bash-prompt && cd sexy-bash-prompt && make install) && source ~/.bashrc
fi

if [ "$use_fish" = true ]
then
  echo "Setting up fish shell ..."
  brew install fish
  echo $(which fish) | sudo tee -a /etc/shells
  chsh -s $(which fish)
  curl -L https://github.com/oh-my-fish/oh-my-fish/raw/master/bin/install | fish
  install 'omf install' ${omfs[@]}

  echo "Installing ruby ..."
  brew install ruby-install chruby chruby-fish
  ruby-install ruby
  echo "source /usr/local/share/chruby/chruby.fish" >> ~/.config/fish/config.fish
  echo "source /usr/local/share/chruby/auto.fish" >> ~/.config/fish/config.fish
  ruby -v
fi

echo "
alias del='mv -t ~/.Trash/'
alias ls='exa -l'
alias cat=bat
export EDITOR=code
" >> ~/.bash_profile

prompt "Install software"
install 'brew cask install' "${casks[@]}"

prompt "Install secondary packages"
# install 'gem install' "${gems[@]}"
install 'npm install --global' "${npms[@]}"
install 'code --install-extension' "${vscode[@]}"
brew tap caskroom/fonts
install 'brew cask install' "${fonts[@]}"
install 'mas install' "${mas[@]}"

if [[ -z "${CI}" ]]; then
  prompt "Install software from App Store"
  mas list
fi

prompt "Cleanup"
brew cleanup
brew cask cleanup

echo "Run [mackup restore] after DropBox has done syncing ..."
echo "Done!"
