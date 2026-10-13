---
title: Data grid row grouping
order: 12
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid row grouping"/>
<EuiSpacer @size="l" />

<EuiCallOut @title="Ember EUI extension" @iconType="info">
  Part of the nested rows and grouping guide. See the
  <a href="/docs/core/docs/tabular/data-grid/grouping">overview</a>.
</EuiCallOut>

<EuiSpacer />

<EuiText>

## Grouping by columns

`@grouping={{hash groupBy=(array "country")}}` groups the rows by the
"country" column's values: the grid renders one group row per country,
with a toggle, the value and the number of rows, and the rows below it when
expanded. Add more columns for nested groups, outermost first:
`groupBy=(array "country" "city")`. An empty `groupBy` turns grouping off,
and the grid is back to a plain grid.

## Where values come from

The grid needs each row's **raw value** for every grouped column:

- With `rows` in the grouping options (flat rows) or with `@rowTree`, it
  reads `row[columnId]`. Renderers also get `@row`, and `@rowCount` isn't
  needed.
- Otherwise pass `getValue(rowIndex, columnId, row)`, along with
  `@rowCount` as usual. Use it for computed values too (a date's year, a
  price bucket).

Rows with the same value (`===`, dates by time, `null` and `undefined`
together) form a group. Groups are ordered by value: numbers and dates
numerically, text naturally (`item 2` before `item 10`, case-insensitive),
empty values last. When `@sorting` sorts a grouped column, its groups
follow that direction (see [sorting](/docs/core/docs/tabular/data-grid/tree-features)).

## Group ids

Each group has an id built from its value path, outermost first:

```
group:["France"]
group:["France","Paris"]
group:[2024]          (numbers stay numbers)
group:[null]          (empty values)
```

The format is `"group:" + JSON.stringify(values)` (dates become ISO
strings). Use these ids in `expandedGroupIds`,
`defaultExpandedGroupIds`, `expandRow(id)` / `collapseRow(id)`, and to
read `onExpandedChange`. Groups have their own expanded state, separate
from `@rowTree`'s row ids, with the same uncontrolled/controlled options
(see [tree expansion](/docs/core/docs/tabular/data-grid/tree-expansion)).

```js
const groupId = (...values) => `group:${JSON.stringify(values)}`;
this.expandedGroupIds = [groupId('France'), groupId('France', 'Paris')];
```

## Group cells and aggregates

By default a group row shows its value and row count in the toggle column,
and the other cells are empty. `renderGroupCell` replaces that: the
component renders in **every data cell** of group rows with:

| Argument | Description |
| --- | --- |
| `@group` | `{ columnId, value, count, rowIndices }`: the grouped column, its value, the number of rows and their data row indexes. |
| `@groupId` | The group id. |
| `@columnId`, `@colIndex` | The cell's column. |
| `@isToggleCell` | Whether this is the toggle column (render the label here: the toggle is already in front). |
| `@isExpanded`, `@depth` | Group state, `0` for outermost groups. |

`rowIndices` makes aggregates a one-liner over your own data: sum, average,
min/max, distinct counts. The aggregates demo shows sums, averages and
counts per column. In a `.gjs`/`.gts` file:

```gts
const sum = (indices, rows, key) => indices.reduce((total, i) => total + rows[i][key], 0);

const GroupCell = <template>
  {{#if @isToggleCell}}
    <strong>{{@group.value}}</strong> ({{@group.count}})
  {{else if (eq @columnId "amount")}}
    {{sum @group.rowIndices rows "amount"}}
  {{/if}}
</template>;
```

## Grouping trees

`@grouping` and `@rowTree` combine: the **root rows** are grouped and keep
their children under them. Group rows come first in the hierarchy, then the
rows' own levels.

</EuiText>

<EuiHorizontalRule />
