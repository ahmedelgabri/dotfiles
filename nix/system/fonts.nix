# Font configuration - platform-aware
# Pragmata Pro on all platforms, additional fonts on Linux
{lib, ...}:
let
  fontsModule = {pkgs, ...}: {
    fonts.packages = with pkgs;
      [pragmatapro]
      ++ (lib.optionals
        pkgs.stdenv.isLinux [
          noto-fonts
          noto-fonts-cjk
          noto-fonts-emoji
          # liberation_ttf
          fira-code
          fira-code-symbols
          mplus-outline-fonts
          dina-font
          proggyfonts
          (nerdfonts.override {fonts = ["FiraCode" "DroidSansMono"];})
        ]);
  };
in {
  # Same font config for both platforms (with platform conditionals inside)
  flake.modules.darwin.fonts = fontsModule;
  flake.modules.nixos.fonts = fontsModule;
}
