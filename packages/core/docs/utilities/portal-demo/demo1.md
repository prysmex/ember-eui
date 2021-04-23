---
order: 1
---

# Demo

```hbs template
<EuiTitle>
Portal
</EuiTitle>
<EuiText>
	EuiPortal allows you to append its contained children onto the document body. It is useful for moving fixed elements like modals, tooltips or toasts when you are worried about a z-index or overflow conflict.
</EuiText>
<EuiSpacer @size="l"/>
<EuiButton
  {{on "click" (set this "showPortal" (not this.showPortal))}}
>
	Toggle portal
</EuiButton>

{{#if this.showPortal}}
	<EuiPortal>
		<EuiBottomBar>
			<p>This element is appended to the body in the DOM if you inspect</p>
		</EuiBottomBar>
	</EuiPortal>
{{/if}}
```

```javascript component
import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class OutsideClickDetectorComponentDemo1 extends GlimmerComponent {
  @tracked showPortal = false;
}
```
