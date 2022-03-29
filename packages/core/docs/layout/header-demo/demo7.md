---
order: 7
---

```hbs template
<EuiTitle @size='s'>
  Stacked headers
</EuiTitle>
<EuiSpacer />
<EuiText>
  Stacking multiple headers provides a great way to separate global navigation
  concerns. However, the
  <EuiCode>position="fixed"</EuiCode>
  option will not be aware of the number of headers. If you do need fixed
  <strong>and</strong>
  stacked headers, you will need to apply the SASS helper mixin and pass in the
  correct height to afford for.
</EuiText>
<EuiSpacer />
<EuiSwitch
  @label={{'Make header fixed position'}}
  @checked={{this.isFixedPosition}}
  @onChange={{set this 'isFixedPosition' (not this.isFixedPosition)}}
/>
<EuiSpacer />
<EuiHeader @position={{if this.isFixedPosition 'fixed'}} @theme='dark'>
  <EuiHeaderSection @side='left'>
    <EuiHeaderSectionItem @border='right'>
      <EuiHeaderLogo>Elastic</EuiHeaderLogo>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
  <EuiHeaderSection @side='right'>
    <EuiHeaderSectionItem>
      <EuiHeaderSectionItemButton>
        <EuiAvatar @name='John Doe' />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
</EuiHeader>
<EuiHeader @position={{if this.isFixedPosition 'fixed'}}>
  <EuiHeaderSection @side='left'>
    <EuiHeaderSectionItem @border='right'>
      <EuiHeaderSectionItemButton>
        <EuiAvatar
          @name='Planta Prysmex'
          @type='space'
          @initialLength={{2}}
          @size='s'
        />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
  <EuiHeaderSection @side='right'>
    <EuiHeaderSectionItem>
      <EuiHeaderSectionItemButton @notification={{true}}>
        <EuiIcon @type='cheer' />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
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
