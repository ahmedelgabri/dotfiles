let
  module = {
    darwin = {pkgs, ...}: {
      config = {
        homebrew.casks = ["tart"];
        my.user.packages = with pkgs; [
          sb
        ];
      };
    };

    generic = {
      pkgs,
      lib,
      ...
    }: {
      config = with lib; {
        my.user.packages = with pkgs; [
          llm-agents.claude-code
          llm-agents.qmd
          llm-agents.agent-browser
          llama-cpp
          ccpeek
        ];
      };
    };

    homeManager = {config, ...}: {
      home.activation.syncAgentSettings = config.lib.dag.entryAfter ["writeBoundary"] ''
        BK="${config.home.homeDirectory}/.claude/settings.json.bk"
        TARGET="${config.home.homeDirectory}/.claude/settings.json"
        if [ -f "$BK" ] || [ -L "$BK" ]; then
          rm -f "$TARGET"
          cp "$BK" "$TARGET"
        fi
      '';

      home.file = {
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
in {
  flake = {
    modules = {
      darwin.ai = module.darwin;
      generic.ai = module.generic;
      homeManager.ai = module.homeManager;
    };
  };
}
