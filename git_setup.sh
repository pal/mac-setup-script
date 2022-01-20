#!/usr/bin/env bash

# Download and setup all repos needed for development
ROOT=~/dev

mkdir $ROOT
cd $ROOT

git clone --single-branch --branch master git@github.com:pal/peasy.git peasy-master
git clone --single-branch --branch v2 git@github.com:pal/peasy.git peasy
# git clone git@github.com:pal/Paw-DigestAuthDynamicValue.git
# git clone git@github.com:pal/datalib.git
# git clone git@github.com:pal/duris.git
git clone git@github.com:pal/frankfurter.git
# git clone git@github.com:pal/in-memory-analytics.git
# git clone git@github.com:pal/julafton.com.git
git clone git@github.com:pal/mac-setup-script.git
# git clone git@github.com:pal/orders-in-mysql.git
# git clone git@github.com:pal/peasy-intranet.git
# git clone git@github.com:pal/peasy-utils.git
# git clone git@github.com:pal/peasy_backoffice.git
# git clone git@github.com:pal/peasy_backoffice_basic.git
git clone git@github.com:pal/peasy_client.git
# git clone git@github.com:pal/peasy_mobile.git
# git clone git@github.com:pal/playbook-template.git
# git clone git@github.com:pal/simple-counter-server.git
git clone git@github.com:pal/subtree-apple-certs.git
# git clone git@github.com:pal/subtree-backoffice.git
git clone git@github.com:subtree/peasy-api-docs.git
git clone https://github.com/flutter/flutter.git

# git clone git@github.com:exchangeratesapi/exchangeratesapi.git

sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

flutter precache
flutter doctor

echo "All done, hack away! 👨‍💻"

