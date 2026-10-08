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

New or changed secret: add `"<name>.age".publicKeys = …` to `secrets.nix`, then pipe the value straight from its source: `<source> | agenix -i /home/cgpp/.age/master.key -e <name>.age`. With stdin not a terminal (always, in the Bash tool), agenix reads the secret from stdin and never starts `$EDITOR`. Never type a secret into a command line or chat. If I have to supply it, use `request_secret`.

OpenBao in a cluster: `kbao <oc-context> <bao args>` (root tokens from the `openbao-tokens` secret), never parse tokens out of credential notes.

Personal credentials (Proxmox root password, PATs, SSH keys, pgpass, …) live in `~/dev/misc/dotfiles/nix/secrets/`; its `secrets.nix` comments say which host each one is for. Before telling me you lack access to a machine or service, check there.

# VPN

Work hosts are VPN-only, and I often work offline (train). DNS failures for them, `oc` "Unauthorized" and az `AADSTS70043` mean the VPN or login is down. Say once what's blocked, start a Monitor that polls the host (`until getent hosts <host>; do sleep 30; done`), and keep doing the work that doesn't need it. Don't stop, retry in a loop, or ask again. I turn the VPN back on when I see an agent needs it.

# Playwright

Never run `playwright install` (browsers are provided system-wide, download is disabled on purpose).

- Project already has `playwright`/`@playwright/test`: use its own install/config.
- Ad hoc/no project: use `nix/scripts/browser-scratch/` (git-tracked, pinned to the installed browser revision).
- Prefer `innerText()`/`getComputedStyle` reads over screenshots; script one bounded flow and stop; always `browser.close()`.
