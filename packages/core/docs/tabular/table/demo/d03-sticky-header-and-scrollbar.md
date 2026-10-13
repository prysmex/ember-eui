---
order: 3
---

# Sticky headers and horizontal scrollbar (beta)

<EuiText>

`@stickyHeader={{true}}` keeps the table header at the top of the viewport
as users scroll through long tables. This keeps the column context during
vertical scrolling and unifies the scrolling experience of `EuiTable`
components and `EuiDataGrid`. Use it where the table can grow longer than
the viewport. Offset it (e.g. below a fixed header) with the
`--euiTableStickyHeaderOffsetTop` CSS variable.

When a table is taller than the viewport, the horizontal scrollbar at its
bottom becomes hard to reach. With `@scrollableInline={{true}}`,
`@stickyScrollbar={{true}}` shows a scrollbar that sticks to the bottom of
the viewport when needed. Cells with `@sticky={{hash side="end"}}` stay at
the end of the table while it scrolls.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import {
  EuiButtonIcon,
  EuiTable,
  EuiTableBody,
  EuiTableHeader,
  EuiTableHeaderCell,
  EuiTableRow,
  EuiTableRowCell,
} from '@ember-eui/core/components';

const REGIONS = ['eu-west-1', 'us-east-1', 'ap-south-1', 'sa-east-1'];

const SERVICES = Array.from({ length: 40 }, (_, i) => ({
  id: i + 1,
  name: `service-${String(i + 1).padStart(2, '0')}`,
  region: REGIONS[i % REGIONS.length],
  owner: ['payments', 'search', 'identity', 'platform'][i % 4],
  load: (i * 37) % 100,
  description: 'Handles requests for one of the product areas and reports its health',
}));

export default class StickyTable extends Component {
  @tracked sortAscending = true;

  get services() {
    return [...SERVICES].sort((a, b) =>
      this.sortAscending ? a.id - b.id : b.id - a.id
    );
  }

  sort = () => {
    this.sortAscending = !this.sortAscending;
  };

  <template>
    <EuiTable
      @stickyHeader={{true}}
      @scrollableInline={{true}}
      @stickyScrollbar={{true}}
      @tableLayout="auto"
      @responsiveBreakpoint={{false}}
    >
      <EuiTableHeader>
        <EuiTableHeaderCell
          @minWidth="10em"
          @onSort={{this.sort}}
          @isSorted={{true}}
          @isSortAscending={{this.sortAscending}}
        >Service</EuiTableHeaderCell>
        <EuiTableHeaderCell @minWidth="10em">Region</EuiTableHeaderCell>
        <EuiTableHeaderCell @minWidth="10em">Owner</EuiTableHeaderCell>
        <EuiTableHeaderCell @minWidth="8em" @align="right">Load</EuiTableHeaderCell>
        <EuiTableHeaderCell @minWidth="30em">Description</EuiTableHeaderCell>
        <EuiTableHeaderCell @width="4em" @sticky={{hash side="end"}}>Actions</EuiTableHeaderCell>
      </EuiTableHeader>
      <EuiTableBody>
        {{#each this.services key="id" as |service|}}
          <EuiTableRow>
            <EuiTableRowCell>{{service.name}}</EuiTableRowCell>
            <EuiTableRowCell>{{service.region}}</EuiTableRowCell>
            <EuiTableRowCell>{{service.owner}}</EuiTableRowCell>
            <EuiTableRowCell @align="right">{{service.load}}%</EuiTableRowCell>
            <EuiTableRowCell>{{service.description}}</EuiTableRowCell>
            <EuiTableRowCell
              @textOnly={{false}}
              @hasActions={{true}}
              @sticky={{hash side="end"}}
            >
              <EuiButtonIcon @iconType="gear" aria-label="Settings of {{service.name}}" />
            </EuiTableRowCell>
          </EuiTableRow>
        {{/each}}
      </EuiTableBody>
    </EuiTable>
  </template>
}
```
