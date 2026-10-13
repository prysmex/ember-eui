---
order: 2
---

# Additional controls in the toolbar

<EuiText>

Use the `<:leftControlsPrepend>`, `<:leftControlsAppend>` and
`<:rightControls>` blocks to pass more buttons to the toolbar (upstream's
`toolbarVisibility.additionalControls`):

- `<:leftControlsPrepend>` prepends its content into the left side of the
  toolbar, before the column & sort controls.
- `<:leftControlsAppend>` appends its content into the left side of the
  toolbar, after the column & sort controls.
- `<:rightControls>` prepends its content into the right side of the
  toolbar, before the density & full screen controls.

`toolbarVisibility.additionalControls` also accepts components, like
upstream's nodes: a single component is placed in the left append position,
or pass `{ left: { prepend, append }, right }` (or `{ left, right }`) to
choose the positions.

Although any content is allowed, the recommendation is to use
`<EuiDataGridToolbarControl />` for the left side of the toolbar and
`<EuiButtonIcon @size="xs" />` for the right side of the toolbar.

The display options popover takes extra content with
`toolbarVisibility.showDisplaySelector.additionalDisplaySettings`, a
component (here with its own state).

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { fn, get, hash, uniqueId } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import {
  EuiButtonEmpty,
  EuiButtonIcon,
  EuiContextMenuItem,
  EuiContextMenuPanel,
  EuiDataGrid,
  EuiDataGridToolbarControl,
  EuiFlyout,
  EuiFlyoutBody,
  EuiFlyoutHeader,
  EuiFormRow,
  EuiLink,
  EuiPopover,
  EuiRange,
  EuiText,
  EuiTitle,
  EuiToolTip
} from '@ember-eui/core/components';

const columns = [
  { id: 'name' },
  { id: 'email' },
  { id: 'city' },
  { id: 'country' },
  { id: 'account' }
];

const PEOPLE = [
  ['Hartmann', 'Ada', 'Jr.', 'Lake Rosalind', 'Iceland'],
  ['Okafor', 'Bruno', 'III', 'North Kailey', 'Portugal'],
  ['Lindqvist', 'Carmen', 'Sr.', 'Port Elnora', 'Chile'],
  ['Moreau', 'Dmitri', 'IV', 'West Juniper', 'Kenya'],
  ['Novak', 'Elena', 'II', 'East Marlon', 'Croatia'],
  ['Quispe', 'Farid', 'V', 'New Alvina', 'Peru'],
  ['Sato', 'Greta', 'Jr.', 'Hollyfort', 'Japan'],
  ['Varga', 'Hugo', 'Sr.', 'South Tamia', 'Hungary'],
  ['Adeyemi', 'Ines', 'III', 'Kirlinview', 'Nigeria'],
  ['Berg', 'Jonas', 'II', 'Lake Destin', 'Norway'],
  ['Costa', 'Kofi', 'IV', 'Port Ottis', 'Brazil'],
  ['Dubois', 'Lena', 'Jr.', 'Rennerberg', 'France'],
  ['Eriksen', 'Mateo', 'Sr.', 'West Aleen', 'Denmark'],
  ['Fischer', 'Nadia', 'V', 'Gusikowski', 'Austria'],
  ['Garcia', 'Oskar', 'II', 'Bayerland', 'Spain'],
  ['Haddad', 'Priya', 'III', 'Kuhicburgh', 'Lebanon'],
  ['Ivanova', 'Quentin', 'IV', 'Mertzfort', 'Bulgaria'],
  ['Jensen', 'Rosa', 'Jr.', 'Port Lexie', 'Greenland'],
  ['Kowalski', 'Sami', 'Sr.', 'Daughertyton', 'Poland']
];

const data = PEOPLE.map(([last, first, suffix, city, country], i) => ({
  name: `${last}, ${first} ${suffix}`,
  email: `${first.toLowerCase()}.${last.toLowerCase()}@example.com`,
  city,
  country,
  account: String(10000000 + ((i + 1) * 48271) % 89999999)
}));

// Some additional custom settings to show in the Display popover
class AdditionalDisplaySettings extends Component {
  @tracked exampleSettingValue = 10;

  onChange = (event) => (this.exampleSettingValue = Number(event.currentTarget.value));

  <template>
    <EuiFormRow @label="Example additional setting" @display="columnCompressed">
      <EuiRange
        @compressed={{true}}
        @fullWidth={{true}}
        @showInput={{true}}
        @min={{1}}
        @max={{100}}
        @step={{1}}
        @value={{this.exampleSettingValue}}
        @onChange={{this.onChange}}
        data-test-subj="exampleAdditionalSetting"
      />
    </EuiFormRow>
  </template>
}

