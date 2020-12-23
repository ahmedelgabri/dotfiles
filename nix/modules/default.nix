{ config, pkgs, ... }:

{
  imports = [
    ./settings

    ./shell

    ./mail
    ./gpg
    ./ssh
    ./git
    ./kitty
    ./alacritty
    ./bat
    ./lf
    ./mpv
    ./newsboat
    ./ripgrep
    ./tmux
    ./tuir
    ./youtube-dl
    ./misc
    ./vim

    ./node
    ./java
    ./kotlin
    ./weechat
    ./go
    ./rust
    ./rescript
    ./gui
    ./clojure
    ./python
  ];
}
