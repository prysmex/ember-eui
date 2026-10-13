# Header and collapsible nav family migration handoff

Status: **In progress, not marked Migrated.** The family tests all pass (header 59/59, collapsible 7/7). The full core suite is 758/762: the 4 failures are pre-existing EuiCheckbox/EuiRadio mark tests that fail identically on the untouched base (the EuiIcon display/size vs checkbox-mark issue the coordinator described). Branch `eui-wave/header`.

Components: EuiHeader, EuiHeaderSection, EuiHeaderSectionItem, EuiHeaderSectionItemButton, EuiHeaderLogo, EuiHeaderLinks, EuiHeaderLink, EuiHeaderAlert, EuiHeaderBreadcrumbs, EuiCollapsibleNav, EuiCollapsibleNavGroup. EuiSkipLink was already migrated and is unchanged.

## Upstream mapping

| Ember | Upstream 123.1.0 styles |
| --- | --- |
| EuiHeader | `header.styles.js` `euiHeaderStyles` (root, `static`/`fixed`, `default`/`dark`) and `euiHeaderVariables`. The fixed-header logic is a port of `EuiFixedHeader` |
| EuiHeaderSection | `euiHeaderSectionStyles()`, a static factory evaluated once at module scope |
| EuiHeaderSectionItem | `euiHeaderSectionItemStyles` |
| EuiHeaderSectionItemButton | `euiHeaderSectionItemButtonStyles`, composed over EuiButtonEmpty, plus the `notification.dot`/`badge` slots |
| EuiHeaderLogo | `euiHeaderLogoStyles` + `euiButtonDisplaysColors().empty.text`, which is what `useEuiButtonColorCSS({display:'empty'}).text` returns |
| EuiHeaderLinks | `euiHeaderLinksStyles` (root, list, `gutterSizes`, mobile list) |
| EuiHeaderLink | No styles upstream. It is EuiButtonEmpty with upstream defaults; the dark header recolors it |
| EuiHeaderAlert | `euiHeaderAlertStyles` |
| EuiHeaderBreadcrumbs | `euiHeaderBreadcrumbsStyles`, composed over EuiBreadcrumbs |
| EuiCollapsibleNav | `collapsible_nav.styles.js` `euiCollapsibleNavStyles` (`push`/`overlay`) on EuiFlyout. This is the flyout-based `EuiCollapsibleNav`, which upstream still ships alongside `EuiCollapsibleNavBeta`; the Ember API is unchanged |
| EuiCollapsibleNavGroup | `euiCollapsibleNavGroupStyles` (border, `none`/`light`/`dark`, `isCollapsible`/`notCollapsible`, children wrapper) + `euiTitleStyles` for the title |

Generator (`// header and collapsible nav` block, 11 names): `euiHeaderVariables`, `euiHeaderStyles`, `euiHeaderSectionStyles`, `euiHeaderSectionItemStyles`, `euiHeaderSectionItemButtonStyles`, `euiHeaderLogoStyles`, `euiHeaderLinksStyles`, `euiHeaderAlertStyles`, `euiHeaderBreadcrumbsStyles`, `euiCollapsibleNavStyles`, `euiCollapsibleNavGroupStyles`.

- All 11 extracted cleanly; no hand ports were needed.
- The same 11 were added to the parity `factories` matrix (12 theme configurations each).
- `styles.generated.ts` and `upstream-sources.json` were regenerated. The worktree-only `../../…/Users/…` source comments were normalized back to `node_modules/…` with sed, as the icon wave did.

## Performance

- Every style getter is `@cached` and gets factory output through `useEuiBorealisStyles`.
- The section factory has no theme argument, so it is evaluated once at module scope.
- EuiCollapsibleNavGroup computes its classes from the inner provider's context via a template-invoked function (`classesFor`), the same pattern as EuiBottomBar's `barClasses`. Glimmer only re-runs it when the context or args it reads change.
- Note for the coordinator: `useEuiBorealisStyles` in this worktree's `utils/eui/styles.ts` does **not** memoize; it calls the factory directly. The brief says it uses a WeakMap. Presumably main has that change. Nothing here depends on it.

## Child styling and the coordinator's `@css` rule

This worktree predates `@css`. I added no competing class whose precedence depends on insertion order:

