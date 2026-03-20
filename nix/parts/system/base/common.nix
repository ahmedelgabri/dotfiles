{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.self.modules.generic.base
  ];

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
      auto-optimise-store = !pkgs.stdenv.isDarwin;
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
    optimise.automatic = pkgs.stdenv.isDarwin;
  };

  fonts = {
    packages = with pkgs;
      [pragmatapro]
      ++ (lib.optionals pkgs.stdenv.isLinux [
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
        fira-code
        fira-code-symbols
        mplus-outline-fonts
        dina-font
        proggyfonts
        (nerdfonts.override {fonts = ["FiraCode" "DroidSansMono"];})
      ]);
  };

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

  system.stateVersion =
    if pkgs.stdenv.isDarwin
    then 5
    else "24.05";

  home-manager.users."${config.my.username}".home.stateVersion =
    if pkgs.stdenv.isDarwin
    then "24.05"
    else config.system.stateVersion;
}
