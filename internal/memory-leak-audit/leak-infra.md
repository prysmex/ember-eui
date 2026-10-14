# Memory-leak audit: infrastructure (leak-infra)

Branch `eui-leak/leak-infra`, base `master` (v16.0.0, EUI 123.1.0 / Borealis port), 2026-10-14.

Scope: everything outside `packages/core/src/components`:
- core `services/`, `modifiers/`, `helpers/`, `utils/` (including the Emotion cache, `euiClass`, `useEuiBorealisStyles`, the theme context and CSS variables), `-private/`, and module-level state;
- the companion packages `validated-form`, `changeset-form`, `flatpickr` and `pikaday`;
- how we use third-party libraries: focus-trap / ember-focus-trap, ember-basic-dropdown / ember-power-select, ember-keyboard, ember-modifier, ember-provide-consume-context, refractor, unified/remark, flatpickr and pikaday.

No library code was changed. The tests added are:

| File | Tests |
| --- | --- |
| `packages/core/tests/helpers/leak-infra-harness.ts` | Harness. Counts listeners left on window, document, `<html>`, `<body>` and MediaQueryList. Counts ResizeObserver and MutationObserver instances still observing. Reports Emotion cache size. |
| `packages/core/tests/integration/leak-infra-test.gts` | 9 passing tests, 4 `todo` tests (LI-1, LI-2, LI-3, LI-4). |
| `packages/flatpickr/tests/integration/leak/eui-flatpickr-leak-test.gts` | 1 passing test, 1 `todo` test (LI-6). |
| `packages/pikaday/tests/integration/leak/eui-pikaday-leak-test.gts` | 1 passing test. |
| `packages/validated-form/tests/integration/leak/validated-form-leak-test.gts` | 1 passing test. |

Test results:
- The full core suite: 2068 tests, 2064 pass, 4 todo, 0 fail.
- The flatpickr, pikaday and validated-form suites are green.
- A QUnit `todo` passes while its assertion fails. Once the leak is fixed it fails, which is the signal to promote it to `test`.
- The companion suites need a core `dist`. Run `rollup --config` in `packages/core` first.

## Summary

| ID | Title | Severity | Status |
| --- | --- | --- | --- |
| LI-1 | The `resizeObserver` modifier creates a new ResizeObserver on each re-run and never disconnects the old one | Medium | Confirmed |
| LI-2 | Emotion caches are append-only: each distinct dynamic `@css` value inserts a full copy of the component's rules, kept for the life of the app | Medium | Confirmed |
| LI-3 | Each distinct provider theme (`@borealisOverrides`, color mode) adds a permanent set of component classes | Low | Confirmed |
| LI-4 | The flyout manager's `goBack` closes the last session without resetting `currentZIndex`, so z-index and the Emotion cache grow on each Back | Medium | Confirmed |
| LI-5 | The `outsideClickDetector` modifier registers a new destructor and re-runs setup on every args update | Low | Suspected (code reading) |
| LI-6 | `EuiFlatpickr` unmounted while its setup is pending (string `@locale`) creates an instance that is never destroyed: calendar left in `<body>` plus window/document listeners | Medium | Confirmed |
| LI-7 | `EuiChangesetForm` and its fields run `later(…, 1)` validation after teardown | Low | Suspected (code reading) |
| LI-8 | The `euiToaster` service keeps toasts until removed, including timed toasts when no `EuiGlobalToastList` is rendered | Low (by design) | Suspected (code reading) |
| LI-9 | The `html-id-generator` `warned` Set grows with every distinct whitespace-containing prefix or suffix | Low | Suspected (code reading) |
| LI-10 | The split-button style memo is keyed by color string per theme | Low (bounded) | Suspected (code reading) |

By severity: High 0, Medium 4 (LI-1, LI-2, LI-4, LI-6), Low 6.

---

## LI-1: the `resizeObserver` modifier stacks observers on re-run

**Where:** `packages/core/src/modifiers/resize-observer.ts:91-101` (`modify`) and `:103-127` (`_setup`).
- It is a public modifier (`{{resizeObserver onResize=…}}`).
- Internal users: EuiToolTip, EuiCodeBlock, EuiBottomBar, EuiContextMenuPanel, EuiInputPopover, EuiMarkdownEditor, EuiMarkdownEditorDropZone and EuiResizableContainer. They pass stable callbacks, so they rarely re-run.

