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
          fabric-ai
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
        dotfilesConfig = "${myConfig.dotfilesDir}/config";
        # Types-only copies of pi's extension API, fetched from npm for tsc
        # and editors; pi resolves these imports internally at runtime. The
        # tree must not link into pi's store path: pi stopped shipping
        # unpacked node_modules, and the links went dangling on every pi
        # bump once the old store path was GC'd. Version drift against the
        # installed pi is harmless for type checking. The pins are generated
        # by the update-pi-extension-types command below (run by nixup).
        piAgentExtensionTypePackages = lib.mapAttrsToList (name: pkg: { inherit name; } // pkg) (
          builtins.fromJSON (builtins.readFile ./pi-extension-types.lock.json)
        );
        updatePiExtensionTypes = pkgs.writeShellApplication {
          name = "update-pi-extension-types";
          runtimeInputs = with pkgs; [
            curl
            jq
            nix
          ];
          # The pi packages are published in lockstep with pi releases;
          # typebox is pinned to whatever pi-coding-agent declares, and
          # undici-types follows @types/node.
          text = ''
            registry="https://registry.npmjs.org"
            lockfile="${myConfig.dotfilesDir}/nix/parts/modules/shared/pi-extension-types.lock.json"

            pi_version=$(curl -fsSL "$registry/@earendil-works%2Fpi-coding-agent/latest" | jq -r .version)
            typebox_version=$(curl -fsSL "$registry/@earendil-works%2Fpi-coding-agent/$pi_version" | jq -r '.dependencies.typebox')
            types_node_meta=$(curl -fsSL "$registry/@types%2Fnode/latest")
            types_node_version=$(jq -r .version <<<"$types_node_meta")
            # @types/node depends on undici-types with a ~x.y.z range;
            # resolve it to the newest matching x.y.* release.
            undici_range=$(jq -r '.dependencies["undici-types"]' <<<"$types_node_meta")
            undici_prefix=''${undici_range#\~}
            undici_prefix=''${undici_prefix%.*}
            undici_version=$(curl -fsSL "$registry/undici-types" |
              jq -r --arg p "$undici_prefix." '.versions | keys | map(select(startswith($p))) | last')

            entry() {
              local name=$1 version=$2 base url hash
              base=''${name##*/}
              url="$registry/$name/-/$base-$version.tgz"
              hash=$(nix store prefetch-file --json "$url" | jq -r .hash)
              printf '%s %s\n' "$name" "$version" >&2
              jq -n --arg name "$name" --arg version "$version" --arg hash "$hash" \
                '{($name): {version: $version, hash: $hash}}'
            }

            {
              entry "@earendil-works/pi-coding-agent" "$pi_version"
              entry "@earendil-works/pi-ai" "$pi_version"
              entry "@earendil-works/pi-tui" "$pi_version"
              entry "@earendil-works/pi-client" "$pi_version"
              entry "typebox" "$typebox_version"
              entry "@types/node" "$types_node_version"
              entry "undici-types" "$undici_version"
            } | jq -s add >"$lockfile"

            echo "Wrote $lockfile"
          '';
        };
        piAgentExtensionNodeModules = pkgs.runCommandLocal "pi-agent-extension-node-modules" { } (
          lib.concatMapStrings (pkg: ''
            mkdir -p "$(dirname "$out/${pkg.name}")" unpack
            tar -xzf ${
              pkgs.fetchurl {
                url = "https://registry.npmjs.org/${pkg.name}/-/${baseNameOf pkg.name}-${pkg.version}.tgz";
                inherit (pkg) hash;
              }
            } -C unpack
            # Most npm tarballs unpack to package/, but not all (@types/node
            # uses node/), so move whatever single root directory exists.
            mv unpack/* "$out/${pkg.name}"
            rmdir unpack
          '') piAgentExtensionTypePackages
        );
        piAgentSettings = (builtins.fromJSON (builtins.readFile ../../../../config/pi/settings.json)) // {
          lastChangelogVersion = pkgs.llm-agents.pi.version;
          extensions = [ "~/.local/share/${myConfig.hostName}/pi/extensions" ];
          skills = [ "~/.local/share/${myConfig.hostName}/pi/skills" ];
          themes = [ "${dotfilesConfig}/pi/agent/themes" ];
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
        mkClaudeTree =
          { sub, target }:
          config.lib.file.mkOutOfStoreTree {
            source = ../../../../config/claude + "/${sub}";
            sourceRoot = "${dotfilesConfig}/claude/${sub}";
            targetRoot = target;
          };
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
          packages = [ updatePiExtensionTypes ];

          activation = {
            linkPiAgentExtensionNodeModules = config.lib.dag.entryAfter [ "writeBoundary" ] ''
              TARGET="${myConfig.dotfilesDir}/config/pi/agent/extensions/node_modules"
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

          file = lib.mergeAttrsList (
            map mkClaudeTree [
              {
                sub = "skills";
                target = ".agents/skills";
              }
              {
                sub = "agents";
                target = ".claude/agents";
              }
              {
                sub = "docs";
                target = ".claude/docs";
              }
              {
                sub = "commands";
                target = ".claude/commands";
              }
              {
                sub = "hooks";
                target = ".claude/hooks";
              }
              {
                sub = "scripts";
                target = ".claude/scripts";
              }
              {
                sub = "skills";
                target = ".claude/skills";
              }
            ]
            ++ [
              {
                ".claude/CLAUDE.md".source =
                  config.lib.file.mkOutOfStoreSymlink "${dotfilesConfig}/claude/CLAUDE-template.md";

                ".claude/settings.json".source =
                  config.lib.file.mkOutOfStoreSymlink "${dotfilesConfig}/claude/settings.json";
              }
            ]
          );
        };
      };

    darwin =
      { pkgs, ... }:
      {
        imports = [ module.commonModule ];
        config = {
          homebrew = {
            brews = [ "openai/tools/tart" ];
            casks = [
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
