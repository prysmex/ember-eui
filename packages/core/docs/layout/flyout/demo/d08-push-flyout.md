---
order: 8
---

# Push flyout

<EuiText>
  <p>
    Another way to allow for continued interactions of the page content while a
    flyout is visible is to change the <EuiCode>@type</EuiCode> from
    <EuiCode>overlay</EuiCode> to <EuiCode>push</EuiCode>.
  </p>
</EuiText>

<EuiSpacer />

<EuiCallOut @title="Push flyouts require manual accessibility management" @color="warning" @iconType="warning">
  <p>
    Push flyouts do not use a focus trap, do not close on Escape keypress, do
    not inherit a dialog role, and do not include any of the default screen
    reader guidance that overlay flyouts contain out-of-the-box.
  </p>
  <p>
    Please be cautious when using push flyouts, and make sure you are managing
    your own focus and screen reader UX.
  </p>
</EuiCallOut>

<EuiSpacer />

<EuiText>
  <p>
    A pushed flyout still positions itself as <EuiCode>fixed</EuiCode>, but adds
    padding to the document's body element to accommodate for the flyout's
    width. Because this squishes the page content, the flyout changes back to
    <EuiCode>overlay</EuiCode> at smaller window widths. You can adjust this
    minimum breakpoint with <EuiCode>@pushMinBreakpoint</EuiCode>.
  </p>
  <h4>Relative positioning</h4>
  <p>
    Push flyouts automatically set global CSS variables that you can use to
    position other elements in your application relative to the flyout's width:
  </p>
  <ul>
    <li><EuiCode>--euiPushFlyoutOffsetInlineStart</EuiCode> (set when <EuiCode>@side="left"</EuiCode>)</li>
    <li><EuiCode>--euiPushFlyoutOffsetInlineEnd</EuiCode> (set when <EuiCode>@side="right"</EuiCode>)</li>
  </ul>
  <p>
    These variables are automatically updated when the flyout resizes and are
    removed when the flyout is closed.
  </p>
</EuiText>

<EuiCodeBlock @language="css" @isCopyable={{false}}>.custom-fixed-sidebar {
  /* Adjust sidebar position when left push flyout is open */
  inset-inline-start: var(--euiPushFlyoutOffsetInlineStart, 0);
}</EuiCodeBlock>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButton, EuiFlyout, EuiFlyoutBody, EuiFlyoutFooter, EuiFlyoutHeader, EuiText, EuiTitle } from '@ember-eui/core/components';

export default class FlyoutPushComponent extends Component {
  @tracked isFlyoutVisible = false;

  @action
  toggleFlyout() {
    this.isFlyoutVisible = !this.isFlyoutVisible;
  }

  @action
  closeFlyout() {
    this.isFlyoutVisible = false;
  }

  <template>
  <EuiButton {{on "click" this.toggleFlyout}}>
    Toggle pushed flyout
  </EuiButton>

  {{#if this.isFlyoutVisible}}
    <EuiFlyout
      @type="push"
      @size="s"
      @onClose={{this.closeFlyout}}
      aria-labelledby="pushedFlyoutTitle"
    >
      <EuiFlyoutHeader @hasBorder={{true}}>
        <EuiTitle @size="m" id="pushedFlyoutTitle">A pushed flyout</EuiTitle>
      </EuiFlyoutHeader>
      <EuiFlyoutBody>
        <EuiText>
          <p>
            A pushed flyout typically contains more information about a particular
            piece of data or complex form controls for editing.
          </p>
          <p>
            Also, it is good to include a close button in the footer for a larger
            hit target than the small close button provides.
          </p>
        </EuiText>
      </EuiFlyoutBody>
      <EuiFlyoutFooter>
        <EuiButton {{on "click" this.closeFlyout}}>Close</EuiButton>
      </EuiFlyoutFooter>
    </EuiFlyout>
  {{/if}}
  </template>
}
```
