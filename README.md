Dead simple script to setup my new Mac:

```shell
xcode-select --install

curl -sL https://raw.githubusercontent.com/pal/mac-setup-script/master/setup.sh | sh
curl -sL https://raw.githubusercontent.com/pal/mac-setup-script/master/defaults.sh | sh

curl -sL https://raw.githubusercontent.com/pal/mac-setup-script/master/git-setup.sh | sh
```

To prepare for leaving (reinstalling) a computer, first make sure you've updated ``setup.sh`` with all used apps, gathering a list using ``brew bundle dump``.

If, for some reason, you want to install only from the Brewfile, simple install Homebrew and run: 
```
curl -sL https://raw.githubusercontent.com/pal/mac-setup-script/master/Brewfile
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" 
brew bundle
```
