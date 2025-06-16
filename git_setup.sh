#!/usr/bin/env bash

set -e # stop on any error
set -x # show debug

# Download and setup all repos needed for development
ROOT=~/dev

mkdir -p $ROOT
cd $ROOT

# Function to clone a repo if it doesn't exist
clone_if_not_exists() {
    local repo=$1
    local dir=$2
    if [ ! -d "$dir" ]; then
        git clone $repo $dir
    else
        echo "Repository $dir already exists, skipping..."
    fi
}

# Peasy & related repos
clone_if_not_exists "git@github.com:pal/peasy.git --single-branch --branch master" "peasy-master"
clone_if_not_exists "git@github.com:pal/peasy.git --single-branch --branch planetscale" "peasy"
clone_if_not_exists "git@github.com:pal/frankfurter.git" "frankfurter"
clone_if_not_exists "git@github.com:pal/peasy_client.git" "peasy_client"
clone_if_not_exists "git@github.com:pal/peasyv3.git" "peasyv3"
clone_if_not_exists "git@github.com:subtree/peasy-ui.git" "peasy-ui"

# Subtree repos
clone_if_not_exists "git@github.com:subtree/saas-template.git" "saas-template"
clone_if_not_exists "git@github.com:subtree/template-magic-board.git" "template-magic-board"
clone_if_not_exists "git@github.com:subtree/setup-hosting.git" "setup-hosting"
clone_if_not_exists "git@github.com:subtree/companynamemaker.com.git" "companynamemaker.com"
clone_if_not_exists "git@github.com:subtree/juniormarketer.ai.git" "juniormarketer.ai"
clone_if_not_exists "git@github.com:subtree/social-image-creator.git" "social-image-creator"
clone_if_not_exists "git@github.com:subtree/saas-template-upptime.git" "saas-template-upptime"
clone_if_not_exists "git@github.com:subtree/subtree-sites.git" "subtree-sites"
clone_if_not_exists "https://github.com/subtree/subtree.se.git" "subtree.se"
clone_if_not_exists "https://github.com/subtree/jujino.com.git" "jujino.com"
clone_if_not_exists "git@github.com:subtree/julafton.com.git" "julafton.com"

# Personal projects
# git clone git@github.com:exchangeratesapi/exchangeratesapi.git
# git clone git@github.com:pal/Paw-DigestAuthDynamicValue.git
# git clone git@github.com:pal/datalib.git
# git clone git@github.com:pal/duris.git
# git clone git@github.com:pal/in-memory-analytics.git
# git clone git@github.com:pal/julafton.com.git
# git clone git@github.com:pal/orders-in-mysql.git
# git clone git@github.com:pal/playbook-template.git
# git clone git@github.com:pal/simple-counter-server.git
clone_if_not_exists "git@github.com:pal/mac-setup-script.git" "mac-setup-script"
clone_if_not_exists "git@github.com:pal/palbrattberg.com.git" "palbrattberg.com"
clone_if_not_exists "git@github.com:pal/ai-pres.git" "ai-pres"
clone_if_not_exists "git@github.com:pal/deep-research.git" "deep-research"
clone_if_not_exists "https://github.com/pal/domainchecker.git" "domainchecker"
clone_if_not_exists "https://github.com/pal/mousegame.git" "mousegame"

# Infrastructure & Tools
clone_if_not_exists "https://github.com/subtree/k8s-hosting.git" "k8s-hosting"
clone_if_not_exists "git@github.com:typemill/typemill.git" "typemill"
clone_if_not_exists "git@github.com:requarks/wiki.git" "wiki"
clone_if_not_exists "git@github.com:stackblitz-labs/bolt.diy.git" "bolt.diy"
clone_if_not_exists "git@github.com:toolbeam/opencontrol.git" "opencontrol"

# Other projects
clone_if_not_exists "git@github.com:WeDoProducts/productvoice.git" "productvoice"
clone_if_not_exists "git@github.com:Shpigford/covid-containment.git" "covid-containment"

# Setup Xcode if installed
if [[ -d "/Applications/Xcode.app" ]]; then
    # Only run xcode-select if it's not already set
    if [[ $(xcode-select -p) != "/Applications/Xcode.app/Contents/Developer" ]]; then
        sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
    fi
    # Only run first launch if it hasn't been run before
    if [[ ! -f "$HOME/Library/Developer/Xcode/FirstLaunch" ]]; then
        sudo xcodebuild -runFirstLaunch
    fi
fi

echo "All done, hack away! 👨‍💻"
