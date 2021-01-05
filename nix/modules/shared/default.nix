{ config, pkgs, ... }:

{
  imports = [
    ./settings.nix
    ./shell.nix
    ./aerc.nix
    ./mail.nix
    ./gpg.nix
    ./ssh.nix
    ./git.nix
    ./kitty.nix
    ./alacritty.nix
    ./bat.nix
    ./lf.nix
    ./mpv.nix
    ./newsboat.nix
    ./ripgrep.nix
    ./tmux.nix
    ./tuir.nix
    ./youtube-dl.nix
    ./misc.nix
    ./vim.nix
    ./node.nix
    ./java.nix
    ./kotlin.nix
    ./weechat.nix
    ./go.nix
    ./rust.nix
    ./rescript.nix
    ./gui.nix
    ./clojure.nix
    ./python.nix
  ];
}
