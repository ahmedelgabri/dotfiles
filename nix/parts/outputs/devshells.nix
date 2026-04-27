{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    devShells = {
      default = pkgs.mkShell {
        name = "dotfiles";
        packages = with pkgs;
          [
            typos
            typos-lsp
            alejandra
            inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
          ]
          ++ lib.optional stdenv.isDarwin sb;
      };

      go = pkgs.mkShell {
        name = "dotfiles-go";
        packages = with pkgs; [
          go
          gopls
          go-tools
          gomodifytags
          gotools
        ];
      };
    };
  };
}
