#!/usr/bin/env bash
IFS=$'\n\t'

# Every time this script is modified, the SCRIPT_VERSION must be incremented
SCRIPT_VERSION="1.0.27"

# Record start time
START_TIME=$(date +%s)

log(){
  if command -v gum &>/dev/null; then
    gum style --foreground 212 "$1"
  else
    printf "\n%s\n" "$1"
  fi
}

error(){
  if command -v gum &>/dev/null; then
    gum style --foreground 196 "ERROR: $1"
  else
    printf "\n\033[31mERROR: %s\033[0m\n" "$1"
  fi
  return 1
}

spin(){
  if command -v gum &>/dev/null; then
    gum spin --spinner dot --title "$1" -- "$2"
  else
    eval "$2"
  fi
}

need_cmd(){
  command -v "$1" &>/dev/null || { error "missing $1"; return 1; }
}

# ---- Intro banner ---------------------------------------------------------
log "⭐  mac-setup-script v$SCRIPT_VERSION ⭐"
log "This script will prepare a new Mac: Xcode, Homebrew, apps, defaults, repos, etc." \
    "\nYou'll be asked for your administrator password once so the script can run commands that require sudo.\n" \
    "After that it runs unattended — feel free to grab a coffee.\n"

# --------------------------------------------------------------------------

# Request sudo up-front with context for the user
log "🔑  Requesting sudo — please enter your macOS password if prompted."
sudo -v || error "Failed to get sudo access"
while true; do sudo -n true; sleep 60; kill -0 "$BASHPID" || exit; done 2>/dev/null &

ARCH=$(uname -m)
BREW_PREFIX="/opt/homebrew"
[[ "$ARCH" == "i386" || "$ARCH" == "x86_64" ]] && BREW_PREFIX="/usr/local"

# Install Rosetta 2 if on Apple Silicon
if [[ "$ARCH" == "arm64" ]]; then
  log "Installing Rosetta 2..."
  if ! /usr/bin/pgrep -q oahd; then
    sudo softwareupdate --install-rosetta --agree-to-license || error "Failed to install Rosetta 2"
  fi
fi

install_xcode_clt(){
  log "📦 Installing Xcode Command Line Tools..."
  if xcode-select -p &>/dev/null; then
    log "Xcode Command Line Tools already installed"
    return 0
  fi
  
  if ! xcode-select --install; then
    error "Failed to install Xcode Command Line Tools"
    return 1
  fi
  until xcode-select -p &>/dev/null; do 
    sleep 20
    if ! pgrep -q "Install Command Line Tools"; then
      error "Xcode Command Line Tools installation failed"
      return 1
    fi
  done
}

install_homebrew(){
  log "🍺 Installing Homebrew..."
  if command -v brew &>/dev/null; then
    log "Homebrew already installed"
    eval "$(brew shellenv)" || error "Failed to source Homebrew environment"
    return 0
  fi
  
  if ! NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    error "Failed to install Homebrew"
    return 1
  fi
  
  # Verify Homebrew installation and set up environment
  if [[ -f "$BREW_PREFIX/bin/brew" ]]; then
    # Add Homebrew to PATH for all shells
    for shell_config in ~/.bash_profile ~/.zshrc ~/.config/fish/config.fish; do
      if [[ -f "$shell_config" ]]; then
        if ! grep -q "brew shellenv" "$shell_config"; then
          echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$shell_config" || error "Failed to update $shell_config"
        fi
      fi
    done
    # Source the environment for current shell
    eval "$($BREW_PREFIX/bin/brew shellenv)" || error "Failed to source Homebrew environment"
  elif [[ -f "/usr/local/bin/brew" ]]; then
    BREW_PREFIX="/usr/local"
    # Add Homebrew to PATH for all shells
    for shell_config in ~/.bash_profile ~/.zshrc ~/.config/fish/config.fish; do
      if [[ -f "$shell_config" ]]; then
        if ! grep -q "brew shellenv" "$shell_config"; then
          echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$shell_config" || error "Failed to update $shell_config"
        fi
      fi
    done
    # Source the environment for current shell
    eval "$($BREW_PREFIX/bin/brew shellenv)" || error "Failed to source Homebrew environment"
  else
    error "Homebrew installation failed - could not find brew executable"
    return 1
  fi
  
  # Verify Homebrew is working
  if ! brew doctor &>/dev/null; then
    log "Homebrew installation may have issues - please run 'brew doctor' for details"
  fi
}

