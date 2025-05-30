{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./settings.nix
    ./shell.nix
    ./mail.nix
    ./gpg.nix
    ./ssh.nix
    ./git.nix
    ./kitty.nix
    ./bat.nix
    ./yazi.nix
    ./mpv.nix
    ./ripgrep.nix
    ./tmux.nix
    ./yt-dlp.nix
    ./misc.nix
    ./vim.nix
    ./node.nix
    ./irc.nix
    ./go.nix
    ./rust.nix
    ./gui.nix
    ./python.nix
    ./discord.nix
    ./zk.nix
    ./hammerspoon.nix
    ./ghostty.nix
    ./ai.nix
    ./karabiner.nix
  ];

  my.modules = {
    shell.enable = lib.mkDefault true;
    git.enable = lib.mkDefault true;
    ssh.enable = lib.mkDefault true;

    kitty.enable = lib.mkDefault true;
    bat.enable = lib.mkDefault true;
    yazi.enable = lib.mkDefault true;
    mpv.enable = lib.mkDefault true;
    python.enable = lib.mkDefault true;
    ripgrep.enable = lib.mkDefault true;
    tmux.enable = lib.mkDefault true;
    misc.enable = lib.mkDefault true;
    vim.enable = lib.mkDefault true;
    gui.enable = lib.mkDefault true;
    yt-dlp.enable = lib.mkDefault true;

    node.enable = lib.mkDefault true;
    go.enable = lib.mkDefault true;
    rust.enable = lib.mkDefault true;
    zk.enable = lib.mkDefault true;
    discord.enable = lib.mkDefault true;
    hammerspoon.enable = lib.mkDefault pkgs.stdenv.isDarwin;
    karabiner.enable = lib.mkDefault pkgs.stdenv.isDarwin;
    ghostty.enable = lib.mkDefault true;
    ai.enable = lib.mkDefault true;
  };
}
