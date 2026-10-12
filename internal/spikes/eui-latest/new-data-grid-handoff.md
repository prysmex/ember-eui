# New component: EuiDataGrid (new-data-grid)

Branch `eui-wave/new-data-grid`, from `feat/eui-latest` (40bb9591). Target EUI
123.1.0 / Borealis 8.1.0. Status: **in progress** (plan below; updated per
milestone).

## Upstream structure (components/datagrid)

- `data_grid.tsx`: grid root, gridStyle → classes/styles, toolbar, in-memory
  renderer, content `div[role=grid]`, pagination, focus/popover/sorting
  contexts.
- `body/`: `data_grid_body_virtualized` (react-window `VariableSizeGrid`, a
  row manager creating `div[role=row]` per row, sticky header/footer rows),
  `data_grid_body_custom` (renderCustomGridBody), `cell/` (cell, cell actions,
  expansion popover, interactive-children focus trap), `header/` (header row,
  header cell + column actions popover, sorting arrow/aria-sort, resizer,
  draggable columns, control header cell), `footer/`.
- `controls/`: toolbar, column selector (hide/reorder), sorting popover,
  display selector (density/row height), keyboard shortcuts, fullscreen.
- `utils/`: focus (keyboard navigation, tab management), scrolling
  (scroll-into-view, border overlays), row heights, column widths, grid
  height/width, sorting (in-memory sorted row map), in-memory values, schema
  detection.
- 17 `*.styles.js` factories; `fullscreen_selector.styles` uses vanilla
  `@emotion/css` and the toolbar control's styles live inline in a hook
  component, so those are hand-ported in `utils/eui/data-grid.ts`.

## Ember architecture

- `EuiDataGrid` (`eui-data-grid.gts`) owns the grid state (focus registry,
  popover cell, display-selector overrides, column order, in-memory values,
  fullscreen) and passes itself to private sub-components in
  `components/eui-data-grid/`.
- Virtualization is Ember-native (no react-window): a scroll container with an
  inner element sized to the full content, a sticky header row and absolutely
  positioned `div[role=row]` rows. Row/column offsets are prefix sums (or
  arithmetic for uniform rows); the rendered row/column window is tracked as
  integers and only changes when the visible index range changes, so scrolling
  within a range causes no tracked churn. Rows and cells are keyed by index
  (`{{#each key="@identity"}}`), so cells that stay in range keep their DOM.
- Focus mirrors upstream: one tabbable cell; cells register a callback in a
  focus registry and own a tracked `isFocused`, so moving focus touches only
  the previous and next cell.
- Cell content: `@renderCellValue` (component) or the `<:cell as |cell|>`
  named block (hbs-friendly), both receiving upstream's cell props.

## Milestones

1. Core grid: columns/rowCount/renderCellValue (+ `<:cell>` block), header row,
   body cells, all upstream styles, gridStyle, rowHeightsOptions
   (default/static/lineCount; auto measured), ARIA grid semantics.
2. Keyboard navigation and focus management, cell actions, expansion popover.
3. Virtualization (rows + columns), `@height`/`@width`, sticky header.
4. Toolbar: column selector, sorting, display selector, fullscreen, keyboard
   shortcuts.
5. Pagination, column resizing, control columns, footer, in-memory sorting.

## Progress

(filled in per milestone)
