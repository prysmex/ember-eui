---
order: 7
---

# Header notifications

<EuiText>

To alert or notify users about the additional information they are receiving, use the `EuiHeaderSectionItemButton` `@notification` argument. You can pass a node that will render inside a `EuiBadgeNotification` or pass `true` to render a simple dot. You can also animate the button by calling the `euiAnimate()` method that `@ref` hands you, in place of upstream's `ref`.

</EuiText>

```gjs component
import { EuiFlexGroup, EuiFlexItem, EuiButton, EuiSpacer, EuiHeader, EuiHeaderSection, EuiHeaderSectionItem, EuiHeaderLogo, EuiHeaderSectionItemButton, EuiIcon } from '@ember-eui/core/components';
import { on } from '@ember/modifier';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class HeaderNotificationsDemo extends Component {
  @tracked showNotification = false;
  @tracked notificationsNumber = 0;
  bellRef;
  cheerRef;

  get ariaLabel() {
    return `News feed: ${this.showNotification ? 'Updates available' : 'No updates'}`;
  }

  get notificationBadge() {
    return this.showNotification && this.notificationsNumber;
  }

  @action
  setBellRef(api) {
    this.bellRef = api;
  }

  @action
  setCheerRef(api) {
    this.cheerRef = api;
  }

  @action
  notify() {
    if (!this.showNotification) {
      this.notificationsNumber = 1;
      this.showNotification = true;
    } else {
      this.notificationsNumber += 1;
    }

    // upstream exposes both animations through one `euiAnimate`
    this.bellRef?.euiAnimate();
    this.cheerRef?.euiAnimate();
  }

  @action
  reset() {
    this.showNotification = false;
    this.notificationsNumber = 0;
  }

  <template>
    <EuiFlexGroup @responsive={{false}} @alignItems="center" @gutterSize="m">
      <EuiFlexItem @grow={{false}}>
        <EuiButton @size="s" {{on "click" this.notify}}>
          Notify &amp; animate
        </EuiButton>
      </EuiFlexItem>

      <EuiFlexItem @grow={{false}}>
        <EuiButton @size="s" @color="warning" {{on "click" this.reset}}>
          Reset
        </EuiButton>
      </EuiFlexItem>
    </EuiFlexGroup>

    <EuiSpacer />

    <EuiHeader>
      <EuiHeaderSection>
        <EuiHeaderSectionItem>
          <EuiHeaderLogo @iconType="logoElastic">Elastic</EuiHeaderLogo>
        </EuiHeaderSectionItem>
      </EuiHeaderSection>
      <EuiHeaderSection @side="right">
        <EuiHeaderSectionItem>
          <EuiHeaderSectionItemButton
            aria-label={{this.ariaLabel}}
            @notification={{this.showNotification}}
            @ref={{this.setBellRef}}
          >
            <EuiIcon @type="bell" />
          </EuiHeaderSectionItemButton>
        </EuiHeaderSectionItem>
        <EuiHeaderSectionItem>
          <EuiHeaderSectionItemButton
            aria-label={{this.ariaLabel}}
            @notification={{this.notificationBadge}}
            @ref={{this.setCheerRef}}
          >
            <EuiIcon @type="popper" />
          </EuiHeaderSectionItemButton>
        </EuiHeaderSectionItem>
      </EuiHeaderSection>
    </EuiHeader>
  </template>
}
```
