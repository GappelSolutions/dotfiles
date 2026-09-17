# Signals: reactivity fundamentals

## `signal` / `computed`

```ts
const count = signal(0);
count.set(3);
count.update((v) => v + 1);

const doubleCount = computed(() => count() * 2); // lazy, memoized, dynamic deps
```

Services expose state readonly to prevent external mutation:

```ts
private readonly _count = signal(0);
readonly count = this._count.asReadonly();
```

## Reactive contexts and `untracked`

Angular tracks signal reads inside `computed`, `effect`, `linkedSignal`, and
templates. To read a signal without creating a dependency, wrap it in `untracked()`.

The reactive context is **synchronous only** — a signal read after an `await` is
not tracked. Read every signal you need before the first `await`, not after.

## `linkedSignal` — derived state the user can still override

Like `computed`, but writable. Resets to the computed value whenever its source
changes; use the `{ source, computation }` object form when you need to preserve a
still-valid manual selection across a source change (`computation` receives
`(newSource, previous)`).

- `computed`: state that must **never** be manually overridden.
- `linkedSignal`: derived default, but the user can override it.
- **Never** use `effect` to sync one signal to another — that's an
  `ExpressionChangedAfterItHasBeenChecked`/infinite-loop trap. Use `computed` or
  `linkedSignal` instead.

## `effect` / `afterRenderEffect`

Effects are for syncing signal state to imperative, non-signal APIs (logging,
`localStorage`, a canvas/3rd-party widget) — not for propagating app state. Must be
created in an injection context (constructor/field initializer). Runs at least once,
before Angular updates the DOM.

```ts
constructor() {
  effect((onCleanup) => {
    console.log(`count = ${this.count()}`);
    const t = setTimeout(...);
    onCleanup(() => clearTimeout(t));
  });
}
```

Need to read/write the DOM after render instead (e.g. wrapping a 3rd-party widget)?
Use `afterRenderEffect` with its ordered phases (`earlyRead` → `write` →
`mixedReadWrite` → `read` — never write in `read`, never read in `write`). Client-only,
never runs during SSR.

## `resource` / `httpResource`

Async data as signals — `params` (reactive) + `loader` (async fn, gets `abortSignal`
— always pass it through so a superseded request is actually cancelled). Status
signals: `value()`, `hasValue()` (type-guard before reading `value()`), `isLoading()`,
`error()`, `status()`. `.reload()` forces a re-run; `.value.set(...)` optimistically
mutates (status becomes `'local'`).

If the data comes over HTTP, prefer `httpResource` over hand-rolling `resource` +
`fetch` — see [http.md](http.md).
