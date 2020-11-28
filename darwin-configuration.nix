# As a first step, I will try to symlink my configs as much as possible then
# migrate the configs to Nix
#
# https://nixcloud.io/ for Nix syntax
# https://discourse.nixos.org/t/home-manager-equivalent-of-apt-upgrade/8424/3
# https://www.mathiaspolligkeit.de/dev/exploring-nix-on-macos/
# https://catgirl.ai/log/nixos-experience/
# https://kevincox.ca/2020/09/06/switching-to-desktop-nixos/
# https://www.reddit.com/r/NixOS/comments/jmom4h/new_neofetch_nixos_logo/gayfal2/
# https://ghedam.at/15978/an-introduction-to-nix-shell
# https://foo-dogsquared.github.io/blog/posts/moving-into-nixos/
# https://www.youtube.com/user/elitespartan117j27/videos?view=0&sort=da&flow=grid
# https://www.youtube.com/playlist?list=PLRGI9KQ3_HP_OFRG6R-p4iFgMSK1t5BHs
#
# Sample repos
# https://github.com/malloc47/config (very simple!)
# https://github.com/wbadart/dotfiles (simple)
# https://github.com/srid/nix-config
# https://github.com/yevhenshymotiuk/darwin-home (this is what I should aim for as a start)
# https://github.com/hlissner/dotfiles/blob/master/modules/shell/zsh.nix (this!)
# https://github.com/rummik/nixos-config
# https://github.com/teoljungberg/dotfiles/tree/master/nixpkgs (contains custom hammerspoon & vim )
# https://github.com/gmarmstrong/dotfiles
# https://github.com/jwiegley/nix-config (nice example)
# https://github.com/kclejeune/system (nice example)
#
# if isDarwin <> then <> else

{ config, pkgs, lib, ... }:

let
  homeDir = builtins.getEnv "HOME";
  fzf_default_command = "${pkgs.fd}/bin/fd --hidden --follow --no-ignore-vcs";
  fzf_preview_command =
    "${pkgs.bat}/bin/bat --style=changes --wrap never --color always {} || cat {} || (${pkgs.exa}/bin/exa --tree --group-directories-first {} || ${pkgs.tree}/bin/tree -C {})";
  comma = (import (builtins.fetchTarball
    "https://github.com/Shopify/comma/archive/master.tar.gz") { });
