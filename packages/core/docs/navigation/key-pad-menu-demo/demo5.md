---
order: 5
---

<EuiText>
	<p>
		For single selection (radio) items, you must pass a singular <EuiCode>name</EuiCode> prop to each item to ensure they are grouped properly. Also, if you would like to hide the visible <EuiCode>legend</EuiCode> in favor of an screen-reader only solution, you can pass <EuiCode>ariaLegend</EuiCode> instead of <EuiCode>legend</EuiCode>.
  </p>
</EuiText>

# Checkable Radio

```hbs template
<EuiKeyPadMenu @checkable={{hash ariaLegend='Single select as radios'}}>

  <EuiKeyPadMenuItem
    @checkable='single'
    @isSelected={{eq this.singleSelectedID this.keypadRadioId__1}}
    @id={{this.keypadRadioId__1}}
    @name={{this.radioGroupName}}
    @label='Radio one'
    @onChange={{this.setSingleSelectedID}}
  >
    <EuiIcon @type='faceHappy' @size='l' />
  </EuiKeyPadMenuItem>
  <EuiKeyPadMenuItem
    @checkable='single'
    @isSelected={{eq this.singleSelectedID this.keypadRadioId__2}}
    @id={{this.keypadRadioId__2}}
    @name={{this.radioGroupName}}
    @label='Radio two'
    @onChange={{this.setSingleSelectedID}}
  >
    <EuiIcon @type='faceNeutral' @size='l' />
  </EuiKeyPadMenuItem>
  <EuiKeyPadMenuItem
    @checkable='single'
    @id={{this.keypadRadioId__3}}
    @name={{this.radioGroupName}}
    @label='Disabled'
    @isDisabled={{true}}
    @onChange={{this.setSingleSelectedID}}
  >
    <EuiIcon @type='faceSad' @size='l' />
  </EuiKeyPadMenuItem>
</EuiKeyPadMenu>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class DemoSideNavComponent extends Component {
  @tracked singleSelectedID = false;

  radioGroupName = 'radioGroupDemo5';
  keypadRadioId__1 = 'keypaddemo51';
  keypadRadioId__2 = 'keypaddemo52';
  keypadRadioId__3 = 'keypaddemo53';

  setSingleSelectedID = (id) => {
    this.singleSelectedID = id;
  };
}
```
