---
order: 1
---

# Grid style

<EuiText>

`@gridStyle` sets borders (`all`, `horizontal`, `none`), the header and
footer styles, stripes, row hover, font size and cell padding. The toolbar's
display options change density at runtime and call `gridStyle.onChange`.
`rowClasses` adds classes to rows by data index.

</EuiText>

```hbs template
<EuiFlexGroup @gutterSize="m" @wrap={{true}} @alignItems="center">
  <EuiFlexItem @grow={{false}}>
    <EuiButtonGroup
      @legend="Borders"
      @buttonSize="compressed"
      @options={{this.borderOptions}}
      @idSelected={{this.border}}
      @onChange={{this.setBorder}}
    />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiSwitch @label="Stripes" @checked={{this.stripes}} @onChange={{this.toggleStripes}} />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiSwitch @label="Underline header" @checked={{this.underline}} @onChange={{this.toggleUnderline}} />
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer @size="m" />
<EuiDataGrid
  aria-label="Grid style demo"
  @columns={{this.columns}}
  @rowCount={{this.rows.length}}
  @gridStyle={{this.gridStyle}}
  @toolbarVisibility={{false}}
>
  <:cell as |cell|>{{get (get this.rows cell.rowIndex) cell.columnId}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class GridStyleDemo extends Component {
  @tracked border = 'all';
  @tracked stripes = true;
  @tracked underline = false;

  borderOptions = [
    { id: 'all', label: 'All' },
    { id: 'horizontal', label: 'Horizontal' },
    { id: 'none', label: 'None' }
  ];

  columns = [
    { id: 'service', displayAsText: 'Service' },
    { id: 'region', displayAsText: 'Region' },
    { id: 'latency', displayAsText: 'Latency (ms)', schema: 'numeric' }
  ];

  rows = ['checkout', 'search', 'accounts', 'payments', 'inventory'].map((service, i) => ({
    service,
    region: ['eu-west', 'us-east', 'ap-south'][i % 3],
    latency: String(40 + i * 17)
  }));

  get gridStyle() {
    return {
      border: this.border,
      stripes: this.stripes,
      header: this.underline ? 'underline' : 'shade',
      rowClasses: { 2: 'demo-highlighted-row' }
    };
  }

  @action setBorder(id) {
    this.border = id;
  }

  @action toggleStripes() {
    this.stripes = !this.stripes;
  }

  @action toggleUnderline() {
    this.underline = !this.underline;
  }
}
```
