# This is handcrafted setup to keep the same performance characteristics I had
# before using nix or even improve it. Simple rules followed here are:
#
# - Setup things as early as possible when the shell runs
# - Inline files when possible instead of souring then
# - User specific shell files are to override or for machine specific setup

{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.shell;

  z = pkgs.callPackage ../../apps/z { };

  xdg = config.home-manager.users.${username}.xdg;
  go_path = "${xdg.dataHome}/go";
  personal_storage = "$HOME/Sync";
  fzf_command = "${pkgs.fd}/bin/fd --hidden --follow --no-ignore-vcs";
  fzf_default_command = "${fzf_command} --type f";
  fzf_alt_c_command = "${fzf_command} --type d .";
  # https://github.com/sharkdp/bat/issues/634#issuecomment-524525661
  fzf_preview_command =
    "COLORTERM=truecolor ${pkgs.bat}/bin/bat --style=changes --wrap never --color always {} || cat {} || (${pkgs.exa}/bin/exa --tree --group-directories-first {} || ${pkgs.tree}/bin/tree -C {})";
  comma = (import (builtins.fetchTarball
    "https://github.com/Shopify/comma/archive/master.tar.gz") { });

in {
  options = with lib; {
    my.shell = {
      enable = mkEnableOption ''
        Whether to enable shell module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {

      environment.systemPackages = with pkgs; [
        fzf
        direnv
        nix-zsh-completions
        zsh
        z
      ];

      users.users.${username} = {
        shell = [ pkgs.zsh ];
        packages = with pkgs; [
          comma
          ncdu
          bat
          jq
          fd
          grc
          go
          pure-prompt
          hyperfine
          exa
          shellcheck
          shfmt # Doesn't work with zsh, only sh & bash
          lnav # System Log file navigator
        ];
      };

      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".config/zsh" = {
                recursive = true;
                source = ./zsh;
              };
            };
          };
        };
      };

      environment = {
        shells = [ pkgs.bashInteractive pkgs.zsh ];

        variables =
          # ====================================================
          # This list gets set in alphabetical order.
          # So care needs to be taken if two env vars depend on each other
          # ====================================================
          {
            TERMINFO_DIRS = "${pkgs.kitty.terminfo.outPath}/share/terminfo";
            COLORTERM = "truecolor";
            BROWSER = if pkgs.stdenv.isDarwin then "open" else "xdg-open";
            # Better spell checking & auto correction prompt
            SPROMPT =
              "zsh: correct %F{red}'%R'%f to %F{blue}'%r'%f [%B%Uy%u%bes, %B%Un%u%bo, %B%Ue%u%bdit, %B%Ua%u%bbort]?";
            # Set the default Less options.
            # Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
            # Remove -X and -F (exit if the content fits on one screen) to enable it.
            LESS = "-F -g -i -M -R -S -w -X -z-4";
            KEYTIMEOUT = "1";
            XDG_CONFIG_HOME = xdg.configHome;
            XDG_CACHE_HOME = xdg.cacheHome;
            XDG_DATA_HOME = xdg.dataHome;
            ZDOTDIR = "${xdg.configHome}/zsh";

            EDITOR = "${pkgs.neovim-unwrapped}/bin/nvim";
            VISUAL = "$EDITOR";
            GIT_EDITOR = "$EDITOR";
            MANPAGER = "${pkgs.neovim-unwrapped}/bin/nvim +Man!";

            MAILDIR =
              "$HOME/.mail"; # will be picked up by .notmuch-config for database.path
            DOTFILES = "$HOME/.dotfiles";
            PROJECTS = "$HOME/Sites/personal/dev";
            WORK = "$HOME/Sites/work";
            PERSONAL_STORAGE = personal_storage;
            NOTES_DIR = "${personal_storage}/notes";

            ############### APPS/POGRAMS XDG SPEC CLEANUP
            GOPATH = go_path;
            CARGO_HOME = "${xdg.dataHome}/cargo";
            GNUPGHOME = "${xdg.configHome}/gnupg";
            NOTMUCH_CONFIG = "${xdg.configHome}/notmuch/config";
            BAT_CONFIG_PATH = "${xdg.configHome}/bat/config";
            RIPGREP_CONFIG_PATH = "${xdg.configHome}/ripgrep/config";
            WEECHAT_HOME = "${xdg.configHome}/weechat";
            PYTHONSTARTUP = "${xdg.configHome}/python/config.py";
            RLWRAP_HOME = "${xdg.dataHome}/rlwrap";
            AWS_SHARED_CREDENTIALS_FILE = "${xdg.configHome}/aws/credentials";
            AWS_CONFIG_FILE = "${xdg.configHome}/aws/config";
            DOCKER_CONFIG = "${xdg.configHome}/docker";
            ELINKS_CONFDIR = "${xdg.configHome}/elinks";
            "_JAVA_OPTIONS" =
              ''-Djava.util.prefs.userRoot="${xdg.configHome}/java"'';
            RUSTUP_HOME = "${xdg.dataHome}/rustup";

            # export MAILCAP="${xdg.configHome}/mailcap"; # elinks, w3m
            # export MAILCAPS="$MAILCAP";   # Mutt, pine

            ############### Telemetry
            DO_NOT_TRACK = "1"; # Future proof? https://consoledonottrack.com/
            HOMEBREW_NO_ANALYTICS = "1";
            GATSBY_TELEMETRY_DISABLED = "1";
            ADBLOCK = "1";

            ############### Go
            GOBIN = "${go_path}/bin";

            ############### Homebrew
            HOMEBREW_INSTALL_BADGE = "⚽️";

            ############### Weechat
            WEECHAT_PASSPHRASE = ''
              `security find-generic-password -g -a weechat 2>&1| perl -e 'if (<STDIN> =~ m/password: \"(.*)\"$/ ) { print $1; }'`'';

            ############### Direnv
            N_PREFIX = "${xdg.dataHome}/n";
            NODE_VERSIONS = "${xdg.dataHome}/n/n/versions/node";
            NODE_VERSION_PREFIX = "";

            ############### Pure
            PURE_GIT_UP_ARROW = "🠥";
            PURE_GIT_DOWN_ARROW = "🠧";
            PURE_GIT_BRANCH = "  ";

            ############### Autosuggest
            ZSH_AUTOSUGGEST_USE_ASYNC = "true";

            GITHUB_USER = config.settings.github_username;

            VIM_FZF_LOG = ''
              "$(${pkgs.git}/bin/git config --get alias.l 2>/dev/null | awk '{$1=""; print $0;}' | tr -d '\r')"'';

            FZF_DEFAULT_COMMAND = fzf_default_command;
            FZF_PREVIEW_COMMAND = fzf_preview_command;
            FZF_CTRL_T_COMMAND = fzf_command;
            FZF_ALT_C_COMMAND = fzf_alt_c_command;
            FZF_DEFAULT_OPTS =
              "--prompt='» ' --pointer='▶' --marker='✓ ' --reverse --tabstop 2 --multi --color=bg+:-1,marker:010 --bind '?:toggle-preview'";
            FZF_CTRL_T_OPTS =
              "--preview '(${fzf_preview_command}) 2> /dev/null' --preview-window down:60%:noborder";
            FZF_CTRL_R_OPTS =
              "--preview 'echo {}' --preview-window down:3:wrap:hidden --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Press CTRL-Y to copy command into clipboard'";
            FZF_ALT_C_OPTS =
              "--preview '(${pkgs.exa}/bin/exa --tree --group-directories-first {} || ${pkgs.tree}/bin/tree -C {}) 2> /dev/null'";
          };

        shellAliases = {
          cp = "cp -iv";
          ln = "ln -iv";
          mv = "mv -iv";
          rm = "rm -i";
          mkdir = "mkdir -p";
          e = "$EDITOR";
          type = "type -a";
          which = "which -a";
          history = "fc -il 1";
          top = "${pkgs.htop}/bin/htop";
          ls = "${pkgs.exa}/bin/exa ";
          ll = "${pkgs.exa}/bin/exa --tree --group-directories-first ";
          tree = "${pkgs.exa}/bin/exa --tree --group-directories-first ";
          c = "clear ";
          KABOOM =
            "yarn global upgrade --latest; brew update; brew upgrade; brew cleanup -s; brew doctor";
          emptytrash = "sudo rm -rfv /Volumes/*/.Trashes;sudo rm -rfv ~/.Trash";
          fs = "stat -f '%z bytes'";
          flushdns = "sudo killall -HUP mDNSResponder";
          play = "mx ϟ";
          cask = "brew cask";
          jobs = "jobs -l";
          # https://twitter.com/wincent/status/1333036294440620036
          sudo = "sudo ";
          cat = "${pkgs.bat}/bin/bat ";
          server = "${pkgs.python3}/bin/python3 -m http.server 80";
          fd = "${pkgs.fd}/bin/fd --hidden ";
          y = "${pkgs.yarn}/bin/yarn";
        };
      };

      programs.zsh = {
        enable = true;
        enableCompletion = false;
        enableBashCompletion = false;

        ########################################################################
        # Instead of sourcing, I can read the files & save startiup time instead
        ########################################################################

        # zshenv
        shellInit = builtins.readFile ./.zshenv;

        # zprofile
        loginShellInit = lib.concatStringsSep "\n" (map builtins.readFile [
          ./.zprofile
          ./zsh/config/input.zsh
          ./zsh/config/environment.zsh
          ./zsh/config/history.zsh
          ./zsh/config/completion.zsh
          ./zsh/config/directory.zsh
          ./zsh/config/utility.zsh
          "${pkgs.nix-zsh-completions}/share/zsh/plugins/nix/nix-zsh-completions.plugin.zsh"

        ]) + ''

          fpath+=${pkgs.pure-prompt}/share/zsh/site-functions
          fpath+=${pkgs.nix-zsh-completions}/share/zsh/site-functions
          autoload -U promptinit; promptinit
          prompt pure'';

        # zshrc
        interactiveShellInit = lib.concatStringsSep "\n"
          (map builtins.readFile [
            "${pkgs.grc}/etc/grc.zsh"
            "${pkgs.fzf}/share/fzf/completion.zsh"
            "${pkgs.fzf}/share/fzf/key-bindings.zsh"
            "${z}/share/z.sh"
            # "${pkgs.direnv}/dhook/direnv-hook.zsh"
            ./.zshrc
          ]) + ''

            eval "$(direnv hook zsh)"
          '';

        # Prevent NixOS from clobbering prompts
        # See: https://github.com/NixOS/nixpkgs/pull/38535
        promptInit = lib.mkDefault "";
        variables = {
          RPS1 =
            ""; # Disable the right side prompt that "walters" theme introduces
        };
      };
    };
}
