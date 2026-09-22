# Zellij Welcome

A beautiful terminal welcome screen for Zellij session management, built with Ratatui.

## Features

- **Two modes:**
  - Full mode: Beautiful welcome screen with ASCII art, quotes, time/date
  - Minimal mode (`-m`): Compact session picker for small panes

- **Session management:**
  - Auto-cleanup of sessions not matching naming template
  - Attach to existing active sessions or create new ones with timestamps
  - Integrates with zellij-switch.wasm plugin

- **Navigation:**
  - Vim-style: `j`/`k` or arrow keys
  - `Enter` to select
  - `q` or `Esc` to quit

## Build

```bash
./build.sh
```

Or manually:

```bash
cargo build --release
```

Binary will be at `target/release/zellij-welcome`

## Usage

```bash
# Full welcome mode (default)
zellij-welcome

# Minimal mode
zellij-welcome --minimal
zellij-welcome -m
```

## Sessions

Predefined sessions:
- new - Start a new session
- mmgdm - Modular Monolith GDM
- iggy - Iggy POC
- watcher - GDM Watcher
- colony - Multi-agent dev environments
- gappel-solutions - Company solutions
- decon - Decon project
- elixir - Elixir projects
- welcome - Return to this screen

## Integration

The binary is automatically installed to `~/.local/bin/zellij-welcome` via home-manager.

Session shortcuts in zsh (from home.nix):
- `zex` - elixir
- `zgs` - gappel-solutions
- `zdc` - decon
- `zco` - colony
- `zig` - iggy
- `zmm` - mmgdm
- `zwa` - watcher
- `zel` - welcome screen
