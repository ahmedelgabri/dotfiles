{ config, lib, pkgs, ... }:

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
    ./wezterm.nix
    ./bat.nix
    ./lf.nix
    ./mpv.nix
    ./ripgrep.nix
    ./tmux.nix
    ./yt-dlp.nix
    ./misc.nix
    ./vim.nix
    ./node.nix
    ./deno.nix
    ./kotlin.nix
    ./irc.nix
    ./go.nix
    ./rust.nix
    ./rescript.nix
    ./gui.nix
    ./clojure.nix
    ./python.nix
    ./syncthing.nix
    ./discord.nix
    ./hledger.nix
    ./zk.nix
  ];

  my.modules = {
    shell.enable = lib.mkDefault true;
    git.enable = lib.mkDefault true;
    ssh.enable = lib.mkDefault true;
    syncthing.enable = lib.mkDefault true;

    kitty.enable = lib.mkDefault true;
    wezterm.enable = lib.mkDefault true;
    bat.enable = lib.mkDefault true;
    lf.enable = lib.mkDefault true;
    mpv.enable = lib.mkDefault true;
    python.enable = lib.mkDefault true;
    ripgrep.enable = lib.mkDefault true;
    tmux.enable = lib.mkDefault true;
    misc.enable = lib.mkDefault true;
    vim.enable = lib.mkDefault true;
    gui.enable = lib.mkDefault true;
    yt-dlp.enable = lib.mkDefault true;

    node.enable = lib.mkDefault true;
    deno.enable = lib.mkDefault true;
    go.enable = lib.mkDefault true;
    rust.enable = lib.mkDefault true;
    zk.enable = lib.mkDefault true;
  };

}
