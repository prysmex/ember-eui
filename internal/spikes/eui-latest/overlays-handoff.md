# Overlays family migration handoff (Popover, ToolTip, ContextMenu)

Branch `eui-wave/overlays`. Target EUI 123.1.0 / Borealis 8.1.0. Status: **ported, rows left `In progress`**: every family test passes, but the full core suite is 758/762 because of 4 `Borealis checkables` failures that also fail on the untouched base commit (verified with a base build). Mark the rows Migrated once the base is green.

## Scope

EuiPopover, EuiPopoverTitle, EuiPopoverFooter, EuiWrappingPopover, EuiInputPopover, EuiToolTip, EuiToolTipPopover (private), EuiContextMenu, EuiContextMenuPanel, EuiContextMenuItem. EuiIconTip: no styles upstream (ToolTip + EuiIcon), unchanged; it now gets the ported tooltip and the `aria-describedby` link. The existing positioning engine (`utils/popover`), focus management (ember-focus-trap, `updateFocus`) and keyboard behavior are kept.

## Files

- Components: `eui-popover.gts`, `eui-popover-title.gts`, `eui-popover-footer.gts` (now Glimmer classes), `eui-wrapping-popover.gts`, `eui-input-popover.gts`, `eui-tool-tip.gts`, `eui-tool-tip-popover.gts`, `eui-context-menu.gts`, `eui-context-menu-panel.gts`, `eui-context-menu-item.gts`.
- `src/-private/eui-popover-panel-context.ts` (new): upstream `EuiPopoverPanelContext` via ember-provide-consume-context; EuiPopover provides its `@panelPaddingSize`, title/footer consume it (default `'l'` outside a popover, as upstream).
- `src/utils/popover/index.ts`: `arrowConfig.borderRadius` (upstream 123): clamps the arrow out of the rounded corner and shifts the panel by the same delta. Additive; callers without it are unchanged.
- `scripts/generate-eui-styles.mjs` (`// overlays` block) and regenerated `styles.generated.ts` / `upstream-sources.json`: `euiPopoverStyles`, `euiPopoverTitleStyles`, `euiPopoverFooterStyles`, `euiPopoverPanelStyles`, `euiPopoverArrowStyles`, `euiToolTipStyles`, `euiToolTipAnchorStyles`, `euiToolTipBackgroundColor`, `euiToolTipBorderColor`, `euiContextMenuStyles`, `euiContextMenuVariables`, `euiContextMenuItemStyles`, `euiContextMenuPanelStyles`, `euiContextMenuPanelTitleStyles`, `euiListItemLayoutStyles`, `euiListItemLayoutWrapperStyles`, `euiListItemVariables`. All extracted cleanly (no hand port needed). Worktree-only `../../…/Users/…` source-path comments were normalized back to `node_modules/…` with sed. EuiInputPopover's max width uses the already-extracted `euiFormVariables(...).maxWidth` (= upstream `euiFormMaxWidth`), so the shared `form.styles.js` entry was not edited.
- `scripts/eui-upstream-parity.test.mjs`: the 15 factories (tooltip color helpers excluded, they are plain getters) join the 12-configuration matrix.
- Tests: new `tests/integration/components/eui-overlays-test.gts` (module `Borealis overlays`, 15 tests). Existing tests updated (below).
- API docs regenerated with `node scripts/generate-api-docs.mjs`.

## API / default changes (latest-only)

