# My [.]files

For setting up development environment on new Macs.

*Disclaimer:* I'm new to this stuff, so if you want to use it, use it on your own risk. The `bin/` folder is not stable, don't use any of the files inside.

You are welcome to give tips on how can I improve this. 

## Tools:

* Command line tools through [Xcode](https://itunes.apple.com/en/app/xcode/id497799835?mt=12) or from [Apple Developer website](https://developer.apple.com/downloads)
* [Prezto](https://github.com/sorin-ionescu/prezto)
* [Homebrew](http://mxcl.github.io/homebrew/)
    * [Git](http://git-scm.com/)
    * [Nodejs](http://nodejs.org/) with [NPM](https://npmjs.org/)
    * [Ruby](http://www.ruby-lang.org/en/) using [rbenv](https://github.com/sstephenson/rbenv/) & [Ruby build](https://github.com/sstephenson/ruby-build)  & [Ruby Gems](http://rubygems.org)
* [PHP](http://php-osx.liip.ch/)

### Applications
* [iTerm](http://www.iterm2.com/)
* [Sublime Text 3](http://www.sublimetext.com/3)
* Browsers
    * [Google Chrome](https://www.google.com/intl/en/chrome/browser/)
    * [Google Chrome Canary](https://www.google.com/intl/en/chrome/browser/canary.html)
    * [Firefox](http://www.mozilla.org/en-US/firefox/new/)
    * [Firefox Nightly](http://nightly.mozilla.org/)
    * [Opera](http://www.opera.com/)
    * [Opera next](http://www.opera.com/computer/next)
* [VirtualBox](https://www.virtualbox.org/)
* [Caffeine](http://itunes.apple.com/us/app/caffeine/id411246225)
* [Alfred](http://www.alfredapp.com/)
* [AppCleaner](http://www.freemacsoft.net/appcleaner/)
* [Dropbox](http://dropbox.com)
* [CloudApp](https://itunes.apple.com/us/app/cloud/id417602904?mt=12)
* [VLC Player](http://www.videolan.org/vlc/index.html)
* [Dash](https://itunes.apple.com/us/app/dash-docs-snippets/id458034879?mt=12)
* [ImageAlpha](http://pngmini.com/)
* [ImageOptim](http://imageoptim.com/)
* [Spectacle](http://spectacleapp.com/)
* [Sequel Pro](http://www.sequelpro.com/)
* [Sketch](http://www.bohemiancoding.com/sketch/)
* [Skype](http://www.skype.com/en/)
* [Wunderlist](https://itunes.apple.com/us/app/wunderlist-to-do-task-list/id410628904?mt=12)
* [Limechat](http://limechat.net/mac/)
* [Tweetbot](https://itunes.apple.com/us/app/tweetbot-for-twitter/id557168941?mt=12)
* [XtraFinder](http://www.trankynam.com/xtrafinder/)

## Installation
1- Install Command line tools through [Xcode](https://itunes.apple.com/en/app/xcode/id497799835?mt=12) from the App Store or download it directly from [Apple Developer website](https://developer.apple.com/downloads).

2- Install [Homebrew](http://mxcl.github.io/homebrew/)

    ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)

3- Install Homebrew packages needed.

    brew install git node rbenv ruby-build rbenv-gem-rehash ack coreutils wget dnsmasq mongodb

afterward install Ruby like so

    rbenv install 2.0.0p-0
    rbenv global 2.0.0p-0

4- Install [Prezto](https://github.com/sorin-ionescu/prezto) & Change the shel to ZSH

    chsh -s /bin/zsh

5- Clone the repo, symlink the files & install all the needed packages/gems/etc...

    git clone https://github.com/ahmedelgabri/dotfiles.git .dotfiles
    $ cd .dotfiles/ && ./bin/install


#### Through Homebrew

6- Install Node with NPM & it's packages under NPM `packages.local`

    brew install node
7- Install Rbenv

    brew install rbenv ruby-build







