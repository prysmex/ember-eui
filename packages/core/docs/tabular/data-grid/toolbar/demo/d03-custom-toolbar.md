---
order: 3
---

# Completely custom toolbar rendering

<EuiText>

If more customized control over the toolbar is required than
`@toolbarVisibility` or the additional controls allow, use the
`<:customToolbar>` block (or pass a component to `@renderCustomToolbar`).
The default data grid controls are passed back as components for optional
usage: `hasRoomForGridControls`, `columnControl`, `columnSortingControl`,
`keyboardShortcutsControl`, `displayControl` and `fullScreenControl`
(undefined when hidden by `@toolbarVisibility`), plus, as an Ember
addition, `additionalControls` (the option components by position).

The custom toolbar should only be used when a very custom layout (e.g.
moving default buttons between sides, interspersing custom controls between
default controls, custom responsive behavior, etc.) is required. For
consistent visuals, we recommend using the `<EuiDataGridToolbarControl />`
component when rendering custom controls.

This example also lays out the display options popover with
`toolbarVisibility.showDisplaySelector.customRender`, a component receiving
the default `@densityControl`, `@rowHeightControl`,
`@additionalDisplaySettings` and `@resetButton` (each undefined when
disabled), with custom border and row stripes settings in between.

</EuiText>

<EuiCallOut @title="Keep consistency in mind when customizing the toolbar" @color="warning" @iconType="warning">
  If using multiple data grid instances across your app, users will
  typically want to reach for the same controls for each grid. Changing the
  available controls inconsistently across your app may result in user
  frustration.
</EuiCallOut>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { get, hash } from '@ember/helper';
import {
  EuiButtonGroup,
  EuiDataGrid,
  EuiDataGridToolbarControl,
  EuiFlexGroup,
  EuiFlexItem,
  EuiFormRow,
  EuiHorizontalRule,
  EuiSpacer,
  EuiSwitch
} from '@ember-eui/core/components';

const raw_data = [
  ['Hartmann, Ada', 'ada.hartmann@example.com', 'Lake Rosalind, Iceland', 'Tue Mar 12 2024 10:41:07 GMT+0000', '$412.08'],
  ['Okafor, Bruno', 'bruno_okafor@example.net', 'North Kailey, Portugal', 'Sat Nov 30 2024 07:15:42 GMT+0000', '$87.50'],
  ['Lindqvist, Carmen', 'carmen.l@example.org', 'Port Elnora, Chile', 'Thu Jun 20 2024 23:58:01 GMT+0000', '$953.71'],
  ['Moreau, Dmitri', 'dmitri44@example.com', 'West Juniper, Kenya', 'Sun Feb 04 2024 13:26:50 GMT+0000', '$230.44'],
  ['Novak, Elena', 'elena.novak@example.com', 'East Marlon, Croatia', 'Wed Aug 07 2024 16:02:55 GMT+0000', '$19.99']
].map(([name, email, location, date, amount]) => ({ name, email, location, date, amount }));

const columns = [
  { id: 'name', displayAsText: 'Name' },
  { id: 'email', displayAsText: 'Email address' },
  { id: 'location', displayAsText: 'Location' },
  { id: 'date', displayAsText: 'Date' },
  { id: 'amount', displayAsText: 'Amount' }
];

const borderOptions = [
  { id: 'all', label: 'All' },
  { id: 'horizontal', label: 'Horizontal only' },
  { id: 'none', label: 'None' }
];

// Without room for the grid controls, keep only the controls' icons
// (`euiScreenReaderOnly` styles on their text)
const mobileStyles = (hasRoomForGridControls) =>
  hasRoomForGridControls
    ? undefined
    : {
        '.euiDataGridToolbarControl__text': {
          position: 'absolute',
          insetBlockStart: 'auto',
          insetInlineStart: '-10000px',
          inlineSize: '1px',
          blockSize: '1px',
          clip: 'rect(0 0 0 0)',
          clipPath: 'inset(50%)',
          overflow: 'hidden',
          margin: '-1px'
        }
      };