**Mechanism:** each `modify()` calls `_setup()`, which does `this.observer = makeResizeObserver(element, …)` without disconnecting the previous observer. It also calls `registerDestructor` again. `_teardown` disconnects only the last observer.

The orphaned observers keep observing the element:
- While the element is mounted, each one fires on every resize and calls `getBoundingClientRect()`, which forces a layout.
- After unmount they are never disconnected.
- Their callbacks close over the element and the modifier, which references `named` and so the component's args. All of that is retained until the element itself is unreachable.

A class-based modifier re-runs when a consumed arg changes. `onResize` is consumed whenever `setSize` calls it, which happens whenever the size changed. So a new `onResize` identity combined with a size change re-runs the modifier. For example, `onResize=(fn this.handle row)` re-runs it whenever `row` changes.

**Trigger:** every update of the modifier's args after a size change. It grows per update, per mounted element.

**Evidence (Confirmed):**
- Test: `Integration | leak-infra > modifiers: resizeObserver: a changed named arg replaces the observer instead of adding one (LI-1)` (todo).
- Output: `live observers while mounted: 11, after unmount: 10, created: 11`, after 10 arg updates.
- The control test (stable callback, mount and unmount 10 times) passes with 0 live observers.

**Proposed fix:** in `modify`:
- call `this.observer?.disconnect()` before `_setup()`, or set up only once and only refresh `this.named`;
- register the destructor once, in the constructor.

Alternatively, rewrite it as a function modifier that returns `observer.disconnect`.

## LI-2: Emotion caches are append-only, and dynamic `@css` values multiply rules

**Where:**
- `packages/core/src/utils/eui/styles.ts:89-91` (`euiClass` → `context.cache.css(...)`)
- `packages/core/src/utils/emotion/context.ts:119-123` (`EuiThemeContext.cache`)
- `packages/core/src/services/eui-emotion.ts:29-41`, the owner-scoped default context whose `fallbackCache` is the cache every provider tree ends up using.

This affects every component that composes `@css` (or any per-instance value) into its class.

**Mechanism:** `@emotion/css` instances keep `cache.inserted` and `cache.registered` plain objects plus one `<style>` rule per inserted rule. Entries are keyed by the hash of the serialized styles and never removed, except by `flush()`. The only `flush()` calls are:
- `EuiThemeContext.destroy()`, which runs when the `eui-emotion` service is destroyed, so on app teardown;
- `EuiEmotionProvider`'s private `eui-global` and `eui-vars` caches.

`euiClass(context, componentStyles, args.css)` serializes the whole component style plus the caller's `@css` into a single class. A new `@css` value therefore inserts a complete new copy of all the component's rules, not just the changed declaration.

**Trigger:** a `@css` (or `@contentProps.css` and so on) that carries a value which changes over time: widths, positions or colors driven by data, animation or drag. Static `@css` values are fine: the cache dedupes identical styles. One entry per distinct value, unbounded.

**Evidence (Confirmed):**
- Test: `Integration | leak-infra > emotion: a dynamic @css value adds one permanent cache entry per distinct value (LI-2)` (todo).
- Output: `cache growth after 50 distinct @css values and unmount: 50 entries, 2800 <style> tags`. That is about 56 CSS rules per value for `EuiText`. Development mode inserts one `<style>` tag per rule; production "speedy" mode inserts CSSOM rules into a few tags, with the same rule count.
- Control: `the shared Emotion cache stops growing when the same components mount again` passes. Repeated mounting of EuiButton, EuiPanel, EuiCallOut and EuiText stays at a fixed entry count after warm-up, so static usage is bounded.

**Proposed fix:**
- Document that `@css` must be static.
- Have components route genuinely dynamic values (sizes, positions, colors) through inline `style` or CSS custom properties, as `EuiRangeHighlight`, `EuiColorStopThumb` and `EuiSaturation` already do.
- Optionally add a development-mode warning when one component instance generates more than K distinct classes. Upstream React EUI has the same Emotion behavior, but its `css` prop users mostly pass static objects.
- The component agent should check its components for internal dynamic values passed to `euiClass`. Candidates spotted from here: EuiBeacon `{blockSize: size}` (static per arg), EuiRangeHighlight `background` (from args), and flyout `maskClass` (see LI-4).

