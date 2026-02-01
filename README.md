# Dotfiles

Personal dotfiles for macOS (Angular + .NET development stack).

## Quick Setup

```bash
curl -fsSL https://raw.githubusercontent.com/GappelSolutions/dotfiles/main/nix/bootstrap.sh | bash
```

This sets up a fully declarative system with nix-darwin, home-manager, and agenix for secrets. See [nix/README.md](nix/README.md) for details.

## Post-Setup: Manual Permissions

macOS requires manual approval for certain app permissions. **The setup will appear complete but these apps won't work properly until you grant permissions.**

Open **System Settings > Privacy & Security** and grant the following:

| App | Permission | What breaks without it |
|-----|------------|------------------------|
| Alacritty | Accessibility | Karabiner keybindings won't work in terminal |
| AeroSpace | Accessibility | Window management won't work |
| Karabiner-Elements | Accessibility | Key remapping won't work at all |
| Karabiner-Elements | Input Monitoring | Key remapping won't work at all |
| Raycast | Accessibility | Window management, snippets won't work |
| Flameshot | Screen Recording | Cannot capture screenshots |

### How to grant permissions

1. Open **System Settings** (Cmd+Space, type "System Settings")
2. Go to **Privacy & Security** (left sidebar)
3. For each permission type:
   - Click the permission (e.g., "Accessibility")
   - Click the **+** button or toggle the app on
   - You may need to unlock with your password (click the lock icon)
4. **Restart the app** after granting permissions

### First-launch prompts

Some apps will prompt automatically on first launch - click "Open System Settings" when prompted and toggle them on. If you dismissed the prompt, find the app manually in the lists above.

### Legacy (Stow-based)

```bash
curl -fsSL https://raw.githubusercontent.com/GappelSolutions/dotfiles/main/init.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/GappelSolutions/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles
./init.sh
```

## Manual Stow

Apply all dotfiles:

```bash
stow -v -R -t ~ */
```

Apply specific packages:

```bash
stow -t ~ zsh nvim alacritty
```

## Packages

| Package | Description |
|---------|-------------|
| `aerospace` | Tiling window manager config |
| `alacritty` | Terminal emulator config |
| `claude` | Claude Code settings, commands, and MCP config |
| `jetbrains` | JetBrains IDE keymaps |
| `lazygit` | Git TUI config |
| `mcphub` | MCP Hub server config |
| `nvim` | Neovim config (LazyVim-based) |
| `raycast` | Raycast settings export (manual import required) |
| `vim` | Minimal .vimrc |
| `vscode` | VS Code keybindings |
| `yazi` | File manager config |
| `zellij` | Terminal multiplexer config and layouts |
| `zsh` | Shell config with custom prompt |

## What init.sh Installs

- **CLI tools**: git, stow, neovim (via bob), zsh, fzf, ripgrep, fd, bat, eza, zoxide, lazygit, yazi, zellij, btop, k9s
- **Development**: node, pnpm, dotnet, rust, angular-cli, flutter, docker, colima
- **GUI apps**: alacritty, aerospace, obsidian, postman, android-studio
- **Fonts**: Fira Code Nerd Font, Hack Nerd Font, SF Mono, SF Pro

## Zellij Layouts

Tabs organized by keyboard position for ergonomic access:

```
Left hand (primary):     1  2  3      → Main development
Middle (utility):              4  5  6  7  8  → Misc/scratch, time tracker at 6
Right hand (secondary):                    9  0  → Backend
```

## References

- [Arch-Hyprland](https://github.com/JaKooLit/Arch-Hyprland) - Base for Linux setup
