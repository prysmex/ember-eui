# Cards family migration handoff (EuiCard, EuiCardSelect, EuiCheckableCard, EuiSplitPanelOuter/Inner)

Status: **ported, rows left `In progress`**. Every family test passes. The full core suite is 796/798. The 2 failures are in `eui-content-blocks-test.gts` (EmptyPrompt asserts the legacy `euiIcon--subdued` class) and fail the same way on the unmodified base `7e5e2214`, so they are not caused by this family. The rows can become `Migrated` once the root fixes those two tests.

## Files

- `packages/core/src/components/eui-card.gts`: rewritten on `euiCardStyles`, `euiCardTextStyles` and `euiCardBetaBadgeStyles`, with `@cached` getters.
  - The card styles are composed into EuiPanel's own class through `@css`. EuiPanel's `isClickable` slot is added the same way, because the card does not pass `@onClick` (see below).
  - The padding-dependent factories are wrapped in module-level per-padding closures, so `useEuiBorealisStyles` memoizes them.
- `eui-card-select.gts`: rebuilt on EuiButton (`m`, `fullWidth`), as upstream.
- `eui-checkable-card.gts`: now a Glimmer class composed from EuiSplitPanelOuter/Inner and `euiCheckableCardStyles`.
- `eui-split-panel/outer.gts` and `inner.gts`: now Glimmer classes on `euiSplitPanelOuterStyles`/`euiSplitPanelInnerStyles`. Both gain `@css`, which is composed into EuiPanel's `@css`.
- `src/-private/eui-split-panel-context.ts` (new): an `ember-provide-consume-context` context, the counterpart of upstream's `SplitPanelInnerBorderDirection`. It carries the border direction and the collapse breakpoints.
- `scripts/generate-eui-styles.mjs`: new `// cards` block with `euiCardStyles`, `euiCardTextStyles`, `euiCardBetaBadgeStyles`, `euiCardSelectStyles`, `euiCheckableCardStyles`, `euiSplitPanelOuterStyles` and `euiSplitPanelInnerStyles` (147 factories in total). `styles.generated.ts` and `upstream-sources.json` were regenerated.
- `scripts/eui-upstream-parity.test.mjs`:
  - `euiCardTextStyles`, `euiCardSelectStyles`, `euiCheckableCardStyles` and `euiSplitPanelInnerStyles` go through the 12-configuration matrix.
  - A new test checks `euiCardStyles`/`euiCardBetaBadgeStyles` for every padding size (none/xs/s/m/l/xl) × 6 themes.
  - A new static `deepEqual` test covers `euiSplitPanelOuterStyles`.
- `packages/core/tests/integration/components/eui-cards-test.gts` (new): 19 tests.
- `eui-card-select-test.gts`: `.euiCheckableCard-isChecked` became `.euiCheckableCard`, and `euiCheckableCard__label-isDisabled` became `euiCheckableCard__label`. Upstream has no state modifier classes; the states are measured in the new file. `eui-card-test.gts` is unchanged and passes.
- API docs regenerated for card and panel (split panel). The icons and button pages also picked up the coordinator's earlier `@css` additions, which were not yet in their generated docs.

## API and default changes (latest-only)

### EuiCard

- **The card itself is no longer `role="button"`/`tabindex=0`.** Upstream's "redundant click" pattern: a click anywhere on the surface clicks the title link/button (or the select button), and that element is the only focusable, accessible control. Keyboard users use the native link/button.
- **Nested interactive content keeps its own clicks (deliberate deviation).** Clicks on links, buttons, inputs, labels, `[tabindex]` and similar inside the card are no longer also forwarded to the title. Upstream forwards them, which double-fires. Clicks inside the link itself are not forwarded either (the old Ember card double-fired on child spans).
- **Surface:**
  - No border (`hasBorder=false`).
  - Shadow only when there is no `@display` and the card is not disabled.
  - Any `@display` (including `plain`) removes the shadow and adds no border. Before, `@display` added a border.
- **Disabled:**
  - Upstream `euiButtonColor('disabled')` surface, `not-allowed` cursor and `disabledText` title.
  - Grayscale top, `subdued` beta badge.
  - `javascript:` hrefs disable the card (upstream `validateHref`).
- **Title:**
  - `@titleElement` is now the title element itself and defaults to **`p`** (it was span/h2). It gets `euiTitle euiCard__title` and the EuiTitle size styles, like upstream's cloned EuiTitle. It also accepts `span`.
  - The link/button sits inside it: `a.euiCard__titleAnchor` / `button.euiCard__titleButton`.
  - The title has an `id`. The description is `EuiText s` with an `id`. The link is described by the description; the button by the beta badge and the description.
- **New `@rel`** (secure rel as in EuiLink) and **`@css`**.
- `betaBadgeProps` gains `tooltipPosition`.
- **DOM follows upstream:**
  - `.euiCard__main` wraps top, content, badge and footer.
  - `<:body>` is wrapped in `.euiCard__children`.
  - The beta badge wrapper is now `.euiCard__betaBadgeAnchor` (was `__betaBadgeWrapper`).
  - The image `alt` is `""` (it was `"card-top"`).
- **Block yields:**
  - `<:icon>` yields `euiCard__icon` plus the generated spacing class (typed `string`).
  - `<:title>` yields a setter typed `(element) => void`.
