{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      source = inputs.self;
      piAgentExtensionNodeModules = import ../modules/shared/pi-extension-types.nix { inherit pkgs; };
      mkCheck =
        name: nativeBuildInputs: script:
        pkgs.runCommandLocal name { inherit nativeBuildInputs; } ''
          set -euo pipefail
          ${script}
          touch "$out"
        '';
    in
    {
      checks = {
        nix-format = mkCheck "nix-format-check" [ pkgs.nixfmt-rs ] ''
          find ${source} -name '*.nix' -print0 | xargs -0 nixfmt --check
        '';

        pi-extensions = mkCheck "pi-extensions-check" [ pkgs.typescript ] ''
          cp -R ${source}/config/pi/agent/extensions source
          chmod -R u+w source
          ln -s ${piAgentExtensionNodeModules} source/node_modules
          cd source
          tsc --noEmit
        '';

        shellcheck = mkCheck "shellcheck" [ pkgs.shellcheck ] ''
          while IFS= read -r -d $'\0' file; do
            first_line=
            IFS= read -r first_line < "$file" || true
            case "$first_line" in
              *bash*|*'/bin/sh'*) shellcheck "$file" ;;
            esac
          done < <(find ${source} -type f -print0)
        '';

        stylua = mkCheck "stylua-check" [ pkgs.stylua ] ''
          stylua --config-path ${source}/.stylua.toml --check ${source}/config
        '';

        typos = mkCheck "typos-check" [ pkgs.typos ] ''
          cd ${source}
          typos .
        '';

        inherit (pkgs) next-prayer;
      };
    };
}
