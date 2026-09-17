# Toolchain: Bun, devenv/Nix, CI parity

## Bun, exclusively

- Never `npm install`/`pnpm install`; `bunx` in place of `npx`.
- `bun install` alone is sufficient for everything except e2e — no postinstall hook
  fetches Playwright's browser binaries, Bun or otherwise.
- All dependency versions are **exact-pinned** (no `^`/`~`) — enforced by
  `bunfig.toml`'s `exact = true`, not just convention.
- `bunfig.toml` also blocks `bun add`/`bun install` of any package version published
  within the last 3 days (`minimumReleaseAge`) and runs Socket.dev malware/typosquat
  scanning on every install. A same-day patch that's genuinely needed requires
  `bun install --minimum-release-age=0` — don't reach for this to silence a scan
  finding without checking why it fired.
- Nx is a plain `package.json` devDependency, not a separate install. Everyday
  commands are the `bun <script>` shortcuts (`nx:build`/`nx:test`/`lint`, named that
  way — not `build`/`test` — because Bun permanently reserves those bare words for
  its own bundler/test runner); anything else goes through `bunx nx ...`.

## devenv/Nix + Playwright

- `.envrc`/direnv wires `devenv shell` automatically in an interactive shell.
  **A non-interactive shell (agent Bash tool included) does not auto-load direnv** —
  a devenv-installed var like `PLAYWRIGHT_BROWSERS_PATH` won't be set there. Prefix
  with `devenv shell -- <command>` (e.g. `devenv shell -- bun e2e`), or install
  Playwright's browsers manually with `bunx playwright install` once and skip devenv
  for that command.
- `devenv tasks run gdm-ui:<install|dev|build|test|lint|e2e>` mirrors the `bun`
  commands 1:1 and is what CI (`infrastructure/azure-pipelines.yml`) actually
  invokes — reach for this over the raw `bun`/`bunx nx` command when trying to
  reproduce a CI failure locally. `devenv tasks run cicd:dry` replays the full
  lint → test → build → e2e pipeline in order.

## Formatting/lint gate

`bun format:check` (Prettier, check-only) is what CI runs — it fails the build on
drift, so run `bun format` (write) before committing, not after CI flags it.

Generated files (`apps/gdm-ui/src/app/i18n-keys.generated.ts`, and any future
`bun gen` API client once `kit-auth` gets a real contract) belong in
`.prettierignore`, not the formatted tree — hand-formatting generator output just
churns the diff on every regeneration.
