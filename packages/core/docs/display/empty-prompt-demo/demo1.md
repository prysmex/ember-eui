---
order: 1
---

<EuiText>
 While no one piece of content is required, each <strong>EuiEmptyPrompt</strong> should contain at least a <EuiCode>title</EuiCode> (wrapped in an HTML heading element) and/or a <EuiCode>description</EuiCode>. They usually contain one or more <EuiCode>actions</EuiCode> that promotes the primary call-to-actions. You can also provide a <EuiCode>footer</EuiCode> to direct users towards making informed decisions.
</EuiText>

```hbs template
<EuiEmptyPrompt
  @iconType="logoSecurity"
  @title="Start adding cases"
  @body="There are no cases to display. Add a new case or change your filter settings."
  @actions={{array (component "eui-button-title" title="Add a case")}}
>
  <:footer>
    <EuiTitle @size="xxs">
      <h3>Want to learn more?</h3>
    </EuiTitle>
    <EuiLink href="#" target="_blank">
      Read documentation
    </EuiLink>
  </:footer>
</EuiEmptyPrompt>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoIconComponent extends Component {
  tabs = [
    { label: 'Tab 1', isSelected: true },
    {
      label: 'Tab 2',
      onClick: this.setShowBottomBar
    }
  ];
  @tracked showing = false;

  @action
  setSHowBottomBar() {
    this.showing = !this.showing;
  }
}
```
