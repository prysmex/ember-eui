# Work log and resume point

Branch: `feat/eui-latest`, based on `feat/emotion`. No catalog-wide completion claim.

## 2026-10-11

- Pinned current stable EUI123.1.0, Borealis8.1.0 and theme-common10.1.0.
- Implemented native theme resolution, cached tracked context, native overrides and contrast inheritance.
- Implemented reproducible extraction of13 pure CSS factories/helpers with source hashes/license preservation. `pnpm eui:check` passes12 independent upstream comparisons and is wired into CI.
- Three agents implemented Button, Panel and three layout ports, with individual handoff notes. Inventory covers275 source component files.
- Initial integration found fractional Chromium border rounding, mode-specific override requirements and page-content growth/default interactions. Fixed tests and wrapper growth; no pass claim before latest rerun.
- User clarified latest-only styling is the target. Removed specificity wrappers and legacy variant classes/coexistence tests. Panel defaults border=true/shadow=false, rule margin=m. Rewrote handoff docs to reflect this direction.
- Added standalone `/docs/eui-latest` showcase: native providers, sibling light/dark, nested token overrides, contrast/loading/action controls. Legacy docs stylesheet is disabled while it is active and restored on exit.

## 2026-10-12

- Text family (EuiText/Title/TextColor/TextAlign) migrated to extracted factories; generator now extracts 17 factories. Full core suite 609/609 in Chromium 130, parity 17/17, types/lint/API docs/core build pass. See [text-handoff.md](text-handoff.md).
- Batch 2 base: pre-registered Link, Badge (+group/beta/notification, color helpers), Flex (group/item/grid), ButtonEmpty and ButtonIcon factories (32 total); parity 29/29, core 609/609. Borealis theme and chroma-js are now external imports instead of being inlined into `styles.generated.ts` (same pinned versions; removes a duplicate theme copy). Services barrel shim also re-exports `is_color_dark`. See [wave-brief.md](wave-brief.md).
- No coordinator/root agent exists (user, 2026-10-12); this session owns root duties. Fixed template `(hash)` Borealis overrides (cebf6dbc). Root validation: core 611/611, site node 8/8, site acceptance 17/17, site build + types, core build + types, showcase screenshot. First five ports + PageContent marked Migrated.
- Merged batch 2 (Link, Flex, ButtonEmpty/Icon, Badges): core 653/653 after merges. User decisions: keep upstream defaults (gutter m, link color text, text size s, grid columns 1) and upstream link `rel="noreferrer"`. Provider now renders an upstream-style color `<span class="euiThemeProvider">` by default (`@wrapper={{false}}` opts out): core 654/654, site acceptance 17/17, showcase screenshot unchanged.
- Note: the branch is being pushed to origin by tooling outside the sandbox (remote reflog shows `update by push` after commits); the session itself does not push.
- Root font size (user: "do what upstream does"): outermost provider now injects upstream global styles (root 14px, reset, body colors). Generator extracts 35 factories (+ resetStyles, euiScrollBarStyles, transparentize); parity 30/30 incl. byte-for-byte EuiGlobalStyles port. Core 656/656, site acceptance 17/17, site build/types, showcase screenshot. Found: legacy docs pages that load Amsterdam CSS override migrated components where legacy selectors are more specific (e.g. `.euiFlexGroup .euiFlexItem` beats FlexItem grow=false, stretching the docs sidebar search). Decision pending.
- User decision: remove legacy Amsterdam CSS from the docs site and migrate everything. The site no longer loads any legacy theme stylesheet; a root `BorealisRoot` provider (header theme switcher → colorMode) supplies upstream global styles. Removed `change-theme` util, theme initializer and `latest-styles-only` modifier. Unmigrated components render unstyled on docs pages until their wave lands (e.g. EuiIcon). Site acceptance 17/17, site node 8/8, site build/types.
- Wave 1 running in parallel worktrees (see [wave-brief.md](wave-brief.md)): icon, forms-layout, form-controls, checkables, page-layout, utilities.
- Performance (user request): `useEuiBorealisStyles` memoizes factory output per resolved theme (WeakMap keyed by `context.upstream`), like upstream's `useEuiMemoizedStyles`; direct factory calls in Token/Progress/PageHeaderContent/Icon routed through it; theme-less factories hoisted; `@cached` added to all 104 style getters in merged components. Node microbenchmark: euiTextStyles 194µs → 0.07µs per call, euiFormControlStyles 94µs → 0.04µs. Agents instructed via the brief.
- Shared `@css` argument (`EuiCss`) on EuiIcon, EuiPanel, EuiButtonIcon: caller styles composed last into the child's class. Fixed checkbox/radio marks regressed by the icon × checkables merge. testem `browser_disconnect_timeout` raised to 120s (icon catalog test under load). Core 747/747.

