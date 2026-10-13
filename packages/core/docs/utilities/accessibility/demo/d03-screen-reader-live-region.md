---
order: 3
---

# Screen reader live region

<EuiText>

Using <strong>EuiScreenReaderLive</strong> to announce dynamic content, such as status changes based on user interaction.

The configurable <EuiCode>@role</EuiCode> and <EuiCode>@ariaLive</EuiCode> arguments default to <EuiCode>status</EuiCode> and <EuiCode>polite</EuiCode> respectively for non-intrusive but timely update announcements. When not using the default values, be sure to follow <a href='https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/ARIA_Live_Regions' target='_blank' rel='noopener noreferrer'>ARIA guidelines</a> for <EuiCode>role</EuiCode> to <EuiCode>aria-live</EuiCode> mapping.

Also consider other live region guidelines, such as that live regions must be present on initial page load, and should not be inside a conditional <EuiCode>&#123;&#123;#if&#125;&#125;</EuiCode> block.

</EuiText>

<EuiSpacer />

```hbs template
<EuiButton {{on 'click' this.startAnnouncements}}>
  Create screen reader announcement
</EuiButton>
<EuiSpacer />
<EuiText>
  <p>
    <em>Content announced by screen reader: </em>
    <EuiCode>{{this.screenReaderText}}</EuiCode>
  </p>
  <EuiScreenReaderLive>
    <p>{{this.screenReaderText}}</p>
  </EuiScreenReaderLive>
</EuiText>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class ScreenReaderLiveRegion extends Component {
  @tracked screenReaderText = 'You have no notifications.';

  @action
  startAnnouncements() {
    const randomNumber = Math.floor(Math.random() * 10) + 1;

    this.screenReaderText = `You have ${randomNumber} new notification${
      randomNumber > 1 ? 's' : ''
    }.`;
  }
}
```
