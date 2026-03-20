_: {
  imports = [
    ./shared/user-shell.nix
    ./shared/mail.nix
    ./shared/gui.nix
    ./shared/ssh.nix
    ./shared/git.nix
    ./shared/bat.nix
    ./shared/ripgrep.nix
    ./shared/yazi.nix
    ./shared/tmux.nix
    ./shared/vim.nix
    ./shared/ai.nix
    ./shared/ghostty.nix
    ./shared/zk.nix
    ./shared/gpg.nix
    ./shared/kitty.nix
    ./shared/mpv.nix
    ./shared/discord.nix
    ./shared/misc.nix
    ./shared/python.nix
    ./shared/jujutsu.nix
    ./shared/yt-dlp.nix
  ];

  flake.modules = {
    generic = {
      base = import ./base/default.nix;
      node = import ./shared/node.nix;
      go = import ./shared/go.nix;
      rust = import ./shared/rust.nix;
      agenix = import ./shared/agenix.nix;
    };

    darwin = {
      defaults = import ./darwin/default.nix;
      hammerspoon = import ./darwin/hammerspoon.nix;
      karabiner = import ./darwin/karabiner.nix;
    };
  };
}
