---
order: 3
---

# Setting a default height and line height for rows

<EuiText>

You can change the default height for all rows via the `defaultHeight`
property. Note that the `showDisplaySelector.allowRowHeight` setting in
`@toolbarVisibility` means the user has the ability to override this default
height. Users will be able to toggle between single rows, a configurable
line count, or `"auto"`.

You can also customize the line height of all cells with the `lineHeight`
property. However, if you wrap your cell content with CSS that
overrides/sets line-height (e.g. in an `EuiText`), your row heights will not
be calculated correctly - make sure to match the passed `lineHeight`
property to the actual cell content line height.

</EuiText>

```hbs template
<EuiDataGrid
  aria-label="Row height options with default height"
  @columns={{this.columns}}
  @columnVisibility={{hash visibleColumns=this.visibleColumns setVisibleColumns=this.setVisibleColumns}}
  @rowCount={{this.rawData.length}}
  @rowHeightsOptions={{this.rowHeightsOptions}}
>
  <:cell as |cell|>{{get (get this.rawData cell.rowIndex) cell.columnId}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

const LOREM = [
  'Vitae cumque aperiam tempora officia.',
  'Tenetur quae nemo esse nostrum similique sed repellendus.',
  'Dolorum quas magnam sint aliquam a accusantium repudiandae.',
  'Ipsa ut consequatur ad quo cupiditate pariatur.',
  'Facilis quia et nihil voluptas iusto.'
];

const products = [
  ['Ergonomic Granite Chair', 'The beautiful range of Apple Naturalé that has an exciting mix of natural ingredients', 2],
  ['Handcrafted Steel Keyboard', 'Andy shoes are designed to keeping in mind durability as well as trends', 0],
  ['Sleek Cotton Hat', 'The Football Is Good For Training And Recreational Purposes', 5],
  ['Rustic Bronze Lamp', 'New range of formal shirts are designed keeping you in mind', 1],
  ['Licensed Wooden Table', 'The slim & simple Maple Gaming Keyboard from Dev Byte comes with a sleek body', 3]
];

export default class DefaultRowHeightDemo extends Component {
  rawData = products.map(([productName, description, lines], index) => ({
    index,
    productName,
    productDescription: `${description}. ${LOREM.slice(0, lines).join('\n')}`
  }));

  columns = [
    { id: 'index', displayAsText: 'Index', isExpandable: false, initialWidth: 52 },
    { id: 'productName', displayAsText: 'Product name', isExpandable: false },
    { id: 'productDescription', displayAsText: 'Description' }
  ];

  rowHeightsOptions = {
    defaultHeight: {
      lineCount: 3 // default every row to 3 lines of text
    },
    lineHeight: '1.25em' // change the default line height
  };

  @tracked visibleColumns = this.columns.map(({ id }) => id);

  @action setVisibleColumns(visibleColumns) {
    this.visibleColumns = visibleColumns;
  }
}
```
