let
  module = {
    commonModule =
      {
        pkgs,
        ...
      }:
      {
        environment.variables = {
          CLAUDE_CODE_TMPDIR = "$HOME/.claude/agent-tmp-stuff";
          PI_CODING_AGENT_DIR = "$HOME/.config/pi/agent";
        };

        my.user.packages = with pkgs; [
          llm-agents.claude-code
          llm-agents.codex
          llm-agents.pi
          llm-agents.qmd
          llm-agents.agent-browser
          llama-cpp
          ccpeek
        ];
      };

    homeManager =
      {
        config,
        lib,
        pkgs,
        myConfig,
        ...
      }:

      let
        dotfilesConfig = "${config.home.homeDirectory}/.dotfiles/config";
        piCodingAgent = "${pkgs.llm-agents.pi}/lib/node_modules/@earendil-works/pi-coding-agent";
        piCodingAgentNodeModules = "${piCodingAgent}/node_modules";
        piAgentExtensionNodeModules = pkgs.runCommandLocal "pi-agent-extension-node-modules" { } ''
          mkdir -p "$out/@earendil-works" "$out/@types"

          ln -s ${piCodingAgent} "$out/@earendil-works/pi-coding-agent"
          for package in ${piCodingAgentNodeModules}/@earendil-works/*; do
            ln -s "$package" "$out/@earendil-works/$(basename "$package")"
          done
          ln -s ${piCodingAgentNodeModules}/typebox "$out/typebox"
          ln -s ${piCodingAgentNodeModules}/@types/node "$out/@types/node"
          ln -s ${piCodingAgentNodeModules}/undici-types "$out/undici-types"
        '';
        piAgentSettings = (builtins.fromJSON (builtins.readFile ../../../../config/pi/settings.json)) // {
          extensions = [ "~/.local/share/${myConfig.hostName}/pi/extensions" ];
          skills = [ "~/.local/share/${myConfig.hostName}/pi/skills" ];
        };
        mkSyncSettings =
          target:
          config.lib.dag.entryAfter [ "writeBoundary" ] ''
            BK="${target}.bk"
            TARGET="${target}"
            if [ -f "$BK" ] || [ -L "$BK" ]; then
              rm -f "$TARGET"
              cp "$BK" "$TARGET"
            fi
          '';
      in
      {
        xdg.configFile =
          config.lib.file.mkOutOfStoreTree {
            source = ../../../../config/pi/agent;
            sourceRoot = "${dotfilesConfig}/pi/agent";
            targetRoot = "pi/agent";
          }
          // {
            "pi/agent/settings.json.bk".text = builtins.toJSON piAgentSettings + "\n";
          };

        home = {
          activation = {
            linkPiAgentExtensionNodeModules = config.lib.dag.entryAfter [ "writeBoundary" ] ''
              TARGET="${config.home.homeDirectory}/.dotfiles/config/pi/agent/extensions/node_modules"
              SOURCE="${piAgentExtensionNodeModules}"

              if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
                echo "Refusing to replace non-symlink $TARGET" >&2
                exit 1
              fi

              mkdir -p "$(dirname "$TARGET")"
              rm -f "$TARGET"
              ln -s "$SOURCE" "$TARGET"
            '';

            syncPiAgentSettings = mkSyncSettings "${config.xdg.configHome}/pi/agent/settings.json";
          };

          file = lib.mergeAttrsList [
            (config.lib.file.mkOutOfStoreTree {
              source = ../../../../config/claude/skills;
              sourceRoot = "${dotfilesConfig}/claude/skills";
              targetRoot = ".agents/skills";
            })
            (config.lib.file.mkOutOfStoreTree {
              source = ../../../../config/claude/agents;
              sourceRoot = "${dotfilesConfig}/claude/agents";
              targetRoot = ".claude/agents";
            })
            (config.lib.file.mkOutOfStoreTree {
              source = ../../../../config/claude/docs;
              sourceRoot = "${dotfilesConfig}/claude/docs";
              targetRoot = ".claude/docs";
            })
            (config.lib.file.mkOutOfStoreTree {
              source = ../../../../config/claude/commands;
              sourceRoot = "${dotfilesConfig}/claude/commands";
              targetRoot = ".claude/commands";
            })
            (config.lib.file.mkOutOfStoreTree {
              source = ../../../../config/claude/hooks;
              sourceRoot = "${dotfilesConfig}/claude/hooks";
              targetRoot = ".claude/hooks";
            })
            (config.lib.file.mkOutOfStoreTree {
              source = ../../../../config/claude/scripts;
              sourceRoot = "${dotfilesConfig}/claude/scripts";
              targetRoot = ".claude/scripts";
            })
            (config.lib.file.mkOutOfStoreTree {
              source = ../../../../config/claude/skills;
              sourceRoot = "${dotfilesConfig}/claude/skills";
              targetRoot = ".claude/skills";
            })
            {
              ".claude/CLAUDE.md".source =
                config.lib.file.mkOutOfStoreSymlink "${dotfilesConfig}/claude/CLAUDE-template.md";

              ".claude/settings.json".source =
                config.lib.file.mkOutOfStoreSymlink "${dotfilesConfig}/claude/settings.json";
            }
          ];
        };
      };

    darwin =
      { pkgs, ... }:
      {
        imports = [ module.commonModule ];
        config = {
          homebrew = {
            brews = [ "cirruslabs/cli/tart" ];
            casks = [
              "claude"
              "codex-app"
            ];
          };
          my.user.packages = with pkgs; [
            sb
          ];
        };
      };

    nixos =
      { ... }:
      {
        imports = [ module.commonModule ];
      };
  };
in
{
  flake = {
    modules = {
      darwin.ai = module.darwin;
      nixos.ai = module.nixos;
      homeManager.ai = module.homeManager;
    };
  };
}
