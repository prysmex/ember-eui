# New components: auto refresh and flyout family

Branch `eui-wave/new-refresh-flyout` (from `feat/eui-latest`). Target EUI
123.1.0 / Borealis 8.1.0. Status: **Migrated** (full core suite green).

## Components and API

- `EuiAutoRefresh`: read-only `EuiFieldText` (value from the new
  `prettyInterval` util: "Off", "5 seconds", "2 minutes") with an
  "Auto refresh" `EuiFormPrepend`-style button, inside `EuiInputPopover` with
  `EuiRefreshInterval`. Args: `@isPaused` (true), `@refreshInterval` (1000),
  `@minInterval` (0), `@intervalUnits` (`s|m|h`), `@onRefreshChange`
  (`{ isPaused, refreshInterval, intervalUnits }`), `@isDisabled`, `@readOnly`
  (true), `@fullWidth`, `@compressed`. Attributes go to the input.
- `EuiAutoRefreshButton`: `EuiButtonEmpty` (`refreshTime` icon, size `s`, color
  `text`) in a tooltip ("Auto refresh is off" / "...is on and set to X") and
  `EuiPopover` with `EuiRefreshInterval`. Extra args `@shortHand`, `@size`,
  `@color`, `@flush`, `@isLoading`, `@isDisabled`, `@css`.
- `EuiFlyoutResizable`: `EuiFlyout` with `resizable` forced on. It is a
  subclass of `EuiFlyout`, so it shares its template, args and behavior.
  Extra `@minWidth`, `@maxWidth` (number), `@onResize(width)`.
- `EuiFlyoutMenu`: the upstream menu bar (public export in 123.1.0): hidden
  title (`@hideTitle`, default true; `@titleId`), close button (`@onClose`,
  `@hideCloseButton`), back button (`@showBackButton`, `@backButtonProps`),
  history popover (`@historyItems`, shown from 2), `@leadingActions`,
  `@trailingActions` (wins over deprecated `@customActions`), `@pagination`,
  `@css`. Dividers and the close spacer follow upstream.
- Private: `EuiFlyoutResizeButton` (the handle).

All style getters are `@cached`; factories go through `useEuiBorealisStyles`.

## Styles

- Generator: added `euiFlyoutResizeButtonStyles` (block `// new-refresh-flyout`)
  with parity coverage. Regenerated `styles.generated.ts` and
  `upstream-sources.json`.
- `euiFlyoutMenuStyles` could not be extracted (it imports `euiScreenReaderOnly`
  from the React accessibility barrel), so it is a hand port in
  `utils/eui/flyout-menu.ts` with a 12-configuration parity test against
  upstream. The generator was not patched.

## Changes to existing components (additive, please review)

- `EuiFlyout` (modal-flyout family): new `@resizable`, `@minWidth`,
  `@onResize`. Window width tracking is now also on while resizable. Behavior
  without `@resizable` is unchanged. Port of `useEuiFlyoutResizable`: the width
  is stored in px and rendered as a percentage of the window (clamped to
  `@minWidth` .. min(`@maxWidth`, 90% window)), arrow keys step 10px (direction
  follows side and RTL), drag listens on `window` (mouse and touch) and
  reports `@onResize` on mouse up, a new `@size` resets the width and window
  resizes rescale it. Not ported: the `container` reference element, sibling
  flyouts and the flyout manager/session API, which Ember's flyout does not
  have.
- `EuiRefreshInterval` (date-pickers family): new `@onRefreshChange` (also
  gets `intervalUnits`), `@minInterval` (clamps edits, sets the field `min`)
  and `@intervalUnits`; `@applyRefreshInterval` is now optional. Existing
  tests pass unchanged.

## Ember differences

- `EuiAutoRefresh*` do not run a timer, like upstream; the docs demo drives a
  counter from `@onRefreshChange`.
- `EuiButtonEmpty` has no `hasAriaDisabled`, so a disabled auto refresh button
  is natively disabled and shows no tooltip.
- `EuiFlyoutMenu` has no flyout context: pass `@onClose`. Actions use camelCase
  (`ariaLabel`, `dataTestSubj`, `toolTipContent`). `iconType` for history is
  per item. There is no `EuiScreenReaderLive`; the pagination counter uses a
  screen reader only `role="status"` region.
- `EuiFlyoutMenu` is not yet auto-rendered by `EuiFlyout` (upstream's
  `flyoutMenuProps`); render it as the first child of the flyout.

## Docs

Demos `d03-auto-refresh-input`, `d04-auto-refresh-button` on the Super date
picker page; `d09-resizable-flyout`, `d10-flyout-menu` on the Flyout page. No
new site pages (nav counts unchanged). API sections regenerated
(`scripts/api-docs-pages.json` lists the new components).

## Checks (2026-10-12)

- `ember-tsc --noEmit`, ESLint on changed files: pass.
- Generator run; parity `node --test`: 311/311 (was 309; +2).
- `generate-api-docs`: pass (99 pages, none stale).
- Rollup: pass; `packages/core/package.json` app-js exports updated.
- Focused `eui-refresh-flyout-test.gts`: 18/18.
- Full core (Playwright Chromium 130): 1152/1152.
- Site checks and site docs build not run.

## Unresolved / notes for the coordinator

- Merge: `components.ts`/`template-registry.ts` additions and generator/parity
  entries are union-friendly; regenerate `styles.generated.ts` after merging.
- Review the additive `EuiFlyout` and `EuiRefreshInterval` args with their
  families' owners.