in {
  imports = [ <home-manager/nix-darwin> ./modules ];
  nixpkgs.config = import ./config.nix;

  # networking = {
  #   hostName = "pandoras-box";
  # };

  time.timeZone = config.settings.timezone;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    openssl
    gawk
    coreutils
    findutils
    curl
    wget
    vim
    fzf
    htop
    direnv
    zoxide
    nix-zsh-completions
    zsh
    # neovim # HEAD?
  ];

  users.users.${config.settings.username} = {
    home = "/Users/${config.settings.username}";
    description = config.settings.name;
    shell = [ pkgs.zsh ];
    packages = with pkgs; [
      comma
      jq
      nodejs # LTS
      nodePackages.npm
      (yarn.override { inherit nodejs; })
      ncdu
      pandoc
      par
      fd
      scc
      tokei
      grc
      go
      pure-prompt
      nodePackages.neovim
      todoist
      asciinema
      # editorconfig-checker # do I use it?
      hyperfine
      proselint # ???
      exa
      shellcheck
      shfmt # Doesn't work with zsh, only sh & bash
      yamllint
      hadolint # Docker linter
      lnav # System Log file navigator
      _1password # CLI
      nixfmt
      niv
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
      # nodePackages.lua-fmt
      nodePackages.vscode-css-languageserver-bin
      nodePackages.vscode-json-languageserver-bin
      reason
      rustup
      rust-analyzer-unwrapped
      #######################
      # Only on personal laptop
      #######################
      clojure
      leiningen
      joker
      kotlin
      ktlint
      # clj-kondo
      weechat # https://github.com/rummik/nixos-config/blob/55023e003095a1affb26906c56ffb883803af354/config/weechat.nix
      weechatScripts.wee-slack
      youtube-dl
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
      vscodium
      slack
    ];
  };

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    users.${config.settings.username} = {
      xdg = {
        enable = true;
        configFile."nixpkgs/config.nix".source = ./config.nix;
        # configHome = "${homeDir}/.config";
        # dataHome = "${homeDir}/.local/share";
        # cacheHome = "${homeDir}/.cache";
      };
      home = {
        stateVersion = "20.09";

        username = config.settings.username;
        homeDirectory = homeDir;
        sessionVariables = {
          TERMINFO_DIRS = "${pkgs.kitty.terminfo.outPath}/share/terminfo";
        };
        sessionPath = [
          # "$ZDOTDIR/bin"
          "$HOME/.local/bin"
          # "$CARGO_HOME/bin"
          # "$GOBIN"
        ];
        file = {
          "foo-nix.zsh".text = ''
            source ${pkgs.grc}/etc/grc.zsh
            source ${pkgs.fzf}/share/fzf/completion.zsh
            source ${pkgs.fzf}/share/fzf/key-bindings.zsh
          '';
          # ".hammerspoon".source =
          #   "${homeDir}/.dotfiles/roles/hammerspoon/files/.hammerspoon";
          # ".vim".source = "${homeDir}/.dotfiles/roles/vim/files/.vim";
          # ".config/zsh-hm/aliases".source = "${homeDir}/.dotfiles/roles/dotfiles/files/.config/zsh/aliases";
          # ".config/zsh-hm/bin".source = "${homeDir}/.dotfiles/roles/dotfiles/files/.config/zsh/bin";
          # ".config/zsh-hm/config".source = "${homeDir}/.dotfiles/roles/dotfiles/files/.config/zsh/config";
          # ".config/zsh-hm/functions".source = "${homeDir}/.dotfiles/roles/dotfiles/files/.config/zsh/functions";
          # ".config/zsh-hm/completions".source = "${homeDir}/.dotfiles/roles/dotfiles/files/.config/zsh/completions";
        };
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

        # ssh = {
        #   enable = true;
        #   controlPath = "~/.ssh/master-%C";
        # };

        # I need HEAD because LSP, look at https://github.com/gilligan/nix-neovim-nightly/issues/2#issuecomment-649531153
        # neovim = {
        #   enable = true;
        #   package = pkgs.neovim-unwrapped.overrideAttrs (attrs: {
        #     pname = "neovim-nightly";
        #     version = "master";
        #     src = pkgs.fetchFromGitHub {
        #       inherit (sources.neovim) owner repo rev sha256;
        #     };
        #   });
        # };

        # password-store.enable = true;

        # fzf = {
        #   enable = true;
        #   enableZshIntegration = true;
        #   defaultCommand = "${fzf_default_command}";
        #   defaultOptions = [
        #     "--prompt='» ' --pointer='▶' --marker='✓ ' --reverse --tabstop 2 --multi --color=bg+:-1,marker:010 --bind '?:toggle-preview'"
        #   ];
        #   # CTRL+T
        #   fileWidgetCommand = "${fzf_default_command} --type f";
        #   fileWidgetOptions = [
        #     "--preview '(${fzf_preview_command}) 2> /dev/null' --preview-window down:60%:noborder"
        #   ];
        #   # ALT+C
        #   changeDirWidgetCommand = "${fzf_default_command} --type d .";
        #   changeDirWidgetOptions = [
        #     "--preview '(${pkgs.exa}/bin/exa --tree --group-directories-first {} || ${pkgs.tree}/bin/tree -C {}) 2> /dev/null'"
        #   ];
        #   # CTRL+R
        #   historyWidgetOptions = [
        #     "--preview 'echo {}' --preview-window down:3:wrap:hidden --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Press CTRL-Y to copy command into clipboard'"
        #   ];
        # };

        # vim.enable = true;

        # jq.enable = true;

        # htop.enable = true;

        # direnv = {
        #   enable = true;
        #   enableZshIntegration = true;
        # };

        # zoxide = {
        #   enable = true;
        #   enableZshIntegration = true;
        # };
      };
    };
  };

  environment = {
    # shells = [ pkgs.zsh ];
    # systemPath = [ ];
    # shellAliases = { };
    # variables = {
    #   COLORTERM = "truecolor";
    #   # Better spell checking & auto correction prompt
    #   SPROMPT =
    #     "zsh: correct %F{red}'%R'%f to %F{blue}'%r'%f [%B%Uy%u%bes, %B%Un%u%bo, %B%Ue%u%bdit, %B%Ua%u%bbort]?";
    #   BROWSER = "open";
    #   # Set the default Less options.
    #   # Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
    #   # Remove -X and -F (exit if the content fits on one screen) to enable it.
    #   LESS = "-F -g -i -M -R -S -w -X -z-4";
    #   KEYTIMEOUT = "1";
    #   XDG_CONFIG_HOME = "$HOME/.config";
    #   XDG_CACHE_HOME = "$HOME/.cache";
    #   XDG_DATA_HOME = "$HOME/.local/share";
    #   ZDOTDIR = "$XDG_CONFIG_HOME/zsh";
    #
    #   ############### APPS/POGRAMS XDG SPEC CLEANUP
    #   GOPATH = "$XDG_DATA_HOME/go";
    #   CARGO_HOME = "$XDG_DATA_HOME/cargo";
    #   GNUPGHOME = "$XDG_CONFIG_HOME/gnupg";
    #   NOTMUCH_CONFIG = "$XDG_CONFIG_HOME/notmuch/config";
    #   BAT_CONFIG_PATH = "$XDG_CONFIG_HOME/bat/config";
    #   RIPGREP_CONFIG_PATH = "$XDG_CONFIG_HOME/ripgrep/config";
    #   WEECHAT_HOME = "$XDG_CONFIG_HOME/weechat";
    #   N_PREFIX = "$XDG_DATA_HOME/n";
    #   PYTHONSTARTUP = "$XDG_CONFIG_HOME/python/config.py";
    #   RLWRAP_HOME = "$XDG_DATA_HOME/rlwrap";
    #   AWS_SHARED_CREDENTIALS_FILE = "$XDG_CONFIG_HOME/aws/credentials";
    #   AWS_CONFIG_FILE = "$XDG_CONFIG_HOME/aws/config";
    #   DOCKER_CONFIG = "$XDG_CONFIG_HOME/docker";
    #   ELINKS_CONFDIR = "$XDG_CONFIG_HOME/elinks";
    #   "_JAVA_OPTIONS" = ''-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME/java"'';
    #   RUSTUP_HOME = "$XDG_DATA_HOME/rustup";
    #
    #   # export MAILCAP="$XDG_CONFIG_HOME/mailcap"; # elinks, w3m
    #   # export MAILCAPS="$MAILCAP";   # Mutt, pine
    #
    #   ############### Telemetry
    #   DO_NOT_TRACK = "1"; # Future proof? https://consoledonottrack.com/
    #   HOMEBREW_NO_ANALYTICS = "1";
    #   GATSBY_TELEMETRY_DISABLED = "1";
    #   ADBLOCK = "1";
    #
    #   ############### Go
    #   GOBIN = "$GOPATH/bin";
    #
    #   ############### Homebrew
    #   HOMEBREW_INSTALL_BADGE = "⚽️";
    #
    #   ############### Weechat
    #   WEECHAT_PASSPHRASE = ''
    #     `security find-generic-password -g -a weechat 2>&1| perl -e 'if (<STDIN> =~ m/password: \"(.*)\"$/ ) { print $1; }'`'';
    #
    #   ############### Direnv
    #   NODE_VERSIONS = "$N_PREFIX/n/versions/node";
    #   NODE_VERSION_PREFIX = "";
    #
    #   ############### Pure
    #   PURE_GIT_UP_ARROW = "🠥";
    #   PURE_GIT_DOWN_ARROW = "🠧";
    #   PURE_GIT_BRANCH = "  ";
    #
    #   ############### Autosuggest
    #   ZSH_AUTOSUGGEST_USE_ASYNC = "true";
    #
    #   GITHUB_USER = config.settings.github_username;
    # };
  };

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  # services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # there are more options to check later...
  programs.zsh = {
    enable = true;
    enableBashCompletion = true;
    enableCompletion = true;
    enableFzfCompletion = true;
    enableFzfHistory = true;
    # Prevent NixOS from clobbering prompts
    # See: https://github.com/NixOS/nixpkgs/pull/38535
    promptInit = lib.mkDefault "";
    variables = {
      RPS1 = ""; # Disable the right side prompt that "walters" theme introduces
    };
  };

  # Check programs.ssh.*

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
  # nix.maxJobs = 4;
  # nix.buildCores = 4;
}
