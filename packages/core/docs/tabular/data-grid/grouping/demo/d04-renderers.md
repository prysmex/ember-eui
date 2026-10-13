---
order: 4
---

# Renderers, `@row` and in-memory sorting

<EuiText>

`@renderCellValue` receives `@row` next to `@rowIndex`, and so do the
off-screen renderer behind `@inMemory` and the cell value shown in the
expansion popover. Here the component formats the size and the in-memory
renderer reads the formatted values to sort them: sort a column from its
header actions and the children are sorted within their parent.

The cell component is a template-only `<template>` component declared
next to the demo class.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { hash } from '@ember/helper';
import { EuiDataGrid } from '@ember-eui/core/components';

const formatValue = (row, columnId) =>
  columnId === 'size' ? `${row[columnId]} KB` : row[columnId];

const CellValue = <template>{{formatValue @row @columnId}}</template>;

export default class RenderersDemo extends Component {
  CellValue = CellValue;
  @tracked sortingColumns = [];

  columns = [
    { id: 'name', displayAsText: 'Name', initialWidth: 240 },
    { id: 'size', displayAsText: 'Size', schema: 'numeric' }
  ];

  files = [
    {
      id: 'b',
      name: 'beta',
      size: 30,
      children: [
        { id: 'b2', name: 'zeta.txt', size: 5 },
        { id: 'b1', name: 'alpha.txt', size: 25 }
      ]
    },
    {
      id: 'a',
      name: 'alpha',
      size: 120,
      children: [
        { id: 'a1', name: 'yankee.txt', size: 100 },
        { id: 'a2', name: 'kilo.txt', size: 20 }
      ]
    }
  ];

  @action onSort(columns) {
    this.sortingColumns = columns;
  }

  <template>
    <EuiDataGrid
      aria-label="Renderers"
      @columns={{this.columns}}
      @rowTree={{hash rows=this.files defaultExpandedRowIds="all"}}
      @renderCellValue={{this.CellValue}}
      @inMemory={{hash level="sorting"}}
      @sorting={{hash columns=this.sortingColumns onSort=this.onSort}}
      @height={{300}}
    />
  </template>
}
```
