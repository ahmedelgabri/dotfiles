# As a first step, I will try to symlink my configs as much as possible then
# migrate the configs to Nix
#
# https://nixcloud.io/ for Nix syntax
# https://discourse.nixos.org/t/home-manager-equivalent-of-apt-upgrade/8424/3
# https://www.mathiaspolligkeit.de/dev/exploring-nix-on-macos/
# https://catgirl.ai/log/nixos-experience/
# https://kevincox.ca/2020/09/06/switching-to-desktop-nixos/
# https://www.reddit.com/r/NixOS/comments/jmom4h/new_neofetch_nixos_logo/gayfal2/
# https://ghedam.at/15978/an-introduction-to-nix-shell
# https://foo-dogsquared.github.io/blog/posts/moving-into-nixos/
# https://www.youtube.com/user/elitespartan117j27/videos?view=0&sort=da&flow=grid
# https://www.youtube.com/playlist?list=PLRGI9KQ3_HP_OFRG6R-p4iFgMSK1t5BHs
# https://www.reddit.com/r/NixOS/comments/k9xwht/best_resources_for_learning_nixos/
# https://www.reddit.com/r/NixOS/comments/k8zobm/nixos_preferred_packages_flow/
#
# Sample repos
# https://github.com/malloc47/config (very simple!)
# https://github.com/wbadart/dotfiles (simple)
# https://github.com/srid/nix-config
# https://github.com/yevhenshymotiuk/darwin-home (this is what I should aim for as a start)
# https://github.com/hlissner/dotfiles/blob/master/modules/shell/zsh.nix (this!)
# https://github.com/rummik/nixos-config
# https://github.com/teoljungberg/dotfiles/tree/master/nixpkgs (contains custom hammerspoon & vim )
# https://github.com/gmarmstrong/dotfiles
# https://github.com/jwiegley/nix-config (nice example)
# https://github.com/kclejeune/system (nice example)
# https://github.com/hardselius/dotfiles (good readme on steps to do for install)
#
# if isDarwin then <> else <>

{ config, pkgs, lib, ... }:

{
  imports = [ <home-manager/nix-darwin> ./modules ];
  nixpkgs.config = import ./config.nix;
  nixpkgs.overlays = [ (import ./overlays) ];

  # networking = {
  #   hostName = "pandoras-box";
  # };

  time.timeZone = config.settings.timezone;

  users.users.${config.settings.username} = {
    home = if pkgs.stdenv.isDarwin then
      "/Users/${config.settings.username}"
    else
      "/home/${config.settings.username}";
    description = "Primary user account";
    shell = [ pkgs.zsh ];
  };

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    users.${config.settings.username} = {
      xdg = {
        enable = true;
        configFile."nixpkgs/config.nix".source = ./config.nix;
      };

      home = { stateVersion = "20.09"; };

      programs = {
        # Let Home Manager install and manage itself.
        home-manager.enable = true;
      };
    };
  };

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  # services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
  # nix.maxJobs = 4;
  # nix.buildCores = 4;
}
