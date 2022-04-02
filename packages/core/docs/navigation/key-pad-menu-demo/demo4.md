---
order: 4
---

<EuiText>
	<p>
		<strong>EuiKeyPadMenuItems</strong> can also be rendered as checkbox or radio form controls using the <EuiCode>checkable</EuiCode> prop. Pass in <EuiCode>"multi"</EuiCode> for checkboxes or <EuiCode>"single"</EuiCode> for radios.
  </p>

  <p>
  To ensure the <strong>EuiKeyPadMenu</strong> renders the semantically appropriate HTML elements, you will need to pass in the <EuiCode>checkable</EuiCode> prop as <EuiCode>true</EuiCode> or an object that requires a <EuiCode>legend</EuiCode>. This will wrap the input group in a <EuiCode>fieldset</EuiCode> with a <EuiCode>legend</EuiCode>.
  </p>

</EuiText>

# Beta item

```hbs template
<EuiKeyPadMenu @checkable={{hash legend='Multi select as checkboxes'}}>

  <EuiKeyPadMenuItem
    @checkable='multi'
    @isSelected={{this.multiSelect1isSelected}}
    @id={{this.keypadMultiSelectButtonId__1}}
    @label='Check one'
    @onChange={{set this 'multiSelect1isSelected'}}
  >
    <EuiIcon @type='faceHappy' @size='l' />
  </EuiKeyPadMenuItem>
  <EuiKeyPadMenuItem
    @checkable='multi'
    @isSelected={{this.multiSelect2isSelected}}
    @id={{this.keypadMultiSelectButtonId__2}}
    @label='Check two'
    @onChange={{set this 'multiSelect2isSelected'}}
  >
    <EuiIcon @type='faceNeutral' @size='l' />
  </EuiKeyPadMenuItem>
  <EuiKeyPadMenuItem
    @checkable='multi'
    @id={{this.keypadMultiSelectButtonId__3}}
    @label='Disabled'
    @isDisabled={{true}}
  >
    <EuiIcon @type='faceSad' @size='l' />
  </EuiKeyPadMenuItem>
</EuiKeyPadMenu>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class DemoSideNavComponent extends Component {
  @tracked multiSelect1isSelected = false;
  @tracked multiSelect2isSelected = false;

  keypadMultiSelectButtonId__1 = 'keypaddemo41';
  keypadMultiSelectButtonId__2 = 'keypaddemo42';
  keypadMultiSelectButtonId__3 = 'keypaddemo43';
}
```
