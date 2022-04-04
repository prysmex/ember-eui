---
order: 3
---

# Fixed header

<EuiText>
  <p>
  Most consumers need a header that does not scroll away with the page contents. You can apply this display by applying the property <EuiCode @language="jsx">position="fixed"</EuiCode>. This will also add a class of <EuiCode>.euiBody--headerIsFixed</EuiCode> to the window body.
  </p>
  <p>
  You will then need to apply your own padding to this body class to afford for the header height. EUI supplies a helper mixin that also accounts for this height in flyouts and the collapsible nav.
  </p>
</EuiText>

```hbs template
<EuiSwitch
  @label={{'Make header fixed position'}}
  @checked={{eq this.position 'fixed'}}
  @onChange={{this.setPosition}}
/>
<EuiSpacer />
<EuiHeader @position={{this.position}}>
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
  @tracked position = 'static';

  setPosition = (e) => {
    if (e.target.checked) {
      this.position = 'fixed';
    } else {
      this.position = 'static';
    }
  };
}
```
