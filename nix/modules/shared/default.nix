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
    shell.enable = true;
    git.enable = true;
    ssh.enable = true;
    syncthing.enable = true;

    kitty.enable = true;
    wezterm.enable = true;
    bat.enable = true;
    lf.enable = true;
    mpv.enable = true;
    python.enable = true;
    ripgrep.enable = true;
    tmux.enable = true;
    misc.enable = true;
    vim.enable = true;
    gui.enable = true;
    yt-dlp.enable = true;

    node.enable = true;
    deno.enable = true;
    go.enable = true;
    rust.enable = true;
    zk.enable = true;
  };

}
