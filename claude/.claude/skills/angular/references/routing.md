# Routing

Routes live in `app.routes.ts`, wired via `provideRouter(routes)` in `app.config.ts`.
First-match-wins — put the wildcard (`**`, not-found) last, specific paths before
less-specific ones.

## Defining routes

```ts
export const routes: Routes = [
  { path: '', component: Home, title: 'Home' },
  { path: 'user/:id', component: UserProfile },
  { path: 'articles', redirectTo: '/blog' },
  { path: '**', component: NotFound },
];
```

Nested views: `children` on the parent route + `<router-outlet />` in the parent
component's template.

## Loading strategy

Eager (`component: X`) for the primary landing route only — everything else lazy,
to keep the initial bundle small:

```ts
{ path: 'admin', loadComponent: () => import('./admin/admin').then((m) => m.Admin) }
{ path: 'settings', loadChildren: () => import('./settings/settings.routes') }
```

Loader functions run in the route's injection context — `inject()` works inside
them for context-aware loading decisions (e.g. feature-flag branching on which
chunk to fetch).

If a lazily-loaded component also has an eager sibling exported from the same lib's
barrel, give the lazy one its own `tsconfig.base.json` path instead of exporting it
from `index.ts` — see `nx-generators.md`'s note on `checkDynamicDependenciesExceptions`,
or the eager barrel import drags the lazy component into the main bundle too.

## Navigation

```html
<a routerLink="/dashboard" routerLinkActive="active-link">Dashboard</a> <a [routerLink]="['/user', userId]">Profile</a>
```

```ts
private readonly router = inject(Router);
this.router.navigate(['/search'], { queryParams: { q: 'angular' } });
this.router.navigateByUrl('/login', { replaceUrl: true });
```

## Guards

Functional, not class-based:

```ts
export const authGuard: CanActivateFn = (route, state) => {
  const auth = inject(AuthService);
  return auth.isLoggedIn() ? true : inject(Router).parseUrl('/login');
};
```

`CanActivate`/`CanActivateChild`/`CanDeactivate`/`CanMatch` (the last controls
whether the router even considers the route a match — e.g. feature flags). Return
`boolean`, `UrlTree`/`RedirectCommand` to redirect, or an `Observable`/`Promise` of
either. **Never treat a client-side guard as real security** — the server must
enforce the same check.

## Resolvers + component inputs

Prefer resolved data landing directly on a signal `input()` over reading
`ActivatedRoute.data` by hand — enable once in `app.config.ts`:

```ts
provideRouter(routes, withComponentInputBinding());
```

```ts
export const userResolver: ResolveFn<User> = (route) => inject(UserService).getUser(route.paramMap.get('id')!);
// route config: resolve: { user: userResolver }
// component:    readonly user = input.required<User>();
```

Navigation blocks until the resolver settles — keep resolvers lightweight, and
surface a global loading indicator (router events) since the UI stays on the old
page in the meantime.
