# If I don't like what home-manager gives by default, I can install the package by
# nix & link my configs as a start? any conflics with home-manager? I don't think
# so but we will see.

{ config, pkgs, lib, ... }:

let
  # double check this (config.home.homeDirectory)?
  homeDir = builtins.getEnv "HOME";
  fzf_default_command = "${pkgs.fd}/bin/fd --hidden --follow --no-ignore-vcs";
  fzf_preview_command =
    "${pkgs.bat}/bin/bat --style=changes --wrap never --color always {} || cat {} || (${pkgs.exa}/bin/exa --tree --group-directories-first {} || ${pkgs.tree}/bin/tree -C {})";

in {
  # to access settings config.settings.<foo>
  imports = [ ./modules/settings.nix ];

  nixpkgs.config = import ./config.nix;
  xdg.configFile."nixpkgs/config.nix".source = ./config.nix;
  # nixpkgs.overlays = [(import ../pkgs/default.nix)];

  xdg = {
    enable = true;
    # configHome = "${homeDir}/.config";
    # dataHome = "${homeDir}/.local/share";
    # cacheHome = "${homeDir}/.cache";
  };

  home = {
    # Home Manager needs a bit of information about you and the
    # paths it should manage.
    username = builtins.getEnv "USER";
    homeDirectory = homeDir;
    sessionPath = [
      # "$ZDOTDIR/bin"
      "$HOME/.local/bin"
      # "$CARGO_HOME/bin"
      # "$GOBIN"
    ];

    packages = with pkgs; [
      openssl
      gawk
      coreutils
      findutils
      curl
      wget
      pinentry_mac
      gnupg
      gitAndTools.transcrypt
      (python3.withPackages
        (ps: with ps; [ pip setuptools pylint grip pynvim vobject ]))
      black
      nodejs # LTS
      nodePackages.npm
      yarn
      ncdu
      ripgrep
      pandoc
      tmuxPlugins.urlview
      # gitAndTools.diff-so-fancy
      gitAndTools.delta
      par
      w3m
      fd
      scc
      tokei
      chafa
      grc
      gitAndTools.hub
      gitAndTools.gh
      gitAndTools.tig
      pure-prompt
      universal-ctags
      nodePackages.neovim
      lbdb
      todoist
      asciinema
      exiftool
      # editorconfig-checker # do I use it?
      hyperfine
      proselint # ???
      exa
      shellcheck
      shfmt # Doesn't work with zsh, only sh & bash
      tuir
      yamllint
      hadolint # Docker linter
      lnav # System Log file navigator
      _1password # CLI
      nixfmt
      docker
      vim-vint
      nodePackages.prettier
      nodePackages.svgo
      nodePackages.bash-language-server
      nodePackages.dockerfile-language-server-nodejs
      nodePackages.ocaml-language-server
      nodePackages.typescript-language-server
      nodePackages.yaml-language-server
      nodePackages.vim-language-server
      nodePackages.vscode-css-languageserver-bin
      nodePackages.vscode-json-languageserver-bin
      rustup
      rust-analyzer-unwrapped
      # nixos.python38Packages.httpx
      #######################
      # Only on personal laptop
      #######################
      clojure
      leiningen
      joker
      # clj-kondo
      weechat
      weechatScripts.wee-slack
      youtube-dl
      keybase
      # keybase-gui # ???
      # sqlitebrowser
      #######################
      # Only on work laptop
      #######################
      # go-jira
      # maven # How to get 3.5? does it matter?
      # jdk8 # is this the right package?
      # vagrant
      #######################
      # GUIs
      #######################
      # brave # Linux only
      # firefox # Linux only?
      # obsidian # Linux only
      # zoom-us # Linux only
      # virtualbox
    ];

    file = {
      # ".config/bat".source =
      #   "${homeDir}/.dotfiles/roles/dotfiles/files/.config/bat";
      # ".config/kitty/kitty.conf".source = "${homeDir}/.dotfiles/roles/dotfiles/files/.config/kitty";
      # ".hammerspoon".source =
      #   "${homeDir}/.dotfiles/roles/hammerspoon/files/.hammerspoon";
      # ".config/lf/lfrc".source =
      #   "${homeDir}/.dotfiles/roles/dotfiles/files/.config/lf";
      # ".config/mpv".source =
      #   "${homeDir}/.dotfiles/roles/dotfiles/files/.config/mpv";
      # ".config/newsboat".source =
      #   "${homeDir}/.dotfiles/roles/dotfiles/files/.config/newsboat";
      # ".vim".source = "${homeDir}/.dotfiles/roles/vim/files/.vim";
      # ".config/zsh-hm/aliases".source = "${homeDir}/.dotfiles/roles/dotfiles/files/.config/zsh/aliases";
      # ".config/zsh-hm/bin".source = "${homeDir}/.dotfiles/roles/dotfiles/files/.config/zsh/bin";
      # ".config/zsh-hm/config".source = "${homeDir}/.dotfiles/roles/dotfiles/files/.config/zsh/config";
      # ".config/zsh-hm/functions".source = "${homeDir}/.dotfiles/roles/dotfiles/files/.config/zsh/functions";
      # ".config/zsh-hm/completions".source = "${homeDir}/.dotfiles/roles/dotfiles/files/.config/zsh/completions";
      # ".config/ripgrep/config".source =
      #   "${homeDir}/.dotfiles/roles/dotfiles/files/.config/ripgrep/config";
    };

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "20.09";
  };

  programs = {
    # Let Home Manager install and manage itself.
    home-manager.enable = true;

    # https://github.com/jared-w/nixos-configs/blob/b2f253b71d5aef4d5ad84ab58f24ec1939c07812/home.nix#L153-L205
    # zsh = {
    #   enable = true;
    #   dotDir = ".config/zsh-hm";
    #   enableCompletion = true;
    #   enableAutosuggestions = true;
    #   autocd = true;
    #   history = {
    #     size = 1000000;
    #     path = "${config.xdg.dataHome}/.zsh_history";
    #   };
    #   initExtraBeforeCompInit = "";
    #   initExtra = "";
    #   initExtra = (builtins.readFile
    #     "${homeDir}/.dotfiles/roles/dotfiles/files/.config/zsh/.zshrc");
    #   profileExtra = (builtins.readFile
    #     "${homeDir}/.dotfiles/roles/dotfiles/files/.config/zsh/.zprofile");
    #   envExtra = (builtins.readFile
    #     "${homeDir}/.dotfiles/roles/dotfiles/templates/.zshenv");
    #   plugins = [{
    #     name = "zsh-fast-syntax-highlighting";
    #     src = pkgs.zsh-fast-syntax-highlighting;
    #     file = "share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
    #   }];
    # };

    # git = {
    #   enable = true;
    # };

    # ssh = {
    #   enable = true;
    #   controlPath = "~/.ssh/master-%C";
    # };

    # tmux = {
    #   enable = true;
    # };

    # gpg = {
    #   enable = true;
    # };

    # I need HEAD because LSP, look at https://github.com/gilligan/nix-neovim-nightly/issues/2#issuecomment-649531153
    # neovim = {
    #   enable = true;
    # };

    # What is neomutt-accounts? https://github.com/nix-community/home-manager/blob/115e76ae12/modules/programs/neomutt-accounts.nix
    # neomutt = {
    #   enable = true;
    # };

    # mbsync = {
    #   enable = true;
    # };

    # What is msmtp-accounts? https://github.com/nix-community/home-manager/blob/115e76ae12a81bce5dcd19714cdeaaa8d5ca3ce8/modules/programs/msmtp-accounts.nix
    # msmtp = {
    #   enable = true;
    # };

    # password-store.enable = true;

    # kitty = {
    #   enable = true;
    # };
    #

    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "${fzf_default_command}";
      defaultOptions = [
        "--prompt='» ' --pointer='▶' --marker='✓ ' --reverse --tabstop 2 --multi --color=bg+:-1,marker:010 --bind '?:toggle-preview'"
      ];
      # CTRL+T
      fileWidgetCommand = "${fzf_default_command} --type f";
      fileWidgetOptions = [
        "--preview '(${fzf_preview_command}) 2> /dev/null' --preview-window down:60%:noborder"
      ];
      # ALT+C
      changeDirWidgetCommand = "${fzf_default_command} --type d .";
      changeDirWidgetOptions = [
        "--preview '(${pkgs.exa}/bin/exa --tree --group-directories-first {} || ${pkgs.tree}/bin/tree -C {}) 2> /dev/null'"
      ];
      # CTRL+R
      historyWidgetOptions = [
        "--preview 'echo {}' --preview-window down:3:wrap:hidden --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Press CTRL-Y to copy command into clipboard'"
      ];
    };

    vim.enable = true;

    jq.enable = true;

    # lf.enable = true;

    mpv.enable = true;

    newsboat.enable = true;

    htop.enable = true;

    direnv = {
      enable = true;
      enableZshIntegration = true;
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    # bat = {
    #   enable = true;
    #   config = {
    #     theme = "TwoDark";
    #     style = "changes,header";
    #     italic-text = "always";
    #     "map-syntax" = ".*ignore:Git Ignore";
    #     "map-syntax" = ".gitconfig.local:Git Config";
    #     # map-syntax = "**/mx*:Bourne Again Shell (bash)";
    #     # map-syntax = "**/completions/_*:Bourne Again Shell (bash)";
    #     # map-syntax = ".zsh*:Bourne Again Shell (bash)";
    #     # map-syntax = ".vimrc.local:VimL";
    #     # map-syntax = "vimrc:VimL";
    #   };
    # };
  };
}
