# This is handcrafted setup to keep the same performance characteristics I had
# before using nix or even improve it. Simple rules followed here are:
#
# - Setup things as early as possible when the shell runs
# - Inline files when possible instead of souring then
# - User specific shell files are to override or for machine specific setup

{ pkgs, lib, config, inputs, ... }:

with config.settings;

let

  cfg = config.my.shell;

  z = pkgs.callPackage ../../pkgs/z.nix { source = inputs.z; };
  lookatme =
    pkgs.callPackage ../../pkgs/lookatme.nix { source = inputs.lookatme; };

  xdg = config.home-manager.users.${username}.xdg;

  darwinPackages = with pkgs; [ openssl gawk gnused coreutils findutils ];
  nixosPackages = with pkgs; [ inputs.nixpkgs-unstable.dwm dmenu xclip ];

  personal_storage = "$HOME/Sync";
  fzf_command = "${pkgs.fd}/bin/fd --hidden --follow --no-ignore-vcs";
  fzf_default_command = "${fzf_command} --type f";
  fzf_alt_c_command = "${fzf_command} --type d .";
  # https://github.com/sharkdp/bat/issues/634#issuecomment-524525661
  fzf_preview_command =
    "COLORTERM=truecolor ${pkgs.bat}/bin/bat --style=changes --wrap never --color always {} || cat {} || (${pkgs.exa}/bin/exa --tree --group-directories-first {} || ${pkgs.tree}/bin/tree -C {})";
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

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = with pkgs;
        (if stdenv.isDarwin then darwinPackages else nixosPackages)
        ++ [ curl wget cachix htop fzf direnv nix-zsh-completions zsh z rsync ];

      users.users.${username} = {
        shell = [ pkgs.zsh ];
        packages = with pkgs; [
          # comma
          ncdu
          bat
          jq
          fd
          grc
          pure-prompt
          hyperfine
          exa
          shellcheck
          shfmt # Doesn't work with zsh, only sh & bash
          lnav # System Log file navigator
          pandoc
          scc
          tokei
          _1password # CLI
          docker
          pass
          lookatme
        ];
      };

      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".config/zsh" = {
                recursive = true;
                source = ../../../config/zsh.d/zsh;
              };
              ".terminfo" = {
                recursive = true;
                source = ../../../config/.terminfo;
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

            DOTFILES = "$HOME/.dotfiles";
            PROJECTS = "$HOME/Sites/personal/dev";
            WORK = "$HOME/Sites/work";
            PERSONAL_STORAGE = personal_storage;
            NOTES_DIR = "${personal_storage}/notes";

            ############### APPS/POGRAMS XDG SPEC CLEANUP
            RLWRAP_HOME = "${xdg.dataHome}/rlwrap";
            AWS_SHARED_CREDENTIALS_FILE = "${xdg.configHome}/aws/credentials";
            AWS_CONFIG_FILE = "${xdg.configHome}/aws/config";
            DOCKER_CONFIG = "${xdg.configHome}/docker";
            ELINKS_CONFDIR = "${xdg.configHome}/elinks";

            ############### Telemetry
            DO_NOT_TRACK = "1"; # Future proof? https://consoledonottrack.com/
            HOMEBREW_NO_ANALYTICS = "1";
            GATSBY_TELEMETRY_DISABLED = "1";
            ADBLOCK = "1";

            ############### Homebrew
            HOMEBREW_INSTALL_BADGE = "⚽️";

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
          ll = ''
            ${pkgs.exa}/bin/exa --tree --group-directories-first -I "node_modules" '';
          tree = ''${pkgs.exa}/bin/tree -I  "node_modules" '';
          c = "clear ";
          KABOOM =
            "${pkgs.yarn}/bin/yarn global upgrade --latest; brew update; brew upgrade; brew cleanup -s; brew doctor";
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

        # darwin only...
        enableCompletion = false;
        enableBashCompletion = false;

        ########################################################################
        # Instead of sourcing, I can read the files & save startiup time instead
        ########################################################################

        # zshenv
        shellInit = builtins.readFile ../../../config/zsh.d/.zshenv;

        # zprofile
        loginShellInit = lib.concatStringsSep "\n" (map builtins.readFile [
          ../../../config/zsh.d/.zprofile
          ../../../config/zsh.d/zsh/config/input.zsh
          ../../../config/zsh.d/zsh/config/environment.zsh
          ../../../config/zsh.d/zsh/config/history.zsh
          ../../../config/zsh.d/zsh/config/completion.zsh
          ../../../config/zsh.d/zsh/config/directory.zsh
          ../../../config/zsh.d/zsh/config/utility.zsh
          "${pkgs.nix-zsh-completions}/share/zsh/plugins/nix/nix-zsh-completions.plugin.zsh"

        ]) + ''

          fpath+=${pkgs.pure-prompt}/share/zsh/site-functions
          fpath+=${pkgs.nix-zsh-completions}/share/zsh/site-functions
          fpath+=${pkgs.gitAndTools.hub}/share/zsh/site-functions
          autoload -U promptinit; promptinit
          prompt pure'';

        # zshrc
        interactiveShellInit = lib.concatStringsSep "\n"
          (map builtins.readFile [
            "${pkgs.grc}/etc/grc.zsh"
            "${pkgs.fzf}/share/fzf/completion.zsh"
            "${pkgs.fzf}/share/fzf/key-bindings.zsh"
            "${z}/share/z.sh"
            ../../../config/zsh.d/.zshrc
          ]);

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
