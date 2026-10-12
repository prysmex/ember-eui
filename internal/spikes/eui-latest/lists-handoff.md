# Lists family migration handoff (ListGroup, PinnableListGroup, KeyPadMenu, DescriptionList, SideNav)

Status: **Migrated**. The full core suite passes in Chromium 130 (715/715), along with upstream parity (76/76), types, lint and API docs.

## Files

- Components, now Glimmer classes on extracted factories (all style getters are `@cached`, factories only go through `useEuiBorealisStyles`, static resets are module constants):
  - `eui-list-group.gts`, `eui-list-group-item.gts`, `eui-pinnable-list-group.gts`
  - `eui-key-pad-menu.gts`, `eui-key-pad-menu-item.gts`
  - `eui-description-list.gts`, `eui-description-list-title.gts`, `eui-description-list-description.gts`
  - `eui-side-nav.gts`, `eui-side-nav-item.gts`, `eui-side-nav-item/button.gts`
- `src/-private/eui-list-context.ts` (new): `ember-provide-consume-context` contexts for ListGroup → items (`color`, `wrapText`) and DescriptionList → title/description (upstream React contexts), plus the `responsiveColumn` media-query helpers.
- `src/utils/eui/lists.ts` (new, upstream license header): hand port of `key_pad_menu_item.styles.js` (`euiKeyPadMenuItemStyles`, `euiKeyPadMenuItemChildStyles`). The upstream module imports the React `components/accessibility` barrel, which the generator rejects; the port composes the extracted pure helpers in upstream order.
- `src/helpers/is-item-open.ts`: new `isItemSelected` (item `isSelected` or id match; an undefined `@selectedItem` no longer matches an item without an id).
- `scripts/generate-eui-styles.mjs`, `// lists` block (84 factories, was 63):
  - `components/list_item_layout/_list_item_layout.styles.js`: `euiListItemLayoutStyles`, `euiListItemLayoutWrapperStyles` (upstream ListGroupItem renders through the internal EuiListItemLayout)
  - `list_group/list_group.styles.js`: `euiListGroupStyles`
  - `list_group/list_group_item.styles.js`: `euiListGroupItemStyles`, `euiListGroupItemTooltipStyles`
  - `list_group/list_group_item_extra_action.styles.js`: `euiListGroupItemExtraActionStyles`
  - `list_group/pinnable_list_group/pinnable_list_group.styles.js`: `euiPinnableListGroupItemExtraActionStyles`
  - `key_pad_menu/key_pad_menu.styles.js`: `euiKeyPadMenuStyles`, `euiKeyPadMenuVariables`
  - `description_list/description_list{,_title,_description}.styles.js`: `euiDescriptionListStyles`, `euiDescriptionListTitleStyles`, `euiDescriptionListDescriptionStyles`
  - `side_nav/side_nav.styles.js`: `euiSideNavMobileStyles`; `side_nav/side_nav_item.styles.js`: `euiSideNavItemStyles`, `euiSideNavItemButtonStyles`
  - Pure helpers for the hand port and local use: `logicalCSS`, `logicalSizeCSS` (`functions/logicals.js`), `euiFontSize`, `euiTextTruncate` (`mixins/_typography.js`), `highContrastModeStyles` (`functions/high_contrast.js`), `euiScreenReaderOnly` (`accessibility/screen_reader_only/screen_reader_only.styles.js`).
  - `styles.generated.ts` / `upstream-sources.json` regenerated (source-path comments normalized to `node_modules/…`).
- `scripts/eui-upstream-parity.test.mjs`: the 14 generated factories in the `factories` map (12-configuration matrix), plus 3 tests: tooltip static slot, helper exports (logicals/typography/contrast/sr-only), and the key pad hand port against upstream `lib/…/key_pad_menu_item.styles.js` in 12 configurations.
- Tests: new `tests/integration/components/eui-lists-test.gts` (17 tests); updated `eui-list-group-test`, `eui-pinnable-list-group-test`, `eui-key-pad-menu-test`, `eui-description-list-test`, `eui-side-nav-test` (see below).
- API docs regenerated: `docs/display/list-group/index.md`, `docs/display/description-list/index.md`, `docs/navigation/key-pad-menu.md`, `docs/navigation/side-nav.md`.
- Not touched: Link/ButtonIcon/Badge/Checkbox/Radio/Text/Title/FormLabel/EuiIcon/EuiButtonEmpty, providers/shared utils, `utils/css-mappings/*` (registry still imports the list mappings; components no longer use them), site/showcase, docs demos.

## API and default changes (latest-only)

