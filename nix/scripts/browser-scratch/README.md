# browser-scratch

A shared, version-pinned Playwright project for ad hoc browser checks that
aren't tied to any specific project's e2e setup (e.g. "does this dev server
render correctly", "click through this flow and tell me what happens").

## Why this exists

Browsers are provided system-wide via home-manager
(`pkgs.playwright-driver.browsers`, see `../../modules/shared/home-packages.nix`),
with `PLAYWRIGHT_BROWSERS_PATH` pointed at the nix store and
`PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1` set globally so npm's `playwright`
package never tries to download its own copy.

That only works if the `playwright` npm package version in play matches the
browser revision nixpkgs actually shipped. `npx playwright@latest` or any
project pinned to a newer `playwright`/`@playwright/test` will resolve a
`playwright-core` that expects browsers this machine doesn't have - and
since downloading is disabled, it just fails. That's the "gets stuck trying
to install playwright" loop.

This project pins `playwright` to the exact version matching the current
`pkgs.playwright-driver.browsers` revision, so there is always a
known-working `playwright` install to fall back to for one-off checks,
with zero download ever required.

## Usage

```bash
cd nix/scripts/browser-scratch
bun install   # one-time per machine; installs the JS package only, no browser download
bun example.mjs http://localhost:4200
```

Copy `example.mjs`'s pattern into a throwaway script (or edit it in place)
rather than reinventing the invocation each time. Never run
`playwright install` / `bunx playwright install` / `npx playwright install`
here or anywhere else - see the Playwright section of the root CLAUDE.md.

## Keeping the version pin correct

If you bump the `nixpkgs` flake input, `pkgs.playwright-driver`'s version can
change. After a `rebuild`, re-sync this project's pin:

```bash
nix eval --raw nixpkgs#playwright-driver.version   # after the rebuild
```

Update `devDependencies.playwright` in `package.json` to match, then
`rm -rf node_modules && bun install`.
