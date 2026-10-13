---
order: 4
---

# Checkable

<EuiText>

**EuiKeyPadMenuItems** can also be rendered as checkbox or radio form controls using the `@checkable` argument. Pass in `"multi"` for checkboxes or `"single"` for radios.

To ensure the **EuiKeyPadMenu** renders the semantically appropriate HTML elements, you will need to pass in the `@checkable` argument as `true` or a hash that requires a `legend`. This will wrap the input group in a `<fieldset>` with a `<legend>`.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { fn, hash } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import { EuiIcon, EuiKeyPadMenu, EuiKeyPadMenuItem, EuiSpacer, EuiText } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked multiSelect1isSelected = true;
  @tracked multiSelect2isSelected = false;

  keypadMultiSelectButtonId__1 = 'keypadMultiSelectButton-first';
  keypadMultiSelectButtonId__2 = 'keypadMultiSelectButton-second';
  keypadMultiSelectButtonId__3 = 'keypadMultiSelectButton-third';

  radioGroupName = 'radioGroup-keypad-demo';
  keypadRadioButtonId__1 = 'keypadRadioButton-first';
  keypadRadioButtonId__2 = 'keypadRadioButton-second';
  keypadRadioButtonId__3 = 'keypadRadioButton-third';

  @tracked singleSelectedID = this.keypadRadioButtonId__1;

  @action
  toggleCheckbox(name) {
    this[name] = !this[name];
  }

  @action
  setSingleSelectedID(id) {
    this.singleSelectedID = id;
  }

  <template>
    <EuiKeyPadMenu @checkable={{hash legend="Multi select as checkboxes"}}>
      <EuiKeyPadMenuItem
        @checkable="multi"
        @isSelected={{this.multiSelect1isSelected}}
        @id={{this.keypadMultiSelectButtonId__1}}
        @label="Check one"
        @onChange={{fn this.toggleCheckbox "multiSelect1isSelected"}}
      >
        <EuiIcon @type="faceHappy" @size="l" />
      </EuiKeyPadMenuItem>
      <EuiKeyPadMenuItem
        @checkable="multi"
        @isSelected={{this.multiSelect2isSelected}}
        @id={{this.keypadMultiSelectButtonId__2}}
        @label="Check two"
        @onChange={{fn this.toggleCheckbox "multiSelect2isSelected"}}
      >
        <EuiIcon @type="faceNeutral" @size="l" />
      </EuiKeyPadMenuItem>
      <EuiKeyPadMenuItem
        @checkable="multi"
        @id={{this.keypadMultiSelectButtonId__3}}
        @label="Disabled"
        @isDisabled={{true}}
      >
        <EuiIcon @type="faceSad" @size="l" />
      </EuiKeyPadMenuItem>
    </EuiKeyPadMenu>

    <EuiSpacer />

    <EuiText>

    For single selection (radio) items, you must pass a singular `@name` argument to each item to ensure they are grouped properly. Also, if you would like to hide the visible `legend` in favor of a screen-reader only solution, you can pass `ariaLegend` instead of `legend`.

    </EuiText>

    <EuiSpacer />

    <EuiKeyPadMenu @checkable={{hash ariaLegend="Single select as radios"}}>
      <EuiKeyPadMenuItem
        @checkable="single"
        @name={{this.radioGroupName}}
        @id={{this.keypadRadioButtonId__1}}
        @label="Radio one"
        @onChange={{this.setSingleSelectedID}}
        @isSelected={{eq this.singleSelectedID this.keypadRadioButtonId__1}}
      >
        <EuiIcon @type="faceHappy" @size="l" />
      </EuiKeyPadMenuItem>
      <EuiKeyPadMenuItem
        @checkable="single"
        @name={{this.radioGroupName}}
        @id={{this.keypadRadioButtonId__2}}
        @label="Radio two"
        @onChange={{this.setSingleSelectedID}}
        @isSelected={{eq this.singleSelectedID this.keypadRadioButtonId__2}}
      >
        <EuiIcon @type="faceNeutral" @size="l" />
      </EuiKeyPadMenuItem>
      <EuiKeyPadMenuItem
        @checkable="single"
        @name={{this.radioGroupName}}
        @id={{this.keypadRadioButtonId__3}}
        @label="Disabled"
        @isDisabled={{true}}
      >
        <EuiIcon @type="faceSad" @size="l" />
      </EuiKeyPadMenuItem>
    </EuiKeyPadMenu>
  </template>
}
```
