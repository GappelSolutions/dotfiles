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
- energyboard - Energy management portal
- backoffice - Admin backend systems
- easyasset - Asset tracking platform
- elixir - Elixir projects
- gappel-solutions - Company solutions
- decon - Decon project
- screensaver - Screensaver development
- new - Start a new session
- welcome - Return to this screen

## Integration

The binary is automatically installed to `~/.local/bin/zellij-welcome` via home-manager.

Session shortcuts in zsh (from home.nix):
- `zeb` - energyboard
- `zbo` - backoffice
- `zea` - easyasset
- `zex` - elixir
- `zgs` - gappel-solutions
- `zdc` - decon
- `zsc` - screensaver
