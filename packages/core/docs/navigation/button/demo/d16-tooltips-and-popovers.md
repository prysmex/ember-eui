---
order: 16
---

# Split button: Tooltips and popovers

<EuiText>

To apply a tooltip to either action, you can pass `@tooltipProps` which will render an `EuiToolTip` wrapping the button. For `ActionSecondary` only, you can also pass `@popoverProps` to render an `EuiPopover`; the block of `ActionSecondary` is the popover content.

Using `ActionSecondary` or `ActionPrimary` with `@isIconOnly` requires `aria-label` to be set to ensure an accessible label for the icon-only button is available to screen readers.

When there is only one primary and one secondary action, an `{{on "click"}}` modifier can be passed directly to each action and perform individual actions for each action button. When there are multiple secondary actions, use `@popoverProps` on `ActionSecondary` to display your custom subset of secondary actions in a popover.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { hash } from '@ember/helper';
import { EuiContextMenu, EuiSplitButton } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked isOpen = false;

  panels = [
    {
      id: 0,
      items: [
        {
          name: 'Action 1 (click)',
          icon: 'magnify',
          onClick: () => {}
        },
        {
          name: 'Action 2 (link)',
          icon: 'user',
          href: 'http://elastic.co',
          target: '_blank'
        },
        {
          name: 'Action 3 (tooltip)',
          icon: 'document',
          toolTipContent: 'Optional content for a tooltip',
          toolTipProps: {
            title: 'Optional tooltip title',
            position: 'right'
          },
          onClick: () => {}
        }
      ]
    }
  ];

  @action
  toggle() {
    this.isOpen = !this.isOpen;
  }

  @action
  close() {
    this.isOpen = false;
  }

  <template>
    <EuiSplitButton as |split|>
      <split.ActionPrimary
        @iconType="save"
        @tooltipProps={{hash content="Primary action tooltip" position="bottom"}}
      >
        Save
      </split.ActionPrimary>
      <split.ActionSecondary
        @iconType="chevronSingleDown"
        aria-label="Open secondary actions menu"
        {{on "click" this.toggle}}
        @popoverProps={{hash
          isOpen=this.isOpen
          closePopover=this.close
          panelPaddingSize="s"
        }}
      >
        <EuiContextMenu @panels={{this.panels}} @initialPanelId={{0}} />
      </split.ActionSecondary>
    </EuiSplitButton>
  </template>
}
```
