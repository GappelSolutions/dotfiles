# Autonomy

When a step doesn't need my input, keep going. Put status notes in the same message as your next action. Stop and ask only when you can't continue without me, or before anything destructive: deleting data, force-pushing, or changing anything outside this repository.

# Dotfiles

Repo root: `~/dev/misc/dotfiles` (not `~/dev/dotfiles`). Every home-manager-managed config (`~/.claude/`, `~/.config/*`, `~/.codex/`, …) is a read-only symlink into the nix store — edit the source in the repo, never the deployed file, then rebuild (`rbw` on WSL, `rb` elsewhere).

# Nix

New files must be `git add`-ed before rebuilding (flakes only see tracked files), or you get "Path not tracked by Git".

## agenix

The age identity is at `/home/cgpp/.age/master.key` (recipient `age1g6lu0x2...`, named `masterKey`/`cgpp` in the `secrets.nix` files). It is NOT `~/.ssh/id_ed25519` and NOT the machine's `/etc/age/host.key` — agenix's default identity search misses it and fails with "no identity matched any of the recipients", so always pass it explicitly:

```sh
cd <repo>/secrets && agenix -i /home/cgpp/.age/master.key -d <name>.age
```

`agenix` must run from the directory holding `secrets.nix`, and the argument is the filename exactly as keyed there — not a path.

# Playwright

Only use when the user asks for a browser check, or nothing else can verify the behavior — not as a default "let's confirm it works" step. Never run `playwright install` (browsers are provided system-wide, download is disabled on purpose).

- Project already has `playwright`/`@playwright/test`: use its own install/config.
- Ad hoc/no project: use `nix/scripts/browser-scratch/` (git-tracked, pinned to the installed browser revision).
- Prefer `innerText()`/`getComputedStyle` reads over screenshots; script one bounded flow and stop; always `browser.close()`.