## LI-3: one permanent set of classes per distinct theme

**Where:**
- `packages/core/src/utils/emotion/context.ts:106-113` (`@cached upstream`)
- `packages/core/src/utils/eui/styles.ts:13` (`memo` WeakMap, which is fine)
- `packages/core/src/components/eui-emotion-provider.gts:209-220` (`colorClass` with scoped CSS variables)

**Mechanism:**
- Each distinct resolved theme (color mode, high contrast, or `@borealisOverrides`) gives new style values, so each rendered component inserts new classes into the shared, append-only cache.
- A nested provider that scopes its theme also inserts a class holding every theme CSS variable, several hundred declarations.
- The JS-side memo (`WeakMap` keyed by the theme object) is collectable. Only the Emotion entries persist.

**Trigger:** user-driven theme overrides, for example a live brand-color picker. Light and dark toggling is bounded (2 or 4 variants).

**Evidence (Confirmed):**
- Test: `changing provider theme overrides adds a full set of component classes per distinct theme (LI-3)` (todo).
- Output: `cache growth after 10 distinct themes and unmount: 40 entries` (3 components plus the provider wrapper per theme).

**Proposed fix:** acceptable for discrete themes. For continuous overrides:
- document it;
- or give a provider that receives `@borealisOverrides` its own cache (`createEuiEmotionCache`) flushed on `willDestroy`, so its theme's classes leave with it;
- or debounce theme changes.

## LI-4: `goBack` that closes the last flyout session never resets the z-index counter

**Where:** `packages/core/src/utils/eui/flyout-manager/reducer.ts:422-471` (`ACTION_GO_BACK`, session-pop branch). The `EuiFlyoutManagerService` state and `EuiFlyout` (`maskClass`, `components/eui-flyout.gts:1161-1165`) are affected.

**Mechanism:**
- `ACTION_ADD` increments `currentZIndex` by 3 for each session.
- `ACTION_CLOSE` and `ACTION_CLOSE_ALL` reset it to 0 when no session or unmanaged flyout remains.
- The `ACTION_GO_BACK` branch that pops the current session returns `{ ...state, sessions, flyouts }` with no reset. This matches upstream 123.1.0 (`flyout/manager/reducer.ts`), so it is a parity bug.

The counter therefore climbs by 3 on each Back that closes the last session. Every session after that renders at a higher z-index. `EuiFlyout.maskClass` serializes `zIndex: ${mask} !important` through `euiClass`, so each new value also adds a permanent Emotion entry (see LI-2).

**Trigger:** a managed flyout session closed with the menu's Back button, or `manager.goBack()`, while it is the only session. Normal use; it grows on every such close.

**Evidence (Confirmed):**
- Test: `flyout manager service: closing the last session with Back resets the z-index counter (LI-4)` (todo).
- Output: `z-index counter reset (got 33; Emotion cache grew by 10 entries over 10 Back closes)`.
- Everything else in the manager returns to baseline. See the passing test `managed flyouts opened, nested and unmounted while open leave the manager empty`: sessions, flyouts, unmanaged flyouts, history items, `pendingCloseMeta`, `containerUsers`, the window resize listener and ResizeObservers.

**Proposed fix:** in `ACTION_GO_BACK`, apply the same rule as `ACTION_CLOSE`:

```ts
if (newSessions.length === 0 && state.unmanagedFlyouts.length === 0) newCurrentZIndex = 0;
```

Consider reporting it upstream.

## LI-5: `outsideClickDetector` re-runs setup and adds a destructor on every update