accept_xcode_license(){
  log "📝 Accepting Xcode license..."
  if xcodebuild -license check &>/dev/null; then
    log "Xcode license already accepted"
    return 0
  fi
  sudo xcodebuild -license accept || error "Failed to accept Xcode license"
}

brew_bundle(){
  log "📦 Installing Homebrew packages and casks..."
  BREW_PKGS=(aws-cdk awscli bash direnv eza ffmpeg fish gh git jq libpq mackup mas maven p7zip pkgconf pnpm postgresql@16 ripgrep subversion wget nx gum)
  BREW_CASKS=(1password aws-vault beekeeper-studio cloudflare-warp cursor cyberduck devutils discord dropbox dynobase elgato-control-center figma rapidapi font-fira-code font-input font-inter font-jetbrains-mono font-roboto font-geist-mono ghostty google-chrome microsoft-teams orbstack raycast session-manager-plugin slack telegram spotify visual-studio-code zoom)
  
  # Get list of installed packages and casks once
  INSTALLED_PKGS=$(brew list --formula -1)
  INSTALLED_CASKS=$(brew list --cask -1)
  
  for f in "${BREW_PKGS[@]}"; do 
    if echo "$INSTALLED_PKGS" | grep -q "^${f}$"; then
      log "Package already installed: $f"
    else
      log "Installing package: $f"
      brew install "$f" || error "Failed to install $f"
    fi
  done
  
  for c in "${BREW_CASKS[@]}"; do 
    if echo "$INSTALLED_CASKS" | grep -q "^${c}$"; then
      log "Cask already installed: $c"
    else
      log "Installing cask: $c"
      brew install --cask "$c" || error "Failed to install $c"
    fi
  done
}

mas_install(){
  log "📱 Installing Mac App Store applications..."
  
  # Check if user is signed into Mac App Store by attempting to list apps
  if ! mas list &>/dev/null; then
    log "⚠️  You need to sign in to the Mac App Store to continue."
    log "1. The App Store will open in a moment"
    log "2. Sign in with your Apple ID"
    log "3. If you don't have an Apple ID, you can create one at appleid.apple.com"
    
    # Open App Store
    open -a "App Store"
    return 1
  else
    log "✅ Successfully signed in to Mac App Store"
  fi
  
  # Define apps as a string to avoid issues with spaces in names
  APPS_STR="Dato:1470584107
HEIC Converter:1294126402
Keynote:409183694
Magnet:441258766
Microsoft Excel:462058435
Microsoft OneNote:784801555
Microsoft Outlook:985367838
Microsoft PowerPoint:462062816
Microsoft To Do:1274495053
Microsoft Word:462054704
Numbers:409203825
OneDrive:823766827
Pages:409201541
Pixelmator Pro:1289583905
TestFlight:899247664
Valheim:1554294918
Xcode:497799835"

  # Get list of installed app IDs
  INSTALLED_APP_IDS=$(mas list 2>/dev/null | awk '{print $1}')
  
  # Count total apps to install
  total_apps=0
  apps_to_install=()
  while IFS=: read -r name id; do
    if ! echo "$INSTALLED_APP_IDS" | grep -qx "$id"; then
      ((total_apps++))
      apps_to_install+=("$name:$id")
    fi
  done <<< "$APPS_STR"
  
  if [ $total_apps -eq 0 ]; then
    log "All Mac App Store applications are already installed"
    return 0
  fi
  
  log "Found $total_apps apps to install"
  
  # Install apps with progress
  current=0
  for app in "${apps_to_install[@]}"; do
    IFS=: read -r name id <<< "$app"
    ((current++))
    log "Installing $name (ID: $id)... ($current/$total_apps)"
    if ! mas install "$id" 2>&1; then
      error "Failed to install $name (ID: $id)"
      return 1
    fi
  done
  
  return 0
}

