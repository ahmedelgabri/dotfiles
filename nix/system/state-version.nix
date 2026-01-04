# State version management - for both system and home-manager
# Handles backwards compatibility version tracking
{...}:
let
  stateVersionModule = {config, pkgs, ...}: {
    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    #
    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It's perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    # https://nixos.org/manual/nixos/stable/index.html#sec-upgrading
    system.stateVersion =
      if pkgs.stdenv.isDarwin
      then 5
      else "24.05"; # Did you read the comment?

    home-manager.users."${config.my.username}".home.stateVersion =
      if pkgs.stdenv.isDarwin
      then "24.05"
      else config.system.stateVersion;
  };
in {
  flake.modules.darwin.state-version = stateVersionModule;
  flake.modules.nixos.state-version = stateVersionModule;
}
