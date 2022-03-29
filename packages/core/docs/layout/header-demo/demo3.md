---
order: 3
---

# Fixed header

<EuiText>
  Most consumers need a header that does not scroll away with the page contents.
  You can apply this display by applying the property <EuiCode>position="fixed"</EuiCode>. This
  will also add a class of <EuiCode>.euiBody--headerIsFixed</EuiCode> to the window body. <br />
  You will then need to apply your own padding to this body class to afford for the
  header height. EUI supplies a helper mixin that also accounts for this height
  in flyouts and the collapsible nav. Simply add <EuiCode>@include euiHeaderAffordForFixed;</EuiCode> anywhere in your SASS.
</EuiText>

```hbs template
<EuiButtonEmpty {{on "click" (fn this.toggleHeaderPosition "header1Fixed")}}>
  Toggle Header 1
</EuiButtonEmpty>
<EuiSpacer />
<EuiHeader @position={{if this.header1Fixed "fixed"}}>
  <EuiHeaderSection @side='left'>
    <EuiHeaderSectionItem @border='right'>
      <EuiHeaderLogo>Elastic</EuiHeaderLogo>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
</EuiHeader>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoHeaderComponent extends Component {
  @tracked header1Fixed = false;

  @action
  toggleHeaderPosition(header) {
    this[header] = !this[header];
  }
}
```
