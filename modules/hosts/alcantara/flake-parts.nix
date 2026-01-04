# Alcantara flake-parts module
# Defines the darwinConfiguration using the lib helper
{inputs, ...}: {
  flake.darwinConfigurations =
    inputs.self.lib.mkDarwin "aarch64-darwin" "alcantara";
}
