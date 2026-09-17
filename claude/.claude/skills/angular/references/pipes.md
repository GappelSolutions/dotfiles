# Pipes

Prefer a pipe in templates; never inject a pipe class into a service just to call
`.transform()` — pipes are template operators, not injectables, and doing so
throws DI errors in a standalone context. The existing repo example of the correct
pattern is `TranslocoPipe` (imported into a component, never injected elsewhere).

## Built-in locale-aware pipes — use the standalone function outside templates

| Pipe           | Standalone function |
| -------------- | ------------------- |
| `DatePipe`     | `formatDate`        |
| `CurrencyPipe` | `formatCurrency`    |
| `DecimalPipe`  | `formatNumber`      |
| `PercentPipe`  | `formatPercent`     |

```ts
@Injectable({ providedIn: 'root' })
export class PriceService {
  private readonly locale = inject(LOCALE_ID);
  formatQuantity(value: number) {
    return formatNumber(value, this.locale, '1.0-0'); // not `inject(DecimalPipe)`
  }
}
```

## Custom pipes — extract the transform into a plain function

The pipe delegates to a plain exported function; anything outside a template
(a service, a test) imports that function directly, never the pipe class:

```ts
// kebab-case.ts
export function toKebabCase(value: string) {
  return value.toLowerCase().replace(/ /g, '-');
}

// kebab-case.pipe.ts
@Pipe({ name: 'kebabCase' })
export class KebabCasePipe implements PipeTransform {
  transform(value: string) {
    return toKebabCase(value);
  }
}
```

`name`: camelCase, no hyphens. Class name: PascalCase + `Pipe` suffix.

## Impure pipes

Default (`pure` unset) is pure — recomputes only when an input reference changes.
Set `pure: false` only to detect in-place array/object mutation, and know it costs
a re-run on every change-detection cycle. Avoid unless there's no alternative
(usually there is: make the upstream state immutable instead).
