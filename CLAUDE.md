# Dotfiles

Personal dotfiles managed with **nix-darwin + home-manager + agenix**.

## Nix Flake Rules

**IMPORTANT:** Nix flakes only see files tracked by git. When creating or modifying files:
- Always run `git add <path>` for new files/directories BEFORE running `rebuild`
- This applies to any new config directories (e.g., `kanata/`, `karabiner/`)
- Forgetting this causes: `error: Path 'X' in the repository is not tracked by Git`

## Quick Start (Fresh Mac)

```bash
curl -fsSL https://raw.githubusercontent.com/GappelSolutions/dotfiles/main/nix/bootstrap.sh | bash
```

This installs everything: Nix, packages, configs, and decrypts your SSH keys (requires your passphrase).

## Daily Usage

```bash
rb                       # rebuild + switch this host (macOS: nix-darwin; NixOS/WSL: attr = hostname)
rollback                 # NixOS/WSL: back to the previous generation
nix/scripts/check-hosts  # evaluate EVERY host (incl. the Mac) from any machine -- run before pushing
win-host/sync.sh         # Windows-native configs: status (default) | diff | pull | push
```

NixOS/WSL hosts also run a daily `update-flake-lock` timer: bumps the lock, builds,
switches, and commits `nix/flake.lock` on success (never pushes).

## Hosts

| Host | Flake attr | Notes |
|------|------------|-------|
| MacBook | `darwinConfigurations.Christians-MacBook-Pro` | nix-darwin + Homebrew |
| WSL (Windows laptop) | `nixosConfigurations.wsl` | NixOS-WSL; Windows side via `win-host/` |
| ThinkPad T14 | `nixosConfigurations.cgpp-t14-nix` (`-lite`: no Caelestia) | Hyprland desktop |
| dev, minix, nix-cc | `nixosConfigurations.<name>` | headless |

Shared files must work on every host that deploys them. Host-specific bits go in
the host module, or behind a runtime check (e.g. `nix/scripts/zellij-copy`), or in
a per-host override that imports a shared base (e.g. Alacritty `base.toml`).

## Structure

```
dotfiles/
├── aerospace/     # window manager config
├── alacritty/     # terminal config: base.toml shared, alacritty.toml = unix override
├── claude/        # claude code config
├── jetbrains/     # ideavimrc for Android Studio
├── k9s/           # k9s config (Linux ~/.config, macOS Application Support)
├── lazygit/       # lazygit config
├── nix/           # main nix config
│   ├── flake.nix              # flake definition (all hosts)
│   ├── hosts/<host>/          # per-host system + home config
│   ├── modules/shared/        # home-manager modules used by several hosts
│   ├── modules/{darwin,desktop,nixos}/  # platform modules
│   ├── scripts/               # check-hosts, zellij-copy, update-flake-lock, ...
│   ├── darwin-configuration.nix  # macOS system config
│   ├── home.nix               # user packages & dotfiles
│   ├── bootstrap.sh           # fresh machine setup script
│   └── secrets/               # agenix-encrypted SSH keys
├── nvim/          # neovim config
├── t3/            # T3 Code settings.json (seeded, not managed) + projects.txt UUID map
├── vim/           # vim/ideavim config
├── vscode/        # vscode settings
├── yazi/          # file manager config
├── win-host/      # Windows-native configs + sync.sh (copied, not symlinked)
└── zellij/        # multiplexer config
```

## Secrets Management

SSH keys are encrypted with [agenix](https://github.com/ryantm/agenix) using an age master key.

- Master key location: `~/.age/master.key`
- Encrypted backup: `~/.age/master.key.age` (passphrase-protected)
- Secrets are decrypted at activation time to `/run/agenix/`

## Legacy (Stow)

The `stow` branch contains the pre-nix setup using GNU Stow. For non-nix machines:

```bash
git checkout stow
stow -v -R -t ~ alacritty nvim zsh ...
```

---

## Zellij Layout Guidelines

### Tab Organization

Tabs are organized by keyboard position for ergonomic access:

| Group | Tabs | Purpose |
|-------|------|---------|
| Primary | 1, 2, 3 | Main development (frontend) |
| Secondary | 0, 9 | Secondary development (backend) |
| Utility | 4, 5, 7, 8 | Misc/scratch tabs |
| Fixed | 6 | Time tracker (centered) |

### Standard Tab Naming

For project layouts (e.g., `mmgdm.kdl`):

- **1-agent** - Claude Code agents
- **2-front-nvim** - Frontend neovim
- **3-front-tools** - Frontend tools (yazi, dev server, etc.)
- **4** - Empty/scratch
- **5** - Empty/scratch
- **6-time** - Work timer (centered position)
- **7** - Empty/scratch
- **8** - Empty/scratch
- **9-back-tools** - Backend tools (yazi, dotnet run, etc.)
- **0-back-nvim** - Backend neovim

### Keyboard Layout Reasoning

```
Left hand (primary):     1  2  3
Middle (utility):              4  5  6  7  8
Right hand (secondary):                    9  0 (accessed as 0, 9)
```

Tab 6 is the centered position, reserved for the time tracker for quick access.
