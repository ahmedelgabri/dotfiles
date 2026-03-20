{lib, ...}:
with lib; let
  mkOptStr = value:
    mkOption {
      type = with types; uniq str;
      default = value;
    };
in {
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
    hostConfigHome = mkOptStr "";
  };
}
