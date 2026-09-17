# Components: anatomy, control flow, inputs/outputs, host

Standalone by default — never add `standalone: true`/`false` explicitly, and never
declare an `NgModule` for new code.

## No `.component` suffix

Component files are named after what they contain — `home.ts`, not
`home.component.ts` — matching current Angular schematics (the type suffix was
dropped by default). Same for directives (`hlm-button.ts`, `@Directive`, no
`.directive.ts`).

A plain `@Injectable` gets `.service.ts` (see [nx-generators.md](nx-generators.md))
— but that's a _default_, not a blanket rule for every injectable: a class
fulfilling a more specific ecosystem role is named after that role instead, e.g.
`transloco-http.loader.ts` implements Transloco's own `TranslocoLoader` interface,
so it's a `.loader.ts`, not force-fit into `.service.ts`. Same logic would apply
to a future guard/interceptor/resolver (`.guard.ts`/`.interceptor.ts`/`.resolver.ts`)
— none exist here yet, but the pattern is: suffix by role, `.service` is just the
generic fallback when no more specific role applies.

## Templates — always a separate file

Every component uses `templateUrl` to its own `.html` file (matching what
`g:component`/`g:gdm-ui`/`g:ensor` scaffold) — never an inline `template:` string,
even for a one-line template. Keeps templates diffable and consistent with the
folder-per-component layout (`home/home.ts` + `home/home.html`).

## Template control flow

```html
@if (user.isAdmin) { <admin-dashboard /> } @else if (user.isModerator) { <mod-dashboard /> } @else { <standard-dashboard /> } @for (item of items(); track item.id; let i = $index, total = $count) {
<li>{{ i + 1 }}/{{ total }}: {{ item.name }}</li>
} @empty {
<li>No items to display.</li>
} @switch (status()) { @case ('loading') { <app-spinner /> } @case ('error') { <app-error-msg /> } @default {
<p>Unknown</p>
} }
```

`track` is **required** on `@for` — use a stable id, not `$index`, unless the list
never reorders. `@if` supports result aliasing: `@if (user.settings(); as settings)`.
`@switch` uses `===`, no fallthrough; `@default never;` for exhaustive union checks.

## Inputs — signal-based, not `@Input()`

```ts
readonly name = input('Guest');
readonly age = input.required<number>();
readonly disabled = input(false, { transform: booleanAttribute });
readonly value = model(0); // two-way: [(value)]="mySignal"
```

`input()`/`input.required()` return signals — read as `this.name()`, never assign.
Don't add a name that collides with a native DOM property (`id`, `title`, ...).

## Outputs — `output()`, not `@Output()`/`EventEmitter`

```ts
readonly valueChanged = output<number>();
// ...
this.valueChanged.emit(50);
```

camelCase, no `on` prefix (`valueChanged`, not `onValueChanged`) — Angular custom
events don't bubble like native DOM events, so this isn't just a style nit.

## Host bindings — `host` object, not `@HostBinding`/`@HostListener`

```ts
@Component({
  host: {
    role: 'slider',
    '[attr.aria-valuenow]': 'value()',
    '[class.active]': 'isActive()',
    '(keydown)': 'onKeyDown($event)',
  },
})
```

Binding collision resolution: consumer's static binding beats component's static
host binding; a dynamic binding always beats a static one; component's host binding
wins dynamic-vs-dynamic.
