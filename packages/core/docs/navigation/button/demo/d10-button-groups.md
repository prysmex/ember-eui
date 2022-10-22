---
order: 10
---

# Button groups

```hbs template
<EuiButtonGroup
  @legend='This is a basic group'
  @options={{this.toggleButtons}}
  @idSelected={{this.toggleIdSelected}}
  @onChange={{set this 'toggleIdSelected'}}
/>
<EuiSpacer @size='m' />
<EuiTitle @size='xxs' @tagName='h3'>
  Primary &amp; multi select
</EuiTitle>
<EuiSpacer @size='s' />
<EuiButtonGroup
  @legend='This is a primary group'
  @options={{this.toggleButtonsMulti}}
  @idToSelectedMap={{this.toggleIdToSelectedMap}}
  @onChange={{this.onChangeMulti}}
  @color='primary'
  @type='multi'
/>
<EuiSpacer @size='m' />
<EuiTitle @size='xxs' @tagName='h3'>
  Disabled &amp; full width
</EuiTitle>
<EuiSpacer @size='s' />
<EuiButtonGroup
  @legend='This is a disabled group'
  @options={{this.toggleButtonsDisabled}}
  @idSelected={{this.toggleIdDisabled}}
  @onChange={{set this 'toggleIdDisabled'}}
  @buttonSize='m'
  @isDisabled={{true}}
  @isFullWidth={{true}}
/>
```

```js component
import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import { tracked } from '@glimmer/tracking';

const basicButtonGroupPrefix = guidFor({});
const multiSelectButtonGroupPrefix = guidFor({});
const disabledButtonGroupPrefix = guidFor({});
export default class extends Component {
  @tracked toggleIdSelected = `${basicButtonGroupPrefix}__1`;
  @tracked toggleIdDisabled = `${disabledButtonGroupPrefix}__1`;
  @tracked toggleIdToSelectedMap = {
    [`${multiSelectButtonGroupPrefix}__1`]: true
  };

  toggleButtons = [
    {
      id: `${basicButtonGroupPrefix}__0`,
      label: 'Option one'
    },
    {
      id: `${basicButtonGroupPrefix}__1`,
      label: 'Option two is selected by default'
    },
    {
      id: `${basicButtonGroupPrefix}__2`,
      label: 'Option three'
    }
  ];

  toggleButtonsDisabled = [
    {
      id: `${disabledButtonGroupPrefix}__0`,
      label: 'Option one'
    },
    {
      id: `${disabledButtonGroupPrefix}__1`,
      label: 'Option two is selected by default'
    },
    {
      id: `${disabledButtonGroupPrefix}__2`,
      label: 'Option three'
    }
  ];

  toggleButtonsMulti = [
    {
      id: `${multiSelectButtonGroupPrefix}__0`,
      label: 'Option one'
    },
    {
      id: `${multiSelectButtonGroupPrefix}__1`,
      label: 'Option two is selected by default'
    },
    {
      id: `${multiSelectButtonGroupPrefix}__2`,
      label: 'Option three'
    }
  ];

  onChangeMulti = (optionId) => {
    const newToggleIdToSelectedMap = {
      ...this.toggleIdToSelectedMap,
      ...{
        [optionId]: !this.toggleIdToSelectedMap[optionId]
      }
    };
    this.toggleIdToSelectedMap = newToggleIdToSelectedMap;
  };
}
```
