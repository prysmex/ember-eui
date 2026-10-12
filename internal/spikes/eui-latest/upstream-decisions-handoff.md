# Upstream decisions handoff (EuiForm callout focus, removed components, EuiRefreshInterval switch)

Branch `eui-wave/upstream-decisions`. Target EUI 123.1.0 / Borealis 8.1.0. The user decided "keep upstream behavior" for three questions left open by the forms-layout, feedback/selectable/color-picker and date-pickers handoffs. EuiControlBar was not touched; another agent handles it.

## 1. EuiForm error callout focus

This resolves forms-layout Unresolved item 3. See the follow-up section appended to [forms-layout-handoff.md](forms-layout-handoff.md).

- The callout gets `tabindex="-1"` and is focused once, when it is inserted.
- File: `packages/core/src/components/eui-form.gts`.

## 2. Components removed upstream are deprecated

### Verified absent from 123.1.0

- No `components/notification` or `components/suggest` directory.
- No color stops under `components/color_picker`.
- No `EuiNotificationEvent`, `EuiSuggest` or `EuiColorStops` anywhere in `es/`, `lib/` or `eui.d.ts`.
- The only leftover is the service hook `useColorStopsState`.

### The deprecation

A new helper, `src/-private/removed-upstream.ts` (`deprecateRemovedUpstream(fileName, name, alternative)`), calls `deprecate()` from `@ember/debug` with these options:

| Option | Value |
| --- | --- |
| `id` | `ember-eui.<file>.removed-upstream` |
| `for` | `'@ember-eui/core'` |
| `since` | `{ available: '14.2.0', enabled: '14.2.0' }` |
| `until` | `'15.0.0'` |

- The message reads "<Name> was removed from Elastic UI (EUI) upstream and will be removed from @ember-eui/core in the next major version." followed by the alternative.
- **Deliberate change, `since.available`:** Ember's types require `available` next to `enabled`, so both are set to 14.2.0.
- **When it fires:** from each component's constructor, so once per rendered instance. Re-renders and argument updates do not fire it again. Deprecations are stripped from production builds.
- **Behavior:** unchanged.

### Components and ids