// Custom display settings: the popover's layout, sharing the demo's state
const customDisplayControls = (demo) => <template>
  <EuiSpacer @size="xs" />
  <EuiSwitch
    @label="Show row stripes"
    @checked={{demo.rowStripes}}
    @onChange={{demo.toggleRowStripes}}
  />
  <EuiHorizontalRule @margin="s" />
  {{#if @densityControl}}<@densityControl />{{/if}}
  <EuiFormRow @label="Border" @display="columnCompressed">
    <EuiButtonGroup
      @isFullWidth={{true}}
      @buttonSize="compressed"
      @legend="Border"
      @options={{borderOptions}}
      @idSelected={{demo.borders}}
      @onChange={{demo.setBorders}}
    />
  </EuiFormRow>
  {{#if @rowHeightControl}}<@rowHeightControl />{{/if}}
</template>;

export default class CustomToolbarDemo extends Component {
  // Column visibility
  @tracked visibleColumns = columns.map(({ id }) => id);
  // Sorting
  @tracked sortingColumns = [];
  // Custom display settings
  @tracked borders = 'none';
  @tracked rowStripes = false;

  toolbarVisibility = {
    showDisplaySelector: {
      allowResetButton: false,
      customRender: customDisplayControls(this)
    }
  };

  get gridStyle() {
    return {
      border: this.borders,
      header: this.borders === 'none' ? 'underline' : 'shade',
      stripes: this.rowStripes
    };
  }

  setVisibleColumns = (visibleColumns) => (this.visibleColumns = visibleColumns);
  onSort = (sortingColumns) => (this.sortingColumns = sortingColumns);
  setBorders = (borders) => (this.borders = borders);
  toggleRowStripes = () => (this.rowStripes = !this.rowStripes);

  <template>
    <EuiDataGrid
      aria-label="Data grid custom toolbar demo"
      @columns={{columns}}
      @columnVisibility={{hash
        visibleColumns=this.visibleColumns
        setVisibleColumns=this.setVisibleColumns
      }}
      @sorting={{hash columns=this.sortingColumns onSort=this.onSort}}
      @rowCount={{raw_data.length}}
      @gridStyle={{this.gridStyle}}
      @toolbarVisibility={{this.toolbarVisibility}}
    >
      <:cell as |cell|>{{get (get raw_data cell.rowIndex) cell.columnId}}</:cell>
      <:customToolbar as |toolbar|>
        <EuiFlexGroup
          @responsive={{false}}
          @gutterSize="s"
          @justifyContent="spaceBetween"
          @alignItems="center"
          @css={{mobileStyles toolbar.hasRoomForGridControls}}
          class="euiDataGrid__controls"
        >
          <EuiFlexItem @grow={{false}}>
            {{#if toolbar.hasRoomForGridControls}}
              <EuiDataGridToolbarControl @iconType="brush" @badgeContent={{10}}>
                Custom left side
              </EuiDataGridToolbarControl>
            {{/if}}
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiFlexGroup @responsive={{false}} @gutterSize="s" @alignItems="center">
              <EuiFlexItem @grow={{false}}><toolbar.columnControl /></EuiFlexItem>
              <EuiFlexItem @grow={{false}}><toolbar.columnSortingControl /></EuiFlexItem>
              <EuiFlexItem @grow={{false}}><toolbar.keyboardShortcutsControl /></EuiFlexItem>
              <EuiFlexItem @grow={{false}}><toolbar.displayControl /></EuiFlexItem>
              <EuiFlexItem @grow={{false}}><toolbar.fullScreenControl /></EuiFlexItem>
            </EuiFlexGroup>
          </EuiFlexItem>
        </EuiFlexGroup>
      </:customToolbar>
    </EuiDataGrid>
  </template>
}
```
