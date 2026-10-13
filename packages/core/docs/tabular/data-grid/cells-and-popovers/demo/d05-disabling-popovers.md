---
order: 5
---

# Disabling cell expansion popovers

<EuiText>

Popovers can sometimes be unnecessary for short form content, and can be
disabled by setting `columns.isExpandable` to `false`. In the example
below, we've turned off expansion on the suffix column.

To set `isExpandable` at a per-cell level instead of per-column, you can
use the `setCellProps` function passed to the `<:cell>` block (or
`@setCellProps` passed to `@renderCellValue`). The below example
conditionally disables the expansion popover for boolean cells that are
'false'. `setCellProps` may be called while rendering: the update is
applied after render.

</EuiText>

<EuiCallOut @title="Cells with actions are always expandable" @color="warning" @iconType="warning">
  If <code>columns.cellActions</code> is defined, <code>isExpandable</code>
  will always be forced to true. This ensures that keyboard and screen
  reader users have access to all cell actions.
</EuiCallOut>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { get, hash } from '@ember/helper';
import { and, eq } from 'ember-truth-helpers';
import { EuiDataGrid } from '@ember-eui/core/components';

const FilterIn = <template>
  <@Component @iconType="plusCircle" aria-label="Filter in">Filter in</@Component>
</template>;
const FilterOut = <template>
  <@Component @iconType="minusCircle" aria-label="Filter out">Filter out</@Component>
</template>;

const cellActions = [FilterIn, FilterOut];

const columns = [
  { id: 'firstName', cellActions },
  {
    id: 'lastName',
    isExpandable: false, // Overridden by the fact that cellActions is set
    cellActions
  },
  { id: 'suffix', isExpandable: false },
  {
    id: 'boolean',
    isExpandable: true // Overridden by setCellProps for specific cells
  }
];

const data = [
  ['Ada', 'Hartmann', 'Jr.', 'false'],
  ['Bruno', 'Okafor', 'III', 'true'],
  ['Carmen', 'Lindqvist', 'Sr.', 'true'],
  ['Dmitri', 'Moreau', 'IV', 'false']
].map(([firstName, lastName, suffix, boolean]) => ({ firstName, lastName, suffix, boolean }));

export default class DisablingPopoversDemo extends Component {
  @tracked visibleColumns = columns.map(({ id }) => id);

  setVisibleColumns = (visibleColumns) => (this.visibleColumns = visibleColumns);

  <template>
    <EuiDataGrid
      aria-label="Data grid example of isExpandable false"
      @columns={{columns}}
      @columnVisibility={{hash
        visibleColumns=this.visibleColumns
        setVisibleColumns=this.setVisibleColumns
      }}
      @rowCount={{data.length}}
    >
      <:cell as |cell|>
        {{#let (get (get data cell.rowIndex) cell.columnId) as |value|}}
          {{#if (and (eq cell.columnId "boolean") (eq value "false"))}}
            {{cell.setCellProps (hash isExpandable=false)}}
          {{/if}}
          {{value}}
        {{/let}}
      </:cell>
    </EuiDataGrid>
  </template>
}
```
