#!/usr/bin/env bash

#set +e # don't stop on error
set -e # stop on any error
set -x # show debug

echo "Install XCode CLI Tool"
if ! xcode-select -p &> /dev/null; then
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install
  # Wait for installation to complete
  while ! xcode-select -p &> /dev/null; do
    sleep 1
  done
fi

# Only install Rosetta if on Apple Silicon
if [[ $(uname -m) == 'arm64' ]]; then
  echo "Installing Rosetta 2..."
  sudo softwareupdate --install-rosetta --agree-to-license
fi

echo "Install Homebrew"
if ! command -v brew &> /dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # Add Homebrew to PATH for Apple Silicon
  if [[ -d /opt/homebrew ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi
brew update
echo "Install Homebrew Packages"
brew bundle
brew doctor

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

echo "Setting up fish shell ..."
brew install fish
echo $(which fish) | sudo tee -a /etc/shells
chsh -s $(which fish)
curl -L https://github.com/oh-my-fish/oh-my-fish/raw/master/bin/install | fish
install 'omf install' ${omfs[@]}


# create ssh key if it doesn't exist
if [[ ! -f ~/.ssh/id_ed25519 ]]; then
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  ssh-keygen -t ed25519 -C "pal@subtree.se"
  
  # Start ssh-agent if not running
  if ! pgrep -x "ssh-agent" > /dev/null; then
    eval "$(ssh-agent -s)"
  fi
  
  # Add key to ssh-agent and verify
  if ssh-add --apple-use-keychain ~/.ssh/id_ed25519; then
    echo "SSH key successfully added to ssh-agent"
  else
    echo "Failed to add SSH key to ssh-agent"
    exit 1
  fi
fi

# Add node using nvm
if ! command -v nvm &> /dev/null; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/refs/heads/master/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Ensure NVM is loaded
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node.js versions if they don't exist
if ! nvm ls | grep -q "lts"; then
  nvm install lts
fi

if ! nvm ls | grep -q "v24"; then
  nvm install 24
fi

nvm alias default lts
nvm use default

# cleanup
echo "Cleanup"
brew cleanup
brew cask cleanup

# Create dev folder
mkdir -p ~/dev

# restore settings from iCloud (if this bugs out, allow time for iCloud sync)
if [[ -f "/Users/pal/Library/Mobile Documents/com~apple~CloudDocs/Mackup/.mackup.cfg" ]]; then
  cp "/Users/pal/Library/Mobile Documents/com~apple~CloudDocs/Mackup/.mackup.cfg" ~/
  mackup restore --force
else
  echo "Error: Mackup config file not found in iCloud"
fi

echo "Run [git_setup.sh] to fetch all you need to start coding!"
echo "Done!"
