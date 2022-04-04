---
order: 6
---

# Header notifications

<EuiText>
  To alert or notify users about the additional information they are receiving,
  use the <strong>EuiHeaderSectionItemButton</strong> <EuiCode>notification</EuiCode> prop. You can pass a node that
  will render inside a <strong>EuiBadgeNotification</strong> or pass <EuiCode>true</EuiCode> to render a simple dot.
  You can also animate the button by calling the <EuiCode>euiAnimate()</EuiCode> method on the
  <strong>EuiHeaderSectionItemButton</strong> <EuiCode>ref</EuiCode>.
</EuiText>

```hbs template
<EuiFlexGroup>
  <EuiFlexItem>
    <EuiButton {{on 'click' this.notify}}>
      Notify
    </EuiButton>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiButton {{on 'click' this.reset}}>
      Reset
    </EuiButton>
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiHeader @position={{if this.header1Fixed 'fixed'}}>
  <EuiHeaderSection @side='left'>
    <EuiHeaderSectionItem @border='right'>
      <EuiHeaderLogo>Elastic</EuiHeaderLogo>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
  <EuiHeaderSection @side='right'>
    <EuiHeaderSectionItem>
      <EuiHeaderSectionItemButton
        @notification={{if this.notificationNumber true false}}
        @notificationColor='accent'
        @ref={{set this 'bellRef'}}
      >
        <EuiIcon @type='bell' />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
    <EuiHeaderSectionItem>
      <EuiHeaderSectionItemButton
        @notification={{this.notificationNumber}}
        @notificationColor='accent'
        @ref={{set this 'cheerRef'}}
      >
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
  @tracked notificationNumber = 0;
  bellRef;
  cheerRef;

  @action
  animate() {
    this.bellRef?.euiAnimate();
    this.cheerRef?.euiAnimate();
  }

  @action
  notify() {
    this.notificationNumber += 1;
    this.animate();
  }

  @action
  reset() {
    this.notificationNumber = 0;
  }
}
```
