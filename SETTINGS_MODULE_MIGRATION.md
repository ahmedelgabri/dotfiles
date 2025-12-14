# Settings Module Migration to Flake-Parts

## Overview

Migrated the `nix/modules/shared/settings.nix` module to be properly exposed as reusable flake outputs through flake-parts.

## What Changed

### Created `flake-modules/system-modules.nix`

This new flake-parts module exposes your NixOS/nix-darwin modules as reusable outputs that other flakes can import.

```nix
{
  inputs,
  self,
  ...
}: {
  flake = {
    # Expose reusable NixOS/nix-darwin modules for other flakes to consume
    nixosModules = {
      # Individual module exports
      settings = import "${self}/nix/modules/shared/settings.nix";

      # Or export all shared modules as a single module
      default = import "${self}/nix/modules/shared";
    };

    darwinModules = {
      # Individual module exports
      settings = import "${self}/nix/modules/shared/settings.nix";

      # Or export all shared modules as a single module
      default = import "${self}/nix/modules/shared";
    };
  };
}
```

### Updated `flake.nix`

Added the new system-modules.nix to the imports list:

```nix
imports = [
  inputs.flake-parts.flakeModules.modules
  inputs.home-manager.flakeModules.home-manager
  ./flake-modules/system-modules.nix  # <-- Added
  ./flake-modules/shared.nix
  ./flake-modules/darwin.nix
  ./flake-modules/nixos.nix
  ./flake-modules/dev-shells.nix
  ./flake-modules/apps.nix
];
```

## Important Clarification

The `settings.nix` module itself was NOT moved or changed. It remains at `nix/modules/shared/settings.nix` and is still imported via `nix/modules/shared/default.nix` as before.

**What this migration does:**
- Exposes the settings module (and all shared modules) as flake outputs
- Allows other flakes to import and reuse your modules
- Follows flake-parts best practices for module organization

**What this migration does NOT do:**
- Does NOT change how settings.nix works internally
- Does NOT change how your system configurations import it
- Does NOT require any changes to existing host configurations

## Why This Matters

Before this migration, the settings module was only usable within this dotfiles repository. Now:

1. **Other flakes can import your modules:**
   ```nix
   {
     inputs.dotfiles.url = "github:ahmedelgabri/dotfiles";

     outputs = {nixpkgs, dotfiles, ...}: {
       nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
         modules = [
           dotfiles.nixosModules.settings
         ];
       };
     };
   }
   ```

2. **Better flake structure:** Follows the standard pattern of exposing `nixosModules` and `darwinModules` outputs

3. **Reusability:** Other projects can benefit from your module system and configuration aliases

## Available Outputs

After this migration, your flake exposes:

- `nixosModules.default` - All shared modules
- `nixosModules.settings` - Just the settings module
- `darwinModules.default` - All shared modules
- `darwinModules.settings` - Just the settings module

## Verification

You can verify the modules are properly exposed:

```bash
# Show all flake outputs
nix flake show

# Test that the module exists
nix eval .#nixosModules.settings --apply 'x: "exists"'
nix eval .#darwinModules.settings --apply 'x: "exists"'

# Build still works
nix flake check --accept-flake-config
```

## Settings Module Contents

The `settings.nix` module defines:

- **Options:** Core configuration options like `my.username`, `my.email`, `my.timezone`, etc.
- **Aliases:** Convenient shortcuts for home-manager paths (`my.hm.file`, `my.hm.configFile`, etc.)
- **User configuration:** Sets up the primary user account
- **Environment variables:** Manages `my.env` for setting shell environment variables

These are all still defined in `nix/modules/shared/settings.nix` - nothing changed there.

## Benefits of This Approach

1. **No breaking changes:** Everything continues to work exactly as before
2. **Additive improvement:** Only adds new capabilities without changing existing behavior
3. **Standard pattern:** Follows how other Nix flakes expose modules
4. **Future-proof:** Makes it easy to share modules with other projects
5. **Flake-parts native:** Uses flake-parts' module system correctly
