{ lib, ... }:
with lib;
let
  mkOptStr =
    value:
    mkOption {
      type = with types; uniq str;
      default = value;
    };
in
{
  options.my = {
    name = mkOptStr "Ahmed El Gabri";
    timezone = mkOptStr "Europe/Amsterdam";
    username = mkOptStr "ahmed";
    website = mkOptStr "https://gabri.me";
    github_username = mkOptStr "ahmedelgabri";
    email = mkOptStr "ahmed@gabri.me";
    company = mkOptStr "";
    devFolder = mkOptStr "code";
    nix_managed = mkOptStr "vim: set nomodifiable : Nix managed - DO NOT EDIT - see source inside ~/.dotfiles or use `:set modifiable` to force.";
    # Logical host name (the flake attribute), set by mk-host. Deliberately
    # decoupled from networking.hostName: an MDM may own the machine's real
    # names, so no configuration should key off them.
    hostName = mkOptStr "";
    hostConfigHome = mkOptStr "";
    # Absolute path of the dotfiles checkout; set in base/home-manager.nix once
    # the user's home directory is known. Every out-of-store symlink and the
    # DOTFILES env var derive from this single value.
    dotfilesDir = mkOptStr "";
    # Feature modules (e.g. mail) declare their options under this namespace;
    # declaring it in base lets home-manager.nix read `config.my.modules`
    # without depending on any feature module being imported.
    modules = { };
  };
}
