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

Coordinator loop per finished agent:
1. Merge `eui-wave/<family>` into `feat/eui-latest`. Shared-file conflicts: `components.md` row-wise (non-Pending row wins); generator/parity entry objects unioned by key with insert-only test additions replayed; generated files regenerated in the main checkout (`node scripts/generate-eui-styles.mjs`), then parity (`node --test scripts/eui-upstream-parity.test.mjs`).
2. Check new code follows the perf rules (all style getters `@cached`, factories only via `useEuiBorealisStyles`) and `@css` for migrated children.
3. Run the full core suite in the main checkout (don't edit sources while its vite build runs); fix cross-family interactions; commit; remove the worktree and branch; start the next family in the freed slot.

In flight / pending at this point (updated 2026-10-12, later check-in):
- Running agents: feedback (accordion/toast/comments/notifications), buttons-misc (button group/content, facet, filter), misc-display (tree view, text diff, expression, tour), resizable-dnd (resizable container, drag and drop), selectable (+ suggest).
- Merged since last update: lists, header, modal-flyout, overlays, cards. Main core suite 858/858. All rows that were In progress are now Migrated.
- Leftovers to review: worktree `wt/icons-refresh` (branch `eui-wave/icons-refresh`, no commits) holds an uncoordinated icon-asset refresh by the earlier icon agent (632 SVGs + 31 components + `icon-assets-handoff.md`) — evaluate as its own family after current waves; do not merge blindly. Two agent stashes (`WIP on eui-wave/overlays`, `RECOVER eui-wave/header work`) duplicate merged work and can be dropped; the user's own older stashes must stay. Agents must never use `git stash` (shared across worktrees).
- `@css` follow-ups: modal/flyout close buttons still use wrapper spans (`closeIconCss`, `closeButtonPositionCss`, `closeButtonLookCss` getters ready); context menu item icons (`align-self`, spinner); EuiButton/EuiText/EuiBetaBadge/EuiButtonEmpty/EuiTitle/EuiPopover/EuiFlyout lack `@css` (some callers use `&&` doubled specificity meanwhile).
- Merge tooling lives in the scratchpad: `wave-merge.sh <family>`, `merge_lists.py`, `rows.py`, `dupkeys.mjs`, `mkwt.sh <family>`.
- Next families after the running ones: combo box; super select; date pickers + super date picker; range/dual range; color picker/palette; markdown editor/format; code block; table family.
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
