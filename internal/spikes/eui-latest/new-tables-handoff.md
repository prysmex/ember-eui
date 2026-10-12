# New components: EuiSearchBar, EuiBasicTable, EuiInMemoryTable

Branch `eui-wave/new-tables` (from `feat/eui-latest` at `7d4f013a`). Target
EUI 123.1.0 / Borealis 8.1.0. Status: **Migrated** (see checks).

## Files

- Query engine (pure TS, upstream license headers):
  `packages/core/src/utils/eui/search-bar/` — `ast.ts`, `query.ts`,
  `default-syntax.ts`, `default-syntax-parser.ts` (the PEG.js 0.10.0 parser
  copied from `@elastic/eui/es/.../default_syntax.js`), `execute-ast.ts`,
  `operators.ts`, `date-format.ts`, `date-value.ts`,
  `ast-to-es-query-dsl.ts`, `ast-to-es-query-string.ts`, `predicate.ts`
  (moment predicates, `get`, `keysOf`), `index.ts`.
- Services: `utils/eui/format.ts` (`formatAuto/Text/Boolean/Number/Date`,
  `dateFormatAliases`), `utils/eui/sort.ts` (`SortDirection`,
  `Comparators`).
- Components: `eui-search-bar.gts`, `eui-search-bar-filters.gts`,
  `eui-search-bar/{eui-search-box,is-filter,field-value-toggle-filter,
  field-value-toggle-group-filter,field-value-selection-filter}.gts`,
  `eui-basic-table.gts`, `eui-basic-table/{pagination-bar,
  default-item-action,expanded-item-actions,collapsed-item-actions}.gts`,
  `eui-in-memory-table.gts`; private types/helpers in
  `-private/search-bar.ts` and `-private/basic-table.ts`.
- Registries: `components.ts`, `template-registry.ts` (4 public
  components, lines added only); `package.json` app-js (13 entries, from
  `rollup --config`).
- Styles: generator entries (`// new-tables` block) for
  `euiSearchBar__searchHolder/__filtersHolder`, `euiBasicTableBodyLoading`,
  `euiBasicTableWrapperPanelledStyles`, `safariLoadingWorkaround`,
  `euiBasicTablePaginationBarStyles`, `euiBasicTablePanelStyles`,
  `EUI_BASIC_TABLE_PANEL_CLASS_NAME`; regenerated `styles.generated.ts` and
  `upstream-sources.json` (worktree path comments; regenerate on merge).
- Tests: `tests/integration/components/eui-search-bar-test.gts` (9),
  `eui-basic-table-test.gts` (8), `eui-in-memory-table-test.gts` (5);
  parity: 3 new engine/service tests + 6 style tests in
  `scripts/eui-upstream-parity.test.mjs`.
- Docs: `docs/forms/search-bar/` (2 demos), `docs/tabular/basic-table/`
  (3 demos), `docs/tabular/in-memory-table/` (2 demos);
  `scripts/api-docs-pages.json` (3 pages).

## Query engine