set_names(){
  log "🏷️  Setting system names..."
  local HOST="pal-brattberg-macbookpro"
  local current_name=$(scutil --get ComputerName 2>/dev/null)
  
  if [[ "$current_name" == "$HOST" ]]; then
    log "System names already set correctly"
    return 0
  fi
  
  scutil --set ComputerName "$HOST" || error "Failed to set ComputerName"
  scutil --set HostName "$HOST" || error "Failed to set HostName"
  scutil --set LocalHostName "$HOST" || error "Failed to set LocalHostName"
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$HOST" || error "Failed to set NetBIOSName"
}

configure_defaults(){
  log "⚙️  Configuring system defaults..."
  
  # Ensure sudo access is still valid
  sudo -v || error "Lost sudo access - please run the script again"
  
  # Close any open System Preferences panes
  osascript -e 'tell application "System Settings" to quit' || osascript -e 'tell application "System Preferences" to quit' || true

  # Disable the sound effects on boot
  sudo nvram SystemAudioVolume=" " || true

  # Language & Region
  # Set system language to English
  defaults write NSGlobalDomain AppleLanguages -array "en" || true
  # Set locale to Swedish
  defaults write NSGlobalDomain AppleLocale -string "sv_SE" || true
  # Set measurement units to centimeters
  defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters" || true
  # Use metric system
  defaults write NSGlobalDomain AppleMetricUnits -bool true || true
  # Set timezone to Stockholm
  sudo ln -sf /usr/share/zoneinfo/Europe/Stockholm /etc/localtime || true

  # Keyboard & Input
  # Disable automatic capitalization
  defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false || true
  # Disable smart dashes
  defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false || true
  # Disable automatic period substitution
  defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false || true
  # Disable smart quotes
  defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false || true
  # Disable auto-correct
  defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false || true
  # Disable press-and-hold for key repeat
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false || true
  # Set a fast keyboard repeat rate
  defaults write NSGlobalDomain KeyRepeat -int 2 || true
  # Set a short initial key repeat delay
  defaults write NSGlobalDomain InitialKeyRepeat -int 15 || true
  # Enable full keyboard access for all controls
  defaults write NSGlobalDomain AppleKeyboardUIMode -int 3 || true

  # Finder
  # Allow quitting Finder via ⌘Q
  defaults write com.apple.finder QuitMenuItem -bool true || true
  # Show hidden files by default
  defaults write com.apple.finder AppleShowAllFiles -bool true || true
  # Show all filename extensions
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true || true
  # Show status bar in Finder
  defaults write com.apple.finder ShowStatusBar -bool true || true
  # Show path bar in Finder
  defaults write com.apple.finder ShowPathbar -bool true || true
  # Display full POSIX path as window title
  defaults write com.apple.finder _FXShowPosixPathInTitle -bool true || true
  # Keep folders on top when sorting by name
  defaults write com.apple.finder _FXSortFoldersFirst -bool true || true
  # Use list view in all Finder windows
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv" || true
  # Expand File Info panes for General, Open with, and Sharing & Permissions
  defaults write com.apple.finder FXInfoPanesExpanded -dict \
    General -bool true \
    OpenWith -bool true \
    Privileges -bool true || true
  # Show the ~/Library folder
  chflags nohidden ~/Library || true
  # Show the /Volumes folder
  sudo chflags nohidden /Volumes || true

  # Dock
  # Show indicator lights for open applications
  defaults write com.apple.dock show-process-indicators -bool true || true
  # Wipe all default app icons from the Dock
  defaults write com.apple.dock persistent-apps -array || true
  # Speed up Mission Control animations
  defaults write com.apple.dock expose-animation-duration -float 0.1 || true
  # Make Dock icons of hidden applications translucent
  defaults write com.apple.dock showhidden -bool true || true
  # Don't show recent applications in Dock
  defaults write com.apple.dock show-recents -bool false || true
  # Disable the Launchpad gesture
  defaults write com.apple.dock showLaunchpadGestureEnabled -int 0 || true
  # Set top right hot corner to show Desktop
  defaults write com.apple.dock wvous-tr-corner -int 4 || true
  # No modifier key for top right hot corner
  defaults write com.apple.dock wvous-tr-modifier -int 0 || true
  # Set bottom left hot corner to start screen saver
  defaults write com.apple.dock wvous-bl-corner -int 5 || true
  # No modifier key for bottom left hot corner
  defaults write com.apple.dock wvous-bl-modifier -int 0 || true

  # Screenshots
  # Save screenshots to iCloud Drive
  defaults write com.apple.screencapture location -string "/Users/pal/Library/Mobile Documents/com~apple~CloudDocs/Screenshots" || true
  # Save screenshots in PNG format
  defaults write com.apple.screencapture type -string "png" || true
  # Disable shadow in screenshots
  defaults write com.apple.screencapture disable-shadow -bool true || true

  # Display
  # Enable subpixel font rendering on non-Apple LCDs
  defaults write NSGlobalDomain AppleFontSmoothing -int 1 || true
  # Enable HiDPI display modes
  # sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true || true

  # Mac App Store
  # Enable WebKit Developer Tools in App Store
  defaults write com.apple.appstore WebKitDeveloperExtras -bool true || true
  # Enable automatic update check
  defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true || true
  # Check for updates daily
  defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1 || true
  # Download updates in background
  defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1 || true
  # Install system data files & security updates
  defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1 || true
  # Turn on app auto-update
  defaults write com.apple.commerce AutoUpdate -bool true || true

  # Photos
  # Prevent Photos from opening automatically when devices are plugged in
  defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true || true

  # Chrome
  # Disable backswipe on trackpads
  defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false || true
  # Disable backswipe on trackpads (Canary)
  defaults write com.google.Chrome.canary AppleEnableSwipeNavigateWithScrolls -bool false || true
  # Disable backswipe on Magic Mouse
  defaults write com.google.Chrome AppleEnableMouseSwipeNavigateWithScrolls -bool false || true
  # Disable backswipe on Magic Mouse (Canary)
  defaults write com.google.Chrome.canary AppleEnableMouseSwipeNavigateWithScrolls -bool false || true
  # Use system-native print preview dialog
  defaults write com.google.Chrome DisablePrintPreview -bool true || true
  # Use system-native print preview dialog (Canary)
  defaults write com.google.Chrome.canary DisablePrintPreview -bool true || true
  # Expand print dialog by default
  defaults write com.google.Chrome PMPrintingExpandedStateForPrint2 -bool true || true
  # Expand print dialog by default (Canary)
  defaults write com.google.Chrome.canary PMPrintingExpandedStateForPrint2 -bool true || true

  # Kill affected applications (excluding Terminal and iTerm2)
  # Restart applications to apply changes
  for app in "Activity Monitor" "Address Book" "Calendar" "cfprefsd" "Contacts" "Dock" "Finder" "Google Chrome Canary" "Google Chrome" "Mail" "Messages" "Photos" "SizeUp" "Spectacle" "SystemUIServer" "Transmission" "iCal"; do
    killall "${app}" &> /dev/null || true
  done

  log "Done. Note that some of these changes require a logout/restart to take effect."
}

