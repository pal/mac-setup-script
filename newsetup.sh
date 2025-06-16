#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# IMPORTANT: Version Update Rule
# =============================
# Every time this script is modified, the SCRIPT_VERSION must be incremented:
# - First number (1): Major version - breaking changes
# - Second number (0): Minor version - new features
# - Third number (4): Patch version - bug fixes and improvements
# Example: After fixing a bug, increment the last number: 1.0.3 -> 1.0.4
SCRIPT_VERSION="1.0.4"

log(){
  if command -v gum &>/dev/null; then
    gum style --foreground 212 "$1"
  else
    printf "\n%s\n" "$1"
  fi
}

spin(){
  if command -v gum &>/dev/null; then
    gum spin --spinner dot --title "$1" -- "$2"
  else
    eval "$2"
  fi
}

need_cmd(){
  command -v "$1" &>/dev/null || { log "missing $1"; return 1; }
}

# ---- Intro banner ---------------------------------------------------------
log "⭐  mac-setup-script v$SCRIPT_VERSION ⭐"
log "This script will prepare a new Mac: Xcode, Homebrew, apps, defaults, repos, etc." \
    "\nYou'll be asked for your administrator password once so the script can run commands that require sudo.\n" \
    "After that it runs unattended — feel free to grab a coffee.\n"

# --------------------------------------------------------------------------

# Request sudo up-front with context for the user
log "🔑  Requesting sudo — please enter your macOS password if prompted."
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$BASHPID" || exit; done 2>/dev/null &

ARCH=$(uname -m)
BREW_PREFIX="/opt/homebrew"
[[ "$ARCH" == "i386" || "$ARCH" == "x86_64" ]] && BREW_PREFIX="/usr/local"

# Install Rosetta 2 if on Apple Silicon
if [[ "$ARCH" == "arm64" ]]; then
  log "Installing Rosetta 2..."
  if ! /usr/bin/pgrep -q oahd; then
    sudo softwareupdate --install-rosetta --agree-to-license
  fi
fi

install_xcode_clt(){
  log "📦 Installing Xcode Command Line Tools..."
  if ! xcode-select -p &>/dev/null; then
    if ! xcode-select --install; then
      log "Failed to install Xcode Command Line Tools"
      return 1
    fi
    until xcode-select -p &>/dev/null; do 
      sleep 20
      if ! pgrep -q "Install Command Line Tools"; then
        log "Xcode Command Line Tools installation failed"
        return 1
      fi
    done
  fi
}

install_homebrew(){
  log "🍺 Installing Homebrew..."
  if ! command -v brew &>/dev/null; then
    if ! NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
      log "Failed to install Homebrew"
      return 1
    fi
    
    # Verify Homebrew installation and set up environment
    if [[ -f "$BREW_PREFIX/bin/brew" ]]; then
      eval "$($BREW_PREFIX/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
      BREW_PREFIX="/usr/local"
      eval "$($BREW_PREFIX/bin/brew shellenv)"
    else
      log "Homebrew installation failed - could not find brew executable"
      return 1
    fi
    
    # Verify Homebrew is working
    if ! brew doctor &>/dev/null; then
      log "Homebrew installation may have issues - please run 'brew doctor' for details"
    fi
  fi
  eval "$(brew shellenv)"
}

brew_bundle(){
  log "📦 Installing Homebrew packages and casks..."
  BREW_PKGS=(aws-cdk awscli bash direnv eza ffmpeg fish gh git jq libpq mackup mas maven p7zip pkgconf pnpm postgresql@16 ripgrep subversion wget nx gum)
  BREW_CASKS=(1password aws-vault beekeeper-studio cursor cyberduck devutils discord dropbox dynobase elgato-control-center figma rapidapi font-fira-code font-input font-inter font-jetbrains-mono font-roboto font-geist-mono ghostty google-chrome orbstack raycast session-manager-plugin slack telegram spotify visual-studio-code zoom)
  for f in "${BREW_PKGS[@]}"; do brew list "$f" &>/dev/null || brew install "$f"; done
  for c in "${BREW_CASKS[@]}"; do brew list --cask "$c" &>/dev/null || brew install --cask "$c"; done
}

