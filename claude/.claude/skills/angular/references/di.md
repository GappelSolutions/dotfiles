# Dependency injection

`@Injectable({ providedIn: 'root' })` for a singleton service — tree-shaken if
never injected, no `providers` array entry needed. This is the only decorator we
use for services; there is no other service decorator in this codebase.

## `inject()`

```ts
export class Navbar {
  private readonly router = inject(Router);
  private readonly analytics = inject(AnalyticsLogger);
}
```

Prefer `inject()` as a class field initializer over constructor-parameter injection
— shorter, and works the same in a functional guard/resolver/interceptor.

### Injection context

`inject()` only works where Angular has set one up: field initializers and
constructors of DI-instantiated classes, `useFactory`/`InjectionToken` factories,
and functional route guards/resolvers/interceptors. Not inside a regular method
body (`onClick() { inject(X) }` throws). To call it from elsewhere, capture an
`Injector`/`EnvironmentInjector` up front and use `runInInjectionContext`; a utility
function that must be called from an injection context should call
`assertInInjectionContext` at its top so a misuse fails with a clear error instead
of a cryptic one.

## Manual providers

Only needed when a service lacks `providedIn`, needs a fresh instance per
component, or configures a runtime value:

```ts
providers: [
  LocalService,                                          // shorthand
  { provide: Logger, useClass: BetterLogger },
  { provide: API_URL_TOKEN, useValue: 'https://...' },
  { provide: ApiClient, useFactory: (http = inject(HttpClient)) => new ApiClient(http) },
  { provide: OldLogger, useExisting: NewLogger },
  { provide: INTERCEPTOR_TOKEN, useClass: AuthInterceptor, multi: true },
],
```

`InjectionToken` for non-class dependencies (config objects, primitives) — give it
`providedIn: 'root'` + `factory` for the same auto-provide behavior as a service.

Library-style config: export a `provide*(config)` function returning a `Provider[]`
rather than asking consumers to hand-assemble the array (this repo's own pattern —
see `provideTranslocoScope('<scope>')`).

## Hierarchical resolution

Two trees: `EnvironmentInjector` (global, `providedIn: 'root'`/`ApplicationConfig.providers`)
and `ElementInjector` (per DOM element, component/directive `providers`/`viewProviders`).
Resolution walks `ElementInjector` up to root, then `EnvironmentInjector` up to root,
then throws unless `optional`. Modifiers on `inject()`: `optional` (null instead of
throw), `self` (this injector only), `skipSelf` (skip this level, start at parent),
`host` (stop at the host component's view boundary).

`providers` vs `viewProviders` on a component: `viewProviders` is invisible to
projected `<ng-content>` — use it to isolate a service from whatever a consumer
passes in; `providers` is visible everywhere including projected content.
