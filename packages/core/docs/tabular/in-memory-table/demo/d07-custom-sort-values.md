---
order: 7
---

# Custom sort values

<EuiText>

Sometimes the value displayed in a column is not appropriate to use for
sorting, such as values pre-formatted to be human-readable. In these cases
pass the column's `sortable` as a function instead of `true` or `false`:
it extracts or calculates the sort value of each item.

</EuiText>

```gjs component
import { EuiInMemoryTable } from '@ember-eui/core/components';

const data = [
  { animal: 'snail', weight: 25 },
  { animal: 'peregrine falcon', weight: 900 },
  { animal: 'small dog', weight: 4500 },
  { animal: 'brown bear', weight: 180000 },
  { animal: 'elephant', weight: 5440000 },
  { animal: 'giraffe', weight: 1180000 },
];

const columns = [
  { field: 'animal', name: 'Animal', sortable: true },
  {
    name: 'Weight',
    render: ({ weight }) => `${weight / 1000}kg`,
    sortable: ({ weight }) => weight,
  },
  { field: 'weight', name: 'Weight (grams)', sortable: true },
];

const sorting = { sort: { field: 'weight', direction: 'asc' } };

<template>
  <EuiInMemoryTable
    @tableCaption="Demo of EuiInMemoryTable with custom sorting"
    @responsiveBreakpoint={{false}}
    @items={{data}}
    @columns={{columns}}
    @pagination={{false}}
    @sorting={{sorting}}
  />
</template>
```