- **EuiIcon notification dots** (`EuiHeaderSectionItemButton`): the styles are interpolation arrays in the `@cached` getter `notificationCss` (`dot`, `badge`, `smallDot`).
  - Until merge they are passed through `@iconClasses`.
  - EuiIcon sets no position, inset or stroke. The only overlapping rules (size and `display` under media queries) are doubled with `&&`.
  - **At merge**, replace `@iconClasses="… {{this.styles.dot}}"` / `smallDot` with `@iconClasses="euiHeaderSectionItemButton__notification euiHeaderSectionItemButton__notification--dot" @css={{this.notificationCss.dot}}` (and `smallDot`). The `&&` wrappers can then be dropped.
  - The color rules (stroke) must stay at single specificity, so that `EuiHeader @theme="dark"`'s descendant rules win, as upstream.
- **Children without `@css` on main** use `composedOver` (`&&`, doubled specificity), so they win regardless of order: EuiButtonEmpty (item button), EuiBreadcrumbs (header breadcrumbs), EuiFlyout (collapsible nav) and EuiPopover (the header links' responsive hide). Switch these to `@css` when those components gain it:
  - EuiButtonEmpty `@css`: `euiHeaderSectionItemButton`;
  - EuiBreadcrumbs: `euiHeaderBreadcrumbs`;
  - EuiFlyout: `euiCollapsibleNav` + `push`/`overlay`.
- **EuiNotificationBadge** (badge slot): `position`, inset and `box-shadow` do not overlap the badge's own rules. Only the `display:none` media rule is doubled. Switch it to `@css` if the badge gains it.

## API and default changes (latest-only)

**EuiHeader**
- Root class `euiHeader` is kept. `euiHeader--{default,dark,static,fixed}` are removed.
- Height is `size.xxxl` (48px) with inline padding `s`, a bottom border, the upstream xSmall shadow and a clip-path for stacked headers.
- `static`: `z-index` = `levels.header - 1`, `position: relative`.
- **`fixed`** follows upstream `EuiFixedHeader`:
  - `z-index` = `levels.header + 1`;
  - each fixed header gets `top` = height × the number of earlier fixed headers, so they stack. A caller's inline `top` wins;
  - `data-fixed-header`;
  - `--euiFixedHeadersOffset` on `<html>` (total height). Already used by EuiPageSideBar sticky and EuiOverlayMask;
  - body class `euiBody--headerIsFixed`.
  - Ember-only, documented behavior kept: `<body>` gets `padding-top: var(--euiFixedHeadersOffset, 0)`. It used to come from legacy CSS; upstream leaves this to EuiPageTemplate's `offset`. The caller's own inline body padding is restored when the last fixed header is removed.
  - Fixed a latent bug: ember-modifier keeps a previous teardown when a run returns nothing, so fixed → static → fixed decremented the counter twice. The modifier now always returns a teardown.
- `@theme="dark"`:
  - upstream pseudo-dark styles: `headerDarkBackground`;
  - logo, logo text, links and item buttons in `textGhost`;
  - the active link is `makeHighContrastColor(primary)` against the background;
  - focus background `headerDarkSectionItemBackgroundFocus`;
  - the badge ring and dot stroke use the header background.
  - As upstream, no dark provider is nested, so other children (EuiBadge, EuiButton) keep the surrounding mode.
- `@theme`/`@position` types are now `'default'|'dark'` / `'static'|'fixed'` (open strings still type-check).
- `@sections` now follows upstream:
  - one EuiHeaderSection per entry, with each item in its own EuiHeaderSectionItem (before: one section per item);
  - breadcrumbs only when given;
  - `border` is deprecated and ignored.
  - `items`/`breadcrumbs` are optional in the type.

**EuiHeaderSection**: unchanged API. `@side="right"` uses a logical `margin-inline-start: auto`, so the section sits at the start in RTL. `euiHeaderSection--*` classes are removed.

**EuiHeaderSectionItem**
- **`@border` is deprecated with no effect.** Upstream 123 removed item dividers.
- An item with no block renders nothing, as upstream.
- `euiHeaderSectionItem--border*` classes are removed.

**EuiHeaderSectionItemButton**
- 40px high, min-width 40px (30px below `s`), inline padding `s`, `font-size: 0`, relative; the content is `inline-block`.
- **The count badge becomes a dot below the theme `m` breakpoint**, as upstream (`useIsWithinMaxBreakpoint('s')`). It was `xs` before.
  - Done with CSS: both the badge and the dot are rendered and media queries hide one. Before, JS EuiHideFor/EuiShowFor did this.
  - The hidden one is `display:none`, so it stays out of the accessibility tree.
- `@notification` also accepts a string. `@notificationColor` is typed as EuiNotificationBadge colors (`accent`/`subdued`/`success`).

**EuiHeaderLogo**
- Upstream box: 40px, inline padding `s` (`xs` start below `s`), radius `control`, empty-button text color, focus ring, no underline.
- Gets upstream's secure `rel` via EuiLink's `getSecureRelForTarget`, with a new `@rel` to merge. A `rel` attribute still wins.
- A `javascript:` href is dropped to `''` (upstream `validateHref`).
- `@iconType` and the text block are kept. Upstream 123 only has `logoType` glyph/horizontal.
- The text is an `xxs` title with `padding-inline-start: s` and inherits the link color. This is Ember-only; upstream's dark header still targets `.euiHeaderLogo__text`.
- `@iconTitle` keeps no default. Upstream defaults to "Elastic", but Ember callers pass text.

**EuiHeaderLinks**
- Default `@gutterSize` is **`'s'`** (12px), as upstream (was `'xs'`). It now accepts `xxs`; `none` is kept (gap 0). Gaps come from upstream `gutterSizes`.
- Default `@panelPaddingSize` is **`'s'`**, as upstream (was `'none'`).
- The responsive swap is CSS media queries on the theme breakpoints, not JS. `'all'`/`'none'`/`[]` skip rendering the unused half. `@popoverBreakpoints` accepts `'all'`/`'none'`.
- The menu button is upstream's: EuiHeaderSectionItemButton, `aria-label="Open menu"`, `apps` icon size m. New `@popoverButtonAriaLabel` and `@popoverButtonIconType`.
  - Before, it was an unlabeled EuiButtonEmpty, which was an a11y bug.
  - Clicking toggles. A window resize closes, as upstream. Uses `repositionOnScroll`.
- `<nav aria-label="App menu">` (upstream).
- New: `Element: HTMLElement` with `...attributes` (previously none). The default block yields `closeMenu`, like upstream's render-prop children.
- Mobile list: links are full-width blocks with start-aligned content.
- `euiHeaderLinks__list--gutter*` / `__mobileList--gutter*` are removed.

**EuiHeaderLink**
- `@size` defaults to **`'s'`**, as upstream (it was not forwarded, so it was `m`).
- `@color` overrides the active/text default.
- Now also forwards `@disabled`, `@isSelected`, `@type`, `@flush`, `@iconSize` and `@contentClasses`.

**EuiHeaderAlert**
- Upstream layout:
  - min-width 300px and inline padding `s`;
  - separator (margin, padding, border) on all but the last alert;
  - `xs` title;
  - `s` text with a `base` bottom margin;
  - `xs` date in `darkShade`.
- **The legacy `euiLink` class was removed from `.euiHeaderAlert__action`**. Pass an `EuiLink` in the block.
- Now a Glimmer class (the signature is unchanged).

**EuiHeaderBreadcrumbs**: flex, grow, inline margin `s`, truncation. Upstream's `type="application"` is not passed because Ember EuiBreadcrumbs has no `@type` (owned by the breadcrumbs wave).

**EuiCollapsibleNav**
- Overlay: `z-index: levels.navigation` (6000), composed over the flyout.
- Docking:
  - uses the nearest theme's breakpoints (it used the static map);
  - is width-tracked, so `@dockedBreakpoint`/`@isDocked` changes apply without a resize;
  - is throttled with a destroy guard.
- Otherwise unchanged: toggle aria attributes, button hidden while docked unless `@showButtonIfDocked`, and the flyout props.
- Not ported: upstream adds the toggle button as a focus-trap shard.

**EuiCollapsibleNavGroup**
- Upstream border between groups, heading padding `base` (or the accordion trigger padding when collapsible), and children padding `s` (no top padding under a heading).
- Backgrounds: `light` = `collapsibleNavGroupBackground`, `dark` = `collapsibleNavGroupBackgroundDark`.
- **`'dark'` renders inside a nested dark provider**, as upstream's `EuiThemeProvider colorMode="dark"` with `cloneElement`:
  - no wrapper element;
  - the dark paragraph color goes on the group;
  - content resolves dark tokens;
  - the title, heading and accordion arrow are `textGhost`.
  - Toggling `@background` keeps the element (the provider always wraps and only inherits the mode when not dark).
- The title keeps the `euiTitle` and `euiCollapsibleNavGroup__title` classes and gets upstream title styles at `@titleSize` (default `xxs`) with a heading reset.
- `@background` is typed `'none'|'light'|'dark'`; open strings still type-check.
- `euiCollapsibleNavGroup--{light,dark,withHeading}` are removed.

`Element` types are unchanged except EuiHeaderLinks, which gained one. `utils/css-mappings/eui-header*.ts` and `eui-collapsible-nav-group.ts` are now dead but still registered in the mappings index; I left them for a coordinated cleanup.

## Existing tests changed (why)

- `eui-header-test.gts`:
  - `euiHeader--dark/--static` became the computed dark background and `position: relative`.
  - `euiHeaderSection--grow/--right` became the computed flex-grow.
  - The `euiHeaderSectionItem--borderRight` selector became `.euiHeaderSectionItem` (borders were removed upstream).
  - `euiHeaderLinks__list--gutterS` became a 12px column gap.
  - The link color assertions in the **dark** header now expect upstream's dark-header recoloring: ghost text, and a high-contrast active color different from the light primary. Before, they asserted plain light empty-button colors, which upstream's dark header overrides.
  - `euiHeader--fixed` became `position: fixed`.
  - The item-button selectors now target `[aria-label="News"]`. EuiHeaderLinks' (CSS-hidden) menu button is now an EuiHeaderSectionItemButton too, so `.euiHeaderSectionItemButton` became ambiguous.
- `eui-collapsible-nav-test.gts`: `euiCollapsibleNavGroup--light/--withHeading` became the `euiCollapsibleNavGroup` root class plus a non-transparent computed background.
- No other existing test changed.

## Coverage (`eui-header-family-test.gts`, 15 tests)

1. **Header base:** flex, space-between, 48px, padding, border token, shadow, static `z-index`/position, default background, no legacy classes, stacked-header clip-path.
2. **Dark theme in light and dark providers:** background; ghost logo, text, link and button; the high-contrast active link via `makeHighContrastColor`; badge ring; dot stroke; focus background.
3. **Fixed:** two stacked headers (top 0/48), offset variable 96 → 48 → removed, body class and padding, restoring the caller's inline body padding, static ↔ fixed on the same element, last-header cleanup, and a caller `top` winning.
4. **Sections and items:** flex, grow/no grow measured, the right section at the end, RTL flip (geometry), items centered, no dividers, empty items not rendered, the `@sections` structure with breadcrumbs.
5. **Item button:**
   - size, padding, `font-size: 0`, text color;
   - content `inline-block`;
   - dot position, offset and stroke, with EuiIcon's accent color;
   - badge position, ring and fill; the small-screen dot hidden; subdued color;
   - link and disabled; click;
   - `euiAnimate` runs a 5000ms Web Animation.
6. **Iframe viewports (m−1/m/s−1):** badge ↔ dot swap; dot shrinks to 16px and moves to 9% below `s`; min-width 30px.
7. **Logo:** box, color, radius, secure `rel` merge, `javascript:` dropped, icon semantics, `iconType`, text style; reduced `xs` padding in an iframe.
8. **Links:** nav label, list layout, all 6 gutters, `'none'`/`[]` never collapse, link size/colors/override; iframe collapse at m−1 vs m.
9. **Mobile menu (`'all'`):** button label and icon; opens; full-width, start-aligned links; resize closes; yielded `closeMenu` closes.
10. **Alert and breadcrumbs:** min width, padding, the separator except on the last alert, title/date/text typography and tokens, `aria-labelledby`, no legacy `euiLink` class, optional blocks; breadcrumbs flex/grow/margins/truncation inside a header.
11. **Collapsible nav:**
    - closed overlay not rendered;
    - `aria-controls`/`aria-expanded`/`aria-pressed` toggling;
    - overlay `z-index` 6000 with a close button;
    - Escape → `@onClose`;
    - docked at breakpoint 0 (no toggle, no close button, no overlay `z-index`);
    - `@showButtonIfDocked` keeps the element;
    - undocking via a reactive breakpoint;
    - the named theme breakpoint `l` docks on the 1440px window.
12. **Nav group:** `none`/`light`/`dark` backgrounds; borders; heading/children padding with and without a heading; title tag and weight; icon; the dark provider (paragraph color, ghost title, dark border, a dark EuiLink inside, no wrapper); collapsible accordion padding and toggle; reactive background on the same element; no legacy classes.
13. **Reactive args, same elements:** theme, side, grow, gutter, notification color/value, iconType, isActive.
14. **Light/dark:** nearest provider, nested dark provider, sibling isolation, mode switch on the same element.
15. **JS-object overrides and high contrast:**
    - `size.xxxl`/`xxl`/`s` reach the header, button and fixed offset;
    - `colors.LIGHT.emptyShade`/`primary` reach the dot stroke and the active link;
    - outside the provider is unaffected;
    - `preferred`/`forced` border, background and active colors match `resolveBorealisTheme`;
    - removing the overrides restores the defaults; teardown clears the offset variable.

## Checks run (2026-10-12, worktree `eui-wave/header`)

Node 22, binaries run directly, Chromium 130 via the scratchpad shim with `CI=true`.

- `node --test scripts/eui-upstream-parity.test.mjs`: **105/105 pass** (the 11 new factories included).
- `node scripts/generate-eui-styles.mjs`: extracted 125 factories/helpers. Provenance paths were normalized as noted. Re-run `--check` in the main checkout after merging.
- `ember-tsc --noEmit`: pass. ESLint on the 11 components and the 3 test files: pass.
- `node scripts/generate-api-docs.mjs --check`: pass, after regenerating `layout/header/index.md` and `navigation/collapsible-nav.md`.
- Filtered runs: `header` 59/59 and `collapsible` 7/7.
- Full core suite (`vite build --mode=development --out-dir dist-tests` + `testem --file testem.cjs ci --port 0`, all final changes included): **762 tests, 758 pass, 4 fail**. The failures are all in `Borealis checkables` (not mine):
  - `EuiCheckbox measures every state…`: expected no mark when unchecked, got `check,stopFilled`;
  - `…native semantics…`;
  - `…reactive args…`;
  - `EuiRadio states, the dot…`.

  The untouched base (`971c518a`) fails the same 4 (checkables 7/11).
- Not run (root): rollup build, site build/acceptance, visual checks.

## Unresolved

1. **Docs shell visual risk** (`site/app/templates/application.hbs`, `<EuiHeader @theme="dark" @position="fixed">`):
   - **The ghost EuiButton (theme switcher) and the EuiBadge keep the page's light mode.** Latest EuiButton maps `ghost` to `text`, so the switcher text is dark on the dark header. Suggested site fix: wrap the right section's content in `<EuiEmotionProvider @colorMode="dark" @wrapper={{false}} @globalStyles={{false}}>`, or use EuiHeaderSectionItemButton/EuiHeaderLink.
   - The `@border="right"` dividers disappear (upstream).
   - The GitHub EuiHeaderLogo now gets `rel="noreferrer"` merged; its explicit `rel` attribute still wins.
   - Body padding stays 48px. EuiPageSideBar `@sticky` now picks up `--euiFixedHeadersOffset` (48px), which is an improvement.
2. **Coordinator `@css` switch at merge** (see "Child styling" above): EuiIcon dots now. EuiButtonEmpty, EuiBreadcrumbs, EuiFlyout, EuiNotificationBadge and EuiPopover once they gain `@css`.
3. Concurrently migrating dependencies were used as-is:
   - EuiFlyout: the collapsible nav's overlay `z-index` is composed with `&&` over whatever the flyout ends up setting;
   - EuiPopover;
   - EuiBreadcrumbs (`type="application"` not available).
   - EuiAccordion is unmigrated: the collapsible group's `.euiAccordion__triggerWrapper` padding applies, but the accordion itself is unstyled.
4. Not ported:
   - EuiHeaderLogo `logoType="horizontal"` (Elastic wordmark);
   - EuiHeaderLinks `popoverProps`/`popoverButtonProps` beyond label and icon;
   - EuiCollapsibleNav focus-trap shards;
   - `EuiCollapsibleNavBeta`.
5. Dead code for a coordinated cleanup: `utils/css-mappings/eui-header*.ts` and `eui-collapsible-nav-group.ts`.

6. **Shared git stash incident (my error):**
   - To run the base comparison I used `git stash push`/`pop` in this worktree. Stashes are shared by all worktrees. My `pop` applied and dropped the overlays agent's stash (`9c614fc4`), while that agent had popped my `header-wip` and re-stashed it as `RECOVER eui-wave/header work` (`1f7081f2`).
   - I checked that my worktree matched `9c614fc4` exactly (tracked and untracked files), restored it with `git stash store` under its original message (it is `stash@{0}` again), cleaned my worktree and reapplied my own `c0309bdf`.
   - The `RECOVER` entry duplicates this commit's work and can be dropped by the coordinator.
   - A `WIP on eui-wave/modal-flyout` stash (`4850c325`) was in the list during this and disappeared later. I never popped or dropped it; its owner presumably popped it. Confirm with the modal-flyout agent.

## Next step

Root:
1. Merge, regenerate the styles in the main checkout and switch the dots to `@css`.
2. Run the core build and the site build/acceptance.
3. Fix the docs-shell header children (item 1) and do a visual pass of the docs header and the header/collapsible-nav docs pages.
