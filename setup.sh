#!/usr/bin/env bash

use_fish=true
use_bash=true

# sources for homebrew
taps=(
  dart-lang/dart
  github/gh
  homebrew/bundle
  homebrew/cask
  homebrew/cask-fonts
  homebrew/cask-versions
  homebrew/core
)

# Install some stuff before others!
important_casks=(
  1password
  alfred
  dropbox
  google-chrome
  tunnelblick
  visual-studio-code
  aws-vault
  paw
)

casks=(
  # evernote #MAS
  # java
  # steam #WIN
  # telegram #MAS
  # battlenet
  # epic installer
  # falcon-sql-client
  # nosql-workbench-for-amazon-dynamodb
  firefox
  google-drive-file-stream
  slack
  skype
  spotify
  transmit
  transmission
)

brews=(
  awscli
  bash
  bash-completion@2
  cocoapods
  dart-lang/dart/dart
  fastlane
  fish
  fzf
  git
  go
  gradle
  jq
  mackup
  mas
  node
  nvm
  openjdk
  openssl
  openssl@1.1
  python
  python3
  ruby
  wget
  yarn
)

mas=(
  497799835 # Xcode (11.1)
  405580712 # StuffIt Expander (15.0.7)
  406056744 # Evernote (7.13)
  407963104 # Pixelmator (3.8.6)
  409183694 # Keynote (9.2)
  409201541 # Pages (8.2)
  409203825 # Numbers (6.2)
  441258766 # Magnet (2.4.4)
  747648890 # Telegram (5.7)
  439623248 # iA Writer Classic
  1470584107 # Dato
  1294126402 # HEIC Converter
)

gems=(
  bundler
)

npms=(
  #@aws-amplify/cli@4.26.1-flutter-preview.0
  #serverless
  #sls-dev-tools
  npx
  standard
)

# not using this anymore, now syncing using VSCode and my Github account
vscode=(
  adpyke.vscode-sql-formatter
  bierner.github-markdown-preview
  bierner.markdown-checkbox
  bierner.markdown-emoji
  bierner.markdown-preview-github-styles
  bierner.markdown-yaml-preamble
  blaxou.freezed
  bungcip.better-toml
  chenxsan.vscode-standardjs
  Dart-Code.dart-code
  Dart-Code.flutter
  formulahendry.code-runner
  golang.go
  mathiasfrohlich.Kotlin
  matt-meyers.vscode-dbml
  mechatroner.rainbow-csv
  Nash.awesome-flutter-snippets
  redhat.vscode-yaml
  skyapps.fish-vscode
  ThreadHeap.serverless-ide-vscode
  Tyriar.sort-lines
  WallabyJs.quokka-vscode
)

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
  "user.email pal@subtree.se"
  "user.name Pål Brattberg"
)

fonts=(
  font-asap
  font-eb-garamond
  font-fira-code
  font-input
  font-inter
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
install 'brew tap' "${taps[@]}"
install 'brew cask install' "${important_casks[@]}"

prompt "Install packages"
install 'brew install' "${brews[@]}"
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
install 'gem install' "${gems[@]}"
install 'npm install --global' "${npms[@]}"
install 'code --install-extension' "${vscode[@]}"

install 'brew cask install' "${fonts[@]}"
install 'mas install' "${mas[@]}"

if [[ -z "${CI}" ]]; then
  prompt "Install software from App Store"
  mas list
fi

prompt "Cleanup"
brew cleanup
brew cask cleanup

echo "Run [mackup restore] after DropBox has done syncing to get dotfiles"
echo "Done!"
