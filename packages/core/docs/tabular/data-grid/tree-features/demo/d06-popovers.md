---
order: 6
---

# Cell popovers and cell actions

<EuiText>

Tree rows keep the grid's cell features. The "Owner" column has cell
actions, and Enter (or the expand action) opens a popover. The custom
popover reads `row` to show the whole record. (Group rows have no
popover.)

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { get, hash } from '@ember/helper';
import { EuiDataGrid, EuiSpacer, EuiText } from '@ember-eui/core/components';

export default class PopoversDemo extends Component {
  @tracked lastAction = null;

  record = (name) => ({ rowIndex }) => {
    this.lastAction = `${name} (data row ${rowIndex})`;
  };

  columns = [
    { id: 'title', displayAsText: 'Task', initialWidth: 240 },
    {
      id: 'owner',
      displayAsText: 'Owner',
      cellActions: [
        { iconType: 'plusInCircle', label: 'Filter for owner', onClick: this.record('Filter for') },
        { iconType: 'minusInCircle', label: 'Filter out owner', onClick: this.record('Filter out') }
      ]
    },
    { id: 'estimate', displayAsText: 'Estimate (h)', schema: 'numeric' }
  ];

  tasks = [
    {
      id: 'release',
      title: 'Release 2.0',
      owner: 'Ada',
      estimate: 40,
      children: [
        { id: 'notes', title: 'Release notes', owner: 'Grace', estimate: 6 },
        { id: 'qa', title: 'QA pass', owner: 'Linus', estimate: 16 }
      ]
    },
    { id: 'blog', title: 'Blog post', owner: 'Grace', estimate: 4 }
  ];

  <template>
    <EuiText @size="s"><p>Last action: {{if this.lastAction this.lastAction "none"}}</p></EuiText>
    <EuiSpacer @size="s" />
    <EuiDataGrid
      aria-label="Popovers"
      @columns={{this.columns}}
      @rowTree={{hash rows=this.tasks defaultExpandedRowIds="all"}}
      @height={{260}}
    >
      <:cell as |cell|>{{get cell.row cell.columnId}}</:cell>
      <:cellPopover as |popover|>
        <EuiText @size="s">
          <p><strong>{{popover.row.title}}</strong></p>
          <p>Owner: {{popover.row.owner}} · Estimate: {{popover.row.estimate}}h</p>
        </EuiText>
        <popover.cellActions />
      </:cellPopover>
    </EuiDataGrid>
  </template>
}
```