setup_fish(){
  log "🐟 Setting up Fish shell..."
  local shell_path="$BREW_PREFIX/bin/fish"
  
  # Check if fish is already set up
  if [[ "$SHELL" == *fish ]] && grep -q "$shell_path" /etc/shells 2>/dev/null; then
    log "Fish shell already set up"
    return 0
  fi
  
  # Add fish to /etc/shells if not already there
  grep -q "$shell_path" /etc/shells || echo "$shell_path" | sudo tee -a /etc/shells || error "Failed to add fish to /etc/shells"
  
  # Create fish config directory if it doesn't exist
  mkdir -p ~/.config/fish || error "Failed to create fish config directory"
  
  # Add Homebrew to fish config if not already there
  if ! grep -q "brew shellenv" ~/.config/fish/config.fish 2>/dev/null; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.config/fish/config.fish || error "Failed to update fish config"
  fi
  
  # Change shell to fish if not already set
  if [[ "$SHELL" != *fish ]]; then
    chsh -s "$shell_path" || error "Failed to change shell to fish"
  fi
}

ghostty_config(){
  log "🖥️  Configuring Ghostty terminal..."
  
  mkdir -p ~/Library/Application\ Support/com.mitchellh.ghostty || error "Failed to create Ghostty config directory"
  cat > ~/Library/Application\ Support/com.mitchellh.ghostty/config <<'EOF' || error "Failed to write Ghostty config"
# see https://x.com/rauchg/status/1923842420778860803
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
  # Check if git is already configured
  if git config --global user.email &>/dev/null && git config --global user.name &>/dev/null; then
    log "Git already configured"
    return 0
  fi
  
  git config --global branch.autoSetupRebase always || error "Failed to set branch.autoSetupRebase"
  git config --global branch.autoSetupMerge always || error "Failed to set branch.autoSetupMerge"
  git config --global color.ui auto || error "Failed to set color.ui"
  git config --global core.autocrlf input || error "Failed to set core.autocrlf"
  git config --global core.editor code || error "Failed to set core.editor"
  git config --global credential.helper osxkeychain || error "Failed to set credential.helper"
  git config --global pull.rebase true || error "Failed to set pull.rebase"
  git config --global push.default simple || error "Failed to set push.default"
  git config --global rebase.autostash true || error "Failed to set rebase.autostash"
  git config --global rerere.autoUpdate true || error "Failed to set rerere.autoUpdate"
  git config --global rerere.enabled true || error "Failed to set rerere.enabled"
  git config --global user.email "pal@subtree.se" || error "Failed to set user.email"
  git config --global user.name "Pål Brattberg" || error "Failed to set user.name"
}

