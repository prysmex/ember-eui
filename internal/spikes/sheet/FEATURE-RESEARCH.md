# `@ember-eui/sheet`: features of other grids, and which are worth adding

Written 2026-11-19 for `TODO-feature-research.md`. Research only: no code
was changed.

**The baseline** is what v0.1 to v0.3 built or designed: `PACKAGE-DESIGN.md`,
`V02-DESIGN.md`, `V03-DESIGN.md` (batches 1 to 5), their RESULTS files and
`packages/sheet/README.md`. A feature that is in any of them has no row here.
Examples: the fill handle with series, TSV copy and paste, undo, frozen
fields, group by, row drag, row colours (a bar), `dateTime`, `button`,
`barcode`, find next and previous, the selection summary, the summary bar,
row heights, the shortcut list and field management.

**Out of scope, on purpose**: formulas, computed fields, rollups and
real-time collaboration. Comments are out too (`V03-DESIGN.md` 14.3, "not
reopened"). None of them counts as a gap.

## How to read the evidence

Every product claim cites a source tag from the Sources section. The tag
says how strong the claim is:

- **P** (read on a page): the page was fetched and read.
- **F** (folder only): a docs or source folder with that name exists. That
  shows the feature exists, but not how it behaves. An AG Grid tier marked
  F was inferred from the package the code lives in.
- **S** (search snippet): only a search result's summary was seen, and the
  page itself refused the fetch. **Treat these as unverified.**

A product missing from "Products" means "not found in what was read". It
does not mean the product lacks the feature.

AG Grid tiers: **C** = Community (free, MIT), **E** = Enterprise (paid).
A page with `enterprise: true` in its front matter counts as E (stated). A
page without that flag is marked "C (inferred)". RevoGrid: **free** or
**Pro** (paid). Glide is MIT and has a single tier. Handsontable has a
single package that needs a paid licence for commercial use [H1 P].

### Sites that refused automated fetches

Every fetch of these returned HTTP 403: ag-grid.com, handsontable.com,
rv-grid.com (including next.rv-grid.com), docs.nocodb.com and nocodb.com,
baserow.io, help.teable.ai, npmjs.com and cdn.jsdelivr.net. In their place
I used the products' GitHub repositories: READMEs, and the docs sources
for AG Grid and Handsontable. NocoDB's docs repository on GitHub
(`nocodb/noco-docs`) holds only built pages of an old version (0.109.7), so
it was not used. NocoDB, Baserow and Teable have no page-confirmed facts
here: every claim about them is **S**.

### Cost and rules

- Line counts are estimates. They are scaled against the V03 batch table:
  batch 1 (four small features) is about 450 source lines.
- "Core" means a change to `packages/core/src`. V03 section 1 says core
  does not change, so any row that needs a core change is at best "maybe".
- "Fits" checks the V03 section 1 rules: the sheet is a pure view of the
  owner's rows, data goes down and actions go up, every write is a change
  set, and there is no built-in toolbar. A feature that is really a query
  or a toolbar (filters, find UI, export) is judged as an outside helper,
  like `summarize` and `groupRecords`, where one makes sense.

## The table

| # | Feature | Products (source) | Our status | Value for an Airtable-style grid | Cost | Per-cell / perf risk | Fits the rules | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Auto-size a column to its content (double-click the resize edge; "fit" in the header menu) | AG Grid C (inferred) [A5 P]; Glide `maxColumnAutoWidth`, `remeasureColumns` [G2 P]; RevoGrid "auto-size columns" in the free list, and "Column Autosize" in the Pro list [R1 P] | none. The core resizer has no double-click (`column-resizer.gts`) | High: wide text and narrow numbers are a daily chore | ~150 lines. Probably no core change: the sheet measures with the type's `format` and emits `@onFieldWidthChange`. Catching a double-click on the core's resizer from the sheet is untested; if it fails, use only the header menu item | Runs once, on demand, over the loaded records (AG Grid measures only the rendered rows [A5 P]) | Yes: a width is presentation, controlled with the handler or kept locally | **Worth it** |
| 2 | Fullscreen | Not confirmed in any of the products' pages. EuiDataGrid has it: `setIsFullScreen` (`eui-data-grid.gts:807`) and a fullscreen selector | none. The README's Limits section says "not yet" | Medium: big sheets on a laptop | ~100 lines. The grid's own fullscreen does not fit: its focus trap leaves out the sheet's editor, which sits beside the grid (`RESULTS.md:131-136`, `DESIGN.md:403`), and the toolbar and footer are outside the grid too. So the sheet would make its own wrapper fullscreen (fixed position, Escape to leave). No core change, but untested | None | Yes: presentation (controlled with a handler, local without). The app puts the button in `<:toolbar>` | **Worth it** |
| 3 | App items in the header (column) menu | AG Grid column menu E [A1 P]; Glide `onHeaderMenuClick`, `onHeaderContextMenu` hooks [G2 P] | partial. The sheet builds a fixed list (`eui-sheet.gts:1238`); the app can add row items (`@rowActions`) but not header items | Medium: "Summarize by", "Lock field" and similar app actions | ~60 lines, mirroring `@rowActions`. No core change | None | Yes: an intent | **Worth it** |
| 4 | A block in the expanded record (for the app's comments, history or activity) | Record comments and revision history in the expanded record: NocoDB [N3 S], Baserow [B3 S, B4 S], Teable [T1 S]. RevoGrid Pro "Audit Trail History" [R1 P] | none. The sheet yields only `<:toolbar>`, `<:footer>` and `<:empty>` | Medium-high: all three Airtable-like apps show comments or history in the expanded record (snippets only, unverified) | ~50 lines. No core change | None | Yes. The owner renders its own data; the sheet stores no comments or history, so this does not reopen comments | **Worth it** |
| 5 | Copy with headers | AG Grid `copyHeadersToClipboard` E [A6 P] | none | Medium: pasting into a report or an email | ~30 lines (row menu item, or Ctrl/Cmd+Shift+C). No core change | None | Yes | **Worth it** |
| 6 | Per-cell colour by a rule (conditional formatting) | Handsontable `cells` → `className`, colour scale [H4 P]; AG Grid `cellClassRules` C (inferred) [A7 P]; Glide per-cell `themeOverride`, `getRowThemeOverride` [G2 P]; RevoGrid Pro "Conditional Formatting" [R1 P]; NocoDB row or cell mode [N4 S]; Baserow left bar or whole-row background [B2 S] | partial. Row colour is designed as a 4 px bar (batch 4, V03 10.2). A full-row tint was turned down (D10: it fights hover, selection and the frozen cells' backgrounds), so it is not proposed again here | Medium-high: overdue dates, failed checks and status at a glance | ~150 lines: `@cellColor(record, field)` with the theme's named colours. For D10's reasons it should not be a background: draw a mark (an inner edge bar, or coloured text). No core change (`setCellProps`) | One call per rendered cell. AG Grid warns about the same cost [A7 P]. Keep it to theme names and cache per render | Yes: the owner decides the rule, the sheet draws it | **Worth it** |
| 7 | CSV export helper | AG Grid CSV export C, Excel export E [A1 P]; Handsontable Excel [H1 P] and CSV [H2 F]; RevoGrid CSV free, Excel Pro [R1 P]; NocoDB CSV and XLSX of a view [N5 S] | partial. Copy as TSV, and `toTsv` in `src/core/tsv.ts` | Medium: "download what I see" | ~60 lines: `toCsv(ctx, records, fields)`, which writes each type's copy text. No core change. Excel would need a dependency: leave it to the app | None (on demand) | Yes, as a helper outside the component, like `summarize` | **Worth it** |
| 8 | CSV import helper with type inference | Handsontable `inferColumnTypes`, `convertToInferredTypes`, `.xlsx` import [H5 P, H6 P]; RevoGrid Pro "Excel Export/Import" [R1 P]; NocoDB CSV import that picks field types [N6 S] | partial. A paste reads text through each type's parse path and inserts lines past the end. Nothing reads a file or guesses types | Medium-high for onboarding: "start from my spreadsheet" | ~250 lines: `importRows(ctx, text, mapping)` returns a change set, with what could not be read in `rejected`; `inferFieldTypes(matrix)` proposes field drafts. No core change | None (on demand) | Yes: helpers, and the result is a change set | **Worth it** (inference: maybe) |
| 9 | Load more at the end of the scroll (infinite loading) | AG Grid infinite row model C [A1 P]; RevoGrid Pro "Infinite Scroll", "Server Loading" [R1 P] | partial. Paging is the owner's. Groups have `loaded` and `continued` for paged data, and the `pageGroups` helper sets them (V03 8.1, GP9). No intent tells the owner that the end is near | High for Prysmex-sized tables: no pager in the toolbar | ~80 lines: `@onVisibleRangeChange({ first, last })` from the grid's `virtualizationOptions.onItemsRendered` (`core/src/utils/data-grid/types.ts:330`). No core change | Once per render pass, not per cell | Yes: an intent. The owner loads and appends | **Worth it** |
| 10 | Auto row height (the row grows to its content) | AG Grid `autoHeight` with `wrapText` C (inferred) [A8 P]; Glide `rowHeight` as a function [G2 P] | partial. Four fixed heights through `lineCount` (`eui-sheet.gts:416`). The core supports `defaultHeight: 'auto'` | Medium: long text and many chips | ~60 lines. No core change | High: auto heights make rows non-uniform (`body-base.ts:180`), so every rendered row is measured and scrolling gets slower | Yes: presentation | **Maybe**: measure the scroll cost first, as was done for the frozen field |
| 11 | Custom fill series per type ("Item 1" → "Item 2") | Glide `onFillPattern` [G2 P]; RevoGrid Pro "Smart Auto Fill" [R1 P] | partial. Numbers and dates continue; anything else repeats | Low-medium | ~60 lines: an optional `fillSeries` on a field type. No core change | None (runs at the fill's release) | Yes | **Maybe** |
| 12 | A cell tooltip with the full value | AG Grid `tooltipValueGetter`, `headerTooltip` C (inferred) [A9 P]; RevoGrid Pro "Tooltips" [R1 P] | partial. Errors show as the cell's `title`; `description` is the header's tooltip | Low-medium: row height and the expanded record cover most of it | ~40 lines with a `title` attribute (an `EuiToolTip` per cell is ruled out by P9). No core change | One attribute per rendered cell | Yes | **Maybe** |
| 13 | Time-only field type | Handsontable `time` cell type [H2 F] | none (`date` and the designed `dateTime`) | Low-medium: shift start times | ~120 lines on top of `dateTime`'s parser. No core change | None | Yes | **Maybe** |
| 14 | A paste wider than the sheet adds fields | Baserow: a paste creates rows and fields as needed [B5 S] | partial. Rows past the end are inserted; columns past the last field are dropped (`paste-plan.ts:85`) | Medium for "paste my spreadsheet" | ~120 lines. It needs `@onFieldCreate`, which may be async, before a second change set. No core change | None | Yes, but two steps (a field intent, then a change set) | **Maybe** |
| 15 | Bulk edit of checked rows (one form, N records) | NocoDB "Bulk update" [N7 S]; AG Grid batch editing E (inferred) [A2 F] | partial. Fill down, the fill handle and a repeated paste do the same for spreadsheet users | Medium for users who do not use spreadsheets | ~200 lines (a form like the field editor). No core change | None | Yes: one change set | **Maybe**: an app can do it now with `@rowActions` and `@onChange` |
| 16 | Cell flash on an external change | AG Grid `enableCellChangeFlash` C (inferred) [A10 P]; RevoGrid Pro "Cell Flash" [R1 P] | partial. A paste, fill or undo already flashes its range (`V03-RESULTS.md:224`) | Low without co-editing (out of scope) | ~30 lines: `api.flash(cells)`, reusing the existing flash. No core change | None | Yes | **Maybe** (only as the API method) |
| 17 | Undo of field operations | Teable: undo of all table operations [T2 S] | partial. Listed in V03 14.3 | Low-medium | ~250 lines: field intents would need inverses | None | Yes | **Maybe** |
| 18 | Markdown or rich text in long text | Glide Markdown cell [G2 P]; Baserow long text [B6 S] | none | Low-medium | ~150 lines plus a sanitizer (risk: HTML injection). It can be a custom type now | Rendering markdown per cell is costly at tall row heights | Yes, as a custom type | **Maybe**: as an example custom type, not built in |
| 19 | Tree data (parent and child records) | AG Grid tree data E [A1 P]; Handsontable nested rows [H2 F]; RevoGrid Pro "Hierarchical Data View" [R1 P] | none. The core has a row-tree extension (`row-tree-hooks.ts`) | Medium for subtasks. Not found in the Airtable-like apps (snippets only), where linked records do this job | ~800 lines on the V03 row model. Probably no core change | Low (rows only) | Yes, if the owner gives depth and order, as with groups | **Maybe**, after group by settles |
| 20 | Grouped (multi-level) column headers | Glide `group` [G2 P]; AG Grid column groups C (inferred) [A11 P]; Handsontable `NestedHeaders`, `CollapsibleColumns` [H7 P]; RevoGrid Pro "Multi-Level Headers" [R1 P] | none | Low: none of the Airtable-like apps showed it | ~400 lines. **Core change**: the header row is one row (`header-row.gts`) | Low | Rule break (core) | **Not** |
| 21 | Pinned records (top or bottom rows) | AG Grid row pinning C (inferred) [A12 P]; Handsontable frozen rows [H1 P]; RevoGrid free pinned rows [R1 P] | partial. The summary bar and group headers | Low. Not found in the Airtable-like apps (snippets only) | **Core change** (a second body) | Low | Rule break (core) | **Not** |
| 22 | Merged cells, column spans | Glide `span` [G2 P]; Handsontable merged cells [H1 P]; RevoGrid Pro "Merge Cells" [R1 P]; AG Grid column spanning [A3 F] | none. The grid has no colspan (V03 9.1) | Low: a record grid has one value per cell | **Core change** | Medium | No: it breaks one-record-per-row | **Not** |
| 23 | Multi-range selection (Ctrl/Cmd+click adds a range) | Glide `multi-rect` [G2 P]; RevoGrid Pro "Multi-Range Selection" [R1 P] | none | Low: copy, fill and paste of several ranges have no clear meaning | ~500 lines through selection, copy, fill and the selection API | Medium (more ranges checked per cell) | Yes | **Not** |
| 24 | Built-in filter UI (set filter, filter builder, header filters) | AG Grid set, multi and advanced filters E [A2 F]; RevoGrid filters, free and Pro [R1 P] | partial: `@onFilterByField` and the EmberSearchUi connector | High | ~600 lines or more | — | No: a query and a toolbar, which are the owner's | **Not** (the app's, or EmberSearchUi's) |
| 25 | Tool panels, side bar, column chooser, status bar UI | AG Grid side bar and tool panels E [A1 P], status bar E [A13 P] | partial. The block API yields `hideField`, `showField` and the selection (batch 5) | Medium | — | — | No: a built-in toolbar | **Not** |
| 26 | Pagination UI | AG Grid C [A1 P]; Handsontable [H1 P]; RevoGrid Pro [R1 P] | partial: `@rowNumberOffset` | — | — | — | No: a query | **Not** (see row 9) |
| 27 | Hidden or trimmed rows | Handsontable hidden rows [H1 P]; RevoGrid trimmed rows [R1 P] | none | — | — | — | No: a query (the owner's filter) | **Not** |
| 28 | Pivot, aggregation of groups, integrated charts, sparklines | AG Grid E [A1 P, A2 F]; RevoGrid Pro [R1 P]; Glide sparkline cell [G3 F] | partial: `summarize` and group summaries | Low for data entry | High | — | No: aggregation is the owner's | **Not** (a sparkline can be a custom type) |
| 29 | Master/detail, full-row editing | AG Grid master/detail E [A1 P], full-row editing [A3 F]; RevoGrid Pro "Full Row Editing" [R1 P] | partial: the expanded record does this job | — | — | — | Yes | **Not** |
| 30 | Right-to-left layout | Handsontable `layoutDirection` [H8 P]; RevoGrid free RTL [R1 P] | none. The core grid has no RTL either | Low, assuming Prysmex has no right-to-left users (to confirm) | High: navigation keys, frozen field, fill handle, editors. Probably a core change | Low | Yes | **Not** now |
| 31 | Cell notes and comments, record history built in | AG Grid notes E [A2 F]; Handsontable comments [H2 F]; NocoDB, Baserow, Teable [N3 S, B3 S, B4 S, T1 S] | none | — | — | — | No: comments are out of scope (V03 14.3) | **Not** (row 4 gives the app a place for them) |
| 32 | Move a range of cells by dragging it | Handsontable move cells [H2 F] | none | Low. Not found in the Airtable-like apps (snippets only) | ~300 lines | Low | Yes | **Not** |
| 33 | Other cell types: JSON, geometry, password, slider, counter | NocoDB JSON and geometry [N8 S]; Handsontable password [H2 F]; RevoGrid Pro slider and counter editors [R1 P] | none | Low | Each one is a custom type | — | Yes | **Not** built in (custom types cover them) |
| 34 | Column stretch to fill the width | RevoGrid Pro "Column Stretch" [R1 P] | none. Widths are fixed | Low | ~60 lines | Low | Yes | **Not** |
| 35 | Resize one row's height | RevoGrid free "row resize" [R1 P] | none. Row height applies to the whole view | Low. The Airtable-like apps show one height per view (snippets only) | Medium | Non-uniform heights (as row 10) | Yes | **Not** |

## Worth it, grouped into possible batches

Line counts are estimates. None is known to need a core change. Two are untested: the double-click on the resizer (1) and the sheet's own fullscreen (2).

**Batch A: small presentation items (about 390 lines).**

- Auto-size a column (1).
- Fullscreen (2), on the sheet's own wrapper.
- App items in the header menu (3).
- A block in the expanded record (4).
- Copy with headers (5).

**Batch B: helpers outside the component (about 310 lines).**

- `toCsv` (7).
- `importRows` (8), which returns a change set. Add `inferFieldTypes` only
  if a first version shows its guesses can be trusted.

**Batch C: colour (about 150 lines).**

- `@cellColor` by rule (6), drawn as a mark, not a background (D10).
- It builds on batch 4's row colour and its theme tokens.

**Batch D: scale (about 80 lines, plus a docs demo).**

- `@onVisibleRangeChange` for load-more (9).
- It is likely the most useful item for big tables, assuming Prysmex's tables are too large to load at once (to confirm).
- It can go before A to C.

**Maybe, later.** Measure row 10 (auto row height) the way the frozen field
was measured, before deciding. The others (11 to 19) are small polish or
ideas without clear demand. Rows 14 and 15 are both "paste my spreadsheet"
and "edit many at once" for non-spreadsheet users, so decide them together.

## Not worth it, and why

- **Grouped headers, pinned rows, merged cells (20 to 22)** need a core
  change. Merged cells also break one record per row. None of the
  Airtable-like apps showed them.
- **Multi-range selection (23)** has no clear meaning for copy, fill and
  paste, and it touches every selection path.
- **Filter UI, tool panels, status bar UI, pagination, hidden rows (24 to
  27)** are queries or toolbars. They are the owner's by rule, and the
  connector and blocks already cover them.
- **Pivot, charts, master/detail (28, 29)** are analysis, not data entry.
  The expanded record already does master/detail's job.
- **RTL (30)** is costly. Its value depends on right-to-left users, which this research assumes Prysmex does not have (to confirm).
- **Built-in comments and history (31)** are out of scope. Row 4 lets the
  app show its own.
- **Moving cells, extra cell types, column stretch, per-row resize (32 to
  35)** are rare in Airtable-style apps, or custom types already cover
  them.

## Sources

Glide Data Grid
- [G1] P: https://raw.githubusercontent.com/glideapps/glide-data-grid/main/README.md
- [G2] P: https://raw.githubusercontent.com/glideapps/glide-data-grid/main/packages/core/API.md
- [G3] F: https://github.com/glideapps/glide-data-grid/tree/main/packages/cells/src/cells

RevoGrid (rv-grid.com refused fetches; the repository README lists the free and Pro features)
- [R1] P: https://github.com/revolist/revogrid

AG Grid (Doc pages are the docs sources in the repository. `<d>` = https://raw.githubusercontent.com/ag-grid/ag-grid/latest/documentation/ag-grid-docs/src/content/docs)
- [A1] P: https://github.com/ag-grid/ag-grid (the README's Community and Enterprise lists)
- [A2] F: https://github.com/ag-grid/ag-grid/tree/latest/packages/ag-grid-enterprise/src
- [A3] F: https://github.com/ag-grid/ag-grid/tree/latest/documentation/ag-grid-docs/src/content/docs
- [A5] P: `<d>/column-sizing/index.mdoc`
- [A6] P: `<d>/clipboard/index.mdoc` (`enterprise: true`)
- [A7] P: `<d>/cell-styles/index.mdoc`
- [A8] P: `<d>/row-height/index.mdoc`
- [A9] P: `<d>/tooltips/index.mdoc`
- [A10] P: `<d>/change-detection/index.mdoc`
- [A11] P: `<d>/column-groups/index.mdoc`
- [A12] P: `<d>/row-pinning/index.mdoc`
- [A13] P: `<d>/status-bar/index.mdoc` (`enterprise: true`)
- AG Grid's fill handle is Enterprise too (`<d>/cell-selection-fill-handle/index.mdoc`, `enterprise: true`). The sheet already has a fill handle, so this is context only.

Handsontable (`<h>` = https://raw.githubusercontent.com/handsontable/handsontable/develop/docs/content/guides)
- [H1] P: https://github.com/handsontable/handsontable (README: features and licence)
- [H2] F: https://github.com/handsontable/handsontable/tree/develop/docs/content/guides
- [H4] P: `<h>/cell-features/conditional-formatting/conditional-formatting.md`
- [H5] P: `<h>/import-and-export/infer-column-types/infer-column-types.md`
- [H6] P: `<h>/accessories-and-menus/import-from-excel/import-from-excel.md`
- [H7] P: `<h>/columns/column-groups/column-groups.md`
- [H8] P: `<h>/internationalization/layout-direction/layout-direction.md`
- Context: Handsontable's search plugin only highlights and returns matches, with no next or previous (`<h>/navigation/searching-values/searching-values.md`). Its column summary writes results into a cell you choose (`<h>/columns/column-summary/column-summary.md`). The sheet already covers both.

NocoDB (every page refused the fetch: S only, unverified)
- [N3] S: https://nocodb.com/docs/product/tables/records/expand-record (comments, revision history)
- [N4] S: https://nocodb.com/docs/product/tables/table-operations/record-colouring
- [N5] S: https://nocodb.com/docs/mcp/records (CSV and XLSX export of a view)
- [N6] S: https://docs.nocodb.com/0.109.7/setup-and-usages/table-operations/ (CSV import)
- [N7] S: https://nocodb.com/docs/product-docs/records/actions-on-record (bulk update)
- [N8] S: https://nocodb.com/docs/scripts/api-reference/field (field types)

Baserow (S only, unverified)
- [B2] S: https://baserow.io/user-docs/row-coloring
- [B3] S: https://baserow.io/user-docs/row-commenting
- [B4] S: https://baserow.io/user-docs/row-change-history
- [B5] S: https://baserow.io/user-docs/baserow-keyboard-shortcuts (a paste creates rows and fields)
- [B6] S: https://baserow.io/user-docs/long-text-field

Teable (S only, unverified)
- [T1] S: https://help.teable.ai/en/basic/view/grid (comments, record history)
- [T2] S: https://help.teable.ai/en/changelog-2024 (undo of all table operations, 2 September 2024)

Code references (this repository, read on 2026-11-19): `packages/core/src/components/eui-data-grid.gts:807` (`setIsFullScreen`), `packages/core/src/components/eui-data-grid/column-resizer.gts` (no double-click), `packages/core/src/components/eui-data-grid/body-base.ts:180` (auto heights are non-uniform), `packages/core/src/utils/data-grid/types.ts:330` (`onItemsRendered`), `packages/sheet/src/components/eui-sheet.gts:416` (row heights) and `:1238` (header menu items), `packages/sheet/src/core/paste-plan.ts:85` (columns past the last field).
