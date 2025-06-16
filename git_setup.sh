#!/usr/bin/env bash

# Download and setup all repos needed for development
ROOT=~/dev

mkdir $ROOT
cd $ROOT

# Peasy & related repos
git clone --single-branch --branch master git@github.com:pal/peasy.git peasy-master
git clone --single-branch --branch planetscale git@github.com:pal/peasy.git peasy
git clone git@github.com:pal/frankfurter.git
git clone git@github.com:pal/peasy_client.git
git clone git@github.com:pal/peasyv3.git
git clone git@github.com:subtree/peasy-ui.git

# Subtree repos
git clone git@github.com:subtree/saas-template.git
git clone git@github.com:subtree/template-magic-board.git
git clone git@github.com:subtree/setup-hosting.git
git clone git@github.com:subtree/companynamemaker.com.git
git clone git@github.com:subtree/juniormarketer.ai.git
git clone git@github.com:subtree/social-image-creator.git
git clone git@github.com:subtree/saas-template-upptime.git
git clone git@github.com:subtree/subtree-sites.git
git clone https://github.com/subtree/subtree.se.git
git clone https://github.com/subtree/jujino.com.git
git clone git@github.com:subtree/julafton.com.git

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
git clone git@github.com:pal/mac-setup-script.git
git clone git@github.com:pal/palbrattberg.com.git
git clone git@github.com:pal/ai-pres.git
git clone git@github.com:pal/deep-research.git
git clone https://github.com/pal/domainchecker.git
git clone https://github.com/pal/mousegame.git

# Infrastructure & Tools
git clone https://github.com/subtree/k8s-hosting.git
git clone git@github.com:typemill/typemill.git
git clone git@github.com:requarks/wiki.git
git clone git@github.com:stackblitz-labs/bolt.diy.git
git clone git@github.com:toolbeam/opencontrol.git

# Other projects
git clone git@github.com:WeDoProducts/productvoice.git
git clone git@github.com:Shpigford/covid-containment.git

sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# flutter precache
# flutter doctor

echo "All done, hack away! 👨‍💻"
