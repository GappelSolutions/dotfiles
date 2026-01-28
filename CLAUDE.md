# Dotfiles

Personal dotfiles managed with GNU Stow for the Angular + .NET development stack.

## Stow Usage

```bash
# Apply all dotfiles
stow -v -R -t ~ *
```

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

For project layouts (e.g., `easyasset.kdl`):

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