## Current resume point

Updated 2026-10-12 (coordinator session). Process: parallel agents per component family in git worktrees (`<scratchpad>/wt/<family>`, branch `eui-wave/<family>`), max 6 at once (8 cores / 7 GB). Rules for agents: [wave-brief.md](wave-brief.md) (incl. Performance rules and `@css`).

Resume update (2026-10-12): merged `new-skeleton` as `3253d497` and regenerated
portable source paths (`6f96d7c6`). Added the new EuiTimeline family in small
commits (`7d7bf077`, `c9e267ca`) with six focused browser tests and docs. The
replacement Chromium 141 runtime is now available: timeline passes 6/6, full
core 1134/1134, and site Node 8/8 plus acceptance 17/17. Its four inventory rows
are Migrated. The site navigation count is now 104 and its Testem heartbeat
matches core's 120s because the catalog-wide route test takes about 45s on ARM.
See [new-timeline-handoff.md](new-timeline-handoff.md).

Resume update 2 (2026-10-12, new coordinator session, scratchpad `625fa540…/scratchpad`):
the README's `/tmp/ember-eui-toolchain` and Chromium 141 paths are gone; tests run
on Playwright Chromium 130 via the old scratchpad `bin/google-chrome` symlink
(timeline 9/9). Model plan agreed with the user: Opus for recovery, tables and
data grid; Sonnet for refresh-flyout and the visual pass. Running: new-inline-split
and new-page-a11y (recovering uncommitted work in their old worktrees, merging
`feat/eui-latest` in), new-truncate (fresh worktree; salvages EuiTextTruncate and
EuiTextBlockTruncate from the old new-timeline worktree, whose timeline parts are
superseded), new-refresh-flyout (fresh worktree). Next: visual-pass recovery,
new-tables, then new-data-grid alone. Merge tooling copied to the new scratchpad.

**Port of upstream-only components complete (2026-10-12, `10e83539`).** Merged:
new-page-a11y, new-truncate, new-inline-split, new-refresh-flyout, visual-pass,
new-tables, new-data-grid (see each `<family>-handoff.md` for API, Ember
differences and what was not ported, e.g. data grid header drag-reorder,
imperative ref API, custom body/toolbar renderers; tables sticky columns and
numeral formats). Checks on main: core 1239/1239, parity 349/349, ember-tsc and
rollup pass, API docs check passes, site Node 8/8 and acceptance 17/17 (113 nav
items; catalog test ~80s idle, 300s timeout). The site's Vite 8
`optimizeDeps.esbuildOptions` warning (from @docfy/ember-vite 0.14.2) is fixed in
`site/vite.config.mjs`. No worktrees or `eui-wave/*` branches remain.

Update (2026-10-13): merged css-gaps (`3268787c`: `@css` on EuiButtonGroup,
EuiDroppable/EuiDraggable, EuiFilterGroup, EuiTable; EuiTablePagination aria
labels; EuiTableHeaderCell `@tooltipProps`) and data-grid-api (header drag
reorder, custom body/toolbar, `@registerApi` imperative API, scrollAnchorRow,
tabular copy, remaining props, docs for the expand button and popover editing;
see new-data-grid-handoff.md). Main: core 1267/1267, parity 349/349, site Node
8/8, acceptance 17/17 (nav still 113). Dev server (`pnpm start`) could not be
verified in the sandbox (first request hangs with or without the optimizeDeps
shim); needs a check on the host.

