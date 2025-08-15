{
  pkgs,
  lib,
  config,
  ...
}: let
  homeDir = config.my.user.home;
  cfg = config.my.modules.ai;
  inherit (pkgs.stdenv) isDarwin isLinux;
in {
  options = with lib; {
    my.modules.ai = {
      enable = mkEnableOption ''
        Whether to enable ai module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [
      (mkIf isDarwin {
        launchd.daemons.swama = {
          # Not sure about passing the flags here, double check
          command = "${pkgs.ollama}/bin/swama serve --host 0.0.0.0 --port 28100";
          serviceConfig = {
            Label = "swama";
            UserName = config.my.username;
            GroupName = "staff";
            ExitTimeOut = 30;
            Disabled = false;
            RunAtLoad = true;
            KeepAlive = true;
            StandardOutPath = "${homeDir}/Library/Logs/swama-output.log";
            StandardErrorPath = "${homeDir}/Library/Logs/swama-error.log";
          };
        };
        homebrew.casks = [
          "swama"
          "claude"
        ];
      })
      (mkIf isLinux {
        my.user = {
          packages = with pkgs; [
            ollama
            open-webui
          ];
        };
      })

      {
        environment = {
          shellAliases = {
            aider = "aider --config ~/.dotfiles/config/aider/config.yml";
          };
        };
        my = {
          user = {
            packages = with pkgs; [
              llama-cpp
              claude-code
              aider-chat
              repomix
              (llm.withPlugins
                {
                  # LLM access to models by Anthropic, including the Claude series <https://github.com/simonw/llm-anthropic>
                  llm-anthropic = true;

                  # Use LLM to generate and execute commands in your shell <https://github.com/simonw/llm-cmd>
                  llm-cmd = true;

                  # Access the Cohere Command R family of models <https://github.com/simonw/llm-command-r>
                  llm-command-r = true;

                  # LLM plugin providing access to Deepseek models. <https://github.com/abrasumente233/llm-deepseek>
                  llm-deepseek = true;

                  # Ask questions of LLM documentation using LLM <https://github.com/simonw/llm-docs>
                  llm-docs = true;

                  # Debug plugin for LLM <https://github.com/simonw/llm-echo>
                  llm-echo = true;

                  # Load GitHub repository contents as LLM fragments <https://github.com/simonw/llm-fragments-github>
                  llm-fragments-github = true;

                  # LLM fragments plugin for PyPI packages metadata <https://github.com/samueldg/llm-fragments-pypi>
                  llm-fragments-pypi = true;

                  # Run URLs through the Jina Reader API <https://github.com/simonw/llm-fragments-reader>
                  llm-fragments-reader = true;

                  # LLM fragment loader for Python symbols <https://github.com/simonw/llm-fragments-symbex>
                  llm-fragments-symbex = true;

                  # LLM plugin to access Google's Gemini family of models <https://github.com/simonw/llm-gemini>
                  llm-gemini = true;

                  # Run models distributed as GGUF files using LLM <https://github.com/simonw/llm-gguf>
                  llm-gguf = true;

                  # AI-powered Git commands for the LLM CLI tool <https://github.com/OttoAllmendinger/llm-git>
                  llm-git = true;

                  # LLM plugin providing access to Grok models using the xAI API <https://github.com/Hiepler/llm-grok>
                  llm-grok = true;

                  # LLM plugin providing access to Groqcloud models. <https://github.com/angerman/llm-groq>
                  llm-groq = true;

                  # LLM plugin for pulling content from Hacker News <https://github.com/simonw/llm-hacker-news>
                  llm-hacker-news = true;

                  # Write and execute jq programs with the help of LLM <https://github.com/simonw/llm-jq>
                  llm-jq = true;

                  # LLM plugin providing access to Mistral models using the Mistral API <https://github.com/simonw/llm-llama-server>
                  llm-llama-server = true;

                  # LLM plugin providing access to Mistral models using the Mistral API <https://github.com/simonw/llm-mistral>
                  llm-mistral = true;

                  # LLM plugin providing access to Ollama models using HTTP API <https://github.com/taketwo/llm-ollama>
                  llm-ollama = true;

                  # OpenAI plugin for LLM <https://github.com/simonw/llm-openai-plugin>
                  llm-openai-plugin = true;

                  # LLM plugin for models hosted by OpenRouter <https://github.com/simonw/llm-openrouter>
                  llm-openrouter = true;

                  # LLM fragment plugin to load a PDF as a sequence of images <https://github.com/simonw/llm-pdf-to-images>
                  llm-pdf-to-images = true;

                  # LLM plugin for embeddings using sentence-transformers <https://github.com/simonw/llm-sentence-transformers>
                  llm-sentence-transformers = true;

                  # Load LLM templates from Fabric <https://github.com/simonw/llm-templates-fabric>
                  llm-templates-fabric = true;

                  # Load LLM templates from GitHub repositories <https://github.com/simonw/llm-templates-github>
                  llm-templates-github = true;

                  # Expose Datasette instances to LLM as a tool <https://github.com/simonw/llm-tools-datasette>
                  llm-tools-datasette = true;

                  # JavaScript execution as a tool for LLM <https://github.com/simonw/llm-tools-quickjs>
                  llm-tools-quickjs = true;

                  # Make simple_eval available as an LLM tool <https://github.com/simonw/llm-tools-simpleeval>
                  llm-tools-simpleeval = true;

                  # LLM tools for running queries against SQLite <https://github.com/simonw/llm-tools-sqlite>
                  llm-tools-sqlite = true;

                  # LLM plugin to access models available via the Venice API <https://github.com/ar-jan/llm-venice>
                  llm-venice = true;

                  # LLM plugin to turn a video into individual frames <https://github.com/simonw/llm-video-frames>
                  llm-video-frames = true;
                })
            ];
          };
          hm.file = {
            ".claude/CLAUDE.md" = {
              source = ../../../config/claude/CLAUDE.md;
            };
          };
        };
      }
    ]);
}
