# Development shells - perSystem outputs
{inputs, ...}: {
  perSystem = {pkgs, system, ...}: {
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
  };
}
