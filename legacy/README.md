Dead simple script to setup my new Mac:

```shell
xcode-select --install

curl -sL https://raw.githubusercontent.com/pal/mac-setup-script/master/setup.sh | sh
curl -sL https://raw.githubusercontent.com/pal/mac-setup-script/master/defaults.sh | sh
curl -sL https://raw.githubusercontent.com/pal/mac-setup-script/master/git-setup.sh | sh
```

To prepare for leaving (reinstalling) a computer, first make sure you've updated ``setup.sh`` with all used apps, gathered a list of current brews using ``brew bundle dump``, looked over your install apps to see if any are missing, made sure the list of repos in ``~/dev/`` is described in ``git_setup.sh`` and that you have run ``mackup backup``.

If, for some reason, you want to install only from the Brewfile, simply install Homebrew and run: 
```
curl -sL https://raw.githubusercontent.com/pal/mac-setup-script/master/Brewfile
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" 
brew bundle
```
# Now what?
Open each application once to make sure it's configured.

Dropbox - select folders to sync.