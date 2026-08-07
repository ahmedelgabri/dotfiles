# Shared host wiring: the feature-module import, the flake.modules entry,
# and the darwinConfigurations/nixosConfigurations plumbing that every host
# file used to repeat. A host file only supplies its hostConfiguration.
#
# Imported as a plain function (not via inputs.self.lib): the returned
# attribute structure must be enumerable without forcing `self`, otherwise
# the flake-parts fixpoint recurses. `self` is only referenced lazily
# inside the attribute values.
{
  inputs,
  runtime, # "darwin" or "nixos"
  name,
  hostConfiguration,
  system ? (if runtime == "darwin" then "aarch64-darwin" else "x86_64-linux"),
  # Darwin hosts get the darwin-only "defaults" feature on top of
  # commonFeatures.
  extraFeatures ? (if runtime == "darwin" then [ "defaults" ] else [ ]),
}:
let
  host =
    if runtime == "darwin" then
      inputs.self.lib.mkDarwin system name
    else
      inputs.self.lib.mkNixos system name;

  featureModule = inputs.self.lib.mkFeatureModule runtime {
    features = inputs.self.lib.commonFeatures ++ extraFeatures;
  };
in
{
  flake = {
    modules.${runtime}.${name}.imports = [
      featureModule
      hostConfiguration
    ];
  }
  // (
    if runtime == "darwin" then
      {
        darwinConfigurations = host;
        # Non-standard convenience output: `nix build .#<name>` builds the
        # system toplevel without switching.
        ${name} = host.${name}.system;
      }
    else
      {
        nixosConfigurations = host;
      }
  );
}
