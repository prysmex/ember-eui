---
order: 1
---

# Context menu

<EuiText>

**EuiContextMenu** is a nested menu system useful for navigating complicated trees. It lives within an **EuiPopover** which itself can be wrapped around any component (like a button in this example).

Panels are a flat list; an item opens another panel with `panel: id`. Panels without `items` render their content with the `<:content>` block.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { eq } from 'ember-truth-helpers';
import { EuiButton, EuiContextMenu, EuiFormRow, EuiPopover, EuiSpacer, EuiSwitch } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked isPopoverOpen = false;

  @action
  onButtonClick() {
    this.isPopoverOpen = !this.isPopoverOpen;
  }

  @action
  closePopover() {
    this.isPopoverOpen = false;
  }

  get panels() {
    const closePopover = this.closePopover;

    return [
      {
        id: 0,
        title: 'This is a context menu',
        items: [
          { name: 'Handle an onClick', icon: 'magnify', onClick: closePopover },
          {
            name: 'Go to a link',
            icon: 'user',
            href: 'http://elastic.co',
            target: '_blank'
          },
          { name: 'Nest panels', icon: 'wrench', panel: 1 },
          {
            name: 'Add a tooltip',
            icon: 'document',
            toolTipContent: 'Optional content for a tooltip',
            toolTipTitle: 'Optional tooltip title',
            onClick: closePopover
          },
          { name: 'Use an app icon', icon: 'visualizeApp', onClick: closePopover },
          {
            name: 'Disabled option',
            icon: 'user',
            toolTipContent: 'For reasons, this item is disabled',
            disabled: true,
            onClick: closePopover
          }
        ]
      },
      {
        id: 1,
        initialFocusedItemIndex: 1,
        title: 'Nest panels',
        items: [
          { name: 'PDF reports', icon: 'user', onClick: closePopover },
          { name: 'Embed code', icon: 'user', panel: 2 },
          { name: 'Permalinks', icon: 'user', onClick: closePopover }
        ]
      },
      { id: 2, title: 'Embed code' }
    ];
  }

  <template>
    <EuiPopover
      @isOpen={{this.isPopoverOpen}}
      @closePopover={{this.closePopover}}
      @panelPaddingSize="none"
      @anchorPosition="downLeft"
    >
      <:button>
        <EuiButton @iconType="chevronSingleDown" @iconSide="right" {{on "click" this.onButtonClick}}>
          Click me to load a context menu
        </EuiButton>
      </:button>
      <:content>
        <EuiContextMenu @initialPanelId={{0}} @panels={{this.panels}}>
          <:content as |panel|>
            {{#if (eq panel.id 2)}}
              <div style="padding: 16px">
                <EuiFormRow @label="Generate a public snapshot?" @hasChildLabel={{false}}>
                  <EuiSwitch @name="switch" @label="Snapshot data" @checked={{true}} />
                </EuiFormRow>
                <EuiFormRow @label="Include the following in the embed" @hasChildLabel={{false}}>
                  <EuiSwitch @name="switch" @label="Current time range" @checked={{true}} />
                </EuiFormRow>
                <EuiSpacer />
                <EuiButton @fill={{true}}>Copy iFrame code</EuiButton>
              </div>
            {{/if}}
          </:content>
        </EuiContextMenu>
      </:content>
    </EuiPopover>
  </template>
}
```
