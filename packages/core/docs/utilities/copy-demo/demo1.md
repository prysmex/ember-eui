---
order: 1
---

<EuiText>
	<p>
	The <strong>EuiCopy</strong> component is a utility for copying text to clipboard. Wrap a function that returns a component. The first argument will be a <EuiCode>copy</EuiCode> function
  </p>
</EuiText>

```hbs template
<div>
  <EuiFormRow @label='Enter text that will be copied to clipboard'>
    <EuiFieldText
      @value={{this.copyText}}
      {{on 'input' (pick 'target.value' (set this 'copyText'))}}
    />
  </EuiFormRow>

  <EuiSpacer @size='m' />

  <EuiCopy @textToCopy={{this.copyText}} as |copy|>
    <EuiButton {{on 'click' copy}}>Click to copy input text</EuiButton>
  </EuiCopy>
</div>
```

```javascript component
import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class OutsideClickDetectorComponentDemo1 extends GlimmerComponent {
  @tracked copyText = 'I am the text that will be copied';
}
```
