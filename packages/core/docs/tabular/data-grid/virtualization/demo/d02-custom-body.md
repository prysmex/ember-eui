---
order: 2
---

# Custom grid body

<EuiText>

The `<:customGridBody>` block lays out each row as a flex row followed by
a full-width description line, without virtualization. Cells still come
from the grid: keyboard navigation, focus and the expansion popover work
as usual. The body's wrapper gets a max height with
`setCustomGridBodyProps`.

</EuiText>

```hbs template
<EuiDataGrid
  aria-label="Custom body demo"
  @columns={{this.columns}}
  @rowCount={{this.rows.length}}
  @toolbarVisibility={{hash showDisplaySelector=false}}
>
  <:customGridBody as |body|>
    {{body.setCustomGridBodyProps this.bodyProps}}
    <body.headerRow />
    {{#each this.rows as |row rowIndex|}}
      <div role="row" class="euiDataGridRow" style="width: fit-content">
        <div style="display: flex">
          {{#each body.visibleColumns as |_column colIndex|}}
            <body.Cell @colIndex={{colIndex}} @visibleRowIndex={{rowIndex}} as |cell|>
              {{get row cell.columnId}}
            </body.Cell>
          {{/each}}
        </div>
        {{! decorative: a row may only contain cells for assistive technology }}
        <EuiText @size="xs" @color="subdued" aria-hidden="true" style="padding: 4px 8px 8px">
          <p>{{row.description}}</p>
        </EuiText>
      </div>
    {{/each}}
  </:customGridBody>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';

export default class CustomBodyDemo extends Component {
  columns = [
    { id: 'name', displayAsText: 'Package' },
    { id: 'version', displayAsText: 'Version' },
    { id: 'downloads', displayAsText: 'Weekly downloads', schema: 'numeric' }
  ];

  bodyProps = { style: { maxHeight: 320 } };

  rows = [
    ['ember-source', '7.3.0', '512000', 'A JavaScript framework for ambitious web applications.'],
    ['@glimmer/component', '2.1.1', '498000', 'The base class of Glimmer components.'],
    ['ember-modifier', '4.2.0', '402000', 'Element modifiers for Ember.'],
    ['ember-focus-trap', '1.1.1', '120000', 'A focus trap modifier.'],
    ['@elastic/eui', '123.1.0', '310000', 'The Elastic UI framework.'],
    ['tabbable', '6.2.0', '9100000', 'Finds tabbable elements.']
  ].map(([name, version, downloads, description]) => ({ name, version, downloads, description }));
}
```