**EuiPopover**
- **Defaults now upstream: `@anchorPosition` `'downLeft'` (was `'downCenter'`), `@hasArrow` `false` (was `true`).** Offsets follow upstream: `@offset` defaults to 0 with an arrow and 4 without, then +16 (arrow) / +8 (no arrow), and no extra for `@attachToAnchor`. Arrow config is upstream's 16px wide / 10px buffer / 12px corner (was 24px Amsterdam arrow).
- The panel is no longer an `EuiPanel` component: it is a div whose single Emotion class composes upstream `EuiPanel` (plain, no border/shadow, radius m, padding) + `euiPopoverPanelStyles` (background var, floating border pseudo, medium `filter` shadow, opacity/transform transitions behind `euiCanAnimate`, `isAttached` shadows), plus a scoped reset and the theme's paragraph color (portaled content leaves the provider's color wrapper). Two Emotion classes on one element would have made precedence depend on insertion order. Classes: `euiPanel euiPanel--plain euiPopover__panel` + `@panelClassName`; `data-popover-panel`, `data-popover-open` (upstream). The coordinator may switch this to `<EuiPanel @css=…>` once `@css` lands; the composed result is identical.
- Removed legacy classes: `euiPopover--anchor*`, `euiPopover--display*`, `euiPopover__panel--{position}`, `-isOpen`, `-noArrow`, `-isAttached`, `euiPopover__panelArrow*`. Kept: `euiPopover`, `euiPopover-isOpen`, `euiPopover__anchor`, `euiPopover__panel`.
- Arrow markup is upstream's: `div.euiPopover__arrowWrapper` (positioned) > `div.euiPopover__arrow[data-popover-arrow=<position>]`; `<:arrowChildren>` renders in the wrapper. Dark mode and high contrast give the arrow a border.
- `@display` accepts any CSS display value (`inlineBlock`/`block` mapped).
- `@panelStyle` is applied again (was documented as no-op; it already merged into the inline styles). `@panelPaddingSize` accepts `xs`/`xl` (upstream, discouraged).
- New args: `@popoverScreenReaderText`, `@repositionToCrossAxis` (default `true`), private `@rootCss` (used by EuiInputPopover, like upstream's `css` prop).
- Screen reader text is upstream's i18n token `euiPopover.screenReaderAnnouncement` ("You are in a dialog. Press Escape, or tap/click outside the dialog to close."; was "…To close this dialog, hit escape.").
- **New a11y (upstream):** the first focusable element of the anchor gets `aria-expanded` and, while open, `aria-controls=<panel id>`, only if it is a `<button>`/`role="button"` (inputs untouched).
- An open popover repositions when `@anchorPosition`, `@buffer`, `@offset` or `@panelPaddingSize` change (upstream `componentDidUpdate`).
- `will-change: transform, opacity` until the panel is stable (upstream).
- Not ported: upstream's initial focus on the panel itself (Ember keeps focusing the first tabbable), `panelProps`, `focusTrapProps`, `onPositionChange`, `aria-live` prop, stranded-focus handling.

**EuiPopoverTitle / EuiPopoverFooter**: upstream styles (title xxs / small text, borders, panel radius corners, footer `popoverFooterBorderColor`); padding defaults to the containing popover's `@panelPaddingSize` with negative margins covering it. `--padding*` classes removed.

**EuiInputPopover**: upstream `max-width: forms.maxWidth` unless `@fullWidth` (class `euiInputPopover--fullWidth` removed); default `@offset` 2 and `@repositionToCrossAxis` false (upstream); new `@panelMinWidth`; panel width set as `inline-size`. Not ported: `closeOnScroll`, repositioning on input resize.

**EuiWrappingPopover**: also forwards `@offset`, `@buffer`, `@zIndex`, `@repositionOnScroll`, `@repositionToCrossAxis`, `@popoverScreenReaderText`, `@ariaLabel`, `@ariaLabelledBy`.

**EuiToolTip / EuiToolTipPopover**
- Upstream `euiToolTipStyles` (tooltip background, ghost text, control radius, 256px max, `levels.toast` z-index, xs font, shadow or HC border, fade-in behind `euiCanAnimate`), arrow (`euiToolTip__arrow` + position slot, 12px), title. Anchor: upstream `euiToolTipAnchorStyles` (display + disabled children `pointer-events: none`). `euiToolTipAnchor--displayBlock` removed; `@display` adds `'flex'`.
- **The anchor no longer has `role="tooltip"`** (it was wrong; the popover keeps it). Anchor gets `id="<tooltip id>-wrapper"` (upstream NVDA fix).
- **New a11y:** while visible, the anchor's first element child gets the tooltip id prepended to `aria-describedby` (existing ids kept, restored on hide). With `@attachTo` the attached element gets it. New `@disableScreenReaderOutput` turns this off.
- New: Escape on the anchor hides the tooltip (stops propagation when visible, unless `@disableScreenReaderOutput`); `@offset` (default 16); arrow corner clamp with `radius.control`; `data-position` on the popover.
- Upstream `toolTipManager`: one tooltip at a time; a tooltip replacing another (or within 250ms of one closing) skips the fade in (`animation: none` inline). Exported as `toolTipManager`.
- Kept: `@delay` JS delay (250ms / 1250ms). Upstream has no delay prop; its CSS animation adds a 150ms delay, so the effective delay is now 400ms by default. Kept: focus shows the tooltip on any focus (upstream only on `:focus-visible`).

**EuiContextMenuItem**
- Upstream `EuiListItemLayout` structure and styles: `button|a.euiContextMenuItem.euiListItemLayout` > `span.euiListItemLayout__content` > `__prepend` (icon/spinner) + `span.euiListItemLayout__text.euiContextMenuItem__text` (wrapping) + `__append` (panel arrow). Interactive hover, disabled (`textDisabled`, not-allowed), scoped button reset.
- Removed: `euiContextMenu__itemLayout(--top/--bottom)` wrapper, `euiContextMenuItem-isDisabled`, `euiContextMenuItem--small`. **`@size` is deprecated/no-op** (no sizes upstream); `@layoutAlign` kept (deprecated upstream) and now aligns the prepend.
- New `@color` (`text` default, e.g. `danger`, upstream button-empty colors), `@toolTipContent` / `@toolTipTitle` (EuiToolTip on the right, block anchor).
- Icon classes `euiContextMenu__icon` / `euiContextMenu__arrow` are plain class names only (coordinator rule: no second Emotion class on migrated children). Upstream's `euiContextMenu__icon` (`flex-shrink: 0`) is already EuiIcon's own style. **Needs EuiIcon `@css`:** `euiContextMenuItem__arrow` (`align-self: flex-end`) for the panel arrow, and `euiContextMenu__icon` for EuiLoadingSpinner — pass `styles.euiContextMenuItem__arrow` / `styles.euiContextMenu__icon` through `@css` at merge.

**EuiContextMenuPanel**: upstream panel styles (padding s, focus outline offset) and slide animations (`next|previous` × `in|out` keyframes, `animation.normal`, resistance easing, `pointer-events: none` while sliding, 0s under reduced motion; zero-duration animations now complete the transition immediately). Title is upstream's: `div.euiContextMenuPanelTitle` (`data-test-subj="contextMenuPanelTitle"`) with an `EuiButtonIcon` back button (`data-test-subj="contextMenuPanelTitleButton"`, `aria-label` token `euiContextMenuPanelTitle.ariaLabel` "Close current panel:", `aria-labelledby` button + title) and an `h2.euiContextMenuPanelTitle__text` (heading reset). **Was:** the whole title was a `button.euiContextMenuPanelTitle`. `--small` removed, `@size` deprecated. List div is `.euiContextMenuPanel__list`; with private `@isMenu` it gets `role="menu"` + `aria-labelledby` (title). Back icon is `arrowLeft` (we don't ship upstream's `chevronSingleLeft`).

**EuiContextMenu**: upstream root (256px wide, panel radius, overflow hidden, height transition); panels `position: absolute` (upstream); items from descriptors get `role="menuitem"`, separators `EuiHorizontalRule @margin="xs" role="separator"` (was margin none); descriptors accept `color`, `toolTipContent`, `toolTipTitle`. `euiContextMenu--small` removed, `@size` deprecated.

## Legacy test assertions changed

- `eui-popover-test.gts`: `euiPopover--anchorUpCenter` + `euiPopover__panel--top` → panel geometry above the trigger; `euiPopoverTitle--paddingSmall` / `euiPopoverFooter--paddingMedium` → computed padding 8px / 16px (Borealis `m` is 16px); `euiPopover--displayBlock` → computed `display: block`; `-noArrow` → no `.euiPopover__arrow`; `euiInputPopover--fullWidth` / `-isAttached` → computed `max-width: 100%`, no arrow, `transform: none`.
- `eui-context-menu-test.gts`: disabled/small/layout classes → computed `cursor`/`align-self`; title button → upstream back button `[data-test-subj="contextMenuPanelTitleButton"]` + `h2`; `--small` → asserts the class is absent. Panel navigation tests now wait for the slide to finish (`waitUntil` one panel left / focus moved): with Borealis animations both panels coexist for `animation.normal` (250ms). The keyboard/focus expectations are unchanged.

## Checks (worktree, Chromium 130, CI=true, Node 22; pnpm unavailable, binaries run directly)

- Core (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **762 tests, 758 pass, 4 fail**. The 4 failures are `Borealis checkables`: "EuiCheckbox measures every state…", "EuiCheckbox keeps native semantics…", "EuiCheckbox reactive args…", "EuiRadio states, the dot…" (icon marks visible when unchecked). The same 4 fail on the base commit 971c518a built without my changes (filtered run: 7 pass, 4 fail), so they predate this branch (the EuiIcon display change the coordinator reported). All 15 `Borealis overlays` tests and the updated `eui-popover`, `eui-tool-tip`, `eui-context-menu` modules pass.
- The first full run also failed `eui-tour: a step on its own`: EuiTourStep relied on the old `hasArrow=true` default for its beacon. Fixed in the caller as upstream does (`@hasArrow={{this.hasBeacon}}`, offset 10 only with a beacon); `eui-tour-step.gts` is otherwise untouched.

- `node --test scripts/eui-upstream-parity.test.mjs`: 109/109 pass (15 new overlays factories).
- `node scripts/generate-eui-styles.mjs --check`: expected worktree failure (symlinked `node_modules` path comments); regenerated and normalized.
- `ember-tsc --noEmit`: pass. ESLint on all changed sources/tests: pass.

## Unresolved / for the coordinator

0. **Stash race (resolved).** A `git stash` round-trip used to verify the base failures swapped work with the header agent (`refs/stash` is shared by all worktrees). Resolved: this branch's commit was checked against the overlays stash `9c614fc4` (tracked and untracked parts identical except the later row/handoff edits). The `RECOVER eui-wave/header work` and `WIP on eui-wave/overlays` stash entries are now redundant; the coordinator will drop them. No `git stash` is used anymore.
1. EuiIcon `@css` for the context menu item arrow/spinner (above).
2. `eui-combo-box.gts` hard-codes legacy `euiPopover__panel-isAttached euiPopover__panel--bottom euiPopover__panel-isOpen euiPanel…` classes on its power-select dropdown; those carry no styles now. The combo box family should compose `euiPopoverPanelStyles` (isAttached) instead.
3. `eui-selectable-template-sitewide.gts` queries `.euiPopover__panel` (still present).
4. Avatar tooltip (icon handoff #1) can now use EuiToolTip.
5. Default changes (`downLeft`, no arrow) affect every caller that relied on the old defaults (super select, date pickers, header popovers…); they pass explicit args where they need them? Audit visually in the showcase/site.
6. Upstream z-index comes from `getElementZIndex` + 2000 (unchanged), not theme levels; only the tooltip uses `levels.toast`.
7. `utils/css-mappings/eui-popover*.ts`, `eui-context-menu-item.ts`, `eui-tool-tip*.ts` are unused by these components now (pagination-button still imports a footer type).
8. Not run (coordinator): rollup build, site build/acceptance, showcase screenshots, forced-colors emulation.
