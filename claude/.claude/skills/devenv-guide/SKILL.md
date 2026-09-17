---
name: devenv-guide
description: Best practices for devenv.sh (devenv.nix/devenv.yaml), direnv integration, secretspec secret management, and combining them with a checked-in non-secret .env. Use when creating or reviewing a devenv.nix/devenv.yaml/.envrc/secretspec.toml, wiring up processes/ports/services, or deciding where a secret vs env var belongs.
---

# devenv.sh + secretspec + .env

## Structure

- `devenv.nix` is `{ pkgs, config, ... }: { ... }` — keep `...` as catch-all, don't enumerate inputs.
- `env = { ... }` for shell-visible vars; `packages = [ ... ]` for tool availability; `dotenv.enable = true` loads `./.env` on top of `env`.
- `enterShell` is fine for a handful of lines (print URLs, render a config file). Once it grows into ordered/parallel steps, migrate to `tasks` — that's what they're for (dependencies, ordering, parallel execution), `enterShell` is not.
- `devenv info` shows what's actually active (resolved env, packages, processes) — use it instead of guessing when something isn't behaving.

## Processes & ports

- devenv 2.0 changed the **default** process manager to `native` (was `process-compose`). Pin `process.manager.implementation` explicitly (`mprocs`, `overmind`, `honcho`, `hivemind`, `process-compose`) rather than relying on the default — protects against behavior shifting under you on upgrade.
- `processes.<name>.ports.<port>.allocate = <base>` walks up from `base` until a free port is found; read the resolved value via `config.processes.<name>.ports.<port>.value`. This exists so parallel checkouts of the same repo (worktrees, parallel CI runs) don't collide on fixed ports. Consume the resolved value everywhere downstream (compose files, generated app config) instead of hardcoding the base port.
- `strict_ports: true` (devenv.yaml or `--strict-ports`) turns allocation into a hard fail instead of silently walking to the next free port — turn this on in CI where a silent port shift would be confusing to debug.
- Cross-process ordering: `processes.X.after = [ "devenv:processes:Y@ready" ]` (default suffix), `@started` (just wait for exec, soft), `@completed` (non-propagating). Prefer this over a process self-probing another process's port in a retry loop — same effect, more explicit intent.

## secretspec

- `devenv.yaml`: `secretspec.enable/provider/profile`. Override without editing the file via `devenv --secretspec-provider dotenv --secretspec-profile dev shell` or env vars `SECRETSPEC_PROVIDER`/`SECRETSPEC_PROFILE` (devenv 2.0+) — use this in CI to force `provider: env` rather than branching the yaml.
- **Profile inheritance is the sanctioned pattern**: named profiles inherit from `[profiles.default]` unless overridden. So `required = true` in `default` + `default = "..."` in a `dev` profile means "real secret required in prod, hardcoded convenience value for local dev" — not a workaround, this is documented intended usage.
- Read in devenv.nix as `config.secretspec.secrets.NAME or "fallback"`.
- Providers: `env`, `dotenv`, `keyring`, `1password`, `lastpass`, plus vault/AWS Secrets Manager/etc (11 total, see secretspec.dev). Only names/descriptions belong in `secretspec.toml` (tracked in git) — never real secret values.
- `{ type = "password", generate = true }` lets secretspec auto-generate a value instead of hardcoding one — use when the dev-profile value doesn't need to be predictable across machines; a fixed string is still fine when predictability (e.g. a known local login) matters more than randomness.
- Known tension worth flagging, not fixing: secretspec's own docs favor apps reading secrets at runtime via its SDK (least-privilege, avoids leaking via `env | grep` to arbitrary subprocesses). devenv's `config.secretspec.secrets.X` wiring pushes the value into shell `env{}` instead — that's inherent to how devenv integrates it, fine for placeholder/dev values, but don't assume it gives SDK-level isolation if a *real* secret ever gets routed through the same path for a prod profile.

## .env / direnv

- `.env` should only ever hold non-secret, dotenv-loaded values (`dotenv.enable = true`). Secrets go through secretspec's `env{}` wiring, not `.env`.
- Modern `.envrc`: `eval "$(devenv direnvrc)"` then `use devenv` — self-updating. A `source_url ... <pinned-sha>` line is the legacy pattern; upgrade it if seen.
- `devenv init` gitignores `.direnv/` (direnv cache) and `.devenv/` (devenv build cache) — both should stay out of git. `devenv.lock` is the opposite: it pins nixpkgs + devenv module inputs and **should be committed** — that's where the reproducibility guarantee actually lives, not in devenv.nix.
- First clone always needs `direnv allow` once — deliberate trust gate, not a bug.
- direnv isn't required: `devenv shell` / `devenv hook` give native shell integration without it.

## Testing / CI

- `enterTest` runs after processes start and before they stop; `devenv test` drives the full start/test/stop lifecycle. `wait_for_port <port> <timeout>` helper is available for waiting on a process before asserting against it.
- `config.devenv.isTesting` + `lib.optionalAttrs (!config.devenv.isTesting)` to skip processes irrelevant to a given test run (e.g. skip a frontend dev server during backend-only integration tests).
- Monorepos compose multiple `devenv.nix` files via `devenv.yaml` `imports:` — the documented pattern, reach for it before inventing a custom multi-project setup.

## Sources

- https://devenv.sh/basics/
- https://devenv.sh/processes/
- https://devenv.sh/getting-started/
- https://devenv.sh/integrations/direnv/
- https://devenv.sh/integrations/secretspec/
- https://devenv.sh/tests/
- https://devenv.sh/blog/2026/03/05/devenv-20-a-fresh-interface-to-nix/
- https://secretspec.dev/