install_nvm_node(){
  log "🟢 Installing Node.js and NVM..."
  # Check if NVM is already installed
  if [[ -d "$HOME/.nvm" ]]; then
    log "NVM already installed"
    return 0
  fi
  
  if ! curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/refs/heads/master/install.sh | bash; then
    error "Failed to install NVM"
    return 1
  fi
  
  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1090
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    . "$NVM_DIR/nvm.sh"
  else
    error "NVM installation appears to be incomplete"
    return 1
  fi
  
  if ! nvm install --lts; then
    error "Failed to install Node.js LTS"
    return 1
  fi
  
  if ! nvm alias default "lts/*"; then
    error "Failed to set default Node.js version"
    return 1
  fi
}

setup_ssh_keys(){
  log "🔑 Setting up SSH keys for GitHub..."
  
  # Check if SSH key exists
  if [[ -f ~/.ssh/id_ed25519 ]]; then
    log "SSH key already exists"
    return 0
  fi
  
  log "Generating new SSH key..."
  ssh-keygen -t ed25519 -C "pal@subtree.se" -f ~/.ssh/id_ed25519 -N "" || error "Failed to generate SSH key"
  
  # Start ssh-agent
  eval "$(ssh-agent -s)" || error "Failed to start ssh-agent"
  ssh-add ~/.ssh/id_ed25519 || error "Failed to add SSH key to ssh-agent"
  
  # Display public key for user to add to GitHub
  log "Please add this SSH key to your GitHub account:"
  cat ~/.ssh/id_ed25519.pub
  log "Press Enter once you've added the key to GitHub..."
  read -r
}