### EuiListGroup / EuiListGroupItem
- **DOM follows upstream EuiListItemLayout.** Text items are a single `<li class="euiListItemLayout euiListGroupItem euiListGroupItem__text">` (`...attributes` now on the `li`, was an inner span). Links/buttons render `<li class="euiListItemLayout__wrapper"><a|button class="euiListItemLayout euiListGroupItem euiListGroupItem__button">` + the extra action as a sibling. The wrapper owns color/hover/selected backgrounds; the action inherits. Inner `euiListItemLayout__content/__prepend/__text` spans; `euiListGroupItem__label` and `__icon` kept.
- **Default `@maxWidth` is now `true`** (upstream): 400px (form max width). `false` removes it; numbers are px.
- **Default item color is `text`** (was `inherit`). `inherit` kept as an Ember extension (`color: inherit`); `ghost` renders as `text` (upstream dropped it). Group `@color` and `@wrapText` (new) reach block items via context; item args win (upstream clone semantics).
- `@size`, `@flush`, `@gutterSize` are deprecated no-ops (upstream removed them): items are one size (font `s`, 6px text padding, 8px inline padding, control radius), no list padding/gaps.
- `@isActive` sets `aria-current="true"` (new) and the selected background; `@isDisabled` sets `aria-disabled` on text items; a disabled link is a disabled `<button>`; `javascript:` hrefs disable the item.
- Links get upstream secure `rel` (`noreferrer`, plus `noopener` for `_blank`); new `@rel`, `@target` external icon + screen-reader text, `@external`.
- `@extraAction` accepts upstream's props object (`{ iconType, alwaysShow, onClick, isDisabled, 'aria-label', title, color, iconSize, size, display, className, css }`) rendered as an EuiButtonIcon with the upstream hover/focus reveal, or still a component (rendered as-is). Disabled items disable their action.
- Label `title` only for `@label` strings (upstream uses innerText for nodes). Not ported: `showToolTip(s)`/`toolTipText`/`toolTipProps`, `iconProps`, `icon` nodes, `listItems` on EuiListGroup, `buttonRef`.

### EuiPinnableListGroup
- Pins are upstream extra actions: `pinFilled` icon (Ember set lacks `pinFill`), rotated 45° (upstream style), pinned = `alwaysShow` + high-contrast light-shade color. Legacy `-pinned` / `__extraAction-alwaysShow` classes removed; `euiPinnableListGroup__itemExtraAction` kept as a hook. An item with its own `extraAction` gets no pin (upstream). New item fields `target`, `wrapText`, `className`, `extraAction`; new `@wrapText`; `@size/@flush/@gutterSize` deprecated no-ops.

### EuiKeyPadMenu / EuiKeyPadMenuItem
- `@checkable` accepts `true` or `{ legend, ariaLegend }`; any truthy value renders a `<fieldset>` (before, only `legend` did). Legend gets upstream `margin-bottom: s`.
- Menu: flex wrap, `xs` gap, width `3 × 96px + 3 × 4px`. Items 96×96, upstream enabled/selected/disabled styles; HC outlines.
- `aria-pressed` is omitted when `@isSelected` is undefined (was always `"false"`), as upstream/EuiButtonIcon. Links get secure `rel` (new `@rel`) and `aria-current`.
- `@checkable` adds `'multi'` (upstream name); legacy `'label'` still means checkbox. Unselected checkable inputs are screen-reader-only until hover/focus (upstream). `@onChange` is optional.
- Legacy `--hasBetaBadge`/`--checkable`/`-isDisabled`/`-isSelected` classes removed. Beta badge keeps the Ember behavior (badge carries its own tooltip) instead of upstream's tooltip around the whole item; not `aria-hidden`.

### EuiDescriptionList
- Title/description styles come from the parent list through context (upstream). New `@rowGutterSize`, `@columnGutterSize`, `@columnWidths` (numbers → `fr`). `data-type` attribute (upstream); legacy modifier classes removed.
- `responsiveColumn` is implemented with media queries at the `m` breakpoint (row below 768px, column from 768px) instead of upstream's resize hook; same result per width, and it works in SSR/iframes. `columnWidths` is a class rule instead of an inline style.
- Alignment is logical (`end`/`start`), as upstream.

### EuiSideNav
- Upstream classes: `euiSideNavItem--root/--trunk/--branch/--emphasized`, `euiSideNavItem-hasChildItems` (was `--hasChildItems`), `euiSideNavItemButton-isOpen/-isSelected`; `--rootIcon`, `--isClickable`, `__label--truncated`, `euiSideNav__contentMobile-*` removed. Labels use `eui-textTruncate` plus local truncate styles.
- **Section items below the root (children, no href/onClick) are now accordion buttons** (upstream): click toggles their children, `aria-expanded` (Ember addition), caret `arrowDown`/`arrowRight` (Ember icon names; upstream uses chevrons). Selection changes reset the toggle.
- Items honor `item.isSelected` (was deprecated) and `forceOpen`; links get secure `rel`.
- Heading: `EuiTitle` `xs` with `@tagName` = `headingProps.element`, carries `id` so `aria-labelledby` resolves (it was missing on desktop before). Screen-reader-only headings keep `euiSideNav__heading` and get real sr-only styles (the old modifier only added an unstyled class). Mobile: upstream toggle (full width, `1em` padding, bottom border), `aria-label="Toggle navigation"` when there is no visible text, content hidden/open styles with transitions.
- `renderItem` remains a deprecated no-op (React render prop).

## Existing test changes

