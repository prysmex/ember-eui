---
order: 4
---

# Fixed header

<EuiText>

Most consumers need a header that does not scroll away with the page contents. You can set this display by applying the argument `@position="fixed"`. Multiple fixed headers will automatically stack underneath one another. No manual positioning is required.

If you're using `EuiPageTemplate`, a padding top will be automatically set based on the number of fixed headers on the page. Flyouts will also automatically account for and sit below fixed headers.

If you're using your own custom layout, or have custom UI that needs to sit below your fixed header(s), EUI provides a global CSS `var(--euiFixedHeadersOffset)` variable. You can use this variable anywhere, or even override it, to correctly offset any and all fixed header heights. Ember EUI also adds the class `euiBody--headerIsFixed` to the `<body>` and pads it by that offset.

</EuiText>

```gjs component
import { EuiSwitch, EuiSpacer, EuiHeader, EuiHeaderSection, EuiHeaderSectionItem, EuiHeaderLogo } from '@ember-eui/core/components';
import { eq } from 'ember-truth-helpers';
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

  <template>
    <EuiSwitch
      @label={{'Make header fixed position'}}
      @checked={{eq this.position 'fixed'}}
      @onChange={{this.setPosition}}
    />
    <EuiSpacer />
    <EuiHeader @position={{this.position}}>
      <EuiHeaderSection @side='left'>
        <EuiHeaderSectionItem>
          <EuiHeaderLogo @iconType="logoElastic">Elastic</EuiHeaderLogo>
        </EuiHeaderSectionItem>
      </EuiHeaderSection>
    </EuiHeader>
  </template>
}
```
