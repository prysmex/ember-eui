---
order: 11
---

# Button group: Options API

<EuiText>

`EuiButtonGroup` groups related buttons together. Use the `@options` array for buttons with radio or checkbox semantics. Set `@type="single"` (default) for a radio-like single selection, or `@type="multi"` for multi-selection (`@idToSelectedMap`).

**Accessibility recommendation:** in order for groups to be properly read as groups with a title, the `@legend` argument is **required**. This is only for accessibility, however, so it will be visibly hidden.

</EuiText>

```hbs template
<EuiFlexGroup @gutterSize="m" @alignItems="center">
  <EuiFlexItem @grow={{false}}>
    <EuiSwitch @compressed={{true}} @label="Full width" @checked={{this.fullButton}} @onChange={{fn this.toggle "fullButton"}} />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiSwitch @compressed={{true}} @label="Disabled" @checked={{this.disableButton}} @onChange={{fn this.toggle "disableButton"}} />
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiPanel @color="plain" @hasBorder={{true}} style="width: 600px; max-width: 100%">
  <EuiTitle @size="xxs" @tagName="h3">Default</EuiTitle>
  <EuiSpacer @size="s" />
  <EuiButtonGroup
    @legend="Default single select button group"
    @isFullWidth={{this.fullButton}}
    @isDisabled={{this.disableButton}}
    @options={{this.toggleButtons}}
    @idSelected={{this.toggleIdSelected}}
    @onChange={{this.onChange}}
  />
</EuiPanel>

<EuiSpacer />

<EuiPanel @color="plain" @hasBorder={{true}} style="width: 600px; max-width: 100%">
  <EuiTitle @size="xxs" @tagName="h3">Multi select</EuiTitle>
  <EuiSpacer @size="s" />
  <EuiButtonGroup
    @legend="Multi select button group"
    @type="multi"
    @isFullWidth={{this.fullButton}}
    @isDisabled={{this.disableButton}}
    @options={{this.toggleButtonsMulti}}
    @idToSelectedMap={{this.toggleIdToSelectedMap}}
    @onChange={{this.onChangeMulti}}
  />
</EuiPanel>
```

```js component
import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

const basicButtonGroupPrefix = guidFor({});
const multiSelectButtonGroupPrefix = guidFor({});

export default class DemoComponent extends Component {
  @tracked disableButton = false;
  @tracked fullButton = false;
  @tracked toggleIdSelected = `${basicButtonGroupPrefix}__1`;
  @tracked toggleIdToSelectedMap = {
    [`${multiSelectButtonGroupPrefix}__1`]: true
  };

  toggleButtons = [
    { id: `${basicButtonGroupPrefix}__0`, label: 'Option one' },
    { id: `${basicButtonGroupPrefix}__1`, label: 'Option two is selected by default' },
    { id: `${basicButtonGroupPrefix}__2`, label: 'Option three' }
  ];

  toggleButtonsMulti = [
    { id: `${multiSelectButtonGroupPrefix}__0`, label: 'Option 1' },
    { id: `${multiSelectButtonGroupPrefix}__1`, label: 'Option 2 is selected by default' },
    { id: `${multiSelectButtonGroupPrefix}__2`, label: 'Option 3' }
  ];

  @action
  toggle(key) {
    this[key] = !this[key];
  }

  @action
  onChange(optionId) {
    this.toggleIdSelected = optionId;
  }

  @action
  onChangeMulti(optionId) {
    this.toggleIdToSelectedMap = {
      ...this.toggleIdToSelectedMap,
      [optionId]: !this.toggleIdToSelectedMap[optionId]
    };
  }
}
```
