_: let
  shell = import ./shared/user-shell.nix;
  mail = import ./shared/mail.nix;
  gui = import ./shared/gui.nix;
  ssh = import ./shared/ssh.nix;
  git = import ./shared/git.nix;
  bat = import ./shared/bat.nix;
  ripgrep = import ./shared/ripgrep.nix;
  yazi = import ./shared/yazi.nix;
  tmux = import ./shared/tmux.nix;
  vim = import ./shared/vim.nix;
  ai = import ./shared/ai.nix;
  ghostty = import ./shared/ghostty.nix;
  zk = import ./shared/zk.nix;
  gpg = import ./shared/gpg.nix;
  kitty = import ./shared/kitty.nix;
  mpv = import ./shared/mpv.nix;
  discord = import ./shared/discord.nix;
  misc = import ./shared/misc.nix;
  python = import ./shared/python.nix;
  jujutsu = import ./shared/jujutsu.nix;
  ytDlp = import ./shared/yt-dlp.nix;
in {
  flake.modules = {
    generic = {
      base = import ./base/default.nix;
      gpg = gpg.generic;
      ssh = ssh.generic;
      git = git.generic;
      bat = bat.generic;
      yazi = yazi.generic;
      ripgrep = ripgrep.generic;
      tmux = tmux.generic;
      "yt-dlp" = ytDlp.generic;
      misc = misc.generic;
      node = import ./shared/node.nix;
      go = import ./shared/go.nix;
      rust = import ./shared/rust.nix;
      python = python.generic;
      zk = zk.generic;
      ai = ai.generic;
      agenix = import ./shared/agenix.nix;
      jujutsu = jujutsu.generic;
    };

    darwin = {
      defaults = import ./darwin/default.nix;
      hammerspoon = import ./darwin/hammerspoon.nix;
      karabiner = import ./darwin/karabiner.nix;
      shell = shell.darwin;
      mail = mail.darwin;
      gui = gui.darwin;
      vim = vim.darwin;
      ghostty = ghostty.darwin;
      kitty = kitty.darwin;
      mpv = mpv.darwin;
      discord = discord.darwin;
    };

    nixos = {
      shell = shell.nixos;
      mail = mail.nixos;
      gui = gui.nixos;
      vim = vim.nixos;
      ghostty = ghostty.nixos;
      mpv = mpv.nixos;
      kitty = kitty.nixos;
      discord = discord.nixos;
    };

    homeManager = {
      shell = shell.homeManager;
      ssh = ssh.homeManager;
      git = git.homeManager;
      bat = bat.homeManager;
      ripgrep = ripgrep.homeManager;
      yazi = yazi.homeManager;
      tmux = tmux.homeManager;
      vim = vim.homeManager;
      ai = ai.homeManager;
      gui = gui.homeManager;
      ghostty = ghostty.homeManager;
      mail = mail.homeManager;
      gpg = gpg.homeManager;
      zk = zk.homeManager;
      kitty = kitty.homeManager;
      mpv = mpv.homeManager;
      misc = misc.homeManager;
      python = python.homeManager;
      jujutsu = jujutsu.homeManager;
      "yt-dlp" = ytDlp.homeManager;
    };
  };
}
