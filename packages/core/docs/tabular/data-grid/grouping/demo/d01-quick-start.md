---
order: 1
---

# Quick start: nested `children`

<EuiText>

The rows nest through their `children` arrays and `@rowTree={{this.files}}`
is the only tree configuration. Cells read `cell.row`. Click a toggle, or
focus a "Name" cell and press Space.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { get } from '@ember/helper';
import { EuiDataGrid } from '@ember-eui/core/components';

export default class QuickStartDemo extends Component {
  columns = [
    { id: 'name', displayAsText: 'Name', initialWidth: 260 },
    { id: 'kind', displayAsText: 'Kind' },
    { id: 'size', displayAsText: 'Size (KB)', schema: 'numeric' }
  ];

  files = [
    {
      id: 'src',
      name: 'src',
      kind: 'folder',
      size: 96,
      children: [
        {
          id: 'src/components',
          name: 'components',
          kind: 'folder',
          size: 64,
          children: [
            { id: 'src/components/grid.gts', name: 'grid.gts', kind: 'file', size: 40 },
            { id: 'src/components/button.gts', name: 'button.gts', kind: 'file', size: 24 }
          ]
        },
        { id: 'src/index.ts', name: 'index.ts', kind: 'file', size: 32 }
      ]
    },
    {
      id: 'docs',
      name: 'docs',
      kind: 'folder',
      size: 12,
      children: [{ id: 'docs/guide.md', name: 'guide.md', kind: 'file', size: 12 }]
    },
    { id: 'package.json', name: 'package.json', kind: 'file', size: 4 },
    { id: 'README.md', name: 'README.md', kind: 'file', size: 8 }
  ];

  <template>
    <EuiDataGrid
      aria-label="Quick start"
      @columns={{this.columns}}
      @rowTree={{this.files}}
      @height={{320}}
    >
      <:cell as |cell|>{{get cell.row cell.columnId}}</:cell>
    </EuiDataGrid>
  </template>
}
```