**Where:** `packages/core/src/modifiers/outside-click-detector.ts:64-77`. Used by EuiPopover and EuiFlyout (`isDisabled=this.outsideClickDisabled` changes over a flyout's life), and public.

**Mechanism:** `modify` calls `_setup()` and `registerDestructor(this, …)` on every arg update. The document and element listeners are bound `@action`s, so `addEventListener` dedupes them and no listener leaks. Two things do accumulate on the modifier instance:
- one destructor closure per update;
- a fresh `guidFor({})` id.

The growth is bounded by the modifier's lifetime and released with it.

**Evidence:**
- Suspected, from code reading.
- Test `outsideClickDetector: arg updates and unmount leave no document listener` passes: no listener leak.

**Proposed fix:** register the destructor and the listeners once, in the constructor or on first `modify`. Later updates only refresh `this.named`.

## LI-6: `EuiFlatpickr` creates an orphan instance when unmounted during setup

**Where:** `packages/flatpickr/src/components/eui-flatpickr.gjs`:
- `:81-84` (`onWillDestroy`)
- `:102` (`scheduleOnce('afterRender', …)`)
- `:105-137` (`async setFlatpickrOptions`, `await loadLocale`)
- `:189-193` (`onLocaleUpdated`)

**Mechanism:** setup is deferred to `afterRender` and, with a string `@locale`, awaits the locale chunk. If the component is torn down in that window:
1. `onWillDestroy` runs while `this.flatpickrRef` is still `undefined`.
2. The pending setup then resumes and calls `flatpickr(element, …)` on the detached input.

flatpickr appends its `.flatpickr-calendar` to `<body>` and binds window and document listeners (resize, mousedown, focus and others). Those listeners retain the instance, the detached input, the calendar DOM and the args closures (`onChange` and the rest) permanently.

`onLocaleUpdated` has the same race: two locale changes in a row start two setups, and the first instance is overwritten in `flatpickrRef`, never destroyed.

**Trigger:**
- unmounting (route change, `{{#if}}`) in the same run loop as render, or before the lazy locale chunk resolves (also on first load over a slow network);
- rapid `@locale` changes.

**Evidence (Confirmed):**
- Test: `Integration | leak-infra | eui-flatpickr: unmounted while a string @locale loads, the picker is never created (LI-6)` (todo).
- Output: `orphaned calendars in <body>: 10, window/document listeners: 30` after 10 cycles.
- Control: normal mount and unmount 10 times leaves 0 calendars and 0 listeners.

**Proposed fix:** after the `await` (and at the start of `setFlatpickrOptions`), bail out with `if (isDestroying(this) || isDestroyed(this) || !element.isConnected) return;`. Track a setup token so that a superseded setup (a locale change) does not assign or create an instance. Destroy any existing `flatpickrRef` before assigning a new one.

## LI-7: changeset-form validation timers run after teardown

**Where:**
- `packages/changeset-form/src/components/eui-changeset-form.gts:141` (`validate` with `initialValidation`)
- `packages/changeset-form/src/components/eui-changeset-form/fields/base.gts:86` (`validate`)

**Mechanism:** `later(this, () => changeset.validate(…), 1)` has no destroyed check and is not cancelled on teardown. It runs about 1 ms later against the (app-owned) changeset. The work is bounded and one-shot, but it can set errors on a changeset after its form is gone. Validated-form's `didUpdateValue` (`field-base.gts:176`) has the same `later` but guards it with `isDestroyed`.

**Evidence:** suspected, from code reading.

**Proposed fix:** guard with `isDestroying(this) || isDestroyed(this)`, or keep the timer and `cancel` it in `willDestroy`.

## LI-8: the `euiToaster` service keeps toasts until removed

**Where:** `packages/core/src/services/eui-toaster.ts:18-33`.

**Mechanism:** `show()` appends to the tracked `toasts` array. Only `remove()` drops entries, and `remove()` is called by `EuiGlobalToastList` (dismiss button, or its `Timer` when `toastLifeTimeMs` expires). Without a rendered toast list, or with toasts that have no lifetime, entries (and any component or closures in their props) stay for the app's life. This is expected queue behavior. It is listed because the service is long-lived.

**Evidence:** suspected, from code reading. The toast list's timers are cleared in `willDestroy` (`eui-global-toast-list.gts:420-436`, component agent's scope).

**Proposed fix:** document it. Optionally, let the service own the lifetime timers so expiry does not depend on a mounted list.

## LI-9: the `htmlIdGenerator` warning Set is unbounded

