---
order: 3
---

# Displaying custom elements

<EuiText>

If you have custom content to show instead of a list of options, you can pass any content as a block to **EuiContextMenuPanel**.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { hash } from '@ember/helper';
import { EuiButton, EuiContextMenuItem, EuiContextMenuPanel, EuiHorizontalRule, EuiPanel, EuiPopover, EuiSelectable, EuiSpacer, EuiTitle } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked isPopoverOpen = false;
  @tracked options = [
    { label: 'APM' },
    { label: 'filebeat-*' },
    { label: 'logs-*' },
    { label: 'metrics-*' }
  ];

  @action
  onButtonClick() {
    this.isPopoverOpen = !this.isPopoverOpen;
  }

  @action
  closePopover() {
    this.isPopoverOpen = false;
  }

  @action
  setOptions(newOptions) {
    this.options = newOptions;
  }

  <template>
    <EuiPopover
      @isOpen={{this.isPopoverOpen}}
      @closePopover={{this.closePopover}}
      @panelPaddingSize="none"
      @anchorPosition="downLeft"
    >
      <:button>
        <EuiButton
          @size="s"
          @iconType="chevronSingleDown"
          @iconSide="right"
          {{on "click" this.onButtonClick}}
        >
          Click to show some content
        </EuiButton>
      </:button>
      <:content>
        <EuiContextMenuPanel>
          <EuiContextMenuItem @icon="indexOpen" @size="s" {{on "click" this.closePopover}}>
            Add a field to this data view
          </EuiContextMenuItem>
          <EuiContextMenuItem @icon="indexSettings" @size="s" {{on "click" this.closePopover}}>
            Manage this data view
          </EuiContextMenuItem>
          <EuiHorizontalRule @margin="none" />
          <EuiPanel @color="transparent" @paddingSize="s" @hasBorder={{false}}>
            <EuiTitle @size="xxxs" @tagName="h3">Data views</EuiTitle>
            <EuiSpacer @size="s" />
            <EuiSelectable
              aria-label="Find a data view"
              @searchable={{true}}
              @searchProps={{hash compressed=true placeholder="Find a data view"}}
              @options={{this.options}}
              @onChange={{this.setOptions}}
              as |parts|
            >
              <parts.search />
              <parts.list />
            </EuiSelectable>
          </EuiPanel>
        </EuiContextMenuPanel>
      </:content>
    </EuiPopover>
  </template>
}
```
