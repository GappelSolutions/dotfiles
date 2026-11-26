---
name: hitch-share
description: Publish a self-contained HTML page (or a folder with an index.html) on play.hitch.ensor.test and return the link, readable without a login. Use when the user wants to share, send, show or upload a page, report or mockup to colleagues via play.hitch / hitch.
argument-hint: "<file.html | dir> [name]"
---

Run `~/.claude/skills/hitch-share/hitch-share <file.html | dir> [name]`. It logs in to agents.hitch.ensor.test as the user, uploads the files to `/workspace/sites/<name>/` in their hitch workspace (a single file becomes `index.html`; files there that the source no longer has are removed), publishes the site and prints its link and expiry. The name defaults to the file or folder name and must match `[A-Za-z0-9][A-Za-z0-9._-]{0,63}`.

- **Same name, same link.** A re-publish replaces the snapshot and keeps the `/s/<id>/` link. Pick a fresh name for a separate page. Before reusing a name you didn't create in this session, check with the user, since it overwrites their published page.
- **Links can't be made up.** A site id is an unforgeable Durable Object id and previews are HMAC-signed. The only way onto play.hitch is publishing through the user's own workspace.
- **Self-contained pages only.** play.hitch serves GET only, so no backend. Inline CSS/JS and images, or ship them in the folder. The server caps files per site, bytes per site and the number of live sites. On a cap error, tell the user which site to unpublish; don't unpublish anything yourself.
- **Credentials.** The login body `{"user": …, "password": …}` is `hitch-agents-login.age` in `~/dev/misc/dotfiles/nix/secrets`, decrypted per run with `~/.age/master.key` and piped straight into the login request. It never goes into a command line, an output or chat. If it's missing, ask with `request_secret` (fields `user`, `password`, `delivery: "file"`) and store it with `jq -n --rawfile u <userfile> --rawfile p <passwordfile> '{user: ($u|rtrimstr("\n")), password: ($p|rtrimstr("\n"))}' | agenix -i ~/.age/master.key -e hitch-agents-login.age` from that directory (the entry is already in `secrets.nix`). The script never logs out, because signing out locks the user's Azure DevOps, OpenBao, OKD and SSH access in hitch.
- **TLS.** The VM's certificate is self-signed and pinned in the script (`HITCH_PIN`). On error 90 (public key does not match), the VM got a new certificate: show the user the new fingerprint and update the pin only once they confirm it.
- Unreachable host (DNS failure, timeout): hitch is VPN-only, see the VPN rule in `~/.claude/CLAUDE.md`.

Reply with the link. `DELETE …/api/company/sites/<name>/publish` unpublishes and `POST …/sites/<name>/renew` extends the expiry; neither runs unless the user asks.
