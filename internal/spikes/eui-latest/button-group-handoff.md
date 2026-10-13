# Upstream gaps: buttons (`hasAriaDisabled`) and the EuiButtonGroup children API

Branch `eui-wave/button-group`, from `feat/eui-latest`. Target EUI 123.1.0 /
Borealis 8.1.0. Closes the button rows of `docs-audit-gaps.md` (except
`EuiButton` `minWidth`, which was out of scope and is still listed).

## `hasAriaDisabled`

Ported from upstream `useEuiDisabledElement` and threaded like upstream:

- `EuiButton`, `EuiButtonEmpty`, `EuiButtonIcon`: `@hasAriaDisabled`. When the
  button is disabled (`@isDisabled`, `@disabled` or `@isLoading`) it renders
  `aria-disabled="true"` and no `disabled` attribute. The disabled styling is
  unchanged: `display.isDisabled` already has upstream's
  `&[aria-disabled='true'] { pointer-events: none }`.
- `EuiSplitButton`: `@hasAriaDisabled` goes through the split button context
  to both actions (upstream spreads the context over the action's own props,
  so actions only take the split button's value).
- `EuiButtonGroup` options API: `@hasAriaDisabled` swaps the fieldset's
  `disabled` for `aria-disabled` (`"true"`/`"false"`, as React renders
  `aria-disabled={isDisabled}`), and every option button uses it; options can
  override it with their own `hasAriaDisabled`. Disabled options are buttons
  (not radio labels), as before.
- Event blocking: `src/-private/eui-disabled-element.ts` is a function
  modifier (`{{euiDisabledElement isDisabled hasAriaDisabled}}`) that, while
  both are true, does exactly what upstream's hook does: capture listeners on
  click, mouse*, pointer*, touch*, keydown/keyup/keypress and submit call
  `stopImmediatePropagation`/`preventDefault`/`stopPropagation` unless the
  key is Tab or Escape; `element.click` becomes a no-op; `dispatchEvent`
  returns `false` for those events (except Tab/Escape keys). Everything is
  restored when the button is enabled again or removed. Focus and blur are
  untouched, so the button stays focusable and tooltips show on focus.
  Upstream additionally unsets the React `onX` props; in Ember the capture
  listener stops `{{on}}` handlers on the same element instead.

Note for apps: `@ember/test-helpers` `click()` goes through `dispatchEvent`, so
it is swallowed on an aria-disabled button (as in the browser); assert
`aria-disabled` rather than `isDisabled()`.

## EuiButtonGroup

- Per-option `title` (native browser tooltip): defaults to the button text as
  before; `''` unsets it.
- Children API. Upstream picks the API by the `options` prop; so does Ember:
  with `@options` the group renders the unchanged `<fieldset>`, without it a
  `<div role="group" aria-label={{@legend}}>` with `data-variant`,
  `data-size`, `data-display`, `data-layout`, `data-dividers` and
  `aria-disabled`, and `.euiButtonGroup__container > .euiButtonGroup__buttons`
  around the block. New args: `@variant` (`default`/`segmented`/`selection`),
  `@gutterSize` (none…xl, default variant), `@showDividers`, `@wrap`,
  `@layout` (`horizontal`/`vertical`), `@display`
  (`regular`/`highlighted`/`inverse`, selection), and `@type`,
  `@idSelected`, `@idToSelectedMap`, `@onChange` for selection. `@onChange`
  is now optional in the signature (still needed with `@options`).

### Ember shape (decision)

```hbs
<EuiButtonGroup @legend="Actions" @variant="selection" @idSelected={{this.id}} @onChange={{this.select}} as |group|>
  <group.Button @id="save">Save</group.Button>
  <EuiToolTip @content="Delete">
    <group.ButtonIcon @id="delete" @iconType="trash" aria-label="Delete" />
  </EuiToolTip>
</EuiButtonGroup>
```

The block yields `{ Button, ButtonEmpty, ButtonIcon }`: the real
`EuiButton`/`EuiButtonEmpty`/`EuiButtonIcon` curried with one private
`@buttonContext` (upstream `EuiButtonContext`: size, color, isDisabled,
hasAriaDisabled, fullWidth, display, fill, getSelectionProps). Each button
resolves its props with `resolveButtonCommonProps` (port of
`useEuiButtonCommonProps`, same precedence: context wins, except
`isDisabled`/`hasAriaDisabled` which the group only ever sets to `true`).
Why not ember-provide-consume-context like `EuiSplitButton`:

- upstream needs `EuiButtonResetProvider` in `EuiPopover` so buttons inside a
  popover panel don't inherit the group; a provided context would leak into
  popovers/tooltips of another family that we can't change. Yielded
  components are explicit: only buttons the user takes from the block are
  wired, plain `<EuiButton>`s in the block are untouched.
- no context lookup in every button outside groups;
- it reads naturally in Ember and Glint types the yielded components.

Ember differences:

- Selection needs `@id` (new arg on `EuiButton`/`EuiButtonIcon`, also
  rendered as the `id` attribute, like upstream's `id` prop). A plain `id=""`
  attribute is invisible to the component.
- Upstream wraps each child of a segmented/selection group in
  `.euiButtonGroup__item`; a block can't wrap its children, so the yielded
  buttons render that wrapper themselves (`-private/eui-button-group-item.gts`).
  A button wrapped in `EuiToolTip` therefore has the item inside the tooltip
  anchor instead of around it; upstream's item selector also matches
  `.euiToolTipAnchor`, so the layout and dividers are the same.
- Upstream's runtime warnings about child types are not ported.

## Styles

No new style files upstream: `euiButtonGroupStyles` and
`euiButtonGroupButtonsStyles` (with container, gutterSize, noWrap, selection
and dividers) were already extracted, so the generator and parity test are
unchanged. New getters are `@cached` and use `useEuiBorealisStyles`.

## Files

- `packages/core/src/-private/eui-disabled-element.ts` (new modifier)
- `packages/core/src/-private/eui-button-context.ts` (context type + resolver)
- `packages/core/src/-private/eui-button-group-item.gts` (item wrapper)
- `packages/core/src/-private/eui-split-button-context.ts` (+`hasAriaDisabled`)
- `eui-button.gts`, `eui-button-empty.gts`, `eui-button-icon.gts`,
  `eui-button-group.gts`, `eui-button-group-button.gts`,
  `eui-split-button.gts`, `eui-split-button/*.gts`
- Tests: `eui-button-aria-disabled-test.gts` (9),
  `eui-button-group-children-test.gts` (9)
- Docs (`docs/navigation/button`): new `d08b-disabled-and-focusable`
  (side-by-side native/custom disabled), `d10a`–`d10e` (children API, gutter
  size, segmented, vertical layout, selection), `d13` gets the
  `hasAriaDisabled` group; intro and regenerated API tables.

## Checks (2026-10-13)

- `ember-tsc --noEmit`: pass.
- ESLint on all changed/new source and test files: pass.
- Style generator: no changes (only worktree path comments, reverted);
  parity `node --test scripts/eui-upstream-parity.test.mjs`: 349/349.
- API docs: `node scripts/generate-api-docs.mjs` updated the button page.
- Core rollup: pass, no `package.json` change (only `-private` files added).
- Focused (`filter=button`, Chromium 130): 186/186 (168 existing unmodified
  + 18 new).
- Full core suite (Chromium 130): 1320/1320 (main 1302 + 18 new).

## Unresolved / for the coordinator

- `node scripts/generate-api-docs.mjs` also rewrote
  `docs/layout/modal/index.md` (an `@initialFocus` row from a signature
  already on main); reverted here to stay in scope, regenerate after merge.
- Demos were not rendered in the docs site (no site builds per the brief).
- `EuiButton` `minWidth` is still an open gap.
