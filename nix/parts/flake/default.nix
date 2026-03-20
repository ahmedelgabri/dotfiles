{
  systems = [
    "aarch64-darwin"
    "x86_64-linux"
  ];

  imports = [
    ../flake-parts/darwinConfigurations-fix.nix
    ../flake-parts/modules.nix
    ../flake-parts/lib.nix
    ../modules/base/default.nix
    ../modules/darwin/default.nix
    ../modules/darwin/hammerspoon.nix
    ../modules/darwin/karabiner.nix
    ../modules/shared/user-shell.nix
    ../modules/shared/mail.nix
    ../modules/shared/gui.nix
    ../modules/shared/ssh.nix
    ../modules/shared/git.nix
    ../modules/shared/bat.nix
    ../modules/shared/ripgrep.nix
    ../modules/shared/yazi.nix
    ../modules/shared/tmux.nix
    ../modules/shared/vim.nix
    ../modules/shared/ai.nix
    ../modules/shared/ghostty.nix
    ../modules/shared/zk.nix
    ../modules/shared/gpg.nix
    ../modules/shared/kitty.nix
    ../modules/shared/mpv.nix
    ../modules/shared/discord.nix
    ../modules/shared/misc.nix
    ../modules/shared/python.nix
    ../modules/shared/jujutsu.nix
    ../modules/shared/yt-dlp.nix
    ../modules/shared/node.nix
    ../modules/shared/go.nix
    ../modules/shared/rust.nix
    ../modules/shared/agenix.nix
    ../hosts/rocket/default.nix
    ../hosts/alcantara/default.nix
    ../hosts/nixos/default.nix
    ../outputs/overlays.nix
    ../outputs/pkgs.nix
    ../outputs/formatter.nix
    ../outputs/devshells.nix
    ../outputs/apps.nix
    ../outputs/templates.nix
  ];

  flake.modules = let
    mkSystemBase = {
      runtimeImports,
      autoOptimiseStore,
      optimiseAutomatic,
      extraFonts,
      homePrefix,
      systemStateVersion,
      homeStateVersion,
    }: {
      config,
      pkgs,
      inputs,
      ...
    }: {
      imports =
        [
          inputs.self.modules.generic.base
        ]
        ++ runtimeImports inputs;

      system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

      nix = {
        enable = true;
        channel.enable = false;
        nixPath = {
          inherit (inputs) nixpkgs;
          inherit (inputs) darwin;
          inherit (inputs) home-manager;
        };
        package = pkgs.nix;
        settings = {
          trusted-users = ["@admin"];
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          auto-optimise-store = autoOptimiseStore;
          substituters = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
            "https://nixpkgs.cachix.org"
            "https://yazi.cachix.org"
            "https://cache.numtide.com"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
            "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
            "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
          ];
          keep-derivations = true;
          keep-outputs = true;
        };
        gc = {
          automatic = true;
          options = "--delete-older-than 3d";
        };
        optimise.automatic = optimiseAutomatic;
      };

      fonts.packages = [pkgs.pragmatapro] ++ extraFonts pkgs;

      nixpkgs = {
        config.allowUnfree = true;
        overlays = [
          inputs.yazi.overlays.default
          inputs.nur.overlays.default
          inputs.llm-agents.overlays.default
          inputs.self.overlays.default
        ];
      };

      time.timeZone = config.my.timezone;
      documentation.man.enable = true;

      my.user.home = "${homePrefix}/${config.my.username}";

      system.stateVersion = systemStateVersion;
      home-manager.users."${config.my.username}".home.stateVersion = homeStateVersion config;
    };
  in {
    darwin.system-base = mkSystemBase {
      runtimeImports = inputs: [
        inputs.home-manager.darwinModules.home-manager
        inputs.nix-homebrew.darwinModules.nix-homebrew
        inputs.agenix.darwinModules.default
      ];
      autoOptimiseStore = false;
      optimiseAutomatic = true;
      extraFonts = _: [];
      homePrefix = "/Users";
      systemStateVersion = 5;
      homeStateVersion = _: "24.05";
    };

    nixos.system-base = mkSystemBase {
      runtimeImports = inputs: [
        inputs.home-manager.nixosModules.home-manager
        inputs.agenix.nixosModules.default
      ];
      autoOptimiseStore = true;
      optimiseAutomatic = false;
      homePrefix = "/home";
      extraFonts = pkgs:
        with pkgs; [
          noto-fonts
          noto-fonts-cjk
          noto-fonts-emoji
          fira-code
          fira-code-symbols
          mplus-outline-fonts
          dina-font
          proggyfonts
          (nerdfonts.override {fonts = ["FiraCode" "DroidSansMono"];})
        ];
      systemStateVersion = "24.05";
      homeStateVersion = config: config.system.stateVersion;
    };
  };
}
