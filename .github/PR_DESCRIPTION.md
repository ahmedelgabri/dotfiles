# Complete Migration to Flake-Parts with Dendritic Pattern

This PR completes the migration of the entire Nix configuration to flake-parts following the [Dendritic Pattern](https://github.com/mightyiam/dendritic) architecture.

## 🎯 Summary

The configuration now follows a modular, aspect-oriented architecture where:
- **Every file is a flake-parts module** (auto-discovered via import-tree)
- **Features are organized by purpose**, not by platform
- **Hosts import features** via `inputs.self.modules.*`
- **Single source of truth** for each feature across all systems

## 📊 Changes Overview

### Modules Migrated (26 Feature Modules)

**Shared modules (21)** - work on both darwin and nixos:
- **Core**: git, vim, tmux, ssh, gpg, user-shell
- **Terminal**: kitty, ghostty, yazi, bat, ripgrep
- **Development**: node, python, go, rust
- **Applications**: gui, mail, discord, ai, zk, mpv, yt-dlp
- **Utilities**: misc, agenix

**Darwin-only modules (2)**:
- hammerspoon, karabiner

**System modules (6)**:
- user-options, nix-daemon, state-version, home-manager-integration, fonts, darwin-defaults

### Architecture Improvements

**Before:**
```
nix/modules/
├── shared/          # 23 modules + default.nix
└── darwin/          # 2 modules + default.nix
```

**After:**
```
nix/
├── modules/        # 26 feature modules
├── system/          # 7 system modules
└── hosts/           # 4 host configs (single file each)
```

## ✨ Key Benefits

1. **✅ Aspect-Oriented Organization** - Organize by feature (git, vim), not platform (darwin, nixos)
2. **✅ Auto-Discovery** - All modules discovered via import-tree
3. **✅ Single File Per Feature** - Each feature is self-contained
4. **✅ Single File Per Host** - No more configuration.nix + flake-parts.nix split
5. **✅ No specialArgs Anti-Pattern** - Access modules via `inputs.self.modules.*`
6. **✅ Sensible Defaults** - feature-defaults module enables common features
7. **✅ Easy Overrides** - Hosts can override with `lib.mkDefault`
8. **✅ Cross-Platform** - Single module works on both darwin and nixos

## 🏗️ Architecture

### Feature Modules

Every feature module follows this pattern:

```nix
# nix/modules/git.nix
{inputs, ...}: let
  gitModule = {pkgs, lib, config, ...}: let
    cfg = config.my.modules.git;
  in {
    options.my.modules.git.enable = lib.mkEnableOption "git module";
    config = lib.mkIf cfg.enable {
      # Git configuration here
    };
  };
in {
  flake.modules.darwin.git = gitModule;
  flake.modules.nixos.git = gitModule;
}
```

### Host Configuration

Hosts import system and feature modules:

```nix
# nix/hosts/alcantara.nix
{inputs, ...}: {
  flake.modules.darwin.alcantara = {config, pkgs, ...}: {
    imports = with inputs.self.modules.darwin; [
      user-options
      nix-daemon
      state-version
      home-manager-integration
      fonts
      defaults
    ];

    # Override or enable opt-in features
    my.modules = {
      mail.enable = true;
      gpg.enable = true;
      discord.enable = true;
    };
  };
}
```

### Auto-Discovery

All modules are auto-discovered via import-tree:

```nix
# flake.nix
inputs.import-tree.url = "github:vic/import-tree";

outputs = inputs @ {flake-parts, import-tree, ...}:
  flake-parts.lib.mkFlake {inherit inputs;} {
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    imports = [(import-tree ./nix)];  # Auto-discover all modules!
  };
```

## 📝 Migration Details

### What Changed

1. **Removed**:
   - `nix/modules/shared/` (23 modules + default.nix)
   - `nix/modules/darwin/` (2 modules + default.nix)
   - `nix/programs/` (example directory)

2. **Added**:
   - `nix/modules/` (26 feature modules in flake-parts format)

3. **Migrated**:
   - All feature modules to `flake.modules.{darwin,nixos}.<name>` pattern
   - All hosts to single-file configuration
   - Fixed relative paths (../../../config/ → ../../config/)
   - Fixed broken host imports (pandoras-box, rocket, nixos)

### Commits

1. `refactor(nix): use import-tree and migrate to nix/ directory`
2. `refactor(nix): cleanup and break down modules into focused aspects`
3. `fix(nix): properly migrate pandoras-box and rocket host configs`
4. `feat(nix): complete migration to flake-parts with Dendritic Pattern`
5. `docs(nix): update migration documentation`

## ⚠️ Testing Required

**Before merging, please test:**

```bash
# Check flake validity
nix flake check

# Test build for each host
nix build .#darwinConfigurations.alcantara.system --dry-run
nix build .#darwinConfigurations.pandoras-box.system --dry-run
nix build .#darwinConfigurations.rocket.system --dry-run
nix build .#nixosConfigurations.nixos.config.system.build.toplevel --dry-run

# Test evaluation
nix eval .#darwinConfigurations.alcantara.config.system.build.toplevel

# Test actual activation (on a test system first!)
darwin-rebuild switch --flake .#alcantara
```

**Known Testing Gaps:**
- ⚠️ This PR was created without access to `nix` command for testing
- ⚠️ Changes need to be validated in a real Nix environment
- ⚠️ Relative paths (../../config/) need verification
- ⚠️ Activation scripts need testing
- ⚠️ Home-manager integration needs verification

## 📚 Documentation

See [DENDRITIC-MIGRATION.md](./DENDRITIC-MIGRATION.md) for:
- Complete architecture overview
- How to add new features
- Benefits and rationale
- Usage examples
- Resources

## 🔄 Migration Path

### Adding New Features

1. Create a feature module in `nix/modules/`:

```nix
# nix/modules/example.nix
{inputs, ...}: let
  exampleModule = {pkgs, lib, config, ...}: let
    cfg = config.my.modules.example;
  in {
    options.my.modules.example.enable = lib.mkEnableOption "example";
    config = lib.mkIf cfg.enable {
      # Your config here
    };
  };
in {
  flake.modules.darwin.example = exampleModule;
  flake.modules.nixos.example = exampleModule;
}
```

3. Enable in hosts as needed

### Disabling Features

Hosts can disable features enabled by default:

```nix
my.modules = {
  discord.enable = lib.mkForce false;  # Disable completely
  # OR
  discord.enable = false;              # If not using mkDefault
};
```

## 🔗 Resources

- [Dendritic Pattern](https://github.com/mightyiam/dendritic)
- [flake-parts Documentation](https://flake.parts/)
- [import-tree](https://github.com/vic/import-tree)
- [Dendritic Design Guide](https://github.com/Doc-Steve/dendritic-design-with-flake-parts)

## 🎉 Result

The configuration now has:
- ✅ Clean separation of concerns (features, system, hosts)
- ✅ Auto-discovery of all modules
- ✅ Aspect-oriented organization
- ✅ Feature-based architecture
- ✅ Single file per host and feature
- ✅ No specialArgs anti-pattern
- ✅ Cross-platform compatibility

This migration sets a solid foundation for future improvements and makes the configuration more maintainable and understandable.