Update 2 (2026-10-13): merged data-grid-grouping, an Ember EUI extension not in
upstream. EuiDataGrid gains `@rowTree` (nested `children` or flat `parentId`)
and `@grouping` (group by column values), with treegrid ARIA, arrow-key
expand/collapse in the toggle cell, and expandRow/collapseRow/expandAll/
collapseAll on `@registerApi`. 46 marked hooks (`ember-eui extension (row-tree)`)
in ported files; see data-grid-extensions.md before re-porting upstream. Docs:
5 pages, 23 demos. Main: core 1302/1302, parity 349/349, site 8/8 + 17/17 (nav 113).

Update 3 (2026-10-13): docs audited against upstream v123.1.0's own docs
(elastic/eui packages/website, sparse clone) and every demo converted to a
single ```gjs component``` block (662 demos, incl. companion packages).
Data grid docs follow upstream's page structure (schema & columns, style &
display, ref methods, custom body, ...), with the row-tree extension pages after.
Site build hygiene: `pnpm clean:docfy` before build/start/test (docfy never
deletes generated files); `freshDocfyConfig()` in site/vite.config.mjs works
around @docfy/ember-vite re-adding its plugins on in-process Vite restarts
(duplicate demos, empty StackBlitz manifest). Prose curlies: inline code in
markdown, `\{{` inside raw HTML. Main: core 1302/1302, site 8/8 + 17/17
(nav 114). Upstream gaps found by the audit: see docs-audit-gaps.md.

Update 4 (2026-10-13): closed audit gaps. Buttons: `hasAriaDisabled` on
EuiButton/Empty/Icon/SplitButton/ButtonGroup; EuiButtonGroup option `title`,
yielded child buttons (no `@options`), gutterSize, segmented/selection
variants, vertical layout, display (button-group-handoff.md). EuiComboBox:
option prepend/append/tooltips, truncationProps, rowHeight auto, delimiter,
isCaseSensitive, sortMatchesBy, noSuggestions, prepend/append, search value in
the option block (combo-box-handoff.md, incl. behaviour that still differs).
Main: core 1333/1333, parity 349/349, site 8/8 + 17/17.

Update 5 (2026-10-13): merged combo box upstream behaviour (stateless
derived list; form packages forward every arg), page template composable
API (legacy API deprecated; Ember default `@offset` 0 because a fixed
EuiHeader pads <body>), selectable, super date picker (`intervalUnits`
always reported), breadcrumb popovers, flyout session management, theming
(OS colour mode / high contrast, CSS variables, theme-function `@css`,
`@ember-eui/core/theming`, docs/theming.md). Fixed ResizeObserver loop
errors in EuiSelectableList / EuiTextTruncate (report in next frame). The
docs site uses the composable page template. Main: core 1658/1658, parity
353/353, validated-form 25, changeset-form 24, flatpickr 8, pikaday 7, site
8/8 + 17/17 (nav 116). Handoffs: combo-box, page-template, selectable,
super-date-picker, breadcrumbs, flyout-manager, theming. Remaining gaps:
docs-audit-gaps.md.

Follow-ups: data grid renderers lack row depth/expanded state; EuiTableHeaderCell `@append`; EuiButtonEmpty `hasAriaDisabled`; the skeleton's private
screen-reader-live copy could reuse EuiScreenReaderLive; button docs page loads
slowly (~20s under load); open decision on focusing the form error callout;
major changeset for 16.0.0 deprecations.

