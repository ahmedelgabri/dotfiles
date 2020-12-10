self: super:

let

  pkgs = import <nixpkgs> { };

in rec {
  neovim-unwrapped = super.neovim-unwrapped.overrideAttrs (oldAttrs: {
    version = "master";
    src = builtins.fetchGit { url = "https://github.com/neovim/neovim.git"; };
    buildInputs = oldAttrs.buildInputs ++ ([ pkgs.tree-sitter ]);
  });

  pure-prompt = super.pure-prompt.overrideAttrs
    (old: { patches = (old.patches or [ ]) ++ [ ./pure-zsh.patch ]; });

  python3 = super.python3.override {
    packageOverrides = self: super: {
      python-language-server = super.python-language-server.overridePythonAttrs
        (old: rec { doCheck = false; });
    };
  };

  # direnv = super.direnv.overrideAttrs (old: {
  #   postInstall = ''
  #     mkdir -p $out/dhook
  #
  #     ${pkgs.direnv}/bin/direnv hook zsh
  #
  #     ${pkgs.direnv}/bin/direnv hook zsh > $out/dhook/direnv-hook.zsh'';
  # });
}
