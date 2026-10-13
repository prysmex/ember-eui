---
order: 2
---

# Menu item

<EuiText>

The **EuiKeyPadMenuItem** component can act both as an anchor as well as a button by specifying `@href` or an `{{on "click"}}` modifier respectively. It requires a text-based `@label` and uses its block for declaring the [icon](/docs/core/docs/display/icons). This is the most flexible way for handling the customization of the icon itself.

When using the `@isSelected` argument to create a toggle button, you must supply both the `true` and `false` states explicitly to ensure the attribute is added for both states.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import { EuiIcon, EuiKeyPadMenu, EuiKeyPadMenuItem } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  keypadButtonId__1 = 'keypadButton-first';
  keypadButtonId__2 = 'keypadButton-second';
  keypadButtonId__3 = 'keypadButton-third';
  keypadButtonId__4 = 'keypadButton-fourth';
  keypadButtonId__5 = 'keypadButton-fifth';
  keypadButtonId__6 = 'keypadButton-sixth';

  @tracked selectedID = this.keypadButtonId__6;

  @action
  select(id, event) {
    // the links only demonstrate the style, don't navigate away
    event.preventDefault();
    this.selectedID = id;
  }

  <template>
    <EuiKeyPadMenu as |Key|>
      <Key>
        <EuiKeyPadMenuItem
          @id={{this.keypadButtonId__1}}
          @label="Button"
          @isSelected={{eq this.selectedID this.keypadButtonId__1}}
          {{on "click" (fn this.select this.keypadButtonId__1)}}
        >
          <EuiIcon @type="grid" @size="l" />
        </EuiKeyPadMenuItem>
      </Key>
      <Key>
        <EuiKeyPadMenuItem
          @id={{this.keypadButtonId__2}}
          @label="Button"
          @isSelected={{eq this.selectedID this.keypadButtonId__2}}
          {{on "click" (fn this.select this.keypadButtonId__2)}}
        >
          <EuiIcon @type="grid" @size="l" />
        </EuiKeyPadMenuItem>
      </Key>
      <Key>
        <EuiKeyPadMenuItem @id={{this.keypadButtonId__3}} @label="Disabled" @isDisabled={{true}}>
          <EuiIcon @type="grid" @size="l" />
        </EuiKeyPadMenuItem>
      </Key>
      <Key>
        <EuiKeyPadMenuItem
          @id={{this.keypadButtonId__4}}
          @label="Link"
          @href="#/navigation/key-pad-menu"
          @isSelected={{eq this.selectedID this.keypadButtonId__4}}
          {{on "click" (fn this.select this.keypadButtonId__4)}}
        >
          <EuiIcon @type="link" @size="l" />
        </EuiKeyPadMenuItem>
      </Key>
      <Key>
        <EuiKeyPadMenuItem
          @id={{this.keypadButtonId__5}}
          @label="Link"
          @href="#/navigation/key-pad-menu"
          @isSelected={{eq this.selectedID this.keypadButtonId__5}}
          {{on "click" (fn this.select this.keypadButtonId__5)}}
        >
          <EuiIcon @type="link" @size="l" />
        </EuiKeyPadMenuItem>
      </Key>
      <Key>
        <EuiKeyPadMenuItem
          @id={{this.keypadButtonId__6}}
          @label="Disabled"
          @isDisabled={{true}}
          @isSelected={{eq this.selectedID this.keypadButtonId__6}}
        >
          <EuiIcon @type="link" @size="l" />
        </EuiKeyPadMenuItem>
      </Key>
    </EuiKeyPadMenu>
  </template>
}
```
