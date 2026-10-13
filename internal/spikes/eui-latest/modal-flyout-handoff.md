# Modal and flyout family migration handoff

Branch `eui-wave/modal-flyout`. Target EUI 123.1.0 / Borealis 8.1.0. Status: **In progress, port complete**. The family tests pass, but the full core suite has 4 failures. Those failures are in `Borealis checkables` and also fail on the untouched base commit (checked with this branch's changes stashed). Per the brief, the rows stay `In progress` until the suite is green.

## Files

- Components (all now Glimmer classes with `@cached` class/style getters; factories go through `useEuiBorealisStyles`):
  - `eui-modal.gts`, `eui-modal-header.gts`, `eui-modal-header-title.gts`, `eui-modal-body.gts`, `eui-modal-footer.gts`
  - `eui-confirm-modal.gts`
  - `eui-flyout.gts`, `eui-flyout-header.gts`, `eui-flyout-body.gts`, `eui-flyout-footer.gts`
- `utils/eui/modal-flyout.ts` (new, upstream license header). It holds what upstream does in hooks or components:
  - the push padding registry from `flyout.component.js`;
  - `useEuiFlyoutZIndex` for unmanaged flyouts;
  - a border-box width observer;
  - React's number-to-px conversion for inline styles;
  - `dialogDescription`, which merges the SR description id into `aria-describedby` and auto-labels a modal from its title.
- Generator (`// modal and flyout` block, 130 factories):
  - `euiModalStyles`, `euiModalHeaderStyles`, `euiModalBodyStyles`, `euiModalFooterStyles`;
  - flyout `const.js` (`FLYOUT_SIZES/SIDES/TYPES/PADDING_SIZES`, `isEuiFlyoutSizeNamed`);
  - `euiFlyoutStyles`, `composeFlyoutInlineStyles`, `FLYOUT_BREAKPOINT`;
  - `euiFlyoutCloseButtonStyles`, `euiFlyoutHeaderStyles`, `euiFlyoutBodyStyles`, `euiFlyoutFooterStyles`.

  Everything extracted without hand ports. `styles.generated.ts` and `upstream-sources.json` were regenerated.
- Parity:
  - 9 factories added to the 12-configuration matrix;
  - a new test covering the flyout constants plus `composeFlyoutInlineStyles` over sizes × maxWidth × z-index.
- Tests:
  - new `tests/integration/components/eui-modal-flyout-test.gts` (13 tests);
  - updated `eui-flyout-test.gts` (see below).
- API docs regenerated: `docs/layout/modal`, `docs/layout/flyout`.

## API / default changes (latest-only)

### EuiModal

- **`@maxWidth` defaults to `true`** (upstream). The default width is now capped at the `m` breakpoint (768px). The minimum is the 400px form max width. It now also accepts numbers (px).
- **New args:** `@outsideClickCloses` (alias of `@clickOutsideToClose`) and `@initialFocus`.
- **Semantics:**
  - `role="dialog"` and `aria-modal="true"` before `...attributes`, so callers can override the role.
  - An SR-only `<p>` description (`euiModal.screenReaderModalDialog`) is merged into `aria-describedby`.
  - **Ember addition:** a modal without `aria-label`/`aria-labelledby` gets `aria-labelledby` pointing at its `.euiModalHeader__title`. An id is generated when the title has none.
- **Escape:**
  - It is now a `keydown` on the modal, as upstream. It closes only when the event comes from inside the modal, and it stops propagation, so nested overlays don't all close.
  - It was a global `ember-keyboard` handler.
- **Focus trap defaults:** `allowOutsideClick: true` (so mask clicks reach the mask) and `escapeDeactivates: false`. Caller options are merged over these.
- **Markup:**
  - The `euiModal__flex` wrapper is removed; header, body and footer are direct flex children.
  - The close button comes after the content, as upstream. It keeps the "Close this dialog" label and the `euiModal__closeIcon` class, and sits in a `span.euiModal__closeIconWrapper` (see the `@css` note under "Needed changes").
- **Color:** sets `color: textParagraph` from the nearest provider. This stands in for upstream's portal theme class.

### EuiModalHeaderTitle

- Gets the upstream `EuiTitle size="m"` styles and the `euiTitle` class.
- Nested `h1`–`h6`/`p` inherit through a `:where()` reset.
- It is still a `div`; upstream renders the heading itself. `Element` is unchanged.

### EuiConfirmModal

- `role="alertdialog"` and upstream `confirmation` styles. The `euiModal--confirmation` class is kept.
- **New args:** `@defaultFocusedButton` (`'confirm' | 'cancel'`, implemented through the trap's `initialFocus`) and `@maxWidth`.
- `@title` renders in an `<h1>` and `@message` in a `<p>`.
- Upstream `data-test-subj`s were added.
- `buttonColor` defaults to `primary`.

### EuiFlyout

- **Styles:** upstream sizes `s/m/l` plus new `fill`. Custom sizes go inline; numbers become px.
- **`@maxWidth`:** `false` (default) means no max width, so `l` is 75% wide. `true` uses the size's max, and numbers or CSS strings are accepted.
- **Padding:** `@paddingSize` is applied through the flyout's descendant rules and `--euiFlyoutBodyPadding`.
- **Removed legacy classes:** `euiFlyout--{size,side,type,padding*}` and `--maxWidth-default`.
- **Markup:**
  - The children are wrapped in `.euiFlyout__content` (upstream).
  - An SR description is added, as for the modal.
  - `tabindex="0"` and `data-autofocus` apply when not pushed. It was `tabindex="-1"`.
- **Role:** `role` defaults to `dialog` with `aria-modal`. A pushed flyout has no role, aria-modal, tabindex or description unless you pass `@role`. `@role={{null}}` is still honored.
- **Mask:**
  - The mask is now a **sibling** of the portalled flyout, not its parent.
  - `z-index` uses `levels.flyout` (or `levels.mask` with `@maskProps={{hash headerZindexLocation="above"}}`). `@maskProps` had no effect before.
  - The mask gets the level minus 2 through an `!important` class, as upstream.
  - `top` follows `var(--euiFixedHeadersOffset, 0)`.
- **Outside clicks:**
  - Mask clicks close the flyout unless `@outsideClickCloses={{false}}`. Before, they always closed it.
  - Without a mask, outside clicks close it only with `@outsideClickCloses={{true}}`.
- **Escape:** a window keydown, as upstream. **Pushed flyouts no longer close on Escape** (upstream).
- **Push:**
  - Uses theme breakpoints, so overrides apply.
  - Pads `<body>` with `padding-inline-start/end` set to the border-box width. This is logical, so it mirrors in RTL; it used to be physical `paddingLeft/Right`.
  - With several pushed flyouts on a side, the widest one wins.
  - The app's own inline padding is restored afterwards, and `--euiPushFlyoutOffsetInline{Start,End}` is set on `<html>`.
  - It is rendered in place (no portal), as upstream.
- **Animation:** new `@hasAnimation` (default `true` for overlays, `false` for push). The slide-in only runs under `prefers-reduced-motion: no-preference`.
- **Body class:** `euiBody--hasFlyout` is now ref-counted (`setBodyClass`).
- **Focus trap default:** gains `escapeDeactivates: false` and a `fallbackFocus` (the flyout). Flyouts with no tabbable content no longer throw.
- **Exports:** `SIZES`/`EuiFlyoutSize` are now `['s','m','l','fill']` from upstream `const.js`. `utils/css-mappings/eui-flyout.ts` is now unused; I left it in place.
- **Close button:** sits in `span.euiFlyout__closeButtonWrapper` (positioning, `outside` translate).

### Flyout parts

- **EuiFlyoutHeader:** upstream styles. The `--hasBorder` class is removed; the flyout pads a bordered header through upstream's `[class*='euiFlyoutHeader-hasBorder']` (the Emotion label).
- **EuiFlyoutBody:** upstream scroll shadows. New `@scrollableTabIndex` (default 0). The `--hasBanner` class is removed. The content wrapper is always rendered.
- **EuiFlyoutFooter:** `flyoutFooterBackground`, plus a border-top in high contrast.

### Not ported

The upstream flyout manager (sessions, child flyouts, `hasChildBackground`, stacked/side-by-side), `resizable`, flyout menu, the `container` prop, and focus-trap shards for fixed headers (`includeFixedHeadersInFocusTrap`).

## Needed changes in other families (not edited)

1. **`@css` on EuiButtonIcon (coordinator rule).** The close buttons do not get a second Emotion class. Positioning lives on wrapper spans until `@css` is available in this branch. At merge, pass these as `@css` to EuiButtonIcon and drop the wrappers:
   - **Modal:** `EuiModal#closeIconCss` (the upstream `euiModal__closeIcon` slot), i.e. `@css={{this.closeIconCss}}`.
   - **Flyout:** `EuiFlyout#closeButtonPositionCss` together with `#closeButtonLookCss`, i.e. `@css` = `[...closeButtonPositionCss, closeButtonLookCss]`.

     Not yet applied: the `outside` button's XL shadow / `animation:none`, and `inside`'s explicit `background-color: transparent`. The empty display is already transparent, and the tests assert that.
2. **EuiPortal:** it does not add the provider's color class to portalled content. Modal and flyout set `color: textParagraph` themselves to compensate.

## Existing tests changed

- `eui-flyout-test.gts`:
  - The mask is now a sibling: `.euiOverlayMask .euiFlyout` became separate existence checks.
  - `euiFlyout--medium/--paddingLarge` became the measured default width (`max(424px, 50vw)`) plus 24px header padding.
  - `euiFlyoutHeader--hasBorder` became a computed 1px bottom border.
  - `euiFlyoutBody__overflow--hasBanner` became a check that the banner is the overflow's first child.
  - `euiFlyout--small/--left/--paddingNone` became measured left 0, small width and `--euiFlyoutBodyPadding: 0`. Animations are finished first.
- `eui-modal-test.gts`, `eui-modal-parts-test.gts` and `eui-collapsible-nav-test.gts` pass unchanged.

## Coverage (`eui-modal-flyout-test.gts`, 13 tests)

- **Modal measurements:**
  - default 768px cap, `false`, px, rem and the 400px minimum, without replacing the element;
  - surface, text color, 16px frame radius, border, XL shadow, z-index 8000, 75vh;
  - header/body/footer padding, gap and alignment;
  - the nested h1 matches `EuiTitle m`;
  - close button position (LTR and RTL);
  - header+footer padding and last-body padding;
  - the reduced-motion guard.
- **Modal behavior:**
  - Escape from inside (prevented, no propagation) vs from outside;
  - mask clicks off by default and on with either arg; inside clicks never close;
  - close button.
- **Modal a11y and focus:**
  - dialog/aria-modal/tabindex; SR description text, visually hidden and merged with the caller's describedby;
  - auto labelledby, and the caller's labelledby/role win;
  - self focus, Tab stays trapped, `@initialFocus`;
  - mask/body class cleanup.
- **Confirm modal:**
  - alertdialog, h1/p, test subjects, labelledby;
  - primary/danger fills equal reference EuiButtons and are reactive on the same element;
  - `defaultFocusedButton` confirm/cancel;
  - cancel/confirm/Escape/close calls;
  - loading (disabled, `aria-busy`, spinner) and disabled; no body without a message.
- **Flyout measurements:**
  - s/m/l/fill measured with and without max width;
  - numeric and CSS `maxWidth`; numeric and CSS sizes;
  - fixed/full height/edge; surface, color and z-index; overlay shadow.
- **Flyout padding:** none/s/m/l reaching the header (bordered), body, banner and footer on the same elements; header border token; footer background; scrollable body; content wrapper; pinned footer; `@scrollableTabIndex`; the `<:content>` block.
- **Flyout sides, RTL and close button:**
  - right/left sides and RTL mirroring;
  - inside/outside close button geometry on both sides;
  - `closeButtonProps` class/onClick;
  - animations: 0s base duration, motion only under no-preference.
- **Z-index:** flyout/mask levels for below/above relative to `levels.header`, siblings, the `--euiFixedHeadersOffset` top, reactive on the same element.
- **Push:**
  - body padding equals the border-box width, plus the CSS variable;
  - no mask, rendered in place, no dialog attributes, border-inline-start, z-index, no animation;
  - Escape ignored;
  - padding follows size changes; with two flyouts the widest wins;
  - the side switch restores the other side; teardown restores the app's own padding and the variables;
  - below the breakpoint it becomes an overlay.
- **Flyout behavior:**
  - dialog semantics and labelledby; both description texts; self focus;
  - Escape; mask click and `outsideClickCloses=false`;
  - no-mask outside clicks (default off, on with the arg, inside ignored);
  - ref-counted body class; `@role={{null}}`; no close button without `@onClose`.
- **Themes:**
  - light/dark nearest provider for portalled flyouts and modals;
  - sibling isolation;
  - nested JS-object overrides (`size.l`, `border.radius.frame`, `levels.flyout` → mask 1498);
  - mode/override changes on the same element.
- **High contrast:** flyout full border instead of shadow, footer border-top, no modal shadow.

## Checks (2026-10-12, this worktree, Chromium 130, Node 22, binaries run directly)

- `node scripts/generate-eui-styles.mjs --check`: pass (130 factories).
- `node --test scripts/eui-upstream-parity.test.mjs`: **104/104 pass**.
- `ember-tsc --noEmit`: pass. ESLint on all changed components, `modal-flyout.ts` and both test files: pass.
- `node scripts/generate-api-docs.mjs --check`: pass, after regenerating 2 pages.
- Filtered runs: `Borealis modal and flyout` 13/13, `eui-flyout` 6/6, `modal` 22/22, `collapsible` 5/5.
- Full core suite (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **760 tests, 756 pass, 4 fail.**
  - The failures are all in `Borealis checkables`: EuiCheckbox states/semantics/reactive and EuiRadio. The first one: "no mark when unchecked", where the actual value was `check,stopFilled`.
  - The same 4 fail on the base commit with this branch's changes stashed (11 tests, 7 pass), which matches the coordinator's note about EuiIcon breaking checkbox marks.
- Not run (root): rollup build, site build/acceptance, showcase screenshots.

## Unresolved / next step

1. Fix the checkables failures on the base, re-run the full suite, then flip these 10 rows to `Migrated`.
2. At merge, switch the close buttons to EuiButtonIcon `@css` (see "Needed changes").
3. Docs demos (`docs/layout/modal`, `docs/layout/flyout`) need a visual pass:
   - the modal is now capped at 768px by default;
   - flyout `l` is 75% wide without `@maxWidth`;
   - the mask is no longer the flyout's parent.
4. Delete `utils/css-mappings/eui-flyout.ts` (and its registry entry) in a coordinated cleanup.
