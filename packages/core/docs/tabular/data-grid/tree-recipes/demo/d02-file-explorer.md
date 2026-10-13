---
order: 2
---

# File explorer

<EuiText>

The "Name" renderer reads `cell.rowTree.isExpanded` to show an open folder
for expanded folders; the grid keeps the expanded state itself.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { get, hash } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import { EuiDataGrid, EuiIcon } from '@ember-eui/core/components';

const ICONS = { ts: 'tokenClass', md: 'document', json: 'tokenObject', png: 'image', svg: 'image' };

const totalSize = (row) =>
  row.children ? row.children.reduce((sum, child) => sum + totalSize(child), 0) : row.size;

export default class FileExplorerDemo extends Component {
  defaultExpandedRowIds = ['/', '/src'];

  columns = [
    { id: 'name', displayAsText: 'Name', initialWidth: 300 },
    { id: 'size', displayAsText: 'Size', schema: 'numeric' },
    { id: 'modified', displayAsText: 'Modified' }
  ];

  files = [
    {
      id: '/',
      name: 'ember-eui',
      modified: '2026-10-13',
      children: [
        {
          id: '/src',
          name: 'src',
          modified: '2026-10-13',
          children: [
            { id: '/src/grid.ts', name: 'grid.ts', size: 42_100, modified: '2026-10-13' },
            { id: '/src/tree.ts', name: 'tree.ts', size: 9_800, modified: '2026-10-12' }
          ]
        },
        {
          id: '/assets',
          name: 'assets',
          modified: '2026-09-30',
          children: [
            { id: '/assets/logo.svg', name: 'logo.svg', size: 2_300, modified: '2026-09-30' },
            { id: '/assets/hero.png', name: 'hero.png', size: 812_000, modified: '2026-09-02' }
          ]
        },
        { id: '/package.json', name: 'package.json', size: 1_900, modified: '2026-10-10' },
        { id: '/README.md', name: 'README.md', size: 6_400, modified: '2026-10-01' }
      ]
    }
  ];

  iconFor = (row, rowTree) => {
    if (rowTree?.hasChildren) return rowTree.isExpanded ? 'folderOpen' : 'folderClosed';
    return ICONS[row.name.split('.').pop()] ?? 'document';
  };

  formatSize = (row) => {
    const bytes = totalSize(row);
    if (bytes >= 1_000_000) return `${(bytes / 1_000_000).toFixed(1)} MB`;
    if (bytes >= 1_000) return `${(bytes / 1_000).toFixed(1)} KB`;
    return `${bytes} B`;
  };

  <template>
    <EuiDataGrid
      aria-label="File explorer"
      @columns={{this.columns}}
      @rowTree={{hash rows=this.files defaultExpandedRowIds=this.defaultExpandedRowIds}}
      @gridStyle={{hash border="horizontal" header="underline" rowHover="highlight"}}
      @height={{360}}
    >
      <:cell as |cell|>
        {{#if (eq cell.columnId "name")}}
          <EuiIcon
            @type={{this.iconFor cell.row cell.rowTree}}
            @color={{if cell.rowTree.hasChildren "warning" "subdued"}}
          />
          {{cell.row.name}}
        {{else if (eq cell.columnId "size")}}
          {{this.formatSize cell.row}}
        {{else}}
          {{get cell.row cell.columnId}}
        {{/if}}
      </:cell>
    </EuiDataGrid>
  </template>
}
```
