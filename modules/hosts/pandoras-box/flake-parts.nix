# Pandoras-box flake-parts module
{inputs, ...}: {
  flake.darwinConfigurations =
    inputs.self.lib.mkDarwin "x86_64-darwin" "pandoras-box";
}
