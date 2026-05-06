# Dotfiles Architecture

The repo is moving toward host-specific entrypoints over shared modules.

## Hosts

- `hosts/macbook`: full macOS workstation. It may contain GUI apps, Homebrew,
  launchd agents, macOS defaults, quarantine workarounds, and private local
  tool paths.
- `hosts/dev`: clean NixOS VM. It should stay server/thin-client friendly:
  SSH, Tailscale, CLI tools, shell, editor, and shared dotfiles only.
- `hosts/windows`: future Windows setup should be separate. Prefer a small
  bootstrap script for Windows Terminal, winget, PowerShell, WSL, and SSH
  rather than forcing Windows into the Nix module shape.

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
5. Add Windows as a separate bootstrap path later.
