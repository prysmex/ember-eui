---
order: 5
---

# Auto heights for rows

<EuiText>

To enable automatically fitting rows to their content you can set
`defaultHeight: 'auto'`. This ensures every row automatically adjusts its
height to fit the contents.

You can also override the height of a specific row by passing a
`rowHeights` object associating the row's index with an `"auto"` value.

The grid also passes `virtualizationOptions.estimatedRowHeight`, a rough
average of the rows' heights: rows that haven't rendered yet count with it
in the scrollable height. Accurately setting it smooths out scrolling.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { array, get, hash } from '@ember/helper';
import { and, eq } from 'ember-truth-helpers';
import { EuiDataGrid, EuiTitle } from '@ember-eui/core/components';

const ADJECTIVES = ['Ergonomic', 'Handcrafted', 'Sleek', 'Rustic', 'Licensed', 'Practical', 'Tasty', 'Gorgeous'];
const MATERIALS = ['Granite', 'Steel', 'Cotton', 'Bronze', 'Wooden', 'Plastic', 'Rubber'];
const NOUNS = ['Chair', 'Keyboard', 'Hat', 'Lamp', 'Table', 'Shoes', 'Gloves', 'Bike', 'Towels'];
const DESCRIPTIONS = [
  'The beautiful range of Apple Naturalé that has an exciting mix of natural ingredients',
  'Andy shoes are designed to keeping in mind durability as well as trends',
  'The Football Is Good For Training And Recreational Purposes',
  'New range of formal shirts are designed keeping you in mind'
];
const LOREM = [
  'Vitae cumque aperiam tempora officia.',
  'Tenetur quae nemo esse nostrum similique sed repellendus.',
  'Dolorum quas magnam sint aliquam a accusantium repudiandae.',
  'Ipsa ut consequatur ad quo cupiditate pariatur.',
  'Facilis quia et nihil voluptas iusto.'
];

export default class AutoRowHeightsDemo extends Component {
  rawData = Array.from({ length: 100 }, (_, i) => ({
    index: i,
    productName: `${ADJECTIVES[i % 8]} ${MATERIALS[(i * 3) % 7]} ${NOUNS[(i * 5) % 9]}`,
    productDescription: `${DESCRIPTIONS[i % 4]}. ${LOREM.slice(0, (i * 7) % 6).join('\n')}`
  }));

  columns = [
    { id: 'index', displayAsText: 'Index', isExpandable: false, initialWidth: 52 },
    { id: 'productName', displayAsText: 'Product name', isExpandable: false },
    { id: 'productDescription', displayAsText: 'Description' }
  ];

  rowHeightsOptions = { defaultHeight: 'auto' };

  virtualizationOptions = {
    // rough average of the cell heights in the example
    // accurately setting this smooths out the scrolling experience
    estimatedRowHeight: 210
  };

  // pagination
  @tracked pageIndex = 0;
  @tracked pageSize = 50;

  @action onChangeItemsPerPage(pageSize) {
    this.pageSize = pageSize;
    this.pageIndex = 0;
  }

  @action onChangePage(pageIndex) {
    this.pageIndex = pageIndex;
  }

  // sorting
  @tracked sortingColumns = [];

  @action onSort(sortingColumns) {
    this.sortingColumns = sortingColumns;
  }

  // column visibility
  @tracked visibleColumns = this.columns.map(({ id }) => id);

  @action setVisibleColumns(visibleColumns) {
    this.visibleColumns = visibleColumns;
  }

  <template>
    <EuiDataGrid
      aria-label="Row height options with auto demo"
      @columns={{this.columns}}
      @columnVisibility={{hash visibleColumns=this.visibleColumns setVisibleColumns=this.setVisibleColumns}}
      @rowCount={{this.rawData.length}}
      @inMemory={{hash level="sorting"}}
      @sorting={{hash columns=this.sortingColumns onSort=this.onSort}}
      @pagination={{hash
        pageIndex=this.pageIndex
        pageSize=this.pageSize
        pageSizeOptions=(array 50 250 1000)
        onChangeItemsPerPage=this.onChangeItemsPerPage
        onChangePage=this.onChangePage
      }}
      @height={{400}}
      @rowHeightsOptions={{this.rowHeightsOptions}}
      @virtualizationOptions={{this.virtualizationOptions}}
    >
      <:cell as |cell|>
        {{#if (eq cell.columnId "productName")}}
          <EuiTitle @size="xs">
            <h3>{{get (get this.rawData cell.rowIndex) cell.columnId}}</h3>
          </EuiTitle>
        {{else if (and (eq cell.columnId "productDescription") (eq cell.rowIndex 2))}}
          <img src="https://picsum.photos/id/9/300/200" alt="Mock product image" class="eui-displayBlock" />
        {{else}}
          {{get (get this.rawData cell.rowIndex) cell.columnId}}
        {{/if}}
      </:cell>
    </EuiDataGrid>
  </template>
}
```
