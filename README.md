# New Mac Setup

Here's a script that will setup a new Mac with all the tools and apps I use.


Run using `
curl -sL https://raw.githubusercontent.com/pal/mac-setup-script/master/setup.sh | bash
`


## Non-functional requirements

- Prefer installation from Mac App Store, second choice Homebrew
- Ensure the order of installation takes dependencies into account (e.g. install Xcode first, then git, then Homebrew etc)
- Ensure the setup script is idempotent and can be run multiple times without causing issues
- Ensure the setup script is robust and that errors are handled gracefully and reported
- Ensure there's a simple way to run the setup script from a brand new Mac, having to do as little as possible to get it working, ideally not evenhaving to download the repo
- Make the solution as simple as possible, with as few moving parts as possible and be able to run on most machines. 
- Prefer bash as scripting language and prefer keeping everything in one file.
- Require all user interaction (such as `sudo`) to be done up-front if possible.


## Prerequisites

- Xcode Command Line Tools
- Homebrew
- Git
- SSH key pair

## System Configuration

### Computer Name
- Set computer name to "pal-brattberg-macbookpro"
- Configure hostname and local hostname to match
- Set NetBIOS name to match

### Language & Region
- Language: English
- Locale: Swedish with SEK currency
- Measurement units: Centimeters
- Timezone: Europe/Stockholm

### Keyboard & Input
- Disable automatic capitalization
- Disable smart dashes
- Disable automatic period substitution
- Disable smart quotes
- Disable auto-correct
- Enable full keyboard access for all controls
- Disable press-and-hold for keys
- Set fast keyboard repeat rate

### Finder Configuration
- Show hidden files by default
- Show all filename extensions
- Show status bar
- Show path bar
- Display full POSIX path as window title
- Keep folders on top when sorting by name
- Show ~/Library folder
- Show /Volumes folder
- Use list view in all Finder windows
- Expand File Info panes for General, Open with, and Sharing & Permissions
- Show icons for hard drives, servers, and removable media on desktop
- Allow quitting via ⌘ + Q
- Avoid creating .DS_Store files on network or USB volumes
- Automatically open new Finder window when volume is mounted

### Screen & Screenshots
- Save screenshots to iCloud Drive/Screenshots/2025_Intersolia
- Save screenshots in PNG format
- Disable shadow in screenshots
- Enable HiDPI display modes

## Development Environment

### Shell Setup
- Install and configure Fish shell
- Set Fish as default shell
- Setup Ghostty as terminal with this config:
```
# see https://x.com/rauchg/status/1923842420778860803
theme = Mathias
font-family = GeistMono NF
font-size = 11
macos-titlebar-style = tabs
#macos-icon = glass
#macos-titlebar-proxy-icon = hidden
split-divider-color = #222
unfocused-split-opacity = 1
cursor-style = block
cursor-style-blink = false
cursor-color = #B62EB2
shell-integration-features = no-cursor

```

### Git Configuration
```bash
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
git config --global user.email pal@subtree.se
git config --global user.name Pål Brattberg
```

### Node.js Setup
- Install NVM
- Install Node.js LTS version
- Set LTS as default version

### Development Tools
Install the following tools via Homebrew:
- aws-cdk
- awscli
- bash
- direnv
- eza
- ffmpeg
- fish
- gh (GitHub CLI)
- git
- jq
- libpq
- mackup
- mas (Mac App Store CLI)
- maven
- p7zip
- pkgconf
- pnpm
- postgresql@16
- ripgrep
- subversion
- wget
- nx

### Applications
Install the following applications:

#### Mac App Store (use mas)
- Dato
- HEIC Converter
- Keynote
- Magnet
- Microsoft Office Suite (Excel, OneNote, Outlook, PowerPoint, To Do, Word)
- Numbers
- OneDrive
- Pages
- Pixelmator Pro
- TestFlight
- Valheim
- Xcode

#### Homebrew Casks
- 1password
- aws-vault
- beekeeper-studio
- cursor
- cyberduck
- devutils
- discord
- dropbox
- dynobase
- elgato-control-center
- figma
- rapidapi
- Fonts: Fira Code, Input, Inter, JetBrains Mono, Roboto, GeistMono NF
- ghostty
- google-chrome
- orbstack
- raycast
- session-manager-plugin
- slack
- telegram
- spotify
- visual-studio-code
- zoom

