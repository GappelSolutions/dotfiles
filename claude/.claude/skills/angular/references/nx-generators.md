# Scaffolding: generators, tags, boundaries, i18n

## Always use the `bun g:*` wrappers, never the bare generator

| Command                                                     | Produces                                          | Notes                                                                                                                                           |
| ----------------------------------------------------------- | ------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `bun g:my-app <name>`                                       | `libs/my-app/<name>`                              | scope tag `scope:<name>`, prefix `app`                                                                                                          |
| `bun g:myorg <name> <data-access\|ui\|util>`                | `libs/myorg/<name>`                               | `scope:myorg` + `type:<type>` tags, prefix `org`; type is a plain positional, not `--type=`                                                     |
| `bun g:kit-ui <primitive>`                                  | `libs/myorg/kit-ui/<primitive>`                   | via `@spartan-ng/cli:ui`, tags `type:ui,scope:myorg`, keeps Spartan's own `hlm` prefix                                                          |
| `bun g:component <my-app\|myorg>/<domain>/<...path>/<name>` | component inside an _existing_ domain             | resolved relative to that project's `src/lib`; folder-per-file (`<name>/<name>.ts`), no style file (Tailwind, `nx.json` defaults `style: none`) |
| `bun g:service <my-app\|myorg>/<domain>/<...path>/<name>`   | `*.service.ts` inside an existing domain          | flat in `src/lib`, no folder; always suffixed `.service`                                                                                        |
| `bun g <generator> ...`                                     | anything else (directive, pipe, Storybook config) | escape hatch straight to `nx generate`, minus the placeholder `README.md` it would otherwise leave                                              |

`g:my-app`/`g:myorg` also unconditionally scaffold `<domain>/i18n/{en,de}.json` (empty
stub) and rerun `scripts/i18n-keys-gen.cjs`. If a domain never ends up needing
translations: `rm -rf <domain>/i18n && bun i18n`.

`g:service` computes `--project=` itself: a `my-app` domain's Nx project name is
prefixed (`my-app-<domain>`), a `myorg` domain's is not (`kit-state`, not
`myorg-kit-state`) — check any `project.json`'s `name` if unsure.

`bunx nx list @nx/angular` lists every generator; `bunx nx show project <name> --web`
lists a project's available targets.

## Tags and `@nx/enforce-module-boundaries` (root `eslint.config.mjs`)

Every `libs/myorg/*` project carries `scope:myorg` + a `type:*` tag
(`data-access`/`ui`/`util`; the Storybook host is `scope:kit-ui`, no `type:*` — it's
a doc host, not a foundational util). Every `libs/my-app/<domain>` carries
`scope:<domain>`.

Layering (AND across every tag a project has, not OR — a project can't dodge a
stricter rule by also carrying a looser tag):

```
type:data-access → data-access, ui, util
type:ui          → ui, util
type:util        → util
scope:myorg      → scope:myorg            (shared foundation never depends on app code)
scope:kit-ui     → scope:myorg            (docs host depends only on what it documents)
scope:<domain>   → scope:myorg, scope:<domain>
```

## Lazy-loaded deep imports vs. the boundary rule

A component meant to be lazy-loaded gets its own `tsconfig.base.json` path instead
of being re-exported from the lib's `index.ts` barrel — _if and only if_ something
else in the same lib is imported eagerly (otherwise the eager barrel import drags
the lazy component into the main bundle too). `@nx/enforce-module-boundaries`
reasons at whole-project granularity: once anything dynamically imports such a deep
path, every other static import from that project gets flagged as a regression. Fix
that at the project level — add the project to root `eslint.config.mjs`'s
`checkDynamicDependenciesExceptions` — not with a per-call-site
`eslint-disable-next-line`.

## i18n scoping (generator side effect)

- Scope name = the owning project's folder name (`libs/my-app/home/i18n` → scope `home`).
- Flat `en.json`/`de.json`, no nesting, no repeating the scope name inside the file.
- Owning component declares the scope: `providers: [provideTranslocoScope('home')]`;
  template still just uses `{{ 'home.welcome' | transloco }}`.
- Unscoped app-shell strings (`app`, `common`, `nav`) live directly in
  `apps/my-app/public/i18n/*.json` — not project-owned.
- Never bundled into a lib's build output — served over HTTP by whichever app hosts
  the feature, via one `assets` glob per scope in that app's `project.json`.
- `bun i18n` regenerates `apps/my-app/src/app/i18n-keys.generated.ts` from every
  `i18n/en.json`; `bun i18n:check` is the CI staleness/missing-key gate.
