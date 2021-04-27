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
    ./ttrv.nix
    ./youtube-dl.nix
    ./misc.nix
    ./vim.nix
    ./node.nix
    ./deno.nix
    ./java.nix
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
  ];

  my.modules = {
    shell.enable = true;
    git.enable = true;
    ssh.enable = true;
    syncthing.enable = true;

    kitty.enable = true;
    alacritty.enable = true;
    bat.enable = true;
    lf.enable = true;
    mpv.enable = true;
    python.enable = true;
    ripgrep.enable = true;
    tmux.enable = true;
    ttrv.enable = true;
    misc.enable = true;
    vim.enable = true;
    gui.enable = true;

    node.enable = true;
    deno.enable = true;
    go.enable = true;
    rust.enable = false;
  };

}
