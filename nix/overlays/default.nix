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

  # https://github.com/NixOS/nixpkgs/issues/106506#issuecomment-742639055
  weechat = super.weechat.override {
    configure = { availablePlugins, ... }: {
      plugins = with availablePlugins;
        [ (perl.withPackages (p: [ p.PodParser ])) ] ++ [ python ];
      scripts = with super.weechatScripts;
        [ wee-slack ]
        ++ self.lib.optionals (!self.stdenv.isDarwin) [ weechat-notify-send ];
    };
  };
}
