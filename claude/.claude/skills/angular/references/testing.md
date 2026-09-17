# Testing

Runner is **Vitest**, via `@angular/build:unit-test` for the app and
`@nx/angular:unit-test` for libs — not Karma, not Jest. `bun nx:test [project]`.

## Zoneless: Act, Wait, Assert

No `NgZone` — state changes schedule updates asynchronously. Don't reach for
`fixture.detectChanges()` to force an update after changing signal-backed state;
it's for the initial render only. For anything driven by a signal change after that:

```ts
it('reacts to a signal update', async () => {
  // Act
  component.someSignal.set('new value');
  // Wait
  await fixture.whenStable();
  // Assert
  expect(el.textContent).toContain('new value');
});
```

`fixture.componentInstance`, `fixture.nativeElement`, `fixture.debugElement` (safer,
platform-agnostic queries via `debugElement.query(By.css(...))`) all work as usual.

## Components with a Transloco scope

Any component with `provideTranslocoScope('<scope>')` needs
`TranslocoTestingModule.forRoot(...)` in the test module, not a bare `TestBed`
config, or the pipe throws at render time:

```ts
await TestBed.configureTestingModule({
  imports: [
    MyComponent,
    TranslocoTestingModule.forRoot({
      langs: { en: { home: { welcome: 'Welcome' } } },
      translocoConfig: { availableLangs: ['en'], defaultLang: 'en' },
    }),
  ],
}).compileComponents();
```

Stub only the keys the test actually reads — no need to mirror the full `en.json`.

## Naming

- **Files:** `<name>.spec.ts` colocated next to `<name>.ts` — mirrors the company
  guide's §4.11 "file name matches the file under test" rule, Angular's own
  suffix. No separate test project to mirror `.UnitTests`-style splitting: Nx
  keeps a project's specs inside that project.
- **Tests:** `describe()` names the unit under test (component/service);
  `it()` states a fact — `<expected behaviour> when <state under test>`, present
  tense, no `should` (`it('disables the submit button while saving')`, not
  `it('should disable the submit button while saving')`). No placeholder titles
  either (`it('should work')`, `it('test 1')`) — a reader should know what broke
  from the description alone, without opening the test body. This is the
  ecosystem's own version of §4.11's `MethodName_StateUnderTest_ExpectedBehavior`
  — same two ingredients (state + expected behaviour), prose instead of a
  PascalCase identifier because `it()` takes a display string, not a method name.
- Enforced by `vitest/valid-title` in `eslint.config.mjs` (`**/*.spec.ts` override)
  — a `should`-prefixed or digit-only title fails lint, not just review.

## E2E

Playwright, `bun e2e` (`apps/gdm-ui-e2e`). Needs browser binaries `bun install` never
fetches — see [toolchain.md](toolchain.md) for the devenv vs. manual-install split,
and the non-interactive-shell `devenv shell --` gotcha before assuming a failure is a
real test bug.
