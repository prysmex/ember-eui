---
order: 6
---

# Focus

<EuiText>

**EuiDataGrid** tracks and manages complicated focus state based upon the
content of the individual inner cells. The following scenarios are
supported and tested:

### Initial focus

- When tabbing to the grid before it has received focus, the header cell is
  focused.
- When tabbing away from the grid and then returning, the last focused cell
  will regain focus.
- If the last focused cell has been scrolled out of view, the first header
  cell receives focus instead.

### Click and key events

- Clicking on an interactive cell or its content should focus on the cell.
- The up, down, left, and right arrow keys can be pressed to navigate
  between cells.
- For expandable cells, either the Enter or F2 keys can be pressed
  interchangeably to toggle the cell popover. The Escape key will close the
  popover.
- For non-expandable cells with interactive content, either the Enter or F2
  keys can be pressed to enter a focus trap, allowing users to Tab between
  the cell's content. The Escape key will exit the cell trap.
- For non-expandable cells with no interactive content, the cell alone will
  receive focus, with no inner content action.

</EuiText>

<EuiCallOut @title="Don't turn off cell expansion when the width of the column is unknown" @color="warning" @iconType="warning">
  In general, you should change <code>isExpandable</code> to
  <code>false</code> only when you know the exact width and number of items
  that a cell will include. Control columns that contain row actions are a
  good example of when to use them. In certain scenarios, allowing multiple
  interactive elements in cells when you cannot control the width can lead
  to hidden focus because the content is truncated.
</EuiCallOut>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { get, hash } from '@ember/helper';
import { eq, lt } from 'ember-truth-helpers';
import {
  EuiBadge,
  EuiButtonIcon,
  EuiDataGrid,
  EuiFlexGroup,
  EuiFlexItem,
  EuiLink,
  EuiTextColor,
  EuiToken,
  EuiToolTip
} from '@ember-eui/core/components';

const noop = () => {};
const columnSettingsLabel = 'Column settings';

// Header displays (column `display` components)
const ColumnSettingsButton = <template>
  <EuiToolTip @content={{columnSettingsLabel}} @disableScreenReaderOutput={{true}}>
    <EuiButtonIcon aria-label={{columnSettingsLabel}} @iconType="gear" {{on "click" noop}} />
  </EuiToolTip>
</template>;

const NoInteractivesNotExpandable = <template>
  <EuiBadge>0 interactive</EuiBadge>
</template>;

const OneInteractiveNotExpandable = <template>
  <EuiFlexGroup @alignItems="center" @gutterSize="xs" @responsive={{false}}>
    <ColumnSettingsButton />
    <EuiBadge>1 interactive</EuiBadge>
  </EuiFlexGroup>
</template>;

const TwoInteractivesNotExpandable = <template>
  <EuiFlexGroup @alignItems="center" @gutterSize="xs" @responsive={{false}}>
    <ColumnSettingsButton />
    <ColumnSettingsButton />
    <EuiBadge>2 interactive</EuiBadge>
  </EuiFlexGroup>
</template>;

const expandableHeader = (count) => <template>
  <EuiFlexGroup @alignItems="center" @gutterSize="xs" @responsive={{false}}>
    <EuiFlexItem @grow={{false}}>
      <EuiToken
        @size="s"
        @iconType="maximize"
        @color="euiColorVis0"
        @shape="square"
        @fill="dark"
        @title="Expandable"
      />
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiBadge>{{count}} interactive</EuiBadge>
    </EuiFlexItem>
  </EuiFlexGroup>
</template>;

const columns = [
  {
    id: 'no-interactives not expandable',
    display: NoInteractivesNotExpandable,
    isExpandable: false,
    actions: false
  },
  {
    id: 'no-interactives is expandable',
    display: expandableHeader(0),
    actions: false
  },
  {
    id: 'one-interactive not expandable',
    display: OneInteractiveNotExpandable,
    isExpandable: false,
    actions: false
  },
  {
    id: 'one-interactives is expandable',
    display: expandableHeader(1),
    actions: false
  },
  {
    id: 'two-interactives not expandable',
    display: TwoInteractivesNotExpandable,
    isExpandable: false,
    actions: false
  },
  {
    id: 'two-interactives is expandable',
    display: expandableHeader(2),
    actions: false
  }
];

// The cell content depends on the column, wherever it is displayed
const columnIdToIndex = Object.fromEntries(columns.map(({ id }, index) => [id, index]));

const FIRST_NAMES = ['Ada', 'Bruno', 'Carmen', 'Dmitri', 'Elena', 'Farid', 'Greta', 'Hugo', 'Ines', 'Jonas'];
const OTHER_NAMES = ['Kofi', 'Lena', 'Mateo', 'Nadia', 'Oskar', 'Priya', 'Quentin', 'Rosa', 'Sami', 'Tess'];

const data = FIRST_NAMES.map((firstName, i) => ({
  names: [firstName, OTHER_NAMES[i]],
  emails: [
    `${firstName.toLowerCase()}@example.com`,
    `${OTHER_NAMES[i].toLowerCase()}.${i + 1}@example.net`
  ]
}));

export default class FocusDemo extends Component {
  @tracked visibleColumns = columns.map(({ id }) => id);
  @tracked pageIndex = 0;
  @tracked pageSize = 4;
  pageSizeOptions = [4];

  setVisibleColumns = (visibleColumns) => (this.visibleColumns = visibleColumns);
  onChangePage = (pageIndex) => (this.pageIndex = pageIndex);
  onChangeItemsPerPage = (pageSize) => (this.pageSize = pageSize);

  <template>
    <EuiDataGrid
      aria-label="Focus"
      @columns={{columns}}
      @columnVisibility={{hash
        visibleColumns=this.visibleColumns
        setVisibleColumns=this.setVisibleColumns
      }}
      @rowCount={{data.length}}
      @pagination={{hash
        pageIndex=this.pageIndex
        pageSize=this.pageSize
        pageSizeOptions=this.pageSizeOptions
        onChangePage=this.onChangePage
        onChangeItemsPerPage=this.onChangeItemsPerPage
      }}
    >
      <:cell as |cell|>
        {{#let (get data cell.rowIndex) (get columnIdToIndex cell.columnId) as |row columnIndex|}}
          {{#if (lt columnIndex 2)}}
            <span>{{get row.names columnIndex}}</span>
          {{else if (lt columnIndex 4)}}
            <span>
              <EuiLink @href="#">{{get row.emails (if (eq columnIndex 2) 0 1)}}</EuiLink>
            </span>
          {{else}}
            <EuiTextColor @color="subdued">
              <EuiLink @color="success" {{on "click" noop}}>Yes</EuiLink>
              |
              <EuiLink @color="danger" {{on "click" noop}}>No</EuiLink>
            </EuiTextColor>
          {{/if}}
        {{/let}}
      </:cell>
    </EuiDataGrid>
  </template>
}
```
