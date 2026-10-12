---
order: 2
---

# Plain text search

<EuiText>

With `@searchFormat="text"` the search matches the text as typed, so
reserved characters such as `(`, `:` or `"` need no escaping.

</EuiText>

```hbs template
<EuiInMemoryTable
  @items={{this.items}}
  @columns={{this.columns}}
  @search={{this.search}}
  @searchFormat="text"
  @sorting={{true}}
/>
```

```js component
import Component from '@glimmer/component';

export default class InMemoryTextSearch extends Component {
  items = [
    { id: 1, expression: 'sum(price)', note: 'Total price' },
    { id: 2, expression: 'avg(score):weighted', note: 'Weighted "average"' },
    { id: 3, expression: 'count(*)', note: 'Row count' },
  ];

  columns = [
    { field: 'expression', name: 'Expression', sortable: true },
    { field: 'note', name: 'Note' },
  ];

  search = { box: { incremental: true, placeholder: 'Search, e.g. (price)' } };
}
```
