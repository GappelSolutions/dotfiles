# State & forms

## State: plain signal services, no state library

- `@Injectable({ providedIn: 'root' })` (see [di.md](di.md)) + `signal()`/`computed()`
  (mechanics in [signals.md](signals.md)). No NgRx, no Elf, no other state library —
  don't introduce one, and don't propose one as a fix for a state-sharing problem.
- Cross-cutting UI state (loading, menu, ...) lives in `libs/ensor/kit-state` — check
  there before adding a new signal service that duplicates something already global.

## Forms: reactive forms + Spartan field primitives

- Angular reactive forms (`FormGroup`/`FormControl`) plus Spartan's field primitives
  (`libs/ensor/kit-ui/field`, `label`, `input`) for markup/validation-state styling.
  No Formly, no Zod/Valibot schema layer on top.
- Static validators (`Validators.required`, `Validators.email`, ...) are passed by
  reference into a form group — that's why `@typescript-eslint/unbound-method` is
  configured with `ignoreStatic: true` in root `eslint.config.mjs`; don't
  `.bind(this)` or wrap them to satisfy a lint error that shouldn't fire here.

## Lib layering reminder

`type:data-access` libs (e.g. `kit-auth`) may reach into `type:ui`/`type:util` for
this — a data-access service is allowed to depend on `kit-ui` field primitives it
renders through. See [nx-generators.md](nx-generators.md) for the full boundary
table if a form/state change trips `@nx/enforce-module-boundaries`.
