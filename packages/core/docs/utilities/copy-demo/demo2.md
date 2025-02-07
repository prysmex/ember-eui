---
	order: 2
---

# Copy to clipboard function

<EuiText>
	<p>
	The function <EuiCode>copyToClipboard</EuiCode> allows you to copy text to the clipboard. It receives an argument of type <EuiCode>string</EuiCode>.
  </p>
</EuiText>

```hbs template
<EuiComment>
  <:username>
    Gusteau
  </:username>
  <:event>
    added a comment
  </:event>
  <:timestamp>
    on tuesday
  </:timestamp>
  <:actions>
    <EuiToolTip @content={{this.tooltipText}}>
      <:anchor>
        <EuiButtonIcon
          {{did-insert (set this 'buttonRef')}}
          aria-label='Copy text to clipboard'
          @color='text'
          @iconType='copy'
          @onClick={{this.onClick}}
          {{on 'click' this.onClick}}
          {{on 'blur' (set this 'isTextCopied' false)}}
        />
      </:anchor>
    </EuiToolTip>
  </:actions>
  <:body>
    <EuiText @size='s'>
      <p>{{this.text}}</p>
    </EuiText>
  </:body>
</EuiComment>
```

```javascript component
import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { copyToClipboard } from '@ember-eui/core/utils/copy-to-clipboard';

export default class OutsideClickDetectorComponentDemo1 extends GlimmerComponent {
  @tracked isTextCopied = false;
  buttonRef = null;

  text =
    'You must be imaginative, strong-hearted. You must try things that may not work, and you must not let anyone define your limits because of where you come from. Your only limit is your soul. What I say is true—anyone can cook… but only the fearless can be great.';

  get tooltipText() {
    return this.isTextCopied ? 'Text copied to clipboard' : 'Copy Text';
  }

  onClick = () => {
    this.buttonRef?.focus?.();
    copyToClipboard(this.text);
    this.isTextCopied = true;
  };
}
```
