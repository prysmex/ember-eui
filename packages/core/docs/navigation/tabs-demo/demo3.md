---
order: 3
---

# Bottom border

<EuiText>

The `@bottomBorder` helps to separate the tab group from the content below and is on by default. However, some components like [flyouts](/docs/core/docs/layout/flyout) already provide borders which can act as the divider. In this case you can turn the border off with `@bottomBorder={{false}}`.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import { EuiButton, EuiButtonEmpty, EuiFlexGroup, EuiFlexItem, EuiFlyout, EuiFlyoutBody, EuiFlyoutFooter, EuiFlyoutHeader, EuiSpacer, EuiTab, EuiTabs, EuiText, EuiTitle } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked isFlyoutVisible = false;
  @tracked selectedTabId = '1';

  @action
  showFlyout() {
    this.isFlyoutVisible = true;
  }

  @action
  closeFlyout() {
    this.isFlyoutVisible = false;
  }

  @action
  select(id) {
    this.selectedTabId = id;
  }

  <template>
    <EuiButton {{on "click" this.showFlyout}}>Show tabs flyout header</EuiButton>

    {{#if this.isFlyoutVisible}}
      <EuiFlyout @ownFocus={{true}} @onClose={{this.closeFlyout}} aria-labelledby="complicatedFlyoutTitle">
        <EuiFlyoutHeader @hasBorder={{true}}>
          <EuiTitle @size="m" @tagName="h2" id="complicatedFlyoutTitle">Flyout header</EuiTitle>
          <EuiSpacer @size="s" />
          <EuiText @color="subdued">
            <p>Put navigation items in the header, and cross tab actions in a footer.</p>
          </EuiText>
          <EuiSpacer @size="s" />
          <EuiTabs @bottomBorder={{false}} style="margin-bottom: -24px">
            <EuiTab @isSelected={{eq this.selectedTabId "1"}} {{on "click" (fn this.select "1")}}>
              Tab 1
            </EuiTab>
            <EuiTab @isSelected={{eq this.selectedTabId "2"}} {{on "click" (fn this.select "2")}}>
              Tab 2
            </EuiTab>
          </EuiTabs>
        </EuiFlyoutHeader>
        <EuiFlyoutBody>
          <EuiText>
            <p>Tab {{this.selectedTabId}} content</p>
          </EuiText>
        </EuiFlyoutBody>
        <EuiFlyoutFooter>
          <EuiFlexGroup @justifyContent="spaceBetween">
            <EuiFlexItem @grow={{false}}>
              <EuiButtonEmpty @iconType="cross" @flush="left" {{on "click" this.closeFlyout}}>
                Close
              </EuiButtonEmpty>
            </EuiFlexItem>
            <EuiFlexItem @grow={{false}}>
              <EuiButton @fill={{true}} {{on "click" this.closeFlyout}}>Save</EuiButton>
            </EuiFlexItem>
          </EuiFlexGroup>
        </EuiFlyoutFooter>
      </EuiFlyout>
    {{/if}}
  </template>
}
```
