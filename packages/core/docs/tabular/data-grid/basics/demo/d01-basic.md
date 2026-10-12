---
order: 1
---

# A basic grid

<EuiText>

Columns accept a `displayAsText` header, an `initialWidth` and a `schema`
(`numeric` and `currency` cells are right aligned). Without
`@columnVisibility`, the grid keeps its own column order and visibility.

</EuiText>

```hbs template
<EuiDataGrid
  aria-label="Basic data grid demo"
  @columns={{this.columns}}
  @rowCount={{this.people.length}}
>
  <:cell as |cell|>
    {{get (get this.people cell.rowIndex) cell.columnId}}
  </:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';

const FIRST = ['Ada', 'Alan', 'Grace', 'Linus', 'Margaret', 'Dennis', 'Barbara', 'Ken'];
const CITIES = ['Lisbon', 'Oslo', 'Austin', 'Kyoto', 'Lagos', 'Lima'];

export default class BasicDataGrid extends Component {
  columns = [
    { id: 'name', displayAsText: 'Name', initialWidth: 160 },
    { id: 'email', displayAsText: 'Email' },
    { id: 'city', displayAsText: 'City' },
    { id: 'age', displayAsText: 'Age', schema: 'numeric', initialWidth: 90 }
  ];

  people = Array.from({ length: 12 }, (_, i) => ({
    name: `${FIRST[i % FIRST.length]} ${String.fromCharCode(65 + i)}.`,
    email: `${FIRST[i % FIRST.length].toLowerCase()}${i}@example.com`,
    city: CITIES[i % CITIES.length],
    age: String(21 + ((i * 7) % 50))
  }));
}
```
