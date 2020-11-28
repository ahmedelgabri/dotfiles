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
      mail = { # Make this a list instead?
        account = mkOption {
          default = "Personal";
          type = with types; uniq str;
        };
        alias_path = mkOption {
          default = "${builtins.getEnv "HOME"}/Sync/dotfiles/aliases";
          type = with types; uniq str;
        };
        keychain = {
          name = mkOption {
            default = "fastmail.com";
            type = with types; uniq str;
          };
          account = mkOption {
            default = "ahmed+mutt@gabri.me"; # can I do this with regex?
            type = with types; uniq str;
          };
        };
        imap_server = mkOption {
          default = "imap.fastmail.com";
          type = with types; uniq str;
        };
        smtp_server = mkOption {
          default = "smtp.fastmail.com";
          type = with types; uniq str;
        };
        accent = mkOption {
          default = "color238";
          type = with types; uniq str;
        };
        switch_to = mkOption {
          default = "";
          type = with types; uniq str;
        };
      };
    };
  };
}
