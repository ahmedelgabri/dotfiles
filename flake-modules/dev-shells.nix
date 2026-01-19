{inputs, ...}: {
  perSystem = {
    config,
    system,
    pkgs,
    ...
  }: {
    devShells = {
      default = pkgs.mkShell {
        name = "dotfiles";
        packages = with pkgs; [
          typos
          typos-lsp
          alejandra
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
