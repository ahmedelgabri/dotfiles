{ inputs, lib, ... }:
{
  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
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

      # `nix flake check` skips darwinConfigurations. Writing the drvPath
      # without its string context forces full evaluation without building
      # the host's closure, so Linux CI can cover darwin hosts.
      darwinHostEvalChecks =
        lib.mapAttrs'
          (
            name: host:
            lib.nameValuePair "${name}-eval" (
              pkgs.writeText "${name}-eval" (builtins.unsafeDiscardStringContext host.system.drvPath)
            )
          )
          (
            lib.filterAttrs (
              _: host: host.pkgs.stdenv.hostPlatform.system == system
            ) inputs.self.darwinConfigurations
          );
    in
    {
      checks = darwinHostEvalChecks // {
        # nixos-generate-config owns hardware-configuration.nix; regenerating
        # it would bring back its unused `pkgs` argument.
        deadnix = mkCheck "deadnix-check" [ pkgs.deadnix ] ''
          deadnix --fail --exclude ${source}/nix/parts/hosts/nixos/hardware-configuration.nix -- ${source}
        '';

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

        # Building runs writeShellApplication's shellcheck.
        inherit (config.packages) doctor;
        inherit (pkgs) next-prayer agent-history;
      };
    };
}
