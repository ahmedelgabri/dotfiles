# Formatter module
{...}: {
  perSystem = {pkgs, ...}: {
    formatter = pkgs.alejandra;
  };
}
