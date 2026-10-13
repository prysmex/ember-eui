---
order: 1
---

# Rendered inner text

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { registerDestructor } from '@ember/destroyable';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import {
  EuiBadge,
  EuiCode,
  EuiHighlight,
  EuiHorizontalRule,
  EuiInnerText,
  EuiPanel,
  EuiSpacer,
  EuiText
} from '@ember-eui/core/components';

export default class InnerTextDemo extends Component {
  @tracked thing = 'First';

  constructor(owner, args) {
    super(owner, args);
    const timer = setInterval(() => {
      this.thing = this.thing === 'First' ? 'Second' : 'First';
    }, 5000);
    registerDestructor(this, () => clearInterval(timer));
  }

  <template>
    <EuiText @size='s'>
      <p><strong>Example:</strong></p>
      <EuiInnerText as |ref innerText|>
        <EuiPanel @paddingSize='s'>
          <span {{didInsert ref}} title={{innerText}}>Simple string content</span>
        </EuiPanel>
        <EuiSpacer />
        <p><strong>Output:</strong> <EuiCode>{{innerText}}</EuiCode></p>
      </EuiInnerText>

      <EuiHorizontalRule @margin='xl' />

      <p><strong>Example with complex children:</strong></p>
      <EuiInnerText as |ref innerText|>
        <EuiPanel @paddingSize='s'>
          <span {{didInsert ref}} title={{innerText}}>
            <EuiHighlight @search='content'>EuiHighlight content</EuiHighlight>
            <EuiBadge>with EuiBadge</EuiBadge>
          </span>
        </EuiPanel>
        <EuiSpacer />
        <p><strong>Output:</strong> <EuiCode>{{innerText}}</EuiCode></p>
      </EuiInnerText>

      <EuiHorizontalRule @margin='xl' />

      <p><strong>Example with updating content (changes every 5 seconds):</strong></p>
      <EuiInnerText as |ref innerText|>
        <EuiPanel @paddingSize='s'>
          <span {{didInsert ref}} title={{innerText}}>{{this.thing}}</span>
        </EuiPanel>
        <EuiSpacer />
        <p><strong>Output:</strong> <EuiCode>{{innerText}}</EuiCode></p>
      </EuiInnerText>
    </EuiText>
  </template>
}
```