Coordinator loop per finished agent:
1. Merge `eui-wave/<family>` into `feat/eui-latest`. Shared-file conflicts: `components.md` row-wise (non-Pending row wins); generator/parity entry objects unioned by key with insert-only test additions replayed; generated files regenerated in the main checkout (`node scripts/generate-eui-styles.mjs`), then parity (`node --test scripts/eui-upstream-parity.test.mjs`).
2. Check new code follows the perf rules (all style getters `@cached`, factories only via `useEuiBorealisStyles`) and `@css` for migrated children.
3. Run the full core suite in the main checkout (don't edit sources while its vite build runs); fix cross-family interactions; commit; remove the worktree and branch; start the next family in the freed slot.

In flight / pending at this point (updated 2026-10-12, migration complete, final cleanup running):
- Every component row is Migrated. Merged since last update: icon-assets (EUI 123.1.0 icon set, 698 names incl. 111 legacy aliases), control-file (EuiControlBar deprecated, EuiFilePicker), upstream-decisions (form error callout focus, refresh interval switch, deprecations of components removed upstream), css-sweep (`@css` on ~25 components, all styling workarounds removed). Main core suite 1117/1117 at `9bb97be3`; parity 305/305 (348 factories).
- Merged: cleanup (core 1120/1120 at 189641fc; companion suites pass; `componentName` option of class-names/inline-styles deprecated). Release notes merged (docs/migrating-to-borealis.md); deprecations now since 15.0.0 until 16.0.0 (a major changeset is pending).
- Running agents (may have been cut off by the usage limit — resume them via SendMessage): new-skeleton, new-timeline, new-inline-split, new-page-a11y, visual-pass. Worktree `wt/new-refresh-flyout` is created but its agent was NOT started yet. Previously listed: cleanup (dead css-mappings and helpers, companion package suites: validated-form, changeset-form, flatpickr, pikaday), release-notes (docs/migrating-to-borealis.md, changelog/changeset, getting-started update), visual-pass (screenshot every docs page desktop/mobile/dark, fix demo/site bugs).
- Environment: the host reinstalled the shared node_modules with macOS binaries. `/etc/sandbox-persistent.sh` sets `NODE_PATH` and `ESBUILD_BINARY_PATH` to Linux copies in `<scratchpad>/linux-natives` (esbuild, rolldown, rollup, lightningcss). Never reinstall node_modules from the sandbox. Don't stop servers with `pkill -f`/`pgrep -f` patterns that match the shell's own command line.
- User decisions: keep upstream behavior (applied); deprecating removed-upstream components is fine (until 16.0.0).
- User request (2026-10-12): also port components that exist upstream (123.1.0) but not in Ember EUI, with tests and docs. Inventory (upstream exports minus Ember files, excluding React contexts/providers/observers and internal sub-parts already ported): 
  - running: new-skeleton (EuiSkeletonText/Title/Circle/Rectangle/Loading, EuiIllustration), new-timeline (EuiTimeline + Item/ItemEvent/ItemIcon, EuiTextTruncate, EuiTextBlockTruncate), new-inline-split (EuiInlineEditText/Title, EuiSplitButton, EuiFormControlButton, EuiFormAppend/Prepend);
  - queued: new-page-a11y (EuiPageSection, EuiPageSidebar, EuiBanner, EuiLiveAnnouncer, EuiScreenReaderLive); new-refresh-flyout (EuiAutoRefresh, EuiAutoRefreshButton, EuiFlyoutResizable, EuiFlyoutMenu); new-tables (EuiSearchBar + Filters, EuiBasicTable, EuiInMemoryTable); new-data-grid (EuiDataGrid — largest, last).
  - not ported (React-only plumbing; Ember uses modifiers/services/EuiEmotionProvider): EuiProvider/EuiThemeProvider/*Context, EuiFocusTrap, EuiOutsideClickDetector, EuiMutationObserver, EuiResizeObserver, EuiWindowEvent, EuiErrorBoundary, EuiValidatableControl. EuiDatePicker (single): core has no calendar engine (companion flatpickr/pikaday packages provide inputs) — gap noted.
  New components get registered in components.ts/template-registry.ts (merge by union) and docs pages (see wave-brief "New components").
- After all agents: merge, run core + site checks, final progress/README summary. Leftover agent stashes and the icons-refresh worktree were removed.
- Merge tooling lives in the scratchpad: `wave-merge.sh <family>`, `merge_lists.py`, `rows.py`, `dupkeys.mjs`, `mkwt.sh <family>`.
- Open user decision: whether forms move focus to the error callout when invalid (upstream does).
- Cleanup later: unused `utils/css-mappings/*` files, docs demo visual pass, release notes for changed defaults.

## Commands

```sh
pnpm eui:check
pnpm --filter @ember-eui/core test
pnpm --filter @ember-eui/core build
pnpm --filter site test
pnpm --filter site build
pnpm --filter @ember-eui/core lint:types
pnpm --filter site lint:types
pnpm docs:api:check
```

Build core before site; site tests/build share output and must run sequentially. Toolchain/environment details are in README.md. Generated styles are not manually formatted or edited.
