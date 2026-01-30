# Dotfiles

Personal dotfiles managed with GNU Stow for macOS (Angular + .NET development stack).

## Quick Setup

Bootstrap a fresh macOS machine:

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
