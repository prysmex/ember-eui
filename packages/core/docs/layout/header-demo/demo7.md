---
order: 7
---

```hbs template
<EuiTitle @size='s'>
  Header notifications
</EuiTitle>
<EuiSpacer />
<EuiText>
  To alert or notify users about the additional information they are receiving,
  use the <strong>EuiHeaderSectionItemButton</strong> <EuiCode>notification</EuiCode> prop. You can pass a node that
  will render inside a <strong>EuiBadgeNotification</strong> or pass <EuiCode>true</EuiCode> to render a simple dot.
  You can also animate the button by calling the <EuiCode>euiAnimate()</EuiCode> method on the
  <strong>EuiHeaderSectionItemButton</strong> <EuiCode>ref</EuiCode>.
</EuiText>
<EuiSpacer />
<EuiButton {{on 'click' this.notify}}>
  Notify
</EuiButton>
<EuiButton {{on 'click' this.reset}}>
  Reset
</EuiButton>
<EuiSpacer />
<EuiHeader @position={{if this.header1Fixed 'fixed'}}>
  <EuiHeaderSection @side='left'>
    <EuiHeaderSectionItem @border='right'>
      <EuiHeaderLogo>Elastic</EuiHeaderLogo>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
  <EuiHeaderSection @side='right'>
    <EuiHeaderSectionItemButton  @notification={{if this.notificationNumber true false}} @notificationColor='accent'>
        <EuiIcon @type='bell' />
      </EuiHeaderSectionItemButton>
      <EuiHeaderSectionItemButton @notification={{this.notificationNumber}} @notificationColor='accent'>
        <EuiIcon @type='cheer' />
      </EuiHeaderSectionItemButton>
  </EuiHeaderSection>
</EuiHeader>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoHeaderComponent extends Component {
  @tracked notificationNumber = 0;

  @action
  notify() {
    this.notificationNumber += 1;
    // headerUpdatesRef.current?.euiAnimate();
  }

  @action
  reset() {
    this.notificationNumber = 0;
  }
}
```