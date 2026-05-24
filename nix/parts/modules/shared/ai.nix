let
  module = {
    commonModule =
      {
        pkgs,
        lib,
        ...
      }:
      {
        environment.variables = {
          PI_CODING_AGENT_DIR = "$HOME/.config/pi/agent";
        };

        homebrew = {
          casks = [
            "claude"
          ];
        };

        config = with lib; {
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
      };

    homeManager =
      { config, pkgs, ... }:

      let
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
      in
      {
        home = {
          activation = {
            syncAgentSettings = config.lib.dag.entryAfter [ "writeBoundary" ] ''
              BK="${config.home.homeDirectory}/.claude/settings.json.bk"
              TARGET="${config.home.homeDirectory}/.claude/settings.json"
              if [ -f "$BK" ] || [ -L "$BK" ]; then
                rm -f "$TARGET"
                cp "$BK" "$TARGET"
              fi
            '';

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

            syncPiAgentSettings = config.lib.dag.entryAfter [ "writeBoundary" ] ''
              BK="${config.xdg.configHome}/pi/agent/settings.json.bk"
              TARGET="${config.xdg.configHome}/pi/agent/settings.json"
              if [ -f "$BK" ] || [ -L "$BK" ]; then
                rm -f "$TARGET"
                cp "$BK" "$TARGET"
              fi
            '';
          };

          file = {
            ".agents/skills" = {
              recursive = true;
              source = ../../../../config/claude/skills;
            };

            ".claude/CLAUDE.md".source = ../../../../config/claude/CLAUDE-template.md;

            ".claude/agents" = {
              recursive = true;
              source = ../../../../config/claude/agents;
            };

            ".claude/docs" = {
              recursive = true;
              source = ../../../../config/claude/docs;
            };

            ".claude/commands" = {
              recursive = true;
              source = ../../../../config/claude/commands;
            };

            ".claude/hooks" = {
              recursive = true;
              source = ../../../../config/claude/hooks;
            };

            ".claude/scripts" = {
              recursive = true;
              source = ../../../../config/claude/scripts;
            };

            ".claude/skills" = {
              recursive = true;
              source = ../../../../config/claude/skills;
            };

            ".claude/settings.json.bk".source = ../../../../config/claude/settings.json;
          };
        };
      };

    darwin =
      { pkgs, ... }:
      {
        imports = [ module.commonModule ];
        config = {
          homebrew.brews = [ "cirruslabs/cli/tart" ];
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