A file-for-file port of upstream `components/search_bar/query` with only
import paths, `!` non-null assertions (core's `noUncheckedIndexedAccess`)
and file-level eslint disables changed. The parser is not hand written:
`default-syntax-parser.ts` is upstream's generated PEG.js output, with two
mechanical edits (Babel's `_toConsumableArray(tail)` → `tail`;
`validateFlag` read from the parse options, which upstream also passes).
The parity suite re-derives the file from the installed upstream and
compares it byte for byte.

Parity (`node --test scripts/eui-upstream-parity.test.mjs`): ~60 query
strings × 3 option sets (plain, strict schema, `recognizedFields`) compare
`text`, clauses (date values resolved) and printing, including parse error
messages and locations; ~30 queries × 3 execute options (`defaultFields`,
custom `isClauseMatcher`) compare `Query.execute` results, `toESQuery` and
`toESQueryString`; the mutation API used by the filters is compared step
by step (>250 comparisons). Format/sort helpers are compared on a value
matrix.

`formatNumber` with a numeral `format` string: upstream uses `numeral`,
which core does not depend on. The `decimal1-3`/`integer` aliases are
implemented with `Intl.NumberFormat` (parity-tested against upstream); other
numeral patterns are not supported. EuiBasicTable only uses the unformatted
path.

## Ember API and differences

- `EuiSearchBar`: `@query`/`@defaultQuery` (Query or text), `@onChange({
  query, queryText, error })`, `@box` (`placeholder`, `incremental`,
  `schema`, `isClearable`, `isLoading`, `compressed`, `fullWidth`,
  `aria-label`, `aria-describedby`, `data-test-subj`, …), `@filters`,
  `@dateFormat`, `@hint` (`content`, `popoverProps`) + `<:hint>` block,
  `@compressed`, `@showErrorTooltip`, `@css`; tools are `<:toolsLeft>`
  and `<:toolsRight>` blocks (one non-growing flex item each, upstream
  wraps every tool element). `EuiSearchBar.Query`, and `Query`/`Ast`
  named exports, like upstream. The controlled-`query` reset follows
  upstream's derive-state-while-rendering logic.
- Filters: same configs as upstream. `custom_component.component` is an
  Ember component (`@query`, `@onChange`); option `view` is text (React
  node upstream). The selection filter's popover panel gets upstream's
  `euiFilterGroup__popoverPanel` through `EuiPopover @panelCss`;
  `aria-expanded` reflects the popover (EuiFilterButton would otherwise
  derive it from `@isSelected`). Not ported: scrolling EuiSelectable to
  the just-checked option after auto-sorting (EuiSelectable has no
  public active-option API), `searchProps.disabled` on load errors (load
  errors show as the empty message), `filterWith` (unused upstream too).
- `EuiBasicTable`: columns/items/pagination/sorting/selection as in
  upstream; `@onChange` gets the same criteria. React nodes become text:
  `render` returns text or `htmlSafe`; new `component` (cell component
  with `@item @value @column`), `mobileOptions.component`; `footer` text
  or function returning text; `name` text (`nameTooltip` renders an
  `EuiIconTip` inside the header cell). Custom actions are `{ component }`
  (`@item`, `@enabled`) instead of `render`. `@noItemsMessage` text +
  `<:noItemsMessage>` block; expanded rows via `<:expandedRow as |item
  itemId value|>` (map values that are text render without the block).
  `@rowProps`/`@cellProps` are applied by an attribute modifier (`on*`
  functions become listeners, `className` classes, scalars attributes); a
  row `onClick` becomes `EuiTableRow @onClick`. Controlled checkboxes are
  reset to the resulting selection after each change (React-like). Items
  dropped from `@items` are reported through `onSelectionChange` in the
  next run loop (upstream does it while deriving state). Not ported:
  sticky actions columns, `stickyHeader/stickyScrollbar` (EuiTable lacks
  them), copy-to-clipboard tabular markers (`OverrideCopiedTabularContent`),
  `EuiComponentDefaultsContext` page-size defaults (upstream defaults
  used). Safari's loading workaround is an inline `position: relative` on
  the `<table>` (EuiTable has no `@css`).
- `EuiInMemoryTable`: owns query/sort/page as tracked state with
  upstream's `getDerivedStateFromProps` rules; `search.onChange` must
  return `true` to keep filtering in memory (upstream); `box.schema: true`
  derives a strict schema; `searchFormat: 'text'`; `childrenBetween`,
  tools and hint are blocks. Ember difference: the previous controlled
  `search.query` value is remembered (not only the `search` object), so a
  mutated or getter-backed config also resets the query.
- Private `@has*Block` args forward block presence through the wrappers
  (in-memory table → basic table / search bar).

## Checks (2026-10-12)

- `ember-tsc --noEmit`: pass.
- ESLint on all new/changed sources, registries and tests: pass.
- `node --test scripts/eui-upstream-parity.test.mjs`: 322/322 (9 new).
- `node scripts/generate-api-docs.mjs --check`: pass (106 pages, 3 new).
- Core `rollup --config`: pass (package.json app-js updated).
- Vite browser-test build: pass.
- Focused Chromium 130: search bar 9/9, basic table 8/8, in-memory 5/5.
- Full core Chromium 130 suite: 1174/1174.
- Site checks/builds not run (per brief).

## Coordinator notes

- Merge `styles.generated.ts`/`upstream-sources.json` by regenerating
  (generator entries in the `// new-tables` block).
- Docs add 3 pages (forms/search-bar, tabular/basic-table,
  tabular/in-memory-table): the site's navigation count test needs +3.
- Report for other families: `EuiFilterGroup` and `EuiTable` have no
  `@css` (search bar filters and the Safari workaround would use them);
  `EuiTablePagination` cannot take an `aria-label` for its navigation
  (upstream's basic table labels it "Pagination for table: …");
  `EuiTableHeaderCell` has no `tooltipProps`/`append`; EuiSelectable's
  `onChange` does not report the changed option (the selection filter
  diffs the options).
