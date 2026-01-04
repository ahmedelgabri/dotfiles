# Dendritic Pattern Migration - COMPLETED ✅

This document describes the completed migration to the [Dendritic Pattern](https://github.com/mightyiam/dendritic) - an architectural approach for organizing Nix configurations using flake-parts where **every file is a flake-parts module**.

## What is the Dendritic Pattern?

The Dendritic Pattern treats each `.nix` file as a top-level flake-parts module. Instead of separating code by configuration type (NixOS, nix-darwin, home-manager), you organize by **feature** or **aspect**. Each module can contribute to multiple configuration types simultaneously.

### Core Principles

1. **Every file is a flake-parts module** - auto-discovered via import-tree
2. **Feature modules** define `flake.modules.{darwin,nixos,homeManager}.<name>`
3. **Host modules** import features via `inputs.self.modules.*`
4. **No specialArgs anti-pattern** - access modules directly
5. **Cross-cutting concerns** - one file can configure multiple systems
6. **Aspect-oriented organization** - organize by feature, not by platform

## Final Architecture

```
├── flake.nix                    # Auto-discovery + mkFlake
├── nix/
│   ├── lib.nix                  # Helper functions (mkDarwin, mkNixos)
│   ├── overlays.nix             # perSystem overlays
│   ├── dev-shells.nix           # perSystem devShells
│   ├── apps.nix                 # perSystem apps
│   │
│   ├── system/                  # System-level modules (7 files)
│   │   ├── user-options.nix         # config.my.* options
│   │   ├── nix-daemon.nix           # Nix daemon config
│   │   ├── state-version.nix        # State version management
│   │   ├── home-manager-integration.nix  # Home-manager setup
│   │   ├── fonts.nix                # Font configuration
│   │   ├── darwin-defaults.nix      # macOS system defaults
│   │   └── feature-defaults.nix     # Default feature enables
│   │
│   ├── features/                # Feature modules (26 files)
│   │   ├── git.nix              # flake.modules.{darwin,nixos}.git
│   │   ├── vim.nix              # flake.modules.{darwin,nixos}.vim
│   │   ├── tmux.nix             # flake.modules.{darwin,nixos}.tmux
│   │   ├── ssh.nix              # flake.modules.{darwin,nixos}.ssh
│   │   ├── gpg.nix              # flake.modules.{darwin,nixos}.gpg
│   │   ├── user-shell.nix       # flake.modules.{darwin,nixos}.shell
│   │   ├── kitty.nix            # Terminal emulator
│   │   ├── ghostty.nix          # Terminal emulator
│   │   ├── yazi.nix             # File manager
│   │   ├── bat.nix              # Better cat
│   │   ├── ripgrep.nix          # Better grep
│   │   ├── mpv.nix              # Media player
│   │   ├── yt-dlp.nix           # YouTube downloader
│   │   ├── mail.nix             # Email (aerc, mbsync, notmuch)
│   │   ├── gui.nix              # GUI applications
│   │   ├── discord.nix          # Discord
│   │   ├── ai.nix               # AI tools (ollama, claude-code)
│   │   ├── zk.nix               # Zettelkasten
│   │   ├── node.nix             # Node.js environment
│   │   ├── python.nix           # Python environment
│   │   ├── go.nix               # Go environment
│   │   ├── rust.nix             # Rust environment
│   │   ├── misc.nix             # Miscellaneous configs
│   │   ├── agenix.nix           # Age encryption
│   │   ├── hammerspoon.nix      # flake.modules.darwin.hammerspoon
│   │   └── karabiner.nix        # flake.modules.darwin.karabiner
│   │
│   ├── hosts/                   # Host configurations (4 hosts)
│   │   ├── alcantara.nix        # aarch64-darwin (personal)
│   │   ├── pandoras-box.nix     # x86_64-darwin (personal)
│   │   ├── rocket.nix           # aarch64-darwin (work - Miro)
│   │   ├── nixos.nix            # x86_64-linux
│   │   └── nixos/               # NixOS-specific config
│   │       ├── default.nix
│   │       ├── dwm.patch
│   │       └── hardware-configuration.nix
│   │
│   ├── pkgs/                    # Custom packages
│   └── secrets/                 # Age-encrypted secrets
```

## How It Works

### 1. Auto-Discovery with import-tree

All modules under `nix/` are auto-discovered using the official [import-tree](https://github.com/vic/import-tree) package:

```nix
# flake.nix
inputs.import-tree.url = "github:vic/import-tree";

outputs = inputs @ {flake-parts, import-tree, ...}:
  flake-parts.lib.mkFlake {inherit inputs;} {
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    imports = [(import-tree ./nix)];  # Auto-discover all modules!
    flake.templates = import ./templates;
  };
```

### 2. Feature Modules

Feature modules define reusable configuration that works across platforms:

```nix
# nix/features/git.nix
{inputs, ...}: let
  gitModule = {pkgs, lib, config, ...}: let
    cfg = config.my.modules.git;
  in {
    options.my.modules.git.enable = lib.mkEnableOption "git module";

    config = lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [git];
      my.user.packages = with pkgs; [delta hub gh tig];
      # ... git config files, etc
    };
  };
in {
  # Define modules for both darwin and nixos
  flake.modules.darwin.git = gitModule;
  flake.modules.nixos.git = gitModule;
}
```

**Key points:**
- Each feature is self-contained
- Shared modules work on both darwin and nixos
- Darwin-only modules (hammerspoon, karabiner) only define `flake.modules.darwin.*`
- Features have **no knowledge of hosts**
- All features use `config.my.modules.<feature>.enable` pattern

### 3. System Modules

System modules provide core configuration and options:

```nix
# nix/system/user-options.nix
{lib, ...}: let
  userOptionsModule = {config, pkgs, options, ...}: {
    options.my = {
      name = mkOptStr "Ahmed El Gabri";
      username = mkOptStr "ahmed";
      email = mkOptStr "ahmed@gabri.me";
      # ... more options
    };
  };
in {
  flake.modules.darwin.user-options = userOptionsModule;
  flake.modules.nixos.user-options = userOptionsModule;
}
```

### 4. Feature Defaults

The `feature-defaults.nix` module sets sensible defaults for which features are enabled:

```nix
# nix/system/feature-defaults.nix
{lib, ...}: let
  featureDefaultsModule = {config, lib, ...}: {
    my.modules = {
      # Core tools enabled by default
      shell.enable = lib.mkDefault true;
      git.enable = lib.mkDefault true;
      vim.enable = lib.mkDefault true;
      # ... more defaults

      # Opt-in features
      mail.enable = lib.mkDefault false;
      gpg.enable = lib.mkDefault false;
      discord.enable = lib.mkDefault false;
    };
  };
in {
  flake.modules.darwin.feature-defaults = featureDefaultsModule;
  flake.modules.nixos.feature-defaults = featureDefaultsModule;
}
```

### 5. Host Configuration

Host modules import system modules, feature-defaults, and external modules:

```nix
# nix/hosts/alcantara.nix
{inputs, ...}: {
  flake.modules.darwin.alcantara = {config, pkgs, ...}: {
    # Import system modules
    imports = with inputs.self.modules.darwin; [
      user-options
      nix-daemon
      state-version
      home-manager-integration
      fonts
      defaults
      feature-defaults  # Enables most features by default
    ];

    # Import external modules
    imports = [
      inputs.home-manager.darwinModules.home-manager
      inputs.nix-homebrew.darwinModules.nix-homebrew
      inputs.agenix.darwinModules.default
    ];

    # Host-specific configuration
    networking.hostName = "alcantara";

    # Override feature defaults or enable opt-in features
    my.modules = {
      mail.enable = true;   # Opt-in
      gpg.enable = true;    # Opt-in
      discord.enable = true; # Opt-in
    };

    # Host-specific packages
    my.user.packages = with pkgs; [amp-cli codex opencode];

    # Host-specific homebrew
    homebrew.casks = ["jdownloader" "signal" "monodraw"];
  };

  # Create the actual darwinConfiguration
  flake.darwinConfigurations =
    inputs.self.lib.mkDarwin "aarch64-darwin" "alcantara";
}
```

### 6. Helper Functions

The `lib.nix` module provides helpers for creating configurations:

```nix
# nix/lib.nix
{inputs, lib, ...}: {
  flake.lib = {
    mkDarwin = system: name: {
      ${name} = inputs.darwin.lib.darwinSystem {
        modules = [
          inputs.self.modules.darwin.${name}
          {nixpkgs.hostPlatform = lib.mkDefault system;}
        ];
      };
    };

    mkNixos = system: name: {
      ${name} = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          inputs.self.modules.nixos.${name}
          {nixpkgs.hostPlatform = lib.mkDefault system;}
        ];
      };
    };
  };
}
```

### 7. perSystem Outputs

Overlays, dev shells, and apps use `perSystem`:

```nix
# nix/overlays.nix
{inputs, ...}: {
  perSystem = {system, ...}: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        inputs.yazi.overlays.default
        inputs.nur.overlays.default
        (final: prev: {
          pragmatapro = prev.callPackage ./pkgs/pragmatapro.nix {};
          hcron = prev.callPackage ./pkgs/hcron.nix {};
          # ... more packages
        })
      ];
    };
  };
}
```

## Migration Summary

### What Changed

**Before:**
```
nix/
├── modules/
│   ├── shared/default.nix       # Imports and defaults
│   ├── shared/git.nix            # Old NixOS module
│   ├── shared/vim.nix            # Old NixOS module
│   ├── shared/...                # 23 more modules
│   └── darwin/default.nix        # Darwin defaults + system config
```

**After:**
```
nix/
├── features/                     # Feature modules (26 files)
│   ├── git.nix                   # flake.modules.{darwin,nixos}.git
│   ├── vim.nix                   # flake.modules.{darwin,nixos}.vim
│   └── ...                       # All features migrated
├── system/                       # System modules (7 files)
│   ├── user-options.nix          # Extracted from old settings.nix
│   ├── nix-daemon.nix            # Extracted from old settings.nix
│   ├── state-version.nix         # Extracted from old settings.nix
│   ├── home-manager-integration.nix  # Extracted
│   ├── fonts.nix                 # Extracted
│   ├── darwin-defaults.nix       # Migrated from darwin/default.nix
│   └── feature-defaults.nix      # NEW - replaces shared/default.nix
└── hosts/                        # Single file per host
    ├── alcantara.nix             # Was: alcantara/{configuration,flake-parts}.nix
    ├── pandoras-box.nix          # Consolidated
    ├── rocket.nix                # Consolidated
    └── nixos.nix                 # Consolidated
```

### Modules Migrated (26 feature modules)

**Shared modules (21)** - work on both darwin and nixos:
- Core: git, vim, tmux, ssh, gpg, user-shell
- Terminal: kitty, ghostty, yazi, bat, ripgrep
- Development: node, python, go, rust
- Applications: gui, mail, discord, ai, zk, mpv, yt-dlp
- Utilities: misc, agenix

**Darwin-only modules (2)**:
- hammerspoon, karabiner

**System modules (7)**:
- user-options, nix-daemon, state-version, home-manager-integration, fonts, darwin-defaults, feature-defaults

### Key Improvements

1. **✅ Single file per feature** - Each feature is self-contained
2. **✅ Auto-discovery** - All modules discovered via import-tree
3. **✅ Aspect-oriented** - Organized by feature, not platform
4. **✅ Single file per host** - No more configuration.nix + flake-parts.nix split
5. **✅ Clean separation** - Features, system, and hosts clearly separated
6. **✅ No specialArgs** - Access modules via `inputs.self.modules.*`
7. **✅ Sensible defaults** - feature-defaults module enables common features
8. **✅ Easy overrides** - Hosts can override with `lib.mkDefault`

## Benefits

### 1. **Aspect-Oriented Organization**

Instead of organizing by platform (darwin/nixos/shared), organize by what it does:
- `features/git.nix` - Git configuration for ALL systems
- `features/vim.nix` - Vim configuration for ALL systems
- `system/nix-daemon.nix` - Nix daemon for ALL systems

### 2. **No Special Args Anti-Pattern**

Features are accessed via `inputs.self.modules.darwin.<name>` instead of passing through specialArgs.

### 3. **Cross-Cutting Concerns**

One file can configure:
- System-level packages (darwin/nixos)
- Environment variables
- Configuration files
- All in one place!

### 4. **Flexibility**

- Easy to rename/move files
- No rigid directory structure
- Organize by mental model
- Easy to refactor

### 5. **Discoverability**

All modules auto-discovered - just add a `.nix` file and it's imported. No manual import lists to maintain.

## Usage

### Building Configurations

```bash
# Darwin systems
nix build .#darwinConfigurations.alcantara.system
nix build .#darwinConfigurations.pandoras-box.system
nix build .#darwinConfigurations.rocket.system

# NixOS systems
nix build .#nixosConfigurations.nixos.config.system.build.toplevel
```

### Activating Configurations

```bash
# Darwin
darwin-rebuild switch --flake .#alcantara

# NixOS
nixos-rebuild switch --flake .#nixos
```

### Verification

```bash
# Check flake validity
nix flake check

# Show flake outputs
nix flake show

# Update lock file
nix flake update
```

## How to Add a New Feature

### 1. Create a feature module:

```nix
# nix/features/example.nix
{inputs, ...}: let
  exampleModule = {pkgs, lib, config, ...}: let
    cfg = config.my.modules.example;
  in {
    options.my.modules.example.enable = lib.mkEnableOption "example module";

    config = lib.mkIf cfg.enable {
      # Your configuration here
      my.user.packages = with pkgs; [example-package];
    };
  };
in {
  # Define for darwin and/or nixos
  flake.modules.darwin.example = exampleModule;
  flake.modules.nixos.example = exampleModule;
}
```

### 2. Add to feature-defaults (optional):

```nix
# nix/system/feature-defaults.nix
my.modules = {
  # ...
  example.enable = lib.mkDefault true;  # Enable by default
  # OR
  example.enable = lib.mkDefault false; # Opt-in only
};
```

### 3. Use in host (if opt-in):

```nix
# nix/hosts/alcantara.nix
my.modules = {
  example.enable = true;  # Override default
};
```

### 4. Done!

The module is auto-discovered, features are enabled by defaults or explicitly, and everything just works.

## Testing Checklist

Before deploying changes:

- [ ] `nix flake check` - Validate flake
- [ ] `nix build .#darwinConfigurations.<host>.system --dry-run` - Test build
- [ ] `nix eval .#darwinConfigurations.<host>.config.system.build.toplevel` - Test evaluation
- [ ] Check for import errors in auto-discovered modules
- [ ] Verify relative paths resolve correctly (../../config/)
- [ ] Test activation scripts work correctly
- [ ] Verify home-manager integration works

## Resources

- [Dendritic Pattern](https://github.com/mightyiam/dendritic) - Original pattern
- [Dendritic Design Guide](https://github.com/Doc-Steve/dendritic-design-with-flake-parts) - Comprehensive guide
- [NixOS Discourse: Every file is a flake-parts module](https://discourse.nixos.org/t/pattern-every-file-is-a-flake-parts-module/61271)
- [flake-parts Documentation](https://flake.parts/)
- [import-tree](https://github.com/vic/import-tree) - Auto-discovery tool

## Migration Commits

1. `refactor(nix): use import-tree and migrate to nix/ directory` - Added import-tree and restructured
2. `refactor(nix): cleanup and break down modules into focused aspects` - Split monolithic settings.nix
3. `fix(nix): properly migrate pandoras-box and rocket host configs` - Fixed broken host imports
4. `feat(nix): complete migration to flake-parts with Dendritic Pattern` - Final migration

## What's Next?

The migration is complete! The configuration now follows the Dendritic Pattern with:
- ✅ Auto-discovery of all modules
- ✅ Aspect-oriented organization
- ✅ Clean separation of concerns
- ✅ Feature-based architecture
- ✅ Single file per host
- ✅ No specialArgs anti-pattern
- ✅ Cross-platform compatibility

Future improvements:
- Consider adding more granular feature modules
- Explore flake-parts options for better module composition
- Document common patterns for contributors
- Add CI/CD testing for configuration builds
