---
order: 3
---

# Header links

<EuiText>
  <p>
    In addition to the components mentioned prior, which lend themselves to more application style navigation patterns, <strong>EuiHeaderLinks</strong> and <strong>EuiHeaderLink</strong> supply the ability to inline a list of navigational or menu style links.
  </p>
  <p>
    <strong>EuiHeaderLinks</strong> comes with responsive functionality built-in which will convert the inline list of links to a popover list triggered by a <strong>EuiHeaderSectionItemButton</strong>. You can adjust at which breakpoints to switch to the popover display by passing your own array of named breakpoints to <EuiCode>popoverBreakpoints</EuiCode>.
  </p>
</EuiText>

```hbs template
<EuiHeader>
  <EuiHeaderSectionItem @border='right'>
    <EuiHeaderLogo>Elastic</EuiHeaderLogo>
  </EuiHeaderSectionItem>

  <EuiHeaderSectionItem>
    <EuiHeaderLinks aria-label='App navigation links example'>
      <EuiHeaderLink @isActive={{true}}>Docs</EuiHeaderLink>

      <EuiHeaderLink>Code</EuiHeaderLink>

      <EuiHeaderLink @iconType='help'>Help</EuiHeaderLink>
    </EuiHeaderLinks>
  </EuiHeaderSectionItem>
</EuiHeader>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoHeaderComponent extends Component {
  @tracked isFixedPosition = false;
}
```
