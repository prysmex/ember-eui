# New components: inline edit, split button, form control button, append/prepend

Branch `eui-wave/new-inline-split` (merged with `feat/eui-latest` at
b1004ad0). Target EUI 123.1.0 / Borealis 8.1.0. Status: **Migrated**.

## Files

New components:

- `eui-inline-edit-text.gts`, `eui-inline-edit-title.gts`, private
  `eui-inline-edit/eui-inline-edit-form.gts` (upstream `EuiInlineEditForm`).
- `eui-split-button.gts`, `eui-split-button/eui-split-button-action-primary.gts`,
  `eui-split-button/eui-split-button-action-secondary.gts`.
- `eui-form-control-button.gts`.
- `eui-form-append.gts`, `eui-form-prepend.gts`, private
  `eui-form-control-layout/eui-form-append-prepend.gts`.
- `-private/eui-form-control-layout-context.ts`,
  `-private/eui-split-button-context.ts` (ember-provide-consume-context).
- `utils/eui/split-button.ts`: per-theme + per-argument memo for the split
  button factories, which take a second argument (so `useEuiBorealisStyles`
  can't memoize them).

Edits to existing components (integration as upstream does it):

- `eui-form-control-layout.gts`: provides upstream's
  `EuiFormControlLayoutContext` (compressed, inputId, isDisabled, isInvalid,
  isLoading, readOnly). `@inputId` is no longer deprecated: append/prepend
  labels point to it.
- `eui-field-text/number/password/search.gts`, `eui-select.gts`: pass
  `@inputId` to their layout (one line each).
- `eui-super-date-picker/eui-quick-select-popover.gts`: its hand-rolled
  prepend button is replaced by `EuiFormPrepend @element="button"`, like
  upstream. Same classes and `data-test-subj`; its tests still pass.

Generator/parity: new factories `euiInlineEdit{ReadMode,Text,Title}Styles`,
`euiSplitButton{,Action,Divider}Styles`, `getEuiButtonColorValues`,
`getEuiFilledButtonColorValues` (under an extension-less `_button` key so the
existing `_button.js` entry wasn't edited) and `euiFormControlButtonStyles`.
There's a parity test that runs every split button argument in 12 theme
configurations. The merge left one duplicate key in each script: the
`skeleton_rectangle` entry also exists in new-skeleton's block. I dropped my
copy.

Docs: new pages `forms/inline-edit` (3 demos),
`forms/form-controls/form-control-button` (1 demo) and
`forms/form-controls/form-append-prepend` (1 demo). On the button page I
rewrote `d08-split-buttons` to use `EuiSplitButton` (it used to say EUI has no
split button) and added the split button to the page's API list. I also
registered the new pages in `scripts/api-docs-pages.json`. The append/prepend
and inline-edit pages have a hand-written args table because the API
generator only prints "Also takes the args of …" for shared arg interfaces.

## API / Ember differences

- `EuiSplitButton` yields `{ ActionPrimary, ActionSecondary }` (upstream
  `EuiSplitButton.ActionPrimary`). The divider is rendered by
  `ActionSecondary`. `@popoverProps`/`@tooltipProps` take the listed
  EuiPopover/EuiToolTip args, and the secondary's block is the popover
  content.
- `EuiInlineEdit*` accept upstream `readModeProps`/`editModeProps` as plain
  objects with the subset listed in the signature. `@onSave` may return
  `false` or a promise (not wrapped in a test waiter, because the promise
  belongs to the app). In edit mode, loading uses the real
  `EuiSkeletonLoading` + `EuiSkeletonRectangle`.
- `EuiFormControlButton` has no text wrapper: the EuiButtonEmpty text span is
  given `display: contents`. `contentProps.css`/`textProps.css` become
  `@contentCss`/`@textCss`.
- `EuiFormAppend`/`EuiFormPrepend` inherit compressed/disabled/inputId from
  the layout context, as upstream does. Put them in the fields'
  `<:prepend>`/`<:append>` blocks.

## Fixes made while finishing (previous agent was cut off)

- The read mode value was a lazy `@tracked` initializer. The first read
  happened only on cancel, so it picked up the edited controlled value. It is
  now seeded in the constructor.
- Fixed tests that asserted non-upstream behavior:
  - Focus outline wins over invalid (upstream `:not(:focus)`).
  - The disabled divider rule only applies when the secondary is a bare
    sibling.
  - Popover content is portalled to the body.
  - The spinner class is `euiBorealisLoadingSpinner`.
  - The side node pads its content by size.xs.
  - The form disabled token is `colorDisabled`.
  - The EuiFormLabel color transition is finished before reading the color.

## Checks (2026-10-12, worktree)

- `ember-tsc --noEmit`: pass. ESLint on changed src/test files: pass.
- `generate-eui-styles.mjs --check`: 361 factories, up to date. Parity
  314/314.
- `generate-api-docs.mjs --check`: up to date (102 pages).
- Rollup core build: pass; `package.json` app-js exports committed.
- Vite test build: 3167 modules. Focused `eui-inline-split-test.gts`: 12/12.
- Full core suite (Chromium 130): **1146/1146**.

## Unresolved / for the coordinator

- Site not built or run (per brief). There are 3 new docs pages, so the
  site's navigation-count test probably needs updating from 104 to 107. Demos
  have not been rendered in the site.
- `scripts/api-docs-pages.json`, `components.ts`, `template-registry.ts`,
  `components.md` and the generator/parity entry lists merge as a union.
  `styles.generated.ts` and `upstream-sources.json` should be regenerated
  after merging.
- I touched `eui-quick-select-popover.gts` (super-date-picker family), as
  described above.
