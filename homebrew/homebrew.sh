# Homebrew taps
TAPS=(
    homebrew/dupes
    homebrew/versions
    caskroom/cask
    caskroom/fonts
    caskroom/versions
    # for sitespeedio
    sitespeedio/sitespeedio
    tobli/browsertime
)

# Homebrew Formulas
FORMULAS=(
    coreutils
    findutils
    zsh
    caskroom/cask/brew-cask
    wget
    z
    git
    node
    tree
    dnsmasq
    mongodb
    phantomjs
    gh
    rbenv
    rbenv-gem-rehash
    ruby-build
    the_silver_searcher
    macvim --override-system-vim --custom-icons --with-lua
    imagemagick
    nginx
    mysql
    sitespeedio
    todo-txt
    ctags
    # Python & work related stuff
    python --universal #2.7.8
    # openssl
    gdal #1.11.1
    geos #3.4.2
    postgis #2.1.4
    postgresql #9.3.5
    proj #4.8.0
    elasticsearch-0.20 #0.20.6
    libmemcached #1.0.18
    redis
)

# Homebrew casks
CASKS=(
    font-inconsolata-dz-for-powerline
    font-inconsolata
    font-source-code-pro
    font-droid-sans-mono
    font-meslo-lg
    box-sync
    chromecast
    google-chrome
    google-chrome-canary
    firefox
    firefox-aurora
    firefox-nightly
    webkit-nightly
    opera
    opera-next
    lynxlet
    caffeine
    alfred
    #cloudapp
    dash
    spectacle
    imagealpha
    imageoptim
    iterm2
    sequel-pro
    sublime-text-3
    the-unarchiver
    sketch
    evernote
    synergy
    telegram
    jdownloader2
    skype
    wunderlist
    lime-chat
    transmit
    virtualbox
    vlc
    hipchat
    betterzipql
    qlcolorcode
    qlmarkdown
    qlprettypatch
    qlstephen
    quicklook-csv
    quicklook-json
    webp-quicklook
    recordit
    transmission
    appcleaner
)

#================================================================================

brew update

brew tap ${TAPS[@]} && brew install ${FORMULAS[@]}

echo "to update setuptools & pip run: pip install --upgrade setuptools pip install --upgrade pip"
echo "Don’t forget to add $(brew --prefix coreutils)/libexec/gnubin to \$PATH."
echo " Changing shell...."
# sudo echo "/usr/local/bin/zsh" >> /etc/shells && chsh -s /usr/local/bin/zsh


brew cask ${CASKS[@]} && brew cask alfred link

echo "Put your license in Dash & Sublime. and Install Tweetbot"

brew cleanup
