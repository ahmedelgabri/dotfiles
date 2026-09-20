# Upstream dotfiles adaptations

## Sandbox image builds

`sb build-image` builds under a staging name, verifies package health, English locales, SSH configuration, and the installed Git, Jujutsu, Node, Claude, and Pi executables before publishing the base. Locale generation runs after package installation and persists the choices in debconf. SSH keepalives bound unresponsive connections, and error traps report the failing command, line, and status.

`sb build-image --force` keeps the existing base until the replacement has passed verification and shut down. Publication renames the previous base aside, renames the staged image into place, and deletes the previous image only after success. A failed promotion restores the previous base name. Running bases cannot be replaced.

Failed or interrupted builds stop and retain the staging VM instead of deleting the evidence. The failure output includes commands to start, connect to, and discard that VM. Inspect it with `tart run --no-graphics <name>` and `ssh admin@$(tart ip <name>)`, using the disposable guest password `admin`. Delete it when finished with `tart delete <name>`.

The implementation keeps our project-oriented commands, registry behavior, and graceful successful shutdown. It adapts the verification and failure-handling ideas from [Wincent's VM manager](https://github.com/wincent/wincent/blob/df97b31ef8699f243e219b3aaf51b81f5f056c55/bin/vm) rather than replacing `sb`.
