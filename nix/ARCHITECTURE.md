# Dotfiles Architecture

The repo is moving toward host-specific entrypoints over shared
  modules.## Hosts

  - `hosts/macbook`: full
  macOS
  workstation.It
  may
  contain
  GUI
  apps, Homebrew,
launchd agents, macOS defaults, quarantine workarounds, and private local
tool paths.
- `hosts/dev`: clean NixOS VM. It should stay server/thin-client friendly:
SSH, Tailscale, CLI tools, shell, editor, and shared dotfiles only.
- `hosts/desktop`: current NixOS desktop host family. It is a real
laptop/desktop system, not a thin client: Hyprland, Caelestia shell,
NetworkManager, Bluetooth, printing, PipeWire, power/battery, Lenovo laptop
keys, clipboard history, keyboard layouts, monitor support, Codex CLI, and a
browser for auth. It may also carry explicit desktop workloads that are
already required, such as the Dockur Windows/CareLink VM. Keep it minimal and
declarative.
- `hosts/desktop/cgpp-t14/recovery-configuration.nix`: fresh-install variant
used by the recovery USB. It avoids generated UUID hardware config and is
paired with the Disko layout in `disko/cgpp-t14.nix`.
- Windows is a VM workload on the NixOS desktop, not a native partition. The
restore/start automation lives in `scripts/cgpp-windows`.

## Shared Modules

Shared modules must avoid host-specific assumptions:

- no `/Users/cgpp`
- no `/opt/homebrew`
- no `/Applications`
- no `launchd`
- no Homebrew
- no GUI apps
- no Darwin-only package paths

Use host modules to provide platform-specific environment values and packages.

## Darwin Modules

The Mac Home Manager setup is split by responsibility:

- `modules/darwin/home-packages.nix`: Mac workstation packages and custom
local packages.
- `modules/darwin/home-shell.nix`: zsh, path, aliases, prompt, editor helpers,
and interactive shell glue.
- `modules/darwin/home-programs.nix`: declarative CLI program config such as
git, ssh, direnv, bat, and lazygit.
- `modules/darwin/home-launchd.nix`: user launch agents and Mac background
workarounds.
- `modules/darwin/home-files.nix`: linked dotfiles, scripts, and created
directories.

The root `home.nix` is now a compatibility wrapper for the Mac host.

## Neovim

Keep Neovim Lua portable first. Nixvim may be useful later, but porting Neovim
and splitting hosts at the same time makes failures harder to isolate.

Platform-specific tool paths should be injected by the host environment, not
hardcoded in Lua. Examples: `DOTNET_ROOT`, `NETCOREDBG_PATH`, and shell paths.

## Migration Order

1. Keep the current Mac host working through compatibility imports.
2. Make the dev VM reproducible from `nixosConfigurations.dev`.
3. Move Mac GUI/workaround pieces into Darwin-only modules.
4. Extract more shared CLI and dotfiles from the Mac modules when stable.
5. Keep the desktop host as a separate NixOS host family, reusing shared CLI
modules but keeping graphical/session services in desktop-specific modules.
6. Keep Windows restore as a Dockur VM workflow managed by `cgpp-windows`.

## Current Audit

The broad architecture is in place:

- `hosts/*` are thin entrypoints.
- NixOS server/dev logic is separate from desktop logic.
- Desktop system modules are split by responsibility: base, boot, networking,
  Hyprland/session, audio, Bluetooth, printing, power, Lenovo hardware, and the
  Windows VM.
- Desktop Home Manager modules are separate from system modules: Hyprland user
  config, Caelestia, ownCloud, shortcuts, and Windows VM helpers.
- The recovery path is declarative: `cgpp-recovery-iso` boots the installer,
  `cgpp-t14-recovery` installs the host with Disko, and `cgpp-windows` restores
  the Windows VM image without using symlinks for `data.img`.

Known gaps to clean up after the login/welcome work:

- Darwin does not yet reuse the shared CLI module. It intentionally has its own
  packages, shell, and program modules, but there is duplicated Git, direnv,
  fzf, bat, package, prompt, and Zellij logic that should be reconciled.
- Shared CLI is now split into session, packages, program config, Bash, and Zsh
  modules. The next refinement is to split `home-zsh.nix` into aliases, prompt,
  navigation helpers, and Zellij helpers after the welcome flow is stable.
- `modules/desktop/home-caelestia.nix` contains a large inline color scheme.
  Move theme data to a data file or dedicated theme module if it grows further.
- `modules/desktop/home-hyprland.nix` is the largest desktop behavior module.
  It is still cohesive enough for now, but keybindings and app integrations are
  good future split points.