mas_install(){
  log "📱 Installing Mac App Store applications..."
  
  # Check if user is signed into Mac App Store
  if ! mas account &>/dev/null; then
    log "⚠️  You need to sign in to the Mac App Store to continue."
    log "1. The App Store will open in a moment"
    log "2. Sign in with your Apple ID"
    log "3. Return here and press Enter to continue"
    log "4. If you don't have an Apple ID, you can create one at appleid.apple.com"
    
    # Give user time to read the instructions
    sleep 3
    
    # Open App Store
    open -a "App Store"
    
    # Wait for user to sign in
    while true; do
      read -p "Press Enter once you've signed in to the App Store (or type 'skip' to skip MAS installations): " input
      
      if [[ "$input" == "skip" ]]; then
        log "Skipping Mac App Store installations..."
        return 0
      fi
      
      # Check if user is now signed in
      if mas account &>/dev/null; then
        log "✅ Successfully signed in to Mac App Store"
        break
      else
        log "❌ Not signed in yet. Please sign in to the App Store and try again."
      fi
    done
  fi
  
  declare -A APPS=(
    [Dato]=1470584107
    ["HEIC Converter"]=1294126402
    [Keynote]=409183694
    [Magnet]=441258766
    ["Microsoft Excel"]=462058435
    ["Microsoft OneNote"]=784801555
    ["Microsoft Outlook"]=985367838
    ["Microsoft PowerPoint"]=462062816
    ["Microsoft To Do"]=1274495053
    ["Microsoft Word"]=462054704
    [Numbers]=409203825
    [OneDrive]=823766827
    [Pages]=409201541
    ["Pixelmator Pro"]=1289583905
    [TestFlight]=899247664
    [Valheim]=1554294918
    [Xcode]=497799835
  )
  
  for name in "${!APPS[@]}"; do
    id="${APPS[$name]}"
    if ! mas list | grep -q " $id "; then
      log "Installing $name..."
      if ! mas install "$id"; then
        log "Failed to install $name"
      fi
    fi
  done
}

set_names(){
  log "🏷️  Setting system names..."
  local HOST="pal-brattberg-macbookpro"
  scutil --set ComputerName "$HOST"
  scutil --set HostName "$HOST"
  scutil --set LocalHostName "$HOST"
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$HOST"
}

configure_defaults(){
  log "⚙️  Configuring system defaults..."
  defaults write NSGlobalDomain AppleLanguages -array "en"
  defaults write NSGlobalDomain AppleLocale -string "sv_SE"
  defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
  sudo systemsetup -settimezone "Europe/Stockholm" > /dev/null

  defaults write -g NSAutomaticCapitalizationEnabled -bool false
  defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
  defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
  defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false
  defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15

  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
  defaults write com.apple.finder _FXDefaultSearchScope -string "SCcf"
  chflags nohidden ~/Library
  sudo chflags nohidden /Volumes
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

  killall Finder || true
}

setup_fish(){
  log "🐟 Setting up Fish shell..."
  local shell_path="$BREW_PREFIX/bin/fish"
  grep -q "$shell_path" /etc/shells || echo "$shell_path" | sudo tee -a /etc/shells
  [[ "$SHELL" == *fish ]] || chsh -s "$shell_path"
}

ghostty_config(){
  log "🖥️  Configuring Ghostty terminal..."
  mkdir -p ~/Library/Application\ Support/Ghostty
  cat > ~/Library/Application\ Support/Ghostty/ghostty.toml <<'EOF'
theme = "Mathias"
font-family = "GeistMono NF"
font-size = 11
macos-titlebar-style = "tabs"
split-divider-color = "#222"
unfocused-split-opacity = 1
cursor-style = "block"
cursor-style-blink = false
cursor-color = "#B62EB2"
shell-integration-features = "no-cursor"
EOF
}

configure_git(){
  log "🔧 Configuring Git..."
  git config --global branch.autoSetupRebase always
  git config --global branch.autoSetupMerge always
  git config --global color.ui auto
  git config --global core.autocrlf input
  git config --global core.editor code
  git config --global credential.helper osxkeychain
  git config --global pull.rebase true
  git config --global push.default simple
  git config --global rebase.autostash true
  git config --global rerere.autoUpdate true
  git config --global rerere.enabled true
  git config --global user.email "pal@subtree.se"
  git config --global user.name "Pål Brattberg"
}

