---
order: 4
---

# Using panels with mixed items and content

<EuiText>

### Custom panels

Context menu panels can render content through the `<:content>` block instead of `items`. The panel will display your custom content without modification.

If your panel contents have different widths or you need to ensure that a specific context menu panel has a certain width, add `width: [number of pixels]` to the panel.

### Custom items

You can add separator lines in the `items` array if you define an item as `{ isSeparator: true }`.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { eq } from 'ember-truth-helpers';
import { EuiButton, EuiContextMenu, EuiIcon, EuiPopover, EuiSpacer, EuiTabbedContent, EuiText } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked isPopoverOpen = false;
  @tracked isDynamicPopoverOpen = false;

  tabs = [
    {
      id: 'cobalt--id',
      name: 'Cobalt',
      content:
        'Cobalt is a chemical element with symbol Co and atomic number 27. Like nickel, cobalt is found in the Earth’s crust only in chemically combined form, save for small deposits found in alloys of natural meteoric iron. The free element, produced by reductive smelting, is a hard, lustrous, silver-gray metal.'
    },
    {
      id: 'dextrose--id',
      name: 'Dextrose',
      content:
        'Intravenous sugar solution, also known as dextrose solution, is a mixture of dextrose (glucose) and water. It is used to treat low blood sugar or water loss without electrolyte loss.'
    },
    {
      id: 'hydrogen--id',
      name: 'Hydrogen',
      content:
        'Hydrogen is a chemical element with symbol H and atomic number 1. With a standard atomic weight of 1.008, hydrogen is the lightest element on the periodic table'
    }
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
  onDynamicButtonClick() {
    this.isDynamicPopoverOpen = !this.isDynamicPopoverOpen;
  }

  @action
  closeDynamicPopover() {
    this.isDynamicPopoverOpen = false;
  }

  createPanels(close) {
    return [
      {
        id: 0,
        title: 'View options',
        items: [
          { name: 'Show fullscreen', icon: 'magnify', onClick: close },
          { isSeparator: true },
          { name: 'See more', icon: 'plusCircle', panel: 1 }
        ]
      },
      { id: 1, width: 400, title: 'See more' }
    ];
  }

  get panels() {
    return this.createPanels(this.closePopover);
  }

  get dynamicPanels() {
    return this.createPanels(this.closeDynamicPopover);
  }

  <template>
    <EuiPopover
      @isOpen={{this.isPopoverOpen}}
      @closePopover={{this.closePopover}}
      @panelPaddingSize="none"
      @anchorPosition="upLeft"
    >
      <:button>
        <EuiButton @iconType="chevronSingleDown" @iconSide="right" {{on "click" this.onButtonClick}}>
          Click me to load mixed content menu
        </EuiButton>
      </:button>
      <:content>
        <EuiContextMenu @initialPanelId={{0}} @panels={{this.panels}}>
          <:content as |panel|>
            {{#if (eq panel.id 1)}}
              <EuiText style="padding: 24px" @textAlign="center">
                <p><EuiIcon @type="faceHappy" @size="xxl" /></p>
                <h3>Context panels can contain anything</h3>
                <p>
                  You can stuff just about anything into these panels. Be mindful of
                  size though. This panel is set to 400px and the height will grow
                  as space allows.
                </p>
              </EuiText>
            {{/if}}
          </:content>
        </EuiContextMenu>
      </:content>
    </EuiPopover>

    <EuiSpacer @size="l" />

    <EuiPopover
      @isOpen={{this.isDynamicPopoverOpen}}
      @closePopover={{this.closeDynamicPopover}}
      @panelPaddingSize="none"
      @anchorPosition="upLeft"
    >
      <:button>
        <EuiButton @iconType="chevronSingleDown" @iconSide="right" {{on "click" this.onDynamicButtonClick}}>
          Click me to load dynamic mixed content menu
        </EuiButton>
      </:button>
      <:content>
        <EuiContextMenu @initialPanelId={{0}} @panels={{this.dynamicPanels}}>
          <:content as |panel|>
            {{#if (eq panel.id 1)}}
              <EuiTabbedContent @tabs={{this.tabs}}>
                <:selectedTabContent as |selected|>
                  <EuiText>
                    <p>{{selected.content}}</p>
                  </EuiText>
                </:selectedTabContent>
              </EuiTabbedContent>
            {{/if}}
          </:content>
        </EuiContextMenu>
      </:content>
    </EuiPopover>
  </template>
}
```