**Where:** `packages/core/src/utils/html-id-generator.ts:11`.

**Mechanism:** a module-level `Set<string>` of every prefix or suffix containing whitespace, so each one is warned once. It is unbounded if an app passes dynamic, localized strings. The entries are only strings.

**Evidence:** suspected, from code reading.

**Proposed fix:** cap it (for example, stop adding after 100 entries), or warn only in development builds.

## LI-10: the split-button style memo is keyed by color string

**Where:** `packages/core/src/utils/eui/split-button.ts:17-35`.

**Mechanism:** the outer `WeakMap` is keyed by the resolved theme, which is fine. The inner `Map<factory, Map<arg, styles>>` is keyed by the background or divider color string. It is bounded by the number of distinct colors per theme, normally the few EUI color names. It is unbounded only if arbitrary color strings are passed.

**Evidence:** suspected, from code reading.

**Proposed fix:** none needed. Optionally restrict the key to known color names.

---

## Module-level and service state containers

The verdict column says whether the container is bounded or unbounded.

### Module-level containers

| Container | Key | Value | Added by | Removed by | Verdict |
| --- | --- | --- | --- | --- | --- |
| `utils/eui/styles.ts:13` `memo` | resolved theme object (`WeakMap`) | `WeakMap<factory, styles>` | `memoizedStyles` / `useEuiBorealisStyles` | GC when the theme object is dropped (`@cached upstream` replaces it on change) | Bounded (weak) |
| Emotion instance `cache.inserted` / `.registered` plus `<style>` rules: service `fallbackCache` (`utils/emotion/context.ts:122`), shared by all providers | hash of the serialized styles | `true` or the CSS string, plus the CSSOM rules | every `euiClass` / `context.cache.css` call | only `flush()`: service destroy (app teardown) | **Unbounded** with dynamic `@css` or themes (LI-2, LI-3, LI-4). Bounded for static use |
| `EuiEmotionProvider` `globals` (`eui-global`) and `variables` (`eui-vars`) caches | the same as above | global reset and `:root` variables | `syncGlobalStyles` (flush plus inject on each theme change) | `flush()` on theme change, on becoming non-root, and in `willDestroy` | Bounded (one theme's worth). Test passes |
| `utils/eui/theme.ts:65` `systemThemes` | `'LIGHT' \| 'DARK'` | computed Borealis theme | `euiHighContrastModifications` | never | Bounded (2 entries) |
| `utils/eui/split-button.ts:17` `memo` | theme (`WeakMap`) → factory → color string | styles | `splitButton*Styles` | GC with the theme | Bounded by distinct colors (LI-10) |
| `-private/focus-trap-registry.ts:19` `active` | `Entry` (trap, base containers, attached surfaces) | n/a (Set) | the trap's `onActivate` | the trap's `onDeactivate`. ember-focus-trap's `destroyModifier` calls `deactivate()` | Bounded by active traps. Tests pass (EuiModal, EuiFocusTrap) |
| `-private/focus-trap-registry.ts:20` `entries` | `FocusTrap` (`WeakMap`) | Entry | `createRegisteredFocusTrap` | GC | Bounded (weak) |
| `Entry.extra` (inside the above) | portalled surface element | n/a | `attachToFocusTraps` (EuiPopover `joinFocusTraps`, combo box list) | the returned cleanup (modifier teardown) | Bounded. Holds detached surfaces only until the modifier tears down |
| `-private/focus-trap-effects.ts:10-11` `scrollLocks`, `savedBody` | n/a | counter, saved body styles | `lockBodyScroll` | its release | Bounded. Test passes (overflow restored) |
| `-private/set-body-class.ts:28` `countsByDocument` | document (`WeakMap`) → class name | reference count | helper `compute` | `release` on update or `willDestroy` (kept in FastBoot by design) | Bounded |
| `-private/link-form-row-control.ts:60` `added` | control element (`WeakMap`) | ids added to `aria-describedby` | `describe` | GC with the element | Bounded (weak). The MutationObserver is disconnected (test passes) |
| `utils/eui/modal-flyout.ts:35` `registry` | push target (`body` or container, `WeakMap`) | per-side base padding plus `Map<flyoutId, contribution>` | `pushFlyoutPadding` install | its teardown (`contributions.delete(id)`) | Bounded |
| `-private/icon-loader.ts:36` `cache` | EUI icon type (asserted, and guarded by `isEuiIconType`) | `LoadingIcon` (component) | `loadedIcon` / `loadIcons` | load failure, `clearIconCache` (tests) | Bounded (the icon catalog) |
| `-private/language-loader.ts:35` `cache`, plus refractor's global registry | language name (filtered by `isLoadable`) | `LoadingLanguage` | `highlightLanguage` / `loadLanguages` | load failure | Bounded (the language list) |
| `utils/html-id-generator.ts:11` `warned` | whitespace-containing id parts | n/a | `warnOnWhitespace` | never | **Unbounded** (strings only, LI-9) |
| `utils/color/eui_palettes.ts:46` `defaultVisColors` | n/a | palette | first call | never | Bounded (1) |
| `utils/container-query/match-container.ts:35` `counter`; `document.adoptedStyleSheets` | n/a | one sheet per `ContainerQueryList` | constructor | `dispose()` (the `containerQuery` modifier's teardown) | Bounded. Test passes |
| `EventTarget`, matchMedia lists in `utils/emotion/system.ts` | n/a | `change` listeners | `EuiSystemPreferences` (root provider) | `destroy()` in the provider's `willDestroy` | Bounded. Test passes |
| Constant tables (`RESERVED`, `UNITLESS`, `languageLoaders`, `iconLoaders`, `DEFAULT_CONFIG`, `COLUMN_KEYS`, `dataTypesProfiles`, `EVENTS`, default markdown plugin lists, …) | n/a | n/a | module init | n/a | Static |
| ember-provide-consume-context `parentContexts` / `nextContexts` / `_contextRefs` | component instance (`WeakMap`); the global `activeContainers` array | contexts | render | `commit` / `reset`, or GC | Bounded |
| ember-keyboard service `registeredResponders` (used by `{{onKey}}`) | modifier instance | n/a | modifier constructor | its destructor | Bounded |
| focus-trap's internal trap queue | trap | n/a | `activate` | `deactivate` | Bounded. Document listeners balanced in tests |

### Service state

| Service state | Per-component content | Teardown | Verdict |
| --- | --- | --- | --- |
| `eui-flyout-manager` `state.sessions` / `flyouts` / `unmanagedFlyouts` | flyout ids, titles, icon types, `historyKey` symbols | `EuiFlyout` `registration` teardown → `closeFlyout`, `closeAllFlyouts` or `closeUnmanagedFlyout` | Bounded. Test passes with unmount while open, nested children and Back |
| `eui-flyout-manager` `state.currentZIndex` | counter | reset on close or close-all, **not on goBack** | **Unbounded** with Back (LI-4) |
| `eui-flyout-manager` `state.containerElement`, `containerUsers` (`Map<HTMLElement, number>`, strong) | container element | `useContainer` release (trackContainer teardown) | Bounded (cleared by the last user) |
| `eui-flyout-manager` `pendingCloseMeta` (`Map<flyoutId, meta>`) | close reasons stamped by `goBack` | `consumeCloseMeta` (registration and watchRegistration) | Bounded. 0 after the test |
| `eui-flyout-manager` `listeners`, `eventListeners` (`Set`) | app subscribers | the returned unsubscribe | Bounded by app code (no internal subscriber) |
| `eui-flyout-manager` window resize listener, container ResizeObserver, rAF | n/a | stopped when there is no session or container, and in `willDestroy` | Bounded. Test passes |
| `eui-flyout-manager` `historyItems` | closures over `dispatch` | recomputed on session change | Bounded |
| `eui-emotion` `context` (`EuiThemeContext`, `fallbackCache`) | the Emotion cache (see above) | `registerDestructor` → `context.destroy()` → `flush()` | Lives for the app; content as in LI-2 |
| `eui-toaster` `toasts` | toast props (may include components and closures) | `remove()` (toast list dismiss or timer) | Bounded by app use (LI-8) |
| `eui-i18n` `translations`, `formatNumber`, `mappingFunc` | app-supplied | replaced on `addTranslations` | Bounded (app data) |
| `eui-config` `_config` | app-supplied | replaced | Bounded |

## Checked and clean

**Modifiers** (`packages/core/src/modifiers`):
- `mutation-observer`, `container-query`, `use-is-within-breakpoints`, `validatable-control`, `simple-style` (never removes styles, but holds no references), `screen-reader-only` (static classes in the service cache) and `-private/window-resize` all tear down correctly.
- `resize-observer` and `outside-click-detector` are clean on mount and unmount (tests pass); see LI-1 and LI-5 for updates.

**`-private` modifiers and helpers:**
- `value-modifier` (one destructor per instance; teardown before re-setup)
- `eui-apply-props`, `euiMinInlineSize`
- `eui-disabled-element` (restores listeners and the overridden `click`/`dispatchEvent`)
- `live-text` (the MutationObserver is disconnected; the microtask is guarded by `active`)
- `link-form-row-control` (test passes)
- `table.ts` (`stickyHeaderOriginal`/`Copy`, `onMediaQueryChange`)
- `basic-table.ts` `elementProps` (listeners removed on update)
- `next-frame` (one-shot rAF, guarded by callers)
- `utils/data-grid/scheduling` (`afterRender` destroyed check; `observeResize` cancels the frame and disconnects)
- `focus-trap-effects` `isolateOutside` (restores `aria-hidden` and `pointer-events`; test passes)

**Focus traps:**
- ember-focus-trap 1.1.0's `destroyModifier` always calls `deactivate()`.
- Our `_createFocusTrap=focusTrapFactory` wrapper deletes the registry entry in `onDeactivate`.
- EuiModal and EuiFocusTrap, mounted and toggled 10 times, leave 0 window/document/body listeners, 0 observers, the scroll lock released, isolation restored and body classes restored.

**Emotion and theming:**
- `EuiEmotionProvider` mounted and unmounted 10 times leaves no matchMedia listeners and no `eui-global` or `eui-vars` style tags.
- `EuiThemeContext.destroy` flushes only its own fallback cache.
- `memoizedStyles` uses WeakMaps.
- `euiThemeCssVariables` is memoized per theme.

**Third-party integrations:**
- pikaday (ember-pikaday 5.1.1): the modifier destroys Pikaday and disconnects its MutationObserver. Mount, open and unmount 10 times leaves 0 `.pika-single` and 0 listeners (test passes).
- flatpickr: normal mount and unmount is clean (test passes); only LI-6 leaks.
- validated-form: `register` in the constructor and `unregister` in `willDestroy`, through `afterRender` queues in FIFO order. Toggling fields and a nested form 10 times leaves exactly the rendered children registered (test passes). The `next`/`later` callbacks are guarded by `isDestroyed`.
- ember-keyboard `{{onKey}}`: registers with the keyboard service in its constructor and unregisters in a destructor.
- ember-basic-dropdown: only `calculate-position` and `config` are imported here. Its dropdown and power-select lifecycle belongs to the combo box, in the component agent's scope.
- ember-concurrency: a dependency, but not imported anywhere in `src`.

**Markdown and code utilities:**
- `utils/markdown` (`unified`/`remark` processors, `to-dom`, the add-components processor) and `utils/code/utils.ts` keep no module state. They build detached DOM that components consume.
- The `markdown-actions` focus retry is bounded by `MAX_TRIES`.
- `utils/transition.performOnFrame` is bounded by the transition duration.
- `utils/copy-to-clipboard` removes its temporary element.

**Helpers:** `use-state` (`scheduleOnce` on its own instance) and the rest are pure.

**changeset-form:** apart from LI-7, it has no listeners, observers or registries (fields read the changeset directly).

## Notes for the coordinator

- `utils/timer.ts` (the toast `Timer`) is safe as long as `clear()` is called. `EuiGlobalToastList.willDestroy` does this (component scope).
- `EuiAutoSizer` uses `utils/detect-element-resize.js`, which adds scroll listeners, injected `<style>` and trigger DOM to the element, plus rAF and setTimeout. Its removal path is the component's responsibility (component scope); worth a check there.
- The candidates for internal dynamic values in `euiClass` (LI-2) are in component files. They are listed in LI-2 for the component agent.
