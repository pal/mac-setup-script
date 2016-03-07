#!/usr/bin/env bash

use_fish=false

brews=(
  bash
  clib
  gpg
  htop
  httpie
  iftop
  ncdu
  nmap
  node
  python
  git
  scala
  sbt
  heroku
  boot2docker
  findutils
  gnu-sed
  maven
  ant
  jenv
  nvm
  rbenv
  ruby-build
  jq
  wget
  elasticsearch
  mackup
)

casks=(
  google-chrome
  firefox
  atom
  lastpass
  slack
  java
  virtualbox
  datagrip
  textwrangler
  mamp
  spotify
  hipchat
  skype
  evernote
  alfred
  dropbox
  google-drive
  microsoft-office
)

gems=(
  bundler
)

npms=(
)

clibs=(
  bpkg/bpkg
)

bkpgs=(
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
  "user.name Pål Brattberg"
  "user.email pal@subtree.se"
)

apms=(
  atom-beautify
  language-scala
  minimap
)

fonts=(
  font-source-code-pro
  font-asap
  font-open-sans
  font-open-sans-condensed
  font-eb-garamond
  font-trebuchet-ms
  font-input
)

omfs=(
  jacaetevha
  osx
  thefuck
)

######################################## End of app list ########################################
set +e

if test ! $(which brew); then
  echo "Installing Xcode ..."
  xcode-select --install

  echo "Installing Homebrew ..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo "Updating Homebrew ..."
  brew update
  brew upgrade
fi

brew doctor
brew tap homebrew/dupes

fails=()

function print_red {
  red='\x1B[0;31m'
  NC='\x1B[0m' # no color
  echo -e "${red}$1${NC}"
}

function install {
  cmd=$1
  shift
  for pkg in $@;
  do
    exec="$cmd $pkg"
    echo "Executing: $exec"
    if $exec ; then
      echo "Installed $pkg"
    else
      fails+=($pkg)
      print_red "Failed to execute: $exec"
    fi
  done
}

function proceed_prompt {
  read -p "Proceed with installation? " -n 1 -r
  if [[ $REPLY =~ ^[Nn]$ ]]
  then
    exit 1
  fi
}

# Disable fish for now
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

brew info ${brews[@]}
proceed_prompt
install 'brew install' ${brews[@]}

echo "Tapping casks ..."
brew tap caskroom/fonts
brew tap caskroom/versions

brew cask info ${casks[@]}
proceed_prompt
install 'brew cask install --appdir="/Applications"' ${casks[@]}

# TODO: add info part of install or do reinstall?
#install 'pip install --upgrade' ${pips[@]}
install 'sudo gem install' ${gems[@]}
#install 'clib install' ${clibs[@]}
#install 'bpkg install' ${bpkgs[@]}
install 'npm install --global' ${npms[@]}
#install 'apm install' ${apms[@]}
install 'brew cask install' ${fonts[@]}

echo "Adding homeshick ..."
git clone git://github.com/andsens/homeshick.git $HOME/.homesick/repos/homeshick
source "$HOME/.homesick/repos/homeshick/homeshick.sh"
homeshick clone pal/profile
ln -s $HOME/.profile.d/init $HOME/.profile

echo "Upgrading bash ..."
sudo bash -c "echo $(brew --prefix)/bin/bash >> /private/etc/shells"

echo "Setting git defaults ..."
for config in "${git_configs[@]}"
do
  git config --global ${config}
done
#git alias rpush '! git up && git push'

if [ "$use_fish" = true ]
then
  echo "Setting up go ..."
  mkdir -p /usr/libs/go
  echo "export GOPATH=/usr/libs/go" >> ~/.config/fish/config.fish
  echo "export PATH=$PATH:$GOPATH/bin" >> ~/.config/fish/config.fish
fi

echo "Upgrading ..."
pip install --upgrade setuptools
pip install --upgrade pip
gem update --system

echo "Cleaning up ..."
brew cleanup
brew cask cleanup
brew linkapps

for fail in ${fails[@]}
do
  echo "Failed to install: $fail"
done

echo 'export PATH="/usr/local/sbin:$PATH"' >> ~/.bash_profile

echo "Run `mackup restore` after DropBox has done syncing"

#read -p "Hit enter to run [OSX for Hackers] script..." c
#sh -c "$(curl -sL https://gist.githubusercontent.com/brandonb927/3195465/raw/osx-for-hackers.sh)"
