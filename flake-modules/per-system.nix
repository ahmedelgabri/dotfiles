# Per-system outputs: formatter, devShells, apps
# These are defined once but built for each system in the systems list
{
  inputs,
  self,
  ...
}: {
  perSystem = {
    config,
    pkgs,
    system,
    ...
  }: {
    # Formatter for nix files
    formatter = pkgs.alejandra;

    # Development shells
    devShells = {
      default = pkgs.mkShell {
        name = "dotfiles";
        packages = with pkgs; [
          typos
          typos-lsp
          alejandra
          inputs.agenix.packages.${system}.default
        ];
      };

      go = pkgs.mkShell {
        name = "dotfiles-go";
        packages = with pkgs; [
          go
          gopls
          go-tools # staticcheck, etc...
          gomodifytags
          gotools # goimports
        ];
      };
    };

    # Bootstrap and utility apps
    apps = let
      utils = pkgs.writeShellApplication {
        name = "utils";
        text = builtins.readFile ../scripts/utils;
      };
      bootstrap = pkgs.writeShellApplication {
        name = "bootstrap";
        runtimeInputs = [pkgs.git];
        text = ''
          # shellcheck disable=SC1091
          source ${pkgs.lib.getExe utils}
          ${builtins.readFile ../scripts/${system}_bootstrap}
        '';
      };
    in {
      default = {
        type = "app";
        program = pkgs.lib.getExe bootstrap;
      };
    };
  };
}
