{ config, pkgs, ... }:

{
  imports = [
    ./settings

    ./shell

    ./macos
    ./hammerspoon

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

  my = {
    shell.enable = true;
    git.enable = true;
    mail = { enable = true; };
    gpg.enable = true;
    ssh.enable = true;
    kitty.enable = true;
    alacritty.enable = true;
    bat.enable = true;
    lf.enable = true;
    mpv.enable = true;
    newsboat.enable = true;
    python.enable = true;
    ripgrep.enable = true;
    tmux.enable = true;
    tuir.enable = true;
    youtube-dl.enable = true;
    misc.enable = true;
    vim.enable = true;

    node.enable = true;
    java.enable = false;
    kotlin.enable = true;
    weechat.enable = true;
    go.enable = true;
    rust.enable = true;
    rescript.enable = true;
    gui.enable = true;
    clojure.enable = true;

    macos.enable = pkgs.stdenv.isDarwin;
    hammerspoon.enable = pkgs.stdenv.isDarwin;
  };
}
