# This is handcrafted setup to keep the same performance characteristics I had
# before using nix or even improve it. Simple rules followed here are:
#
# - Setup things as early as possible when the shell runs
# - Inline files when possible instead of souring then
# - User specific shell files are to override or for machine specific setup
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.my.modules.shell;
  inherit (config.my.user) home;
  inherit (config.my) hm devFolder hostConfigHome company;
  inherit (pkgs.stdenv) isDarwin isLinux;

  local_zshrc = "${hostConfigHome}/zshrc";
in {
  options = with lib; {
    my.modules.shell = {
      enable = mkEnableOption ''
        Whether to enable shell module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [
      (mkIf isDarwin {
        launchd.user.agents."maxfiles" = {
          serviceConfig = {
            ProgramArguments = [
              "launchctl"
              "limit"
              "maxfiles"
              "65536"
              "65536"
            ];
            RunAtLoad = true;
            ServiceIPC = false;
          };
        };
        environment = {
          shellAliases = {
            emptytrash = "sudo rm -rfv /Volumes/*/.Trashes;sudo rm -rfv ~/.Trash";
            flushdns = "sudo killall -HUP mDNSResponder";
          };

          variables = {
            LANG = "en_US.UTF-8";
            LC_TIME = "en_GB.UTF-8";
            NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
            # NOTE: Darwin doesn't set them by default, unlike NixOS. So we have to set them.
            # This is just using what's inside home-manager. Defaults are here
            # https://github.com/nix-community/home-manager/blob/a4b0a3faa4055521f2a20cfafe26eb85e6954751/modules/misc/xdg.nix#L14-L17
            XDG_CACHE_HOME = hm.cacheHome;
            XDG_CONFIG_HOME = hm.configHome;
            XDG_DATA_HOME = hm.dataHome;
            XDG_STATE_HOME = hm.stateHome;
          };

          systemPackages = with pkgs;
            [
              openssl
              gawk
              gnused
              coreutils
              findutils
              (pkgs.writeScriptBin "nixsw"
                /*
                bash
                */
                ''
                  pushd $DOTFILES/
                  sudo darwin-rebuild switch --flake .
                  popd
                '')
            ]
            ++
            # Packages broken on Intel
            (
              lib.optional (stdenv.hostPlatform.system == "aarch64-darwin")
              lnav # System Log file navigator
            );
        };
      })

      (mkIf isLinux {
        environment = {
          systemPackages = with pkgs; [dwm dmenu xclip];

          shellAliases = {
            chmod = "chmod --preserve-root -v";
            chown = "chown --preserve-root -v";
          };
        };
      })

      {
        environment = {
          shells = [pkgs.bashInteractive pkgs.zsh];
          shellAliases = {
            cp = "cp -iv";
            ln = "ln -iv";
            mv = "mv -iv";
            rm = "rm -i";
            mkdir = "mkdir -p";
            sudo = "sudo ";
            type = "type -a";
            c = "clear";
            df = "df -kh";
            du = "du -kh";
            fd = "fd --hidden";
            history-stat = ''fc -l 1 | awk '{print \$2}' | sort | uniq -c | sort -n -r | head'';
            history = "fc -il 1";
            jobs = "jobs -l";
            play = "mx ϟ";
            y = "yarn";
            p = "pnpm";
            b = "bun";
            top = "htop";
            l = "eza --all --long --color-scale=all --group-directories-first --sort=type --hyperlink --icons=auto --octal-permissions";
            ll = "eza --icons --tree --group-directories-first --all --level=2";
            lt = "eza --tree --group-directories-first --all";
            cat = "bat";
            grep = "grep --color=auto";
            get = "wget --continue --progress=bar --timestamping";
          };

          variables =
            # ====================================================
            # This list gets set in alphabetical order.
            # So care needs to be taken if two env vars depend on each other
            #
            # Allowed variables is only $HOME
            # Everything else has to be explicit
            # ====================================================
            rec {
              ADBLOCK = "true";
              AWS_CONFIG_FILE = "${hm.configHome}/aws/config";
              AWS_SHARED_CREDENTIALS_FILE = "${hm.configHome}/aws/credentials";
              BROWSER =
                if pkgs.stdenv.isDarwin
                then "open"
                else "xdg-open";
              CDPATH = ".:~:~/${devFolder}";
              COLORTERM = "truecolor";
              COMPANY = company;
              DOCKER_CONFIG = "${hm.configHome}/docker";
              DOTFILES = "$HOME/.dotfiles";
              DO_NOT_TRACK = "1"; # Future proof? https://consoledonottrack.com/
              ELINKS_CONFDIR = "${hm.configHome}/elinks";
              EZA_COLORS = "ur=35;nnn:gr=35;nnn:tr=35;nnn:uw=34;nnn:gw=34;nnn:tw=34;nnn:ux=36;nnn:ue=36;nnn:gx=36;nnn:tx=36;nnn:uu=36;nnn:uu=38;5;235:da=38;5;238";
              EZA_ICON_SPACING = "2";
              FZF_ALT_C_COMMAND = "${FZF_CTRL_T_COMMAND} --type d .";
              FZF_ALT_C_OPTS = "--preview='(${FZF_PREVIEW_COMMAND}) 2> /dev/null' --walker-skip .git,node_modules";
              FZF_CTRL_R_OPTS = "--preview 'echo {}' --preview-window down:3:wrap:hidden --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Press CTRL-Y to copy command into clipboard'";
              FZF_CTRL_T_COMMAND = "${lib.getExe pkgs.fd} --strip-cwd-prefix --hidden --follow --no-ignore-vcs";
              FZF_CTRL_T_OPTS = "--preview-window right:border-left:60%:hidden --preview='(${FZF_PREVIEW_COMMAND})' --walker-skip .git,node_modules";
              FZF_DEFAULT_COMMAND = "${FZF_CTRL_T_COMMAND} --type f";
              FZF_DEFAULT_OPTS = "--border thinblock --prompt='» ' --pointer='▶' --marker='✓ ' --reverse --tabstop 2 --multi --color=bg+:-1,marker:010 --gutter ' ' --separator='' --bind '?:toggle-preview' --info inline-right";
              # https://github.com/sharkdp/bat/issues/634#issuecomment-524525661
              FZF_PREVIEW_COMMAND = "COLORTERM=truecolor previewer {}";
              GATSBY_TELEMETRY_DISABLED = "1";
              GITHUB_USER = config.my.github_username;
              # https://github.blog/2022-04-12-git-security-vulnerability-announced/
              GIT_CEILING_DIRECTORIES = builtins.dirOf home;
              HOMEBREW_INSTALL_BADGE = "⚽️";
              HOMEBREW_NO_ANALYTICS = "1";
              HOST_CONFIGS = "${hostConfigHome}";
              KEYTIMEOUT = "1";
              KITTY_LISTEN_ON = "unix:/tmp/kitty";
              # Set the default Less options.
              # Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
              # Remove -X and -F (exit if the content fits on one screen) to enable it.
              LESS = "-F -g -i -M -R -S -w -X -z-4";
              # LESSOPEN = "|${lib.getExe pkgs.lesspipe}.sh %s";
              LS_COLORS = "$(${lib.getExe pkgs.vivid} generate ~/.config/vivid/theme.yml)";
              NEXT_TELEMETRY_DISABLED = "1";
              NOTES_DIR = "${PERSONAL_STORAGE}/notes";
              PAGER = "less";
              PERSONAL_STORAGE = "$HOME/Sync";
              PROJECTS = "$HOME/${devFolder}/personal/dev";
              RLWRAP_HOME = "${hm.dataHome}/rlwrap";
              # Better spell checking & auto correction prompt
              SHELL = "${pkgs.zsh}/bin/zsh";
              SPROMPT = "zsh: correct %F{red}'%R'%f to %F{blue}'%r'%f [%B%Uy%u%bes, %B%Un%u%bo, %B%Ue%u%bdit, %B%Ua%u%bbort]?";
              VIM_FZF_LOG = ''"$(${lib.getExe pkgs.git} config --get alias.l 2>/dev/null | awk '{$1=""; print $0;}' | tr -d '\r')"'';
              ZCOMPDUMP_PATH = "${ZDOTDIR}/.zcompdump";
              ZDOTDIR = "${hm.configHome}/zsh";
              # I use a single zk notes dir, so set it and forget
              ZK_NOTEBOOK_DIR = "${NOTES_DIR}";
              WORK = "$HOME/${devFolder}/work";
              _ZO_DATA_DIR = "${hm.configHome}/zoxide";
            };

          systemPackages = with pkgs; [
            ast-grep
            cachix
            curl
            direnv
            fzf
            grc
            htop
            jq
            pass
            nix-direnv
            pandoc
            ripgrep
            rsync
            wget
            zoxide
            mise
            devcontainer
            pure-prompt
            (pkgs.writeScriptBin "nixup"
              /*
              bash
              */
              ''
                pushd $DOTFILES/
                nix flake update
                popd
              '')
          ];
        };

        my = {
          user = {
            shell = pkgs.zsh;
            packages = with pkgs; [
              _1password-cli
              atuin
              bat
              # buku
              eza
              fd
              ffmpeg
              glow
              hcron
              shellcheck
              shfmt # Doesn't work with zsh, only sh & bash
              vivid
              zsh-completions
              zsh-history-substring-search
              (imagemagick.override {
                ghostscriptSupport = true;
              })
              ghostscript # to preview PDFs as images
              poppler-utils # to preview PDFs as text
              newsraft
              bun
              circumflex # HN CLI reader
              repomix
            ];
          };

          hm.file = {
            ".config/zsh" = {
              recursive = true;
              source = ../../../config/zsh.d/zsh;
            };
            # $ZDOTDIR must include a `.zshrc` file
            ".config/zsh/.zshrc" = {
              recursive = true;
              text = "";
            };
            ".config/mods" = {
              recursive = true;
              source = ../../../config/mods;
            };
            ".terminfo" = {
              recursive = true;
              source = ../../../config/.terminfo;
            };
            ".config/direnv/direnvrc" = {
              text =
                lib.concatStringsSep "\n"
                [
                  "source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc"
                  (builtins.readFile ../../../config/direnv/direnvrc)
                ];
            };
            # This is an emptyfile that's needed to get rid of the "Last login..." message when opening a new shell
            ".hushlogin" = {
              text = "";
            };
            ".config/vivid" = {
              recursive = true;
              source = ../../../config/vivid;
            };
            ".config/atuin" = {
              source = ../../../config/atuin;
            };
            ".config/repomix" = {
              source = ../../../config/repomix;
            };
          };
        };

        system.activationScripts.postActivation.text = ''
          echo ":: -> Running shell activationScript..."
          if [ ! -e "${local_zshrc}" ]; then
          	mkdir -p "$(dirname "${local_zshrc}")"

            cat > ${local_zshrc}<< EOF
          	# vim:ft=zsh:
          	[[ -z "$GITHUB_TOKEN" ]] && echo "⚠ GITHUB_TOKEN is not set"
          	[[ -z "$HOMEBREW_GITHUB_API_TOKEN" ]] && echo "⚠ HOMEBREW_GITHUB_API_TOKEN is not set"
          	[[ -z "$NPM_REGISTRY_TOKEN" ]] && echo "⚠ NPM_REGISTRY_TOKEN is not set"
          	[[ -z "$GITHUB_REGISTRY_TOKEN" ]] && echo "⚠ GITHUB_REGISTRY_TOKEN is not set"
          	[[ -z "$GH_PASS" ]] && echo "⚠ GH_PASS is not set"
          EOF
          fi

          if dscl . -read /Users/${config.my.username} UserShell | grep -qv "/run/current-system/sw/bin/zsh"; then
            echo ":: -> Changing Shell..."
            sudo dscl . -create /Users/${config.my.username} UserShell /run/current-system/sw/bin/zsh
          fi
        '';

        programs.zsh = {
          enable = true;
          # This will also add nix-zsh-completions to the systemPackages.
          # https://github.com/LnL7/nix-darwin/blob/58b905ea87674592aa84c37873e6c07bc3807aba/modules/programs/zsh/default.nix#L117
          enableCompletion = true;
          # Default is the value of enableCompletion but I want to handle it myself
          # https://github.com/LnL7/nix-darwin/blob/58b905ea87674592aa84c37873e6c07bc3807aba/modules/programs/zsh/default.nix#L76
          enableGlobalCompInit = false;
          enableBashCompletion = false;

          enableFastSyntaxHighlighting = true;

          enableAutosuggestions = true;

          histSize = 10000000;
          histFile = "${"$"}{ZDOTDIR}/.zsh_history";

          ########################################################################
          # Instead of sourcing, I can read the files & save startiup time instead
          ########################################################################

          # zshenv
          shellInit =
            lib.concatStringsSep "\n"
            [
              /*
              zsh
              */
              ''
                export LESS_TERMCAP_mb=$'\E[1;31m'   # Begins blinking.
                export LESS_TERMCAP_md=$'\E[1;31m'   # Begins bold.
                export LESS_TERMCAP_me=$'\E[0m'      # Ends mode.
                export LESS_TERMCAP_se=$'\E[0m'      # Ends standout-mode.
                export LESS_TERMCAP_so=$'\E[7m'      # Begins standout-mode.
                export LESS_TERMCAP_ue=$'\E[0m'      # Ends underline.
                export LESS_TERMCAP_us=$'\E[1;32m'   # Begins underline.
                # Remove path separator from WORDCHARS.
                WORDCHARS=${"$"}{WORDCHARS//[\/]}


                # Ensure path arrays do not contain duplicates.
                typeset -gU cdpath fpath mailpath manpath path

                ##############################################################
                # PATH.
                # (N-/): do not register if the directory does not exists
                # (Nn[-1]-/)
                #
                #  N   : NULL_GLOB option (ignore path if the path does not match the glob)
                #  n   : Sort the output
                #  [-1]: Select the last item in the array
                #  -   : follow the symbol links
                #  /   : ignore files
                #  t   : tail of the path
                ##############################################################

                path=(
                	${"$"}{ZDOTDIR}/bin
                	${"$"}{HOME}/.local/bin(N-/)
                	${"$"}path
                	# For M1/2 machines
                	/opt/homebrew/bin(N-/)
                	/usr/local/{bin,sbin}
                )

                fpath+=(${pkgs.zsh-completions}/share/zsh/site-functions)
                fpath+=(${pkgs.pure-prompt}/share/zsh/site-functions)
              ''
            ];

          # zshrc
          interactiveShellInit =
            lib.concatStringsSep "\n"
            ([
                /*
                zsh
                */
                ''

                  ##############################################################
                  # Profiling.
                  ##############################################################

                  # Start profiling (uncomment when necessary)
                  #
                  # See: https://stackoverflow.com/a/4351664/2103996

                  # Per-command profiling:

                  # zmodload zsh/datetime
                  # setopt promptsubst
                  # PS4='+$EPOCHREALTIME %N:%i> '
                  # # More human readable
                  # PS4=$'%D{%S.%.} %N:%i> '
                  # exec 3>&2 2> startlog.$$
                  # setopt xtrace prompt_subst

                  # Per-function profiling:

                  # zmodload zsh/zprof

                   PROMPT_SYMBOLS=("λ" "ϟ" "▲" "∴" "→" "»" "৸")
                   # Arrays in zsh starts from 1
                   export PURE_PROMPT_SYMBOL=${"$"}{PROMPT_SYMBOLS[${"$"}RANDOM % ${"$"}{#PROMPT_SYMBOLS[@]} + 1]}
                   export PURE_SUSPENDED_JOBS_SYMBOL="%F{008}%(1j.[%j].)"

                   zstyle :prompt:pure:git:branch color blue
                   zstyle :prompt:pure:git:arrow color blue
                   zstyle :prompt:pure:git:stash color blue
                   zstyle :prompt:pure:git:dirty color red
                   zstyle :prompt:pure:git:action color 003
                   zstyle :prompt:pure:prompt:success color 003
                   zstyle :prompt:pure:path color 242
                   zstyle :prompt:pure:git:stash show yes
                   zstyle :prompt:pure:environment:nix-shell show no
                   zstyle :prompt:pure:git:fetch only_upstream yes

                  # This is not set by nix-darwin so I have to set it myself https://github.com/nix-darwin/nix-darwin/blob/e95de00a471d07435e0527ff4db092c84998698e/modules/programs/zsh/default.nix#L204-L208
                  export HISTFILESIZE=${"$"}HISTSIZE

                  autoload -U select-word-style
                  # only alphanumeric chars are considered WORDCHARS
                  select-word-style bash

                  # Rebuild zcompdump when fpath completion count changes (e.g. new package installed)
                  autoload -Uz compinit
                  if [[ -f "${"$"}{ZCOMPDUMP_PATH}" ]]; then
                    local dump_header
                    read -r dump_header < "${"$"}{ZCOMPDUMP_PATH}"
                    local dump_count=${"$"}{${"$"}{dump_header#\#files: }%%[[:space:]]*}
                    local -a comp_files=( ${"$"}{^fpath}/*(-.,@N) )
                    local current_count=${"$"}{#comp_files}
                    if [[ "${"$"}dump_count" == "${"$"}current_count" ]]; then
                      compinit -C -d "${"$"}{ZCOMPDUMP_PATH}"
                    else
                      compinit -d "${"$"}{ZCOMPDUMP_PATH}"
                    fi
                  else
                    compinit -d "${"$"}{ZCOMPDUMP_PATH}"
                  fi

                  # Compile zcompdump for faster loading
                  if [[ ! -f "${"$"}{ZCOMPDUMP_PATH}".zwc || "${"$"}{ZCOMPDUMP_PATH}" -nt "${"$"}{ZCOMPDUMP_PATH}".zwc ]]; then
                    zcompile "${"$"}ZCOMPDUMP_PATH"
                  fi

                  # Autocomplete the g script
                  if (( ${"$"}+commands[hub] )); then
                    compdef g=hub
                  elif (( ${"$"}+commands[git] )); then
                    compdef g=git
                  fi

                  # Note that this will only ensure unique history if we supply a prefix
                  # before hitting "up" (ie. we perform a "search"). HIST_FIND_NO_DUPS
                  # won't prevent dupes from appearing when just hitting "up" without a
                  # prefix (ie. that's "zle up-line-or-history" and not classified as a
                  # "search"). So, we have HIST_IGNORE_DUPS to make life bearable for that
                  # case.
                  #
                  # https://superuser.com/a/1494647/322531
                  HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

                  # For speed:
                  # https://github.com/zsh-users/zsh-autosuggestions#disabling-automatic-widget-re-binding
                  ZSH_AUTOSUGGEST_MANUAL_REBIND=1
                  ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd history completion)
                ''
              ]
              ++ map builtins.readFile [
                ../../../config/zsh.d/zsh/config/options.zsh
                ../../../config/zsh.d/zsh/config/input.zsh
                ../../../config/zsh.d/zsh/config/completion.zsh
                "${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh"
              ]
              ++ [
                /*
                zsh
                */
                ''
                  # bind UP and DOWN keys
                  bindkey '^[[A' history-substring-search-up
                  bindkey '^[[B' history-substring-search-down
                  # In vi mode
                  bindkey -M vicmd 'k' history-substring-search-up
                  bindkey -M vicmd 'j' history-substring-search-down

                  # Very slow chormas https://github.com/zdharma-continuum/fast-syntax-highlighting/issues/27
                  unset "FAST_HIGHLIGHT[chroma-whatis]" "FAST_HIGHLIGHT[chroma-man]"

                  # This breaks p10k instant prompt if I inline the file, but sourcing works fine
                  source "${pkgs.grc}/etc/grc.zsh"

                  source <(${lib.getExe pkgs.fzf} --zsh)

                  eval "${"$"}(${lib.getExe pkgs.direnv} hook zsh)"
                  eval "${"$"}(${lib.getExe pkgs.mise} activate zsh)"
                  eval "${"$"}(${lib.getExe pkgs.atuin} init zsh --disable-up-arrow --disable-ctrl-r)"
                  eval "${"$"}(${lib.getExe pkgs.zoxide} init zsh --hook pwd)"
                ''
                (builtins.readFile ../../../config/zsh.d/zsh/config/extras.zsh)
                ''
                  # Per machine config
                  if [ -f ${"$"}HOST_CONFIGS/zshrc ]; then
                  	source ${"$"}HOST_CONFIGS/zshrc
                  fi
                  #
                  # End profiling (uncomment when necessary)
                  #

                  # Per-command profiling:

                  # unsetopt xtrace
                  # exec 2>&3 3>&-

                  # Per-function profiling:

                  # zprof
                ''
              ]);

          promptInit = "autoload -U promptinit; promptinit; prompt pure";
        };
      }
    ]);
}
