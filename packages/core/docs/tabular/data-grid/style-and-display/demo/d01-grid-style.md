---
order: 1
---

# Grid style

<EuiText>

Styling can be passed down to the grid through the `@gridStyle` argument. It
accepts an object that allows for customization. Use the toggles to change
it; the snippet below the grid shows the object passed.

<EuiCallOut @title="Tip" @size="s">
  <p>
    To reduce grid re-renders, define your grid styles as a constant (or a
    cached getter) instead of building a new object on every render.
  </p>
</EuiCallOut>

<EuiSpacer @size="m" />

<EuiCallOut @title="Density selector and grid styles" @size="s">
  <p>
    The <code>showDisplaySelector.allowDensity</code> setting in
    <code>@toolbarVisibility</code> means the user has the ability to
    override the padding and font size passed into <code>@gridStyle</code>
    by the engineer.
  </p>
  <p>
    The font size overriding only works with text or elements that can
    inherit the parent font size or elements that use units relative to the
    parent container.
  </p>
</EuiCallOut>

</EuiText>

```hbs template
<EuiSplitPanelOuter @hasBorder={{true}}>
  <EuiSplitPanelInner @grow={{false}}>
    <EuiFlexGroup @wrap={{true}} @gutterSize="m">
      <EuiFlexItem @grow={{false}} style="flex: 0 0 350px; max-width: 100%;">
        {{#each this.configuration as |config|}}
          <EuiFormRow @label={{config.label}} @display="columnCompressed">
            <EuiButtonGroup
              @isFullWidth={{true}}
              @buttonSize="compressed"
              @legend={{config.label}}
              @options={{config.options}}
              @idSelected={{config.idSelected}}
              @onChange={{fn this.select config.key}}
            />
          </EuiFormRow>
        {{/each}}
      </EuiFlexItem>
      <EuiFlexItem style="min-width: 0;">
        <EuiDataGrid
          aria-label="Data grid with custom gridStyle set"
          @columns={{this.columns}}
          @columnVisibility={{hash visibleColumns=this.visibleColumns setVisibleColumns=this.setVisibleColumns}}
          @sorting={{hash columns=this.sortingColumns onSort=this.onSort}}
          @pagination={{hash
            pageIndex=this.pageIndex
            pageSize=this.pageSize
            onChangeItemsPerPage=this.setPageSize
            onChangePage=this.setPageIndex
          }}
          @rowCount={{this.data.length}}
          @height="auto"
          @gridStyle={{this.gridStyle}}
        >
          <:cell as |cell|>
            {{#if (eq cell.columnId "avatar")}}
              <EuiAvatar @size="s" @name={{get (get this.data cell.rowIndex) "avatar"}} />
            {{else}}
              {{get (get this.data cell.rowIndex) cell.columnId}}
            {{/if}}
          </:cell>
          <:footerCell as |cell|>{{get this.footerCellValues cell.columnId}}</:footerCell>
        </EuiDataGrid>
      </EuiFlexItem>
    </EuiFlexGroup>
  </EuiSplitPanelInner>
  <EuiSplitPanelInner @color="subdued" @paddingSize="none" @grow={{false}}>
    <EuiCodeBlock @language="js" @fontSize="m" @paddingSize="m" @isCopyable={{true}}>{{this.snippet}}</EuiCodeBlock>
  </EuiSplitPanelInner>
</EuiSplitPanelOuter>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

const data = [
  ['Kertzmann, Lorenzo', 'Kertzmann, Lorenzo Jr.', '43172691'],
  ['Hessel, Adela', 'Hessel, Adela DVM', '08812395'],
  ['Bauch, Celestino', 'Bauch, Celestino III', '91254066'],
  ['Wiza, Marlene', 'Wiza, Marlene PhD', '37020518'],
  ['Okuneva, Dario', 'Okuneva, Dario Sr.', '64409837']
].map(([avatar, name, account]) => ({ avatar, name, account }));

const options = (...ids) => ids.map(([id, label]) => ({ id, label }));

export default class GridStyleDemo extends Component {
  data = data;

  columns = [
    { id: 'avatar', initialWidth: 40 },
    { id: 'name' },
    { id: 'account', schema: 'numeric' }
  ];

  footerCellValues = { account: '5 accounts' };

  @tracked border = 'none';
  @tracked fontSize = 'm';
  @tracked cellPadding = 'm';
  @tracked stripes = 'true';
  @tracked rowHover = 'highlight';
  @tracked header = 'underline';
  @tracked footer = 'overline';

  get configuration() {
    return [
      {
        key: 'border',
        label: 'Border',
        options: options(['all', 'All'], ['horizontal', 'Horizontal only'], ['none', 'None']),
        idSelected: this.border
      },
      { key: 'stripes', label: 'Stripes', options: options(['true', 'True'], ['false', 'False']), idSelected: this.stripes },
      {
        key: 'rowHover',
        label: 'Hover row',
        options: options(['none', 'None'], ['highlight', 'Highlight']),
        idSelected: this.rowHover
      },
      {
        key: 'header',
        label: 'Header',
        options: options(['shade', 'Shade'], ['underline', 'Underline']),
        idSelected: this.header
      },
      {
        key: 'cellPadding',
        label: 'Cell padding',
        options: options(['s', 'Small'], ['m', 'Medium'], ['l', 'Large']),
        idSelected: this.cellPadding
      },
      {
        key: 'fontSize',
        label: 'Font size',
        options: options(['s', 'Small'], ['m', 'Medium'], ['l', 'Large']),
        idSelected: this.fontSize
      },
      {
        key: 'footer',
        label: 'Footer',
        options: [
          { id: 'shade', label: 'Shade' },
          { id: 'overline', label: 'Overline' },
          {
            id: 'striped',
            label: 'Striped',
            isDisabled: this.stripes === 'false',
            toolTipContent:
              'A striped footer will be shaded depending on whether it is an even or an odd row considering the rest of the rows in the datagrid. Needs to be used with stripes={true}.',
            toolTipProps: { position: 'bottom' }
          }
        ],
        idSelected: this.footer
      }
    ];
  }

  get gridStyle() {
    return {
      border: this.border,
      fontSize: this.fontSize,
      cellPadding: this.cellPadding,
      stripes: this.stripes === 'true',
      rowHover: this.rowHover,
      header: this.header,
      footer: this.footer
    };
  }

  get snippet() {
    const object = JSON.stringify(this.gridStyle, null, 2).replace(/^( {2,})"([^"]+)":/gm, '$1$2:');
    return `gridStyle = ${object};\n\n<EuiDataGrid @gridStyle={{this.gridStyle}} … />`;
  }

  @action select(key, id) {
    this[key] = id;
  }

  // column visibility
  @tracked visibleColumns = this.columns.map(({ id }) => id);

  @action setVisibleColumns(visibleColumns) {
    this.visibleColumns = visibleColumns;
  }

  // pagination
  @tracked pageIndex = 0;
  @tracked pageSize;

  @action setPageIndex(pageIndex) {
    this.pageIndex = pageIndex;
  }

  @action setPageSize(pageSize) {
    this.pageSize = pageSize;
    this.pageIndex = 0;
  }

  // sorting (the grid only reports it; the data is not sorted here)
  @tracked sortingColumns = [];

  @action onSort(sortingColumns) {
    this.sortingColumns = sortingColumns;
  }
}
```

