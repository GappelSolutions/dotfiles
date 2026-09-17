# HTTP: `HttpClient` and `httpResource`

No live backend integration exists in this codebase yet (`kit-auth` is currently an
empty `AuthService` skeleton, `bun gen` is a no-op until a real API contract lands)
— this is the convention to follow once one does.

## Setup

`HttpClient` is injectable by default in v21+; only call `provideHttpClient(...)`
when an injector needs specific features (interceptors, XSRF config, XHR instead of
fetch):

```ts
providers: [provideHttpClient(withInterceptors([authInterceptor]))],
```

## Reads: prefer `httpResource`

```ts
readonly userId = input.required<string>();
readonly user = httpResource(() => `/api/users/${this.userId()}`);
```

Eager — fires when its reactive request computation runs, not on subscription.
Cancels the in-flight request and re-fires when a dependency changes. Return
`undefined` from the request function to skip a call. Guard `value()` with
`hasValue()` — reading `value()` in an error state throws. `.text`/`.blob`/
`.arrayBuffer` for non-JSON; `parse` option to validate/transform with a runtime
schema; `headers()`/`statusCode()`/`progress()` (with `reportProgress: true`) for
metadata.

## Mutations: `HttpClient` directly, in a service

```ts
@Injectable({ providedIn: 'root' })
export class UserService {
  private readonly http = inject(HttpClient);
  updateUser(id: string, patch: Partial<User>) {
    return this.http.patch<User>(`/api/users/${id}`, patch);
  }
}
```

- Requests are cold `Observable`s — nothing is sent until subscribed; a mutation
  call the caller forgets to subscribe to silently never happens.
- Generic type param is a type assertion only, not runtime validation.
- `HttpHeaders`/`HttpParams` are immutable — use the value `.set()`/`.append()`
  return, don't mutate in place.
- Failures surface as `HttpErrorResponse`; status `0` means network/timeout, not a
  server response.
- Component reads: `async` pipe or `toSignal()`, never a manual `.subscribe()` that
  has to be manually torn down.

## Interceptors

Functional, via `withInterceptors`, not the DI-based class form (`withInterceptorsFromDi()`
exists only for legacy code):

```ts
export function authInterceptor(req: HttpRequest<unknown>, next: HttpHandlerFn) {
  return next(req.clone({ setHeaders: { Authorization: `Bearer ${token}` } }));
}
```

Run in list order. `inject()` works inside them. Clone before changing a
request/response — don't mutate a body in place, since a retry can re-run the same
interceptor over the same object. `HttpContextToken` for per-request metadata an
interceptor needs but the backend shouldn't receive.

## Security

`provideHttpClient()` wires XSRF protection by default for same-origin mutating
requests (`XSRF-TOKEN` cookie → `X-XSRF-TOKEN` header) — the backend must set that
cookie and verify the header; only disable with `withNoXsrfProtection()`
deliberately, never to silence an error you haven't diagnosed.