- **Selectable:**
  - `EuiSpacer` sized like the padding, then EuiCardSelect with `aria-describedby` set to the title id and description id.
  - A disabled card disables its select button.
  - Upstream 123 has **no selected/selectable border colors** on the card, so `euiCard--isSelectable--*` and `euiCard-isSelected` are gone.
- **Removed classes:** `euiCard--horizontal`, `--isClickable`, `--hasBetaBadge`, `--hasIcon`, `--isSelectable*`, `-isSelected`, `-isDisabled` and the alignment class.
- **Kept:** `euiCard`, `__top`, `__content`, `__title`, `__description`, `__footer`, `__image`, `__icon`, and the `top/content/footerClassName` args.
- Horizontal layout ignores `@image`, `@footer` and `@textAlign`. Upstream throws; Ember keeps the old lenient behavior.

### EuiCardSelect

- **Now a full-width `m` EuiButton** (was an `xs` EuiButtonEmpty). The `Element` type is EuiButton's, so `HTMLLabelElement` is added.
- **`@flush` is deprecated** and has no effect.
- Texts come from the i18n tokens `euiCardSelect.select`, `euiCardSelect.selected` and `euiCardSelect.unavailable`.
- The root class is `euiCardSelect`. The `euiCardSelect--<color>` class was removed.

### EuiCheckableCard

- **Structure:** a row EuiSplitPanel with `@responsive={{false}}`.
  - The control's section is `primary` when checked and `subdued` otherwise, and does not grow.
  - The label section holds the full-bleed label and the details.
- **Checked:** the primary border is upstream's `::after` (or the solid border in preferred contrast). It is not shown while disabled. The border color has a transition.
- **Clicks:** the control's section is clickable (EuiPanel's `isClickable` slot plus a click handler; it is not a `role=button`). Clicks there, and on details without interactive content, click the label.
  - The details cursor is `pointer` unless they contain interactive elements. This uses a CSS `:has()` rule instead of upstream's tabbable effect.
- **New arguments:** `@hasBorder` (default true), `@hasShadow` and `@css`.
- **Removed classes:** `euiCheckableCard-isChecked`, `euiCheckableCard__label-isDisabled` and every hardcoded `euiPanel--*` class.

### EuiSplitPanel

- **The responsive collapse is CSS.** Upstream picks the direction with `useIsWithinBreakpoints` in JS. Here a row collapses to a column through one media query per breakpoint in `@responsive`, at the same widths.
  - The JS resize modifier and the `euiSplitPanel--row`/`euiSplitPanel-isResponsive` classes are gone.
  - `@responsive` is typed `EuiBreakpointSize[] | false` (`false` was documented but not typed).
- **Inner sections:**
  - They gain upstream's high-contrast dividers through the outer context: a right/bottom border on every section but the last, and column dividers inside the collapse media queries.
  - They gain `@grow` (default true).

## Checks (2026-10-12, worktree `eui-wave/cards`, Chromium 130, `CI=true`)

- Filtered `card` run: **23/23**. That is the 19 new tests plus 4 legacy card/card-select/checkable tests.
- Full core suite: **796 pass, 2 fail (798)**.
  - Failures: `Borealis content blocks: empty prompt defaults…` and `…empty prompt colors…`. Both expect `euiIcon--subdued`.
  - Both fail identically on the unmodified base (filtered `content blocks` run on base: 14 pass, 2 fail).
- `node scripts/generate-eui-styles.mjs --check`: pass (147 factories). `node --test scripts/eui-upstream-parity.test.mjs`: **125/125**.
- `ember-tsc --noEmit`: pass. ESLint on all changed sources and tests: pass. `generate-api-docs.mjs --check`: pass.
- Not run (root): rollup/core build, site build/types, acceptance tests, showcase.

## Unresolved / needed from other owners

1. **EuiButton has no `@css`.** Upstream's `euiCardSelectStyles` (`transform: none !important; align-self: flex-end`) is not applied. Both declarations are visual no-ops today: Borealis buttons do not translate, and the button is full width. Add `@css` to EuiButton, then pass the slot.
2. **EuiText and EuiBetaBadge have no `@css`.** The description margin and the badge's `inline-size: 100%` are applied from the parent with descendant rules (`.euiCard__content > .euiCard__description`, `.euiCard__betaBadgeAnchor .euiCard__betaBadge`). That is deterministic by specificity, and no second class is put on the child. Switch to `@css` once those components have it.
3. **EuiTitle's `TextBlock` has no `span` tag.** The card renders its own title element with the extracted `euiTitleStyles`, like EuiStat's title.
4. **Upstream behaviors kept as-is:**
   - The interactive title is underlined on focus and on card hover.
   - The card's focus ring uses `:has([class*='euiCard__text'][class*='-interactive']:focus-visible)`. That depends on Emotion labels in class names, which `euiClass` keeps.
   - With `paddingSize="none"` plus a beta badge, upstream's `calc(null + 8px)` is invalid, so there is no extra top padding.
5. The pre-existing EmptyPrompt test failures (root / content-blocks owner) block the `Migrated` status.
6. Docs demos were not visually audited. Card demos that relied on `@display` adding a border, on selectable borders, or on the default `span` title element will look different.

## Next step

Root: fix the two EmptyPrompt assertions, merge, regenerate in the main checkout, run the core build, site build and showcase, then mark these five rows `Migrated`. Then add `@css` to EuiButton, EuiText and EuiBetaBadge and drop the descendant rules (items 1 and 2).