### VS Code Extensions
- adpyke.vscode-sql-formatter
- aeschli.vscode-css-formatter
- bierner.markdown-checkbox
- bierner.markdown-emoji
- bierner.markdown-mermaid
- bierner.markdown-preview-github-styles
- bierner.markdown-yaml-preamble
- bradlc.vscode-tailwindcss
- fabianlauer.vs-code-xml-format
- github.vscode-github-actions
- matt-meyers.vscode-dbml
- mechatroner.rainbow-csv
- ms-azuretools.vscode-docker
- tyriar.sort-lines

## Repository Setup

Create and clone the following repositories in ~/dev:

### Peasy & Related
- peasy-master (master branch of peasy): `git@github.com:pal/peasy.git --single-branch --branch master`
- peasy (planetscale branch of peasy): `git@github.com:pal/peasy.git --single-branch --branch planetscale`
- frankfurter: `git@github.com:pal/frankfurter.git`
- peasy_client: `git@github.com:pal/peasy_client.git`
- peasyv3: `git@github.com:pal/peasyv3.git`
- peasy-ui: `git@github.com:subtree/peasy-ui.git`

### Subtree
- saas-template: `git@github.com:subtree/saas-template.git`
- template-magic-board: `git@github.com:subtree/template-magic-board.git`
- setup-hosting: `git@github.com:subtree/setup-hosting.git`
- companynamemaker.com: `git@github.com:subtree/companynamemaker.com.git`
- juniormarketer.ai: `git@github.com:subtree/juniormarketer.ai.git`
- social-image-creator: `git@github.com:subtree/social-image-creator.git`
- saas-template-upptime: `git@github.com:subtree/saas-template-upptime.git`
- subtree-sites: `git@github.com:subtree/subtree-sites.git`
- subtree.se: `https://github.com/subtree/subtree.se.git`
- jujino.com: `https://github.com/subtree/jujino.com.git`
- julafton.com: `git@github.com:subtree/julafton.com.git`

### Personal Projects
- mac-setup-script: `git@github.com:pal/mac-setup-script.git`
- palbrattberg.com: `git@github.com:pal/palbrattberg.com.git`
- ai-pres: `git@github.com:pal/ai-pres.git`
- deep-research: `git@github.com:pal/deep-research.git`
- domainchecker: `https://github.com/pal/domainchecker.git`
- mousegame: `https://github.com/pal/mousegame.git`

### Infrastructure & Tools
- k8s-hosting: `https://github.com/subtree/k8s-hosting.git`
- typemill: `git@github.com:typemill/typemill.git`
- wiki: `git@github.com:requarks/wiki.git`
- bolt.diy: `git@github.com:stackblitz-labs/bolt.diy.git`
- opencontrol: `git@github.com:toolbeam/opencontrol.git`

### Other Projects
- productvoice: `git@github.com:WeDoProducts/productvoice.git`
- covid-containment: `git@github.com:Shpigford/covid-containment.git`

## Backup & Restore

- Configure Mackup for settings backup/restore
- Store Mackup configuration in iCloud Drive
- Restore settings from iCloud backup

## Post-Installation Steps

1. Open each of the following applications once to ensure proper configuration and login:
   - 1password
   - cursor
   - discord
   - slack
   - dropbox
   - dynobase (see https://member.dynobase.dev/)
   - rapidapi
2. Configure Dropbox folder sync to only sync the following folders:
   - ~/Mackup
   - ~/Privat/palbrattberg.com
   - ~/Privat/tictactoe
3. Accept Xcode license
4. Configure Xcode:
   - Set as default developer directory
   - Run first launch setup

## Success Criteria

The new implementation should:
1. Successfully install all required tools and applications
2. Configure all system settings as specified
3. Set up development environment with correct versions
4. Clone all required repositories
5. Configure Git with specified settings
6. Set up backup and restore functionality
7. Handle both Intel and Apple Silicon Macs
8. Provide clear error messages and logging
9. Allow for partial execution and resume capability
10. Support both fresh installs and updates to existing setup 