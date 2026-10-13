---
order: 7
---

# Sizing and containers

<EuiText>

The component's `list` and `search` parts are yielded by the default block (`as |parts|`), which means you can wrap the individual elements in anything you want.

### Width and height

The width has been made to always be 100% of its container, including stretching the search input. When used inside of an `EuiPopover`, we recommend setting a width (or min/max values) via CSS on the element containing the list.

### Flexbox

Be aware that `display: flex` with column layout is applied to the wrapping container. This is so that you can opt in to allow the height of the list stretch to fill its container. See the flyout example.

**Ember EUI difference:** upstream's input popover example (`EuiInputPopover` driven by `searchProps.value`/`onChange`) has no counterpart, so it is left out.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButton, EuiCode, EuiFlyout, EuiFlyoutFooter, EuiFlyoutHeader, EuiPopover, EuiPopoverFooter, EuiPopoverTitle, EuiSelectable, EuiSpacer, EuiTitle } from '@ember-eui/core/components';
import { on } from '@ember/modifier';
import { hash } from '@ember/helper';

const OPTIONS = [
  { label: 'Titan' },
  { label: 'Enceladus' },
  { label: 'Mimas', checked: 'on' },
  { label: 'Dione' },
  { label: 'Iapetus' },
  { label: 'Phoebe' },
  { label: 'Rhea' },
  { label: 'Pandora' },
  { label: 'Tethys' },
  { label: 'Hyperion' },
  { label: 'Pan' },
  { label: 'Atlas' },
  { label: 'Prometheus' },
  { label: 'Janus' },
  { label: 'Epimetheus' },
  { label: 'Amalthea' },
  { label: 'Thebe' },
  { label: 'Io' },
  { label: 'Europa' },
  { label: 'Ganymede' },
  { label: 'Callisto' },
  { label: 'Himalia' },
  { label: 'Phobos' },
  { label: 'Deimos' },
  { label: 'Puck' },
  { label: 'Miranda' },
  { label: 'Ariel' },
  { label: 'Umbriel' },
  { label: 'Titania' },
  { label: 'Oberon' },
  { label: 'Despina' },
  { label: 'Galatea' },
  { label: 'Larissa' },
  { label: 'Triton' },
  { label: 'Nereid' },
  { label: 'Charon' },
  { label: 'Styx' },
  { label: 'Nix' },
  { label: 'Kerberos' },
  { label: 'Hydra' },
];


export default class SelectableSizingDemo extends Component {
  @tracked options = OPTIONS;
  @tracked isPopoverOpen = false;
  @tracked isFlyoutVisible = false;

  @action
  setOptions(options) {
    this.options = options;
  }

  @action
  togglePopover() {
    this.isPopoverOpen = !this.isPopoverOpen;
  }

  @action
  closePopover() {
    this.isPopoverOpen = false;
  }

  @action
  showFlyout() {
    this.isFlyoutVisible = true;
  }

  @action
  closeFlyout() {
    this.isFlyoutVisible = false;
  }

  <template>
    <EuiPopover
      @panelPaddingSize="none"
      @isOpen={{this.isPopoverOpen}}
      @closePopover={{this.closePopover}}
    >
      <:button>
        <EuiButton
          @iconType="chevronSingleDown"
          @iconSide="right"
          {{on "click" this.togglePopover}}
        >
          Show popover
        </EuiButton>
      </:button>
      <:content>
        <EuiSelectable
          aria-label="Selectable + popover example"
          @searchable={{true}}
          @searchProps={{hash placeholder="Filter list" compressed=true}}
          @options={{this.options}}
          @onChange={{this.setOptions}}
          as |parts|
        >
          <div style="width: 240px">
            <EuiPopoverTitle @paddingSize="s"><parts.search /></EuiPopoverTitle>
            <parts.list />
            <EuiPopoverFooter @paddingSize="s">
              <EuiButton @size="s" @fullWidth={{true}}>Manage this list</EuiButton>
            </EuiPopoverFooter>
          </div>
        </EuiSelectable>
      </:content>
    </EuiPopover>
    <EuiSpacer />
    <EuiButton {{on "click" this.showFlyout}}>Show flyout</EuiButton>
    {{#if this.isFlyoutVisible}}
      <EuiFlyout @ownFocus={{true}} @onClose={{this.closeFlyout}}>
        <EuiSelectable
          aria-label="Selectable + flyout example"
          @searchable={{true}}
          @options={{this.options}}
          @onChange={{this.setOptions}}
          @height="full"
          as |parts|
        >
          <EuiFlyoutHeader @hasBorder={{true}}>
            <EuiTitle @size="m"><h2 id="selectableFlyout">Be mindful of the flexbox</h2></EuiTitle>
            <EuiSpacer />
            <parts.search />
          </EuiFlyoutHeader>
          <EuiSpacer @size="xs" />
          <parts.list />
        </EuiSelectable>
        <EuiSpacer @size="xs" />
        <EuiFlyoutFooter>
          <EuiButton @fill={{true}}>Some extra action</EuiButton>
        </EuiFlyoutFooter>
      </EuiFlyout>
    {{/if}}
    <EuiSpacer />
    <EuiTitle @size="xxs">
      <h4>
        Using <EuiCode>@listProps.bordered=true</EuiCode> and
        <EuiCode>@listProps.paddingSize="s"</EuiCode>
      </h4>
    </EuiTitle>
    <EuiSpacer @size="s" />
    <EuiSelectable
      aria-label="Bordered selectable example"
      style="width: 300px"
      @options={{this.options}}
      @onChange={{this.setOptions}}
      @listProps={{hash bordered=true paddingSize="s"}}
    />
  </template>
}
```
