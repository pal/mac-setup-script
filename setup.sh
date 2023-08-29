#!/usr/bin/env bash

#set +e # don't stop on error
set -e # stop on any error
set -x # show debug

echo "Install XCode CLI Tool"
if type xcode-select >&- && xpath=$( xcode-select --print-path ) &&
  test -d "${xpath}" && test -x "${xpath}" ; then
echo "Xcode is installed ok" 
else
echo "Xcode is NOT installed ok" 
#  xcode-select --install
#  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
#  sudo xcodebuild -runFirstLaunch
fi

# Needed for compatibility in M1 Mac
sudo softwareupdate --install-rosetta --agree-to-license

echo "Install Homebrew"
if test ! $(which brew); then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/pal/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
brew update
echo "Install Homebrew Packages"
brew tap homebrew/bundle
brew bundle
brew doctor

brew link cocoapods

# Accept xcode license
sudo xcodebuild -license accept

echo "Set git defaults"
git_configs=(
  "alias.br branch"
  "alias.ci commit"
  "alias.co checkout"
  "alias.st status"
  "branch.autoSetupRebase always"
  "color.ui auto"
  "core.autocrlf input"
  "core.editor $(which code)"
  "credential.helper osxkeychain"
  "merge.conflictstyle diff3"
  "merge.ff false"
  "merge.tool diffmerge"
  "mergetool.echo false"
  "pull.rebase true"
  "push.default simple"
  "rebase.autostash true"
  "rerere.autoUpdate true"
  "rerere.enabled true"
  "user.email pal@subtree.se"
  "user.name Pål Brattberg"
)
for config in "${git_configs[@]}"
do
  git config --global ${config}
done


echo "Upgrade bash"
brew install bash bash-completion2 fzf
sudo bash -c "echo $(brew --prefix)/bin/bash >> /private/etc/shells"
#sudo chsh -s "$(brew --prefix)"/bin/bash
# Install https://github.com/twolfson/sexy-bash-echo
touch ~/.bash_profile #see https://github.com/twolfson/sexy-bash-echo/issues/51
(cd /tmp && git clone --depth 1 --config core.autocrlf=false https://github.com/twolfson/sexy-bash-echo && cd sexy-bash-echo && make install) && source ~/.bashrc


echo "Setting up fish shell ..."
brew install fish
echo $(which fish) | sudo tee -a /etc/shells
chsh -s $(which fish)
curl -L https://github.com/oh-my-fish/oh-my-fish/raw/master/bin/install | fish
install 'omf install' ${omfs[@]}

echo "Install newer versions of dev languages"

# touch ~/.zshrc 

# Add ruby
# echo 'frum init | source' > ~/.config/fish/conf.d/frum.fish
# echo 'eval "$(frum init)"' >> ~/.zshrc
# echo 'eval "$(frum init)"' >> ~/.bashrc
# frum init
# frum install 3.1.0
# frum global 3.1.0

# create ssh key
ssh-keygen -t ed25519 -C "pal@subtree.se"
eval "$(ssh-agent -s)"
ssh-add -K ~/.ssh/id_rsa

# Add node using nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
nvm install lts/hydrogen
nvm alias default lts/hydrogen
nvm install 20
nvm use default

# cleanup
echo "Cleanup"
brew cleanup
brew cask cleanup

# Create my dev folder
mkdir ~/dev

# restore settings from iCloud (if this bugs out, allow time for iCloud sync)
cp /Users/pal/Library/Mobile\ Documents/com\~apple\~CloudDocs/Mackup/.mackup.cfg ~/
mackup restore --force

echo "Run [git_setup.sh] to fetch all you need to start coding!"
echo "Done!"
