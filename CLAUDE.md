# Dotfiles

Personal dotfiles for every machine: **nix-darwin / NixOS + home-manager + agenix**, one flake in `nix/`.

## Nix Flake Rules

Flakes only see git-tracked files. `git add` new files/directories BEFORE rebuilding, or you get
`error: Path 'X' in the repository is not tracked by Git`.

## Daily Usage

```bash
rb                       # rebuild + switch this host (macOS: nix-darwin; NixOS: attr = hostname)
rbw                      # WSL: rebuild + switch nixosConfigurations.wsl
rollback                 # NixOS/WSL: back to the previous generation
nix/scripts/check-hosts  # evaluate EVERY host (incl. the Mac) from any machine -- run before pushing
win-host/sync.sh         # Windows-native configs: status (default) | diff | pull | push
```

NixOS/WSL hosts run a daily `update-flake-lock` timer: bumps the lock, builds, switches, and
commits `nix/flake.lock` on success (never pushes).

Fresh Mac: `curl -fsSL https://raw.githubusercontent.com/GappelSolutions/dotfiles/main/nix/bootstrap.sh | bash`

## Hosts

| Host | Flake attr | Notes |
|------|------------|-------|
| MacBook | `darwinConfigurations.Christians-MacBook-Pro` | nix-darwin + Homebrew |
| WSL (Windows laptop) | `nixosConfigurations.wsl` | NixOS-WSL; Windows side via `win-host/` |
| ThinkPad T14 | `nixosConfigurations.cgpp-t14-nix` (`-lite`: no Caelestia) | Hyprland desktop, users `cgpp` + `wife`; `cgpp-t14-recovery` / `cgpp-recovery-iso` for recovery |
| dev, minix, nix-cc | `nixosConfigurations.<name>` (`minix-iso` installer) | headless servers; nix-cc user is `cga` |

Shared files must work on every host that deploys them. Host-specific bits go in the host module,
behind a runtime check (e.g. `nix/scripts/zellij-copy`), or in a per-host override that imports a
shared base (e.g. Alacritty `base.toml`).

## Structure

Top-level dirs mirror `$HOME` (`<tool>/.config/<tool>/...`) and are deployed by home-manager as
read-only symlinks — edit here, never the deployed file.

```
nix/
├── flake.nix                 # all hosts
├── hosts/<host>/             # per-host system + home config (desktop/cgpp-t14 for the T14)
├── modules/shared/           # home-manager modules used by several hosts (home-*.nix)
├── modules/{darwin,desktop,nixos}/  # platform modules
├── pkgs/  rust/              # own packages (agent-of-empires, codex, opencode, zellij-welcome, ...)
├── scripts/                  # check-hosts, update-flake-lock, zellij-copy, browser-scratch, ...
├── secrets/                  # agenix-encrypted secrets
└── bootstrap.sh              # fresh machine setup

claude/      # Claude Code: CLAUDE.md, settings.json, statusline, skills/
codex/       # Codex skills
t3/          # T3 Code settings.json (seeded, not managed) + projects.txt UUID map
win-host/    # Windows-native configs + sync.sh (copied, not symlinked)
windows/     # Dockur Windows VM for the T14 (medtronic.md: CareLink setup inside it)
wife/        # helper script + cheatsheet for the T14 `wife` user
zellij/      # config.kdl, per-project layouts/, plugins/
nvim/ vim/ alacritty/ yazi/ lazygit/ lazyops/ k9s/   # shared CLI/terminal configs
aerospace/ jetbrains/ vscode/                        # macOS only
```

Not deployed by nix: `karabiner/`, `init.sh` (pre-nix setup), `archive/`, `tmp`. The pre-nix Stow
setup lives on the `stow` branch.

## Secrets

agenix with an age master key at `~/.age/master.key` (passphrase-protected backup
`~/.age/master.key.age`); secrets are decrypted at activation time to `/run/agenix/`.

## Zellij Layouts

One layout per project in `zellij/.config/zellij/layouts/<project>.kdl` (+ `.swap.kdl`). Tabs are
named by number key: `1-aoe` (agents), `2-nvim`, `3-tools`, then empty `4`–`0`.