| Component | Id | Alternative in the message |
| --- | --- | --- |
| EuiNotificationEvent | `eui-notification-event` | compose EuiPanel/EuiTitle/EuiText/EuiContextMenu |
| EuiNotificationEventMessages | `eui-notification-event-messages` | same |
| EuiNotificationEventMeta | `eui-notification-event-meta` | same |
| EuiNotificationEventReadButton | `eui-notification-event-read-button` | same |
| EuiNotificationEventReadIcon | `eui-notification-event-read-icon` | same |
| EuiSuggest | `eui-suggest` | EuiSelectable or EuiComboBox (upstream's #7263 recommendation) |
| EuiSuggestInput | `eui-suggest-input` | same |
| EuiSuggestItem | `eui-suggest-item` | same |
| EuiColorStops | `eui-color-stops` | no direct replacement; EuiColorPalettePicker for predefined gradients |
| EuiColorStopThumb (`eui-color-stops/thumb.gts`) | `eui-color-stops-thumb` (the `/` is flattened to `-`) | same |

### Sub-components fire too

The parents render their sub-components, so they fire as well:

- An EuiNotificationEvent reports its own id plus messages, meta and read button or icon.
- EuiSuggest reports its input and each item.
- EuiColorStops reports one thumb deprecation per stop.

This is intended: every public file is announced. If it is too noisy, the parents could pass a private argument to silence their children.

### Docs notices

A warning EuiCallOut ("Deprecated: removed upstream") was added at the top of three pages:

- `docs/display/notification-event/index.md`
- `docs/forms/suggest/index.md`
- `docs/forms/color-stops/index.md`

## 3. EuiRefreshInterval switch

This matches upstream `date_picker/auto_refresh/refresh_interval.js`.

### What changed

- **Toggle:** the Start/Stop EuiButton is replaced by a compressed `EuiSwitch` in a `grow=false` flex item.
  - It keeps `data-test-subj="superDatePickerToggleRefreshButton"`.
  - It is `role="switch"` with `aria-checked` set to "not paused" and `aria-label="Toggle refresh"` (token `euiRefreshInterval.toggleAriaLabel`).
  - `aria-labelledby` is removed and `aria-describedby` points to the screen-reader description.
  - Its visible label is an `EuiFormLabel` reading "Refresh every" (`euiRefreshInterval.toggleLabel`). Clicking the label toggles too.
- **Fields:**
  - The number field and the units select are disabled while paused.
  - The number field gets `@min={{0}}` (upstream `getMinInterval(0)`).
  - Both stay compressed and full width. The value is `aria-invalid` only while running with an empty or ≤ 0 value.
  - `aria-describedby` now points only to the description, as upstream does; it no longer includes the legend.
- **Description:** the screen-reader text is "Refresh is off/on, interval set to {value} {units}." (`euiRefreshInterval.fullDescriptionOff/On`). It replaces "Refresh interval currently set to …" (`euiRefreshInterval.fullDescription`).
- **Toggle rules (upstream):**
  - The switch ignores only an empty value.
  - It is never disabled, so a 0 interval can be switched on. The Start button used to be disabled for invalid values.
  - Enter in the fields still starts refreshing only for a valid value.
- **Kept:**
  - The Ember args `@isPaused`, `@refreshInterval` and `@applyRefreshInterval`, with the `{ refreshInterval, isPaused }` payload. EuiSuperDatePicker's `@onRefreshChange` passes through unchanged. `intervalUnits`/`minInterval` were not added.
  - The `Element` type (`HTMLFieldSetElement`). The root is still the quick select panel fieldset (class `euiRefreshInterval`) with the fieldset reset.
  - Local draft behavior and external sync.
- **Deliberate changes:**
  - The fieldset no longer has a `<legend>` or a title section. Upstream renders a plain panel whose switch label names the control. The fieldset was kept for type stability, so it now has no accessible name of its own.
  - Removed: i18n tokens `euiRefreshInterval.legend`, `.start`, `.stop` and `.fullDescription`, and the class `euiRefreshInterval__startButton`.

## Tests

### New: `tests/integration/components/eui-upstream-decisions-test.gts`

This file adds 6 tests.

- **Form focus:**
  - Focus moves to the callout exactly on the invalid transition.
  - Focus stays on the field across re-renders with new errors and title; the element is the same.
  - Becoming valid does not move focus, and the next transition focuses again.
  - `invalidCallout="none"` never focuses.
- **Deprecations, using `getDeprecations()` from `@ember/test-helpers`:**
  - All 10 ids fire with `for`/`since`/`until`.
  - Each message names the component, says "next major version" and gives the alternative.
  - Counts are once per instance and one per stop thumb.
  - Sub-components fire on their own, and updating arguments does not fire again.
- **Refresh interval:**
  - The switch's semantics and visible label; no button and no legend.
  - Fields are disabled while paused and enabled while running.
  - Emitted payloads cover start, edits while running and stop.
  - The value is invalid while running and the on/off description updates.
  - Clicking the label toggles, and Enter starts.

### Updated existing tests

- **`eui-refresh-interval-test.gts`**
  - Start/Stop button assertions became switch `aria-checked` assertions, and the legend check became the switch label check.
  - "an empty value disables the button" became "an empty value is ignored by the switch". The switch is never disabled upstream, so the test now asserts that clicking emits nothing. It starts running because the fields are disabled while paused.
  - "Refresh interval currently set to 2 Minutes." became "Refresh is off, interval set to 2 Minutes." (upstream wording).
  - The "button disabled at 0" check became the value being `aria-invalid` while running. The Enter-is-ignored assertion is kept.
  - The "local edits survive" test now passes `@isPaused={{false}}`, because fields are disabled while paused (the default).
- **`eui-date-pickers-test.gts`** ("refresh interval: quick select panel styles…")
  - The legend now asserts that there is no legend and that the switch label reads "Refresh every".
  - `.euiRefreshInterval__startButton` "Stop" became switch `role`/`aria-checked="true"`.
  - Added: the field is disabled once paused.

No form test asserted the absence of focus, so no form test changed. `eui-super-date-picker-test.gts` clicks the toggle by `data-test-subj` and passes unchanged.

## Checks (2026-10-12, this worktree)

- `ember-tsc --noEmit`: pass.
- ESLint on all changed or new `src`/`tests` files: pass.
- Filtered run (`/upstream decisions|refresh-interval|date picker|super-date|eui-form|suggest|notification|color-stops|color picker|feedback/i`): 123/123.
- Full core suite (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **1057 tests, 1057 pass, 0 fail**.
- `node scripts/generate-api-docs.mjs`: regenerated 2 pages (form-layouts, super-date-picker). `--check` then passes.
- `node --test scripts/eui-upstream-parity.test.mjs`: 304/304. The generator was not touched.

## Unresolved

1. **Deprecation log noise in tests.** The test log now shows the deprecation warnings: 130 `removed-upstream` lines across the suite, from the existing notification/suggest/color stops tests. If that is unwanted, `tests/deprecations.ts` could swallow `*.removed-upstream` ids. It was left alone because it is shared harness.
2. **Validated-form and changeset-form.** Their suites (EuiForm callout focus on submit) and the site/visual checks were not run.
3. **Fieldset without a name.** The refresh interval fieldset has no accessible name now; upstream uses a div. Changing the root to a div would change the public `Element` type.
4. **`components.md` and `progress.md`.** They were not edited, to avoid merge conflicts; the coordinator can add a progress line.
