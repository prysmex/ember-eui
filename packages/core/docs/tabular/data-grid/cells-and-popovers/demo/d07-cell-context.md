---
order: 7
---

# Cell context

<EuiText>

The `@cellContext` argument is an easy way of passing your custom data or
context from the top level of **EuiDataGrid** down to the cell content
rendered by your `@renderCellValue` component, which receives it as
`@cellContext` (and the `<:cell>` block as `cellContext`).

The primary use of the cell context API is performance: if your data relies
on state from your app, it allows you to define your `@renderCellValue`
component statically, outside of your app's component, while the grid
still passes it fresh data.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { get, hash } from '@ember/helper';
import { EuiButton, EuiDataGrid, EuiSkeletonText, EuiSpacer } from '@ember-eui/core/components';

// Defined statically: the data comes from `@cellContext`
const CellValue = <template>
  {{#if @cellContext.isLoading}}
    <EuiSkeletonText @lines={{1}} />
  {{else}}
    {{get (get @cellContext.data @rowIndex) @columnId}}
  {{/if}}
</template>;

const columns = [{ id: 'firstName' }, { id: 'lastName' }, { id: 'suffix' }, { id: 'boolean' }];

const FIRST_NAMES = ['Ada', 'Bruno', 'Carmen', 'Dmitri', 'Elena', 'Farid', 'Greta', 'Hugo'];
const LAST_NAMES = ['Hartmann', 'Okafor', 'Lindqvist', 'Moreau', 'Novak', 'Quispe', 'Sato', 'Varga'];
const SUFFIXES = ['Jr.', 'Sr.', 'II', 'III', 'IV', 'V'];

// A tiny seeded generator, so each fetch returns different (but repeatable) rows
let seed = 7;
const random = (length) => {
  seed = (seed * 9301 + 49297) % 233280;
  return Math.floor((seed / 233280) * length);
};

const fetchRows = () =>
  Array.from({ length: 4 }, () => ({
    firstName: FIRST_NAMES[random(FIRST_NAMES.length)],
    lastName: LAST_NAMES[random(LAST_NAMES.length)],
    suffix: SUFFIXES[random(SUFFIXES.length)],
    boolean: `${random(2) === 1}`
  }));

export default class CellContextDemo extends Component {
  @tracked visibleColumns = columns.map(({ id }) => id);
  @tracked data = [];
  @tracked isLoading = false;
  timeout = null;

  constructor(owner, args) {
    super(owner, args);
    // Fetch data on page load
    this.fetchData();
  }

  get cellContext() {
    return { data: this.data, isLoading: this.isLoading };
  }

  // Mock fetching data from an async API
  mockLoading() {
    this.isLoading = true;
    // End the loading state after 3 seconds
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => (this.isLoading = false), 3000);
  }

  fetchData = () => {
    this.mockLoading();
    this.data = fetchRows();
  };

  setVisibleColumns = (visibleColumns) => (this.visibleColumns = visibleColumns);

  willDestroy() {
    super.willDestroy();
    clearTimeout(this.timeout);
  }

  <template>
    <EuiButton @size="s" {{on "click" this.fetchData}}>
      Fetch grid data
    </EuiButton>
    <EuiSpacer @size="s" />
    <EuiDataGrid
      aria-label="Data grid example of cellContext"
      @columns={{columns}}
      @columnVisibility={{hash
        visibleColumns=this.visibleColumns
        setVisibleColumns=this.setVisibleColumns
      }}
      @rowCount={{this.data.length}}
      @renderCellValue={{CellValue}}
      @cellContext={{this.cellContext}}
    />
  </template>
}
```
