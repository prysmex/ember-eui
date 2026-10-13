---
order: 10
---

# Custom panels

<EuiText>

You can create your own supporting panels for toolbars and other features
with `useEuiBasicTablePanelProps()` (upstream's hook, a plain function
here): it returns the panel `css` (for any component's `@css`) and
`className`. `EuiBasicTablePanel` is a `<div>` built on it, and the
`<:childrenBetween>` block yields it. Put panels in the
`<:childrenBetween>` block of a `@panelled` table, so the table joins the
panels above it.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiCode, EuiInMemoryTable } from '@ember-eui/core/components';
import { formatDate } from '@ember-eui/core/utils/eui/format';

const USERS = [
  ['Ada', 'Lovelace', [1991, 11, 10]],
  ['Alan', 'Turing', [1994, 5, 23]],
  ['Grace', 'Hopper', [1986, 11, 9]],
  ['Linus', 'Torvalds', [1999, 11, 28]],
  ['Margaret', 'Hamilton', [1996, 7, 17]],
].map(([firstName, lastName, [year, month, day]], i) => ({
  id: i + 1,
  firstName,
  lastName,
  dateOfBirth: new Date(year, month, day),
}));

const columns = [
  { field: 'firstName', name: 'First Name', sortable: true, truncateText: true },
  { field: 'lastName', name: 'Last Name', truncateText: true },
  {
    field: 'dateOfBirth',
    name: 'Date of Birth',
    nameTooltip: { content: "Colloquially known as a 'birthday'" },
    dataType: 'date',
    render: (dateOfBirth) => formatDate(dateOfBirth, 'dobLong'),
    sortable: true,
  },
];

// `@css` accepts a theme function (upstream's `useEuiPaddingCSS().m`)
const padding = ({ euiTheme }) => ({ padding: euiTheme.size.m });

export default class InMemoryTableCustomPanels extends Component {
  @tracked items = USERS;
  @tracked pageIndex = 0;

  columns = columns;

  get pagination() {
    return { pageIndex: this.pageIndex, pageSizeOptions: [5], pageSize: 5 };
  }

  onTableChange = ({ page: { index } }) => {
    this.pageIndex = index;
  };

  search = {
    box: { incremental: true },
    onChange: ({ query }) => {
      const text = query?.text.toLowerCase() || '';
      this.items = USERS.filter((user) =>
        `${user.firstName} ${user.lastName}`.toLowerCase().includes(text)
      );
    },
  };

  padding = padding;

  <template>
    <EuiInMemoryTable
      @tableCaption="Demo of EuiInMemoryTable"
      @responsiveBreakpoint={{false}}
      @scrollableInline={{true}}
      @items={{this.items}}
      @columns={{this.columns}}
      @pagination={{this.pagination}}
      @search={{this.search}}
      @onTableChange={{this.onTableChange}}
      @panelled={{true}}
    >
      <:childrenBetween as |Panel|>
        <Panel @css={{this.padding}}>
          A custom panel styled with <EuiCode>useEuiBasicTablePanelProps</EuiCode>
        </Panel>
      </:childrenBetween>
    </EuiInMemoryTable>
  </template>
}
```
