#!/usr/bin/env bash

# Download and setup all repos needed for development
ROOT=~/dev3

mkdir $ROOT
cd $ROOT

git clone https://github.com/flutter/flutter.git
git clone git@github.com:pal/Paw-DigestAuthDynamicValue.git
git clone git@github.com:pal/mac-setup-script.git
git clone git@github.com:pal/peasy-utils.git
git clone --single-branch --branch master git@github.com:pal/peasy.git peasy-master
git clone --single-branch --branch v2 git@github.com:pal/peasy.git peasy
git clone git@github.com:pal/peasy_mobile.git
git clone git@github.com:pal/duris.git
git clone git@github.com:pal/julafton.com.git

sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

flutter precache
flutter doctor

echo "All done, hack away! 👨‍💻"