# EuiDataGrid Ember EUI extensions

`EuiDataGrid` is a port of EUI 123.1.0. Ember EUI adds features upstream
doesn't have. To keep future re-ports of upstream cheap, each extension
lives in its own files. The ported upstream files only contain **marked
hooks**: single calls or getters that delegate into those files. Each
marked line carries a comment:

```
// ember-eui extension (<name>): <why>          (JS/TS)
{{! ember-eui extension (<name>): <why> }}      (templates)
```

`grep -rn "ember-eui extension" packages/core/src/components/eui-data-grid*`
lists them all.

## `row-tree`: nested rows (`@rowTree`) and row grouping (`@grouping`)

Docs: `packages/core/docs/tabular/data-grid/{grouping,tree-expansion,group-by,tree-features,tree-recipes}/`.
Handoff: [data-grid-grouping-handoff.md](data-grid-grouping-handoff.md).

### Extension files (own code, no upstream counterpart)

| File | Contents |
| --- | --- |
| `src/utils/data-grid/row-tree.ts` | Pure model: build nested/flat trees, group, sort siblings, flatten visible rows, ancestors. |
| `src/components/eui-data-grid/row-model.ts` | `EuiDataGridRowModel`: tracked expanded state (controlled/uncontrolled), sorting inputs, visible rows, index mapping, API methods. |
| `src/components/eui-data-grid/row-tree-hooks.ts` | What the hooks call: cell state, toggle cell keyboard, row ARIA attributes, page index clamping. |
| `src/components/eui-data-grid/tree-cell.gts` | Indentation, toggle button, group label/count, `renderGroupCell`. |
| `src/utils/data-grid/types.ts` (appended block) | `EuiDataGridRowTree*`, `EuiDataGridGrouping`, `EuiDataGridGroupCellProps`; `row?` on cell value props; API method types. |

### Touchpoints in ported upstream files

46 marked lines in 5 files. "Delegates to" names the extension code that
holds the logic.

**`eui-data-grid.gts`**

| Symbol | Hook | Delegates to |
| --- | --- | --- |
| imports | `EuiDataGridRowModel`, `clampRowTreePageIndex` | row-model.ts, row-tree-hooks.ts |
| `EuiDataGridCellPopoverElementProps` | `row?` field | — (type) |
| `Args` | `rowCount` optional; `rowTree`, `grouping` args | types.ts |
| `rowTreeModel` / `rowModel` | model instance; `rowModel` null without the args | `EuiDataGridRowModel.isActive` |
| `rowCount`, `dataRowCount` | visible rows / data rows, else `@rowCount` | `rowModel.visibleRows`, `rowModel.dataRowCount` |
| `showPagination`, `visibleRows`, `ariaPageCount`, `onContentKeyDown` | `this.rowCount` instead of `this.args.rowCount` | `rowCount` |
| `inMemoryRowCount`, `checkCellExists` | `this.dataRowCount` instead of `this.args.rowCount` | `dataRowCount` |
| `getCorrectRowIndex` | `if (this.rowModel) return this.rowModel.rowIndexAt(i)` (before the sorted row map) | `rowModel.rowIndexAt` |
| `findVisibleRowIndex` | tree branch | `rowModel.findVisibleRowIndex` (reveals collapsed ancestors) |
| `toggleRow` | close popover + toggle | `rowModel.toggle` |
| `hasRowModel`, `registerApi` modifier | API gets tree methods when active | `rowModel.api` |
| `clampRowTreePageIndex` field + template modifier | page index past the end | row-tree-hooks.ts |
| template `role`, `aria-rowcount` | `treegrid`, visible row count | `rowModel`, `rowCount` |

**`eui-data-grid/cell.gts`**

| Symbol | Hook | Delegates to |
| --- | --- | --- |
| imports | `EuiDataGridTreeCell`, hooks | tree-cell.gts, row-tree-hooks.ts |
| `rowTree` (`@cached`) | tree row, `isGroupRow`, `isToggleCell`, `rowData` | `rowTreeCellState` |
| `defaultIsExpandable`, `isExpandable` | group rows are not expandable | `rowTree.isGroupRow` |
| `onKeyDown` | first statement: Space/Enter/ArrowLeft/ArrowRight in the toggle cell | `handleRowTreeCellKeyDown` |
| `cellValueProps` | `row` | `rowTree.rowData` |
| template (×2 content branches) | `<EuiDataGridTreeCell>` before the renderer; `{{#if this.rowTree.isGroupRow}}{{else if this.renderer}}` | tree-cell.gts |
| template renderers (×6) | `@row` on the 4 `Renderer` and the `PopoverRenderer` invocations, `row` in the `<:cellPopover>` hash | `rowTree.rowData` |

**`eui-data-grid/row.gts`**: `rowTree` getter → `rowTreeRowAttributes`;
the group row class in `classes`; the template's `aria-level`,
`aria-expanded`, `aria-setsize` and `aria-posinset`.

**`eui-data-grid/pagination.gts`**: `pageCount` reads `grid.rowCount`
(the visible rows) instead of `grid.args.rowCount`.

**`eui-data-grid/in-memory-renderer.gts`**: `rowAt` → `grid.rowModel.rowAt`;
`@row` on the renderer.

Unmarked, but part of the extension: `package.json` app-js entries for
`row-model.js`, `row-tree-hooks.js` and `tree-cell.js`.

### Tests guarding the contract

| File | Covers |
| --- | --- |
| `tests/unit/utils/data-grid-row-tree-test.ts` | Pure model: shapes, cycles, grouping, sorting, flattening, `hasChildren`, timings (logged). |
| `tests/integration/components/eui-data-grid-grouping-test.gts` | No-arg regression, nested/flat/accessors, controlled/default expansion, grouping, `renderGroupCell`, sorting, pagination (+ clamping), API, lazy loading. |
| `tests/integration/components/eui-data-grid-grouping-keyboard-test.gts` | Space/Enter/arrow keys, parent focus across pages, groups, popover/focus-trap exclusions, no-arg arrows. |
| `tests/integration/components/eui-data-grid-grouping-virtualization-test.gts` | 5,550-row tree: windowing, end of list, toggling mid-scroll, `scrollToItem`, auto row heights. |

The other `eui-data-grid*-test.gts` files are the upstream port's own tests.
They must keep passing unchanged, since they prove the hooks are inert
without the arguments.

### Re-porting upstream (checklist)

1. Before re-porting, list the hooks:
   `grep -rn "ember-eui extension (row-tree)" packages/core/src/components/eui-data-grid*`.
2. Re-port the upstream file as usual (`eui-data-grid.gts`, `cell.gts`,
   `row.gts`, `pagination.gts`, `in-memory-renderer.gts`).
3. Re-apply each marked hook from the table above, with its marker
   comment. Keep each hook a single call or getter; put any new logic in
   `row-tree-hooks.ts` / `row-model.ts`, never in the ported file.
4. If upstream renamed something a hook depends on (`getCorrectRowIndex`,
   `findVisibleRowIndex`, `isExpandable`, `onKeyDown`, the `Renderer`
   invocations, `visibleRows`, `pagination`), adapt `row-tree-hooks.ts`
   and `row-model.ts` rather than the hooks.
5. Run `ember-tsc --noEmit`, then the contract tests
   (`--test_page 'tests/index.html?filter=grouping'` plus
   `?filter=row-tree`), then the full data grid tests
   (`?filter=EuiDataGrid`), then the full core suite.
6. Update the touchpoint tables here if hooks moved.
