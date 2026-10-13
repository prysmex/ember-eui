---
order: 2
---

# Tab sizes

<EuiText>

**EuiTabs** allow a `@size` argument. In general you should always use the default (medium) size. The small size is best for when placing inside popovers or other small containers. Reserve using the large size for when using as primary page navigation, like inside of **EuiPageHeader**.

You can also use the `@expand` argument to evenly stretch each tab horizontally.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import { EuiButton, EuiIcon, EuiPopover, EuiSpacer, EuiTab, EuiTabs } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked isPopoverOpen = false;
  @tracked selectedTabId = 'cobalt';

  @action
  select(id) {
    this.selectedTabId = id;
  }

  @action
  onButtonClick() {
    this.isPopoverOpen = !this.isPopoverOpen;
  }

  @action
  closePopover() {
    this.isPopoverOpen = false;
  }

  <template>
    <EuiPopover
      @isOpen={{this.isPopoverOpen}}
      @closePopover={{this.closePopover}}
      @anchorPosition="downLeft"
    >
      <:button>
        <EuiButton @iconType="chevronSingleDown" @iconSide="right" {{on "click" this.onButtonClick}}>
          Click to show small tabs in a popover
        </EuiButton>
      </:button>
      <:content>
        <div style="width: 300px">
          <EuiTabs @size="s" @expand={{true}}>
            <EuiTab
              @isSelected={{eq this.selectedTabId "cobalt"}}
              {{on "click" (fn this.select "cobalt")}}
            >
              Cobalt
            </EuiTab>
            <EuiTab
              @isSelected={{eq this.selectedTabId "dextrose"}}
              {{on "click" (fn this.select "dextrose")}}
            >
              Dextrose
            </EuiTab>
            <EuiTab
              @disabled={{true}}
              @isSelected={{eq this.selectedTabId "hydrogen"}}
              {{on "click" (fn this.select "hydrogen")}}
            >
              <:prepend><EuiIcon @type="chartHeatmap" @size="s" /></:prepend>
              <:default>Hydrogen</:default>
            </EuiTab>
          </EuiTabs>
          <EuiSpacer @size="m" />
          A spacer is usually needed between the tabs and the content. Try to use
          the same size as the surrounding padding.
        </div>
      </:content>
    </EuiPopover>
  </template>
}
```
