# Dotfiles

Personal workstation config. Current path is Nix first:

- macOS: `nix-darwin` + Home Manager + Homebrew.
- NixOS: host configs for `dev` and `cgpp-t14-nix`, plus shared Home Manager
  CLI/dotfiles.
- WSL: use plain Nix for now; no dedicated `hosts/wsl` flake output yet.

## macOS

Fresh Mac:

```bash
curl -fsSL https://raw.githubusercontent.com/GappelSolutions/dotfiles/main/nix/bootstrap.sh | bash
```

Rebuild after changes:

```bash
cd ~/dev/misc/dotfiles/nix
darwin-rebuild switch --flake .#Christians-MacBook-Pro
# or: rb
```

After first build, grant macOS permissions in System Settings:

- Alacritty, AeroSpace, Karabiner-Elements, Raycast: Accessibility.
- Karabiner-Elements: Input Monitoring.
- Flameshot: Screen Recording.

## NixOS

This repo exposes a thin NixOS host, `dev`, the current ThinkPad desktop host
`cgpp-t14-nix`, and recovery outputs for rebuilding the ThinkPad from USB.

```bash
git clone https://github.com/GappelSolutions/dotfiles.git ~/dev/misc/dotfiles
cd ~/dev/misc/dotfiles/nix
sudo nixos-rebuild switch --flake .#dev
# or after activation: rb
```

`dev` is meant as a clean VM/thin dev host: SSH, Tailscale, Podman, Samba,
CLI tools, shell, Neovim, Zellij, and shared dotfiles.

The desktop host is the current ThinkPad NixOS system:

```bash
cd ~/dev/misc/dotfiles/nix
sudo nixos-rebuild switch --flake .#cgpp-t14-nix
```

The recovery USB and Windows VM restore runbook is in
[nix/NIX_DESKTOP_PLAN.md](nix/NIX_DESKTOP_PLAN.md).

Build the recovery ISO:

```bash
cd ~/dev/misc/dotfiles/nix
nix build .#nixosConfigurations.cgpp-recovery-iso.config.system.build.isoImage
```

From the recovery environment:

```bash
sudo cgpp-install tui
```

## WSL

WSL is not a flake host yet. Current minimal setup:

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
mkdir -p ~/dev/misc
git clone https://github.com/GappelSolutions/dotfiles.git ~/dev/misc/dotfiles
cd ~/dev/misc/dotfiles
```

Use the shared configs manually until a `hosts/wsl` output exists. Keep Windows
Terminal, PowerShell, winget, and WSL bootstrap separate from the NixOS/Darwin
module tree.

## Repo Map

```text
nix/flake.nix                 flake entrypoint
nix/hosts/macbook/            macOS host
nix/hosts/dev/                NixOS dev host
nix/hosts/desktop/cgpp-t14/   ThinkPad desktop and recovery install host
nix/disko/                    Disko layouts for fresh installs
nix/modules/darwin/           macOS-only modules
nix/modules/nixos/            NixOS-only modules
nix/modules/desktop/          NixOS desktop services and Hyprland/Caelestia
nix/modules/shared/           portable CLI + dotfile modules
nix/scripts/cgpp-install      Recovery USB installer/TUI
nix/scripts/cgpp-windows      Windows VM restore/start/TUI
nix/secrets/                  encrypted SSH key material for macOS
windows/.config/windows/      Dockur Windows compose for CareLink
wife/                         shortcut reference helper and cheatsheet
nvim/ zellij/ alacritty/      source dotfiles linked by Home Manager
```

## Rules

- New files used by flakes must be tracked before rebuild: `git add <path>`.
- Put portable CLI/dotfile behavior in `nix/modules/shared`.
- Keep macOS GUI, Homebrew, launchd, `/Applications`, and `/Users/cgpp` paths in
  Darwin modules.
- Keep NixOS/VM services in NixOS modules.
- Keep graphical laptop services in `nix/modules/desktop`.

More detail: [nix/ARCHITECTURE.md](nix/ARCHITECTURE.md).
Recovery USB plan: [nix/NIX_DESKTOP_PLAN.md](nix/NIX_DESKTOP_PLAN.md).
