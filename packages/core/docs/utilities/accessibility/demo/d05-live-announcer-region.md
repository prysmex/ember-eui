---
order: 5
---

# Live announcer region (beta)

<EuiText>

<strong>EuiLiveAnnouncer</strong> is a new, experimental alternative to <strong>EuiScreenReaderLive</strong> for screen reader live region announcements. Its API and behavior may change based on feedback and testing.

Both are designed for the <strong>same use cases</strong>: to announce dynamic content, such as notifications or status changes based on user interaction. The main drawback for live regions is that they must be present on initial page load before reading content updates. <strong>EuiLiveAnnouncer</strong> addresses this by updating the content after the initial render to ensure an announcement is made when mounting a component.

Same as for <strong>EuiScreenReaderLive</strong>, <strong>EuiLiveAnnouncer</strong> supports configurable <EuiCode>@role</EuiCode> and <EuiCode>@ariaLive</EuiCode> arguments which default to <EuiCode>status</EuiCode> and <EuiCode>polite</EuiCode> respectively. If you're not using the default values, be sure to follow ARIA guidelines for <EuiCode>role</EuiCode> to <EuiCode>aria-live</EuiCode> mapping.

### Main difference

<ul>
<li><strong>EuiLiveAnnouncer</strong> will announce the message <strong>when the component mounts</strong> (e.g., when it first appears in the DOM), as well as when the message changes.</li>
<li><strong>EuiScreenReaderLive</strong> will only announce when the message changes, and will not announce the initial message on mount.</li>
</ul>

This means <strong>EuiLiveAnnouncer</strong> is especially useful for scenarios where you want to ensure an announcement is made immediately when a component is mounted, e.g. showing a notification or alert based on user interaction.

An additional difference is that <strong>EuiLiveAnnouncer</strong> can clear its message after a configurable timeout via <EuiCode>@clearAfterMs</EuiCode>, which prevents stale announcements and duplicated DOM content for screen reader users. Screen readers will continue reading the message even if it was already cleared.

</EuiText>

<EuiSpacer />

```hbs template
<EuiFlexGroup @direction='column' @gutterSize='m' style='max-width: 300px'>
  <EuiFlexItem>
    <EuiButton {{on 'click' this.toggleShown}}>
      Toggle announcement
    </EuiButton>
  </EuiFlexItem>

  <EuiFlexItem>
    {{#if this.isShown}}
      <EuiButton {{on 'click' this.updateAnnouncement}}>
        Update announcement
      </EuiButton>
      <EuiSpacer @size='m' />
      <EuiCodeBlock>{{this.announcement}}</EuiCodeBlock>
      <EuiLiveAnnouncer>
        {{this.announcement}}
      </EuiLiveAnnouncer>
    {{/if}}
  </EuiFlexItem>
</EuiFlexGroup>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class LiveAnnouncerRegion extends Component {
  @tracked announcement = 'No notifications.';
  @tracked isShown = false;

  @action
  toggleShown() {
    this.isShown = !this.isShown;
  }

  @action
  updateAnnouncement() {
    this.announcement = `You have ${Math.floor(
      Math.random() * 1000
    )} new notifications.`;
  }
}
```
