---
order: 17
---

# Container-relative positioning

<EuiText>

By default flyouts are fixed to the viewport. `@container` scopes a flyout
to a region of the page instead (an element, a function returning one, or a
CSS selector): the flyout stays in `document.body` with `position: fixed`,
but its position, size and mask follow the container's bounds, so it does
not cover application chrome such as a side navigation. Push flyouts pad the
container instead of `<body>`, and resizing and push breakpoints use its
width. The container is not otherwise modified.

Flyouts nested in a flyout's block inherit its container;
`@container={{null}}` uses the viewport again (and puts the flyout above
fixed headers).

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';
import { EuiButton, EuiFlyout, EuiFlyoutBody, EuiFlyoutHeader, EuiPanel, EuiText, EuiTitle } from '@ember-eui/core/components';

export default class FlyoutContainerComponent extends Component {
  @tracked isOpen = false;
  @tracked area = null;

  registerArea = modifier((element) => {
    this.area = element;
  });

  @action open() {
    this.isOpen = true;
  }

  @action close() {
    this.isOpen = false;
  }

  <template>
  <EuiPanel @hasBorder={{true}} @paddingSize="l" style="min-height: 320px;" {{this.registerArea}}>
    <EuiButton {{on "click" this.open}}>Open flyout in this panel</EuiButton>
  </EuiPanel>

  {{#if this.isOpen}}
    <EuiFlyout @container={{this.area}} @size="m" @onClose={{this.close}} aria-labelledby="containerFlyoutTitle">
      <EuiFlyoutHeader @hasBorder={{true}}>
        <EuiTitle @size="m"><h2 id="containerFlyoutTitle">Scoped flyout</h2></EuiTitle>
      </EuiFlyoutHeader>
      <EuiFlyoutBody>
        <EuiText><p>This flyout and its mask stay within the panel.</p></EuiText>
      </EuiFlyoutBody>
    </EuiFlyout>
  {{/if}}
  </template>
}
```