install_nvm_node(){
  log "🟢 Installing Node.js and NVM..."
  if [[ ! -d "$HOME/.nvm" ]]; then
    if ! curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/refs/heads/master/install.sh | bash; then
      log "Failed to install NVM"
      return 1
    fi
  fi
  
  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1090
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    . "$NVM_DIR/nvm.sh"
  else
    log "NVM installation appears to be incomplete"
    return 1
  fi
  
  if ! nvm install --lts; then
    log "Failed to install Node.js LTS"
    return 1
  fi
  
  if ! nvm alias default "lts/*"; then
    log "Failed to set default Node.js version"
    return 1
  fi
}

clone_repos(){
  log "📚 Cloning development repositories..."
  local BASE=~/dev
  mkdir -p "$BASE"
  cd "$BASE"
  declare -A REPOS=(
    [peasy-master]=git@github.com:pal/peasy.git#master
    [peasy]=git@github.com:pal/peasy.git#planetscale
    [frankfurter]=git@github.com:pal/frankfurter.git
    [peasy_client]=git@github.com:pal/peasy_client.git
    [peasyv3]=git@github.com:pal/peasyv3.git
    [peasy-ui]=git@github.com:subtree/peasy-ui.git
    [saas-template]=git@github.com:subtree/saas-template.git
    [template-magic-board]=git@github.com:subtree/template-magic-board.git
    [setup-hosting]=git@github.com:subtree/setup-hosting.git
    [companynamemaker.com]=git@github.com:subtree/companynamemaker.com.git
    [juniormarketer.ai]=git@github.com:subtree/juniormarketer.ai.git
    [social-image-creator]=git@github.com:subtree/social-image-creator.git
    [saas-template-upptime]=git@github.com:subtree/saas-template-upptime.git
    [subtree-sites]=git@github.com:subtree/subtree-sites.git
    [subtree.se]=https://github.com/subtree/subtree.se.git
    [jujino.com]=https://github.com/subtree/jujino.com.git
    [julafton.com]=git@github.com:subtree/julafton.com.git
    [mac-setup-script]=git@github.com:pal/mac-setup-script.git
    [palbrattberg.com]=git@github.com:pal/palbrattberg.com.git
    [ai-pres]=git@github.com:pal/ai-pres.git
    [deep-research]=git@github.com:pal/deep-research.git
    [domainchecker]=https://github.com/pal/domainchecker.git
    [mousegame]=https://github.com/pal/mousegame.git
    [k8s-hosting]=https://github.com/subtree/k8s-hosting.git
    [bolt.diy]=git@github.com:stackblitz-labs/bolt.diy.git
    [opencontrol]=git@github.com:toolbeam/opencontrol.git
    [productvoice]=git@github.com:WeDoProducts/productvoice.git
    [covid-containment]=git@github.com:Shpigford/covid-containment.git
  )
  for dir in "${!REPOS[@]}"; do
    url_branch="${REPOS[$dir]}"
    url=${url_branch%%#*}
    branch=${url_branch#*#}
    [[ "$branch" == "$url_branch" ]] && branch=""
    if [[ ! -d $dir ]]; then
      if [[ -n $branch ]]; then
        git clone --single-branch --branch "$branch" "$url" "$dir"
      else
        git clone "$url" "$dir"
      fi
    fi
  done
}

mackup_config(){
  log "💾 Configuring Mackup backup..."
  mkdir -p ~/.mackup
  cat > ~/.mackup.cfg <<'EOF'
[storage]
engine = iCloud Drive
EOF
}

post_install(){
  log "Post-installation steps:\n1. Open and sign in to required apps.\n2. Configure Dropbox selective sync.\n3. Accept Xcode licence (sudo xcodebuild -license accept)."
}

main(){
  install_xcode_clt
  install_homebrew
  brew_bundle
  mas_install
  set_names
  configure_defaults
  setup_fish
  ghostty_config
  configure_git
  install_nvm_node
  clone_repos
  mackup_config
  post_install
  log "Setup complete!"
}

main "$@"
