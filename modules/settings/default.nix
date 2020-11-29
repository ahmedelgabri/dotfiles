{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    settings = {
      name = mkOption {
        default = "Ahmed El Gabri";
        type = with types; uniq str;
      };
      timezone = mkOption {
        default = "Europe/Amsterdam";
        type = with types; uniq str;
      };
      username = mkOption {
        default = "ahmed";
        type = with types; uniq str;
      };
      website = mkOption {
        default = "https://gabri.me";
        type = with types; uniq str;
      };
      github_username = mkOption {
        default = "ahmedelgabri";
        type = with types; uniq str;
      };
      email = mkOption {
        default = "ahmed@gabri.me";
        type = with types; uniq str;
      };
      terminal = mkOption {
        default = "kitty";
        type = with types; uniq str;
      };
      nix_managed = mkOption {
        default =
          "vim: set nomodifiable : Nix managed - DO NOT EDIT - see source inside ~/.dotfiles or use `:set modifiable` to force.";
        type = with types; uniq str;
      };
    };
  };
}