- `eui-list-group-test`: legacy `--gutterMedium/-bordered/-flush/-maxWidthDefault` classes → computed border and 400px max width; asserts the classes are gone.
- `eui-pinnable-list-group-test`: pins are siblings of the item link inside the wrapper `li` (selector `li:nth-child(n)`); `-pinned`/`-alwaysShow` classes → computed opacity 1/0.
- `eui-key-pad-menu-test`: `-isSelected`/`-isDisabled`/`--hasBetaBadge`/`--checkable` classes → `aria-pressed`, disabled, `rel`, badge text, `label.euiKeyPadMenuItem`.
- `eui-description-list-test`: modifier classes → `data-type`, computed grid/center/`end` alignment.
- `eui-side-nav-test`: `--hasChildItems` → `-hasChildItems`; the screen-reader-only heading now keeps `euiSideNav__heading` (upstream) — asserts no `EuiTitle`, sr-only computed styles and `aria-labelledby`.

## New coverage (`Borealis lists, key pad and side nav`, 17 tests)

List group reset/border/max width (reactive, no element replacement); item li/a/button semantics, aria-current, disabled, `javascript:`, clicks/focus; measured padding/radius/font/text padding/truncation, colors (group context, item override, inherit, ghost), active/disabled; wrapText + reactive color/active without replacement; extra actions (props/component, hover-hidden, focus reveal, alwaysShow, disabled parent, wrapper padding) and external links; pinnable pins/own action/pinned color/rotation; key pad measured grid/item/label, aria-pressed undefined→false→true, link `aria-current`/`rel`, beta badge position, disabled/disabled-selected; checkable fieldset/legend/ariaLegend/`true`, radios/checkboxes, sr-only inputs, onChange; description list row/reverse/compressed/inline/gutters; column grid/gaps/widths/center; `responsiveColumn` at `m - 1` and `m` in iframes; side nav depth indentation, tree line, selected/emphasized/disabled/truncate/links; accordion toggling and reset; mobile toggle/heading/content; light/dark nearest provider + sibling isolation; JS-object overrides + preferred high contrast; RTL logical padding/positions/margins/indentation.

## Checks run (2026-10-12, worktree `eui-wave/lists`)

Node 22, binaries run directly, Chromium 130 via the scratchpad shim, `CI=true`.

- Core tests (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **715 tests, 715 pass, 0 fail** (17 new).
- One earlier full run hit a 10s browser timeout in the unrelated `eui-icon` "every named icon" test while five other builds loaded the machine (load ~15); the rerun on the final code passed 715/715.
- Filtered family run (`lists|list-group|key-pad|description-list|side-nav|pinnable`): 34/34.
- `node --test scripts/eui-upstream-parity.test.mjs`: **76/76** (59 before + 14 factories + 3 tests).
- `node scripts/generate-eui-styles.mjs --check`: run in this worktree it reports only the symlink source-path comments (expected); output extracted 84 factories, React-free.
- `ember-tsc --noEmit`: pass. ESLint on all changed components/helpers/tests: pass.
- `node scripts/generate-api-docs.mjs --check`: pass after regenerating.
- Not run (root): rollup core build, site build/acceptance, showcase.

## Unresolved

1. **Child styling through a second class (needs `@css` at merge).** Per the coordinator rule these are exposed as interpolations and must switch to the child's `@css` when available:
   - EuiButtonIcon extra action: `EuiListGroupItem.extraActionCss` (includes the pinnable `css`), applied today as a second class (`extraActionClass`).
   - EuiIcon external icon: `EuiListGroupItem.externalIconCss` (`externalIconClass`).
   - Children without `@css` in this worktree that get a local class: EuiButtonEmpty (side nav mobile toggle class + `@contentClasses`), EuiTitle (side nav heading margin `l` / `0`), EuiFormLabel (key pad legend margin), EuiRadio/EuiCheckbox `@containerClass` (key pad checkable input position/scale/sr-only), EuiBetaBadge (key pad badge position). None of these overlap the child's own properties except the side nav toggle (width/height/padding/radius vs EuiButtonEmpty) and heading margin vs EuiTitle's reset; both are asserted and pass today, but rely on insertion order.
2. **Docs site sidebar (EuiSideNav) visual risks:** root items are now bold `xxs` titles with an `s` bottom padding and separators; trunk items are heading-colored, branches subdued with a 1px tree line and 4px tick; selected items are bold primary + underline; items gain 8px focus padding offsets. The site gives every page `items: []` + `onClick`, so no accordions appear there; disabled pages render `textDisabled`. The mobile toggle now spans the full width with a bottom border. Check with the site build.
3. Pin glyph: upstream rotates its upright `pinFill` 45°; Ember's `pinFilled` may already be diagonal. Revisit with the icon family.
4. List groups now default to 400px max width: CollapsibleNav/Header/PageTemplate docs that put EuiListGroup in wide containers will narrow unless they pass `@maxWidth={{false}}`.
5. Not ported: list item tooltips, `listItems` on EuiListGroup, side nav `renderItem`, key pad whole-item tooltip for beta badges.

## Next step

Root: merge, regenerate in the main checkout, switch the items in Unresolved 1 to `@css`, then run the core build, site build/acceptance and check the docs sidebar visually.
