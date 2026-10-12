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
- Batch 2 base: pre-registered Link, Badge (+group/beta/notification, color helpers), Flex (group/item/grid), ButtonEmpty and ButtonIcon factories (32 total); parity 29/29, core 609/609. Borealis theme and chroma-js are now external imports instead of being inlined into `styles.generated.ts` (same pinned versions; removes a duplicate theme copy). Services barrel shim also re-exports `is_color_dark`. See [batch2-brief.md](batch2-brief.md).
- No coordinator/root agent exists (user, 2026-10-12); this session owns root duties. Fixed template `(hash)` Borealis overrides (cebf6dbc). Root validation: core 611/611, site node 8/8, site acceptance 17/17, site build + types, core build + types, showcase screenshot. First five ports + PageContent marked Migrated.

## Current resume point

Latest-only full core tests and core rebuild are in progress. Previous runs are superseded by latest-only changes. Root must finish full tests, site acceptance/build, type/lint checks and browser smoke, then update component status and exact counts. Do not stage `.vscode/settings.json`.

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