clone_repos(){
  log "📚 Cloning development repositories..."
  local BASE=~/dev
  mkdir -p "$BASE" || error "Failed to create dev directory"
  cd "$BASE" || error "Failed to change to dev directory"
  
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
    [subtree.se]=git@github.com:subtree/subtree.se.git
    [jujino.com]=git@github.com:subtree/jujino.com.git
    [julafton.com]=git@github.com:subtree/julafton.com.git
    [mac-setup-script]=git@github.com:pal/mac-setup-script.git
    [palbrattberg.com]=git@github.com:pal/palbrattberg.com.git
    [ai-pres]=git@github.com:pal/ai-pres.git
    [deep-research]=git@github.com:pal/deep-research.git
    [domainchecker]=git@github.com:pal/domainchecker.git
    [mousegame]=git@github.com:pal/mousegame.git
    [k8s-hosting]=git@github.com:subtree/k8s-hosting.git
    [bolt.diy]=git@github.com:stackblitz-labs/bolt.diy.git
    [opencontrol]=git@github.com:toolbeam/opencontrol.git
    # [productvoice]=git@github.com:WeDoProducts/productvoice.git
    # [covid-containment]=git@github.com:Shpigford/covid-containment.git
  )
  
  for dir in "${!REPOS[@]}"; do
    if [[ -d "$dir" ]]; then
      log "Repository already exists: $dir"
      continue
    fi
    
    url_branch="${REPOS[$dir]}"
    url=${url_branch%%#*}
    branch=${url_branch#*#}
    [[ "$branch" == "$url_branch" ]] && branch=""
    
    if [[ -n $branch ]]; then
      git clone --single-branch --branch "$branch" "$url" "$dir" || error "Failed to clone $dir"
    else
      git clone "$url" "$dir" || error "Failed to clone $dir"
    fi
  done
}

mackup_config(){
  log "💾 Configuring Mackup backup..."
  # Check if config already exists
  if [[ -f ~/.mackup.cfg ]]; then
    log "Mackup configuration already exists"
    return 0
  fi
  
  mkdir -p ~/.mackup || error "Failed to create Mackup directory"
  cat > ~/.mackup.cfg <<'EOF' || error "Failed to write Mackup config"
[storage]
engine = iCloud Drive
EOF
}

post_install(){
  log "Post-installation steps:"
  log "1. Open and sign in to required apps: 1Password, Dropbox, Google Chrome, Magnet"
  log "2. Configure Dropbox selective sync."
}

prevent_sleep(){
  log "💤 Preventing system sleep during installation..."
  caffeinate -i &
  CAFFEINATE_PID=$!
  # Set up trap to restore sleep on script exit
  trap 'restore_sleep' EXIT
}

restore_sleep(){
  if [[ -n "${CAFFEINATE_PID:-}" ]]; then
    log "💤 Restoring normal sleep settings..."
    kill $CAFFEINATE_PID 2>/dev/null || true
  fi
}

check_manual_steps(){
  log "🔍 Checking manual steps..."
  local needs_manual_steps=false
  local manual_steps=()

  # Check Mac App Store login
  if ! mas list &>/dev/null; then
    needs_manual_steps=true
    manual_steps+=("Sign in to Mac App Store")
  fi

  # Check 1Password
  if ! osascript -e 'tell application "1Password" to get version' &>/dev/null; then
    needs_manual_steps=true
    manual_steps+=("Open and sign in to 1Password")
  fi

  # Check Dropbox
  if ! osascript -e 'tell application "Dropbox" to get version' &>/dev/null; then
    needs_manual_steps=true
    manual_steps+=("Open and sign in to Dropbox")
  fi

  # Check Chrome
  if ! osascript -e 'tell application "Google Chrome" to get version' &>/dev/null; then
    needs_manual_steps=true
    manual_steps+=("Open and sign in to Chrome")
  fi

  if $needs_manual_steps; then
    log "⚠️  Manual steps required:"
    for step in "${manual_steps[@]}"; do
      log "  • $step"
    done
    log "\nPlease complete these steps and run the script again."
    exit 0
  fi
}

main(){
  prevent_sleep
  install_xcode_clt
  install_homebrew
  accept_xcode_license
  brew_bundle
  check_manual_steps
  mas_install
  set_names
  configure_defaults
  setup_fish
  ghostty_config
  configure_git
  install_nvm_node
  setup_ssh_keys
  clone_repos
  mackup_config
  post_install
  
  # Calculate and display duration
  END_TIME=$(date +%s)
  DURATION=$((END_TIME - START_TIME))
  HOURS=$((DURATION / 3600))
  MINUTES=$(( (DURATION % 3600) / 60 ))
  SECONDS=$((DURATION % 60))
  
  DURATION_MSG="Installation took "
  if [ $HOURS -gt 0 ]; then
    DURATION_MSG+="${HOURS}h "
  fi
  if [ $MINUTES -gt 0 ]; then
    DURATION_MSG+="${MINUTES}m "
  fi
  DURATION_MSG+="${SECONDS}s"
  
  log "Setup complete! $DURATION_MSG"
}

main "$@"
