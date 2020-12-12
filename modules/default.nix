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
    ./node
    ./vim

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
    node.enable = true;
    vim.enable = true;
    macos.enable = pkgs.stdenv.isDarwin;
    hammerspoon.enable = pkgs.stdenv.isDarwin;
  };
}
