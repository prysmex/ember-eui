---
order: 2
---

<EuiText>
	<p>
		The <strong>EuiKeyPadMenuItem</strong> component can act both as an anchor as well as a button by specifying <EuiCode>href</EuiCode> or <EuiCode>onClick</EuiCode> respectively. It requires a text-based <EuiCode>label</EuiCode> and using the block for declaring the icon. This is the most flexible way for handling the customization of the icon itself.
  </p>

  <p>
  When using the <EuiCode>isSelected</EuiCode> prop to create a toggle button, you must supply both the <EuiCode>true</EuiCode> and <EuiCode>false</EuiCode> states explicitly to ensure the attribute is added for both states.
  </p>

</EuiText>

# Menu item

```hbs template
<EuiKeyPadMenu>
  <li>
    <EuiKeyPadMenuItem
      @label='Button'
      @isSelected={{eq this.selectedID this.keypadButtonId__1}}
      @id={{this.keypadButtonId__1}}
      {{on 'click' (set this 'selectedID' this.keypadButtonId__1)}}
    >
      <EuiIcon @type='grid' @size='l' />
    </EuiKeyPadMenuItem>
  </li>
  <li>
    <EuiKeyPadMenuItem
      @label='Button'
      @isSelected={{eq this.selectedID this.keypadButtonId__2}}
      @id={{this.keypadButtonId__2}}
      {{on 'click' (set this 'selectedID' this.keypadButtonId__2)}}
    >
      <EuiIcon @type='grid' @size='l' />
    </EuiKeyPadMenuItem>
  </li>
  <li>
    <EuiKeyPadMenuItem
      @label='Disabled'
      @id={{this.keypadButtonId__3}}
      @isDisabled={{true}}
    >
      <EuiIcon @type='grid' @size='l' />
    </EuiKeyPadMenuItem>
  </li>
  <li>
    <EuiKeyPadMenuItem
      @label='Link'
      @isSelected={{eq this.selectedID this.keypadButtonId__4}}
      @id={{this.keypadButtonId__4}}
      @href='#'
      {{on 'click' (set this 'selectedID' this.keypadButtonId__4)}}
    >
      <EuiIcon @type='link' @size='l' />
    </EuiKeyPadMenuItem>
  </li>
  <li>
    <EuiKeyPadMenuItem
      @label='Button'
      @isSelected={{eq this.selectedID this.keypadButtonId__5}}
      @id={{this.keypadButtonId__5}}
      {{on 'click' (set this 'selectedID' this.keypadButtonId__5)}}
    >
      <EuiIcon @type='link' @size='l' />
    </EuiKeyPadMenuItem>
  </li>
  <li>
    <EuiKeyPadMenuItem
      @label='Button'
      @isSelected={{eq this.selectedID this.keypadButtonId__6}}
      @id={{this.keypadButtonId__6}}
      {{on 'click' (set this 'selectedID' this.keypadButtonId__6)}}
    >
      <EuiIcon @type='link' @size='l' />
    </EuiKeyPadMenuItem>
  </li>
</EuiKeyPadMenu>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class DemoSideNavComponent extends Component {
  @tracked selectedID;
  keypadButtonId__1 = 'keypad1';
  keypadButtonId__2 = 'keypad2';
  keypadButtonId__3 = 'keypad3';
  keypadButtonId__4 = 'keypad4';
  keypadButtonId__5 = 'keypad5';
  keypadButtonId__6 = 'keypad6';

  constructor() {
    super(...arguments);
    this.selectedID = this.keypadButtonId__6;
  }
}
```