export default class AdditionalControlsDemo extends Component {
  @tracked visibleColumns = columns.map(({ id }) => id);
  @tracked pageIndex = 0;
  @tracked pageSize = 10;
  @tracked isFlyoutVisible = false;
  @tracked isPopoverOpen = false;

  toolbarVisibility = {
    showDisplaySelector: {
      allowResetButton: false,
      additionalDisplaySettings: AdditionalDisplaySettings
    }
  };

  setVisibleColumns = (visibleColumns) => (this.visibleColumns = visibleColumns);
  onChangePage = (pageIndex) => (this.pageIndex = pageIndex);
  onChangeItemsPerPage = (pageSize) => {
    this.pageSize = pageSize;
    this.pageIndex = 0;
  };

  togglePopover = () => (this.isPopoverOpen = !this.isPopoverOpen);
  closePopover = () => (this.isPopoverOpen = false);
  showFlyout = () => (this.isFlyoutVisible = true);
  closeFlyout = () => (this.isFlyoutVisible = false);

  alertAndClosePopover = (position) => {
    this.isPopoverOpen = false;
    window.alert(`This is not a real control. It was passed into the \`${position}\` position.`);
  };

  <template>
    <EuiDataGrid
      aria-label="Data grid demo with additional controls"
      @columns={{columns}}
      @columnVisibility={{hash
        visibleColumns=this.visibleColumns
        setVisibleColumns=this.setVisibleColumns
      }}
      @rowCount={{data.length}}
      @gridStyle={{hash border="horizontal" header="underline"}}
      @pagination={{hash
        pageIndex=this.pageIndex
        pageSize=this.pageSize
        onChangePage=this.onChangePage
        onChangeItemsPerPage=this.onChangeItemsPerPage
      }}
      @toolbarVisibility={{this.toolbarVisibility}}
    >
      <:cell as |cell|>
        {{#let (get (get data cell.rowIndex) cell.columnId) as |value|}}
          {{#if (eq cell.columnId "city")}}
            <EuiLink @href="http://google.com">{{value}}</EuiLink>
          {{else}}
            {{value}}
          {{/if}}
        {{/let}}
      </:cell>
      <:leftControlsPrepend>
        <EuiButtonEmpty
          @size="xs"
          @iconType="document"
          @color="text"
          {{on "click" (fn this.alertAndClosePopover "left.prepend")}}
        >
          {{data.length}} results
        </EuiButtonEmpty>
      </:leftControlsPrepend>
      <:leftControlsAppend>
        <EuiPopover
          @isOpen={{this.isPopoverOpen}}
          @closePopover={{this.closePopover}}
          @panelPaddingSize="none"
        >
          <:button>
            <EuiDataGridToolbarControl @iconType="download" {{on "click" this.togglePopover}}>
              Download
            </EuiDataGridToolbarControl>
          </:button>
          <:content>
            <EuiContextMenuPanel>
              <EuiContextMenuItem {{on "click" (fn this.alertAndClosePopover "left.append")}}>
                CSV
              </EuiContextMenuItem>
              <EuiContextMenuItem {{on "click" (fn this.alertAndClosePopover "left.append")}}>
                JSON
              </EuiContextMenuItem>
            </EuiContextMenuPanel>
          </:content>
        </EuiPopover>
      </:leftControlsAppend>
      <:rightControls>
        <EuiToolTip @title="Updated 3 min ago" @content="Click to refresh">
          <EuiButtonIcon
            aria-label="Refresh grid data"
            @size="xs"
            @iconType="refresh"
            {{on "click" (fn this.alertAndClosePopover "right")}}
          />
        </EuiToolTip>
        <EuiToolTip @content="Inspect grid data">
          <EuiButtonIcon
            aria-label="Inspect grid data"
            @size="xs"
            @iconType="inspect"
            {{on "click" this.showFlyout}}
          />
        </EuiToolTip>
      </:rightControls>
    </EuiDataGrid>
    {{#if this.isFlyoutVisible}}
      {{#let (uniqueId) as |flyoutTitleId|}}
        <EuiFlyout @onClose={{this.closeFlyout}} aria-labelledby={{flyoutTitleId}}>
          <EuiFlyoutHeader @hasBorder={{true}}>
            <EuiTitle @size="m"><h2 id={{flyoutTitleId}}>Inspect</h2></EuiTitle>
          </EuiFlyoutHeader>
          <EuiFlyoutBody>
            <EuiText>
              <p>
                This is not a real control, just an example of how to trigger a
                flyout from a custom data grid control.
              </p>
            </EuiText>
          </EuiFlyoutBody>
        </EuiFlyout>
      {{/let}}
    {{/if}}
  </template>
}
```
