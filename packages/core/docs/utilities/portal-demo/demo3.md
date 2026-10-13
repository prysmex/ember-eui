---
order: 3
---

# A custom flyout

<EuiText>

Custom flyouts should only be implemented if your design diverges a lot from <strong>EuiFlyout</strong>. You need to implement accessibility features, which can be challenging.

<strong>Here are some accessibility considerations you should keep in mind when implementing a custom flyout.</strong>

<ul>
<li>If you use an <strong>EuiOverlayMask</strong>, it should be dismissed when clicked outside: pass a method to close the flyout to its <EuiCode>@onClick</EuiCode>. (Upstream also nests an <strong>EuiFocusTrap</strong> to keep keyboard focus inside the flyout; Ember EUI doesn't have one.)</li>
<li>When pressing the ESC key your flyout should close. Listen for the <EuiCode>keydown</EuiCode> event.</li>
<li>Pass an ID to the first heading in the flyout.</li>
<li>Pass to your <strong>EuiPanel</strong> <EuiCode>aria-labelledby</EuiCode> with that ID to announce the flyout to screen readers.</li>
</ul>

You should also take into account some design considerations:

<ul>
<li>Use an <strong>EuiPanel</strong> for the background.</li>
<li>A flyout should always have a close button on the right top corner. This gives a visual clue that the flyout can be closed.</li>
<li>For writing CSS consider using our theme tokens.</li>
</ul>

In the following demo, you can see how to create your own flyout with these accessibility and design features:

</EuiText>

<EuiSpacer />

```hbs template
<div>
  <EuiEmptyPrompt
    @color='subdued'
    @iconType='logoObservability'
    @iconColor='default'
    @titleSize='xs'
  >
    <:content>
      <EuiTitle @size='xs'><h2>Observe my data</h2></EuiTitle>
      <EuiSpacer @size='m' />
      <EuiText @size='s' @color='subdued'>
        <p>
          Choose one of our many integrations to bring your data in, and start
          visualizing it.
        </p>
      </EuiText>
      <EuiSpacer @size='m' />
      <EuiButton {{on 'click' this.toggleCustomFlyout}}>View guide</EuiButton>
    </:content>
  </EuiEmptyPrompt>

  {{#if this.isCustomFlyoutVisible}}
    <EuiPortal>
      <EuiOverlayMask @onClick={{this.closeCustomFlyout}}>
        <EuiPanel
          aria-labelledby='customFlyoutTitle'
          role='dialog'
          @paddingSize='l'
          style='position: fixed; max-inline-size: 480px; inset-inline-end: 24px; inset-block-start: 24px; block-size: calc(100% - 48px); display: flex; flex-direction: column; justify-content: space-between;'
        >
          <div style='flex-grow: 0;'>
            <EuiSpacer @size='s' />
            <EuiTitle @size='m'>
              <h2 id='customFlyoutTitle'>Let's get started!</h2>
            </EuiTitle>
            <div style='position: absolute; inset-block-start: 16px; inset-inline-end: 16px;'>
              <EuiToolTip @content='Close modal'>
                <EuiButtonIcon
                  @iconType='cross'
                  @color='text'
                  aria-label='Close modal'
                  {{on 'click' this.closeCustomFlyout}}
                  {{on 'keydown' this.onKeyDown}}
                />
              </EuiToolTip>
            </div>
            <EuiHorizontalRule />
          </div>

          <div style='flex-grow: 1; overflow-y: auto;'>
            <EuiText @size='s'>
              <p>
                Elastic Observability provides a unified view into the health
                and performance of your entire digital ecosystem. With easy
                ingest of multiple kinds of data via pre-built collectors for
                hundreds of data sources.
              </p>
              <EuiHorizontalRule />
              <ol style='margin-inline-start: 0;'>
                <li style='list-style-type: none;'>
                  <h3>Step 1</h3>
                  <p>Select an ingestion method</p>
                  <EuiHorizontalRule />
                </li>
                <li style='list-style-type: none;'>
                  <EuiTextColor @color='subdued'>
                    <h3>Step 2</h3>
                    <p>Select an ingestion method</p>
                  </EuiTextColor>
                  <EuiHorizontalRule />
                </li>
                <li style='list-style-type: none;'>
                  <EuiTextColor @color='subdued'>
                    <h3>Step 3</h3>
                    <p>Select an ingestion method</p>
                  </EuiTextColor>
                  <EuiHorizontalRule />
                </li>
              </ol>
            </EuiText>
          </div>

          <div style='flex-grow: 0;'>
            <EuiText @textAlign='center' @color='subdued' @size='s'>
              <EuiButtonEmpty @size='s' {{on 'click' this.closeCustomFlyout}}>
                Exit setup guide
              </EuiButtonEmpty>
              <EuiSpacer @size='s' />
              <p>
                How's onboarding? We'd love your
                <EuiLink @href='#'>feedback</EuiLink>.
              </p>
            </EuiText>
          </div>
        </EuiPanel>
      </EuiOverlayMask>
    </EuiPortal>
  {{/if}}
</div>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class CustomFlyoutDemo extends Component {
  @tracked isCustomFlyoutVisible = false;

  @action
  toggleCustomFlyout() {
    this.isCustomFlyoutVisible = !this.isCustomFlyoutVisible;
  }

  @action
  closeCustomFlyout() {
    this.isCustomFlyoutVisible = false;
  }

  /** ESC key closes the custom flyout */
  @action
  onKeyDown(event) {
    if (event.key === 'Escape') {
      event.preventDefault();
      event.stopPropagation();
      this.closeCustomFlyout();
    }
  }
}
```
