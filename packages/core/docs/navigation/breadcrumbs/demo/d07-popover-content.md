---
order: 7
---

# Popover content

<EuiText>
	<p>
		If you want a breadcrumb that toggles a popover, e.g. for an account switcher, use <EuiCode>popoverContent</EuiCode>. <strong>EuiBreadcrumbs</strong> renders the popover indicator and the popover accessibility best practices for you. Use <EuiCode>popoverProps</EuiCode> to pass almost any <strong>EuiPopover</strong> argument, such as <EuiCode>panelPaddingSize</EuiCode> or <EuiCode>anchorPosition</EuiCode>. Arguments that control the popover's state (<EuiCode>closePopover</EuiCode>, <EuiCode>isOpen</EuiCode>, <EuiCode>button</EuiCode>) are not accepted.
  </p>
	<p>
		Instead of upstream's render function, <EuiCode>popoverContent</EuiCode> takes a string, a component that receives <EuiCode>@closePopover</EuiCode> and <EuiCode>@breadcrumb</EuiCode> (see the Deployment breadcrumb), or <EuiCode>true</EuiCode> to render the <EuiCode>&lt;:popoverContent as |breadcrumb closePopover|&gt;</EuiCode> block of <strong>EuiBreadcrumbs</strong> (see the Space breadcrumb).
  </p>
	<p>
		Creating a breadcrumb with a popover ignores any <EuiCode>href</EuiCode> or <EuiCode>onClick</EuiCode>, as the only interaction the breadcrumb has is the popover toggle.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { hash } from '@ember/helper';
import {
  EuiAvatar,
  EuiBreadcrumbs,
  EuiButton,
  EuiContextMenuItem,
  EuiContextMenuPanel,
  EuiPopoverFooter,
  EuiPopoverTitle,
  EuiSelectable
} from '@ember-eui/core/components';

// A component given as `popoverContent` gets `@closePopover`.
const Deployments = <template>
  <EuiPopoverTitle @paddingSize="s">Select a deployment</EuiPopoverTitle>
  <EuiContextMenuPanel>
    <EuiContextMenuItem @href="#" {{on "click" @closePopover}}>Go to Deployment A</EuiContextMenuItem>
    <EuiContextMenuItem @href="#" {{on "click" @closePopover}}>Go to Deployment B</EuiContextMenuItem>
    <EuiContextMenuItem @href="#" {{on "click" @closePopover}}>Go to all deployments</EuiContextMenuItem>
  </EuiContextMenuPanel>
</template>;

export default class DemoComponent extends Component {
  @tracked spaces = [
    { label: 'My space', checked: 'on' },
    { label: "Jim's space" },
    { label: "Pam's space" },
    { label: "Michael's space" },
    { label: "Assistant Manager Dwight's space" }
  ];

  get breadcrumbs() {
    return [
      {
        text: 'My deployment',
        popoverContent: Deployments,
        popoverProps: { panelPaddingSize: 'none' }
      },
      {
        text: this.spaces.find((space) => space.checked === 'on').label,
        popoverContent: true,
        popoverProps: { panelPaddingSize: 'none' }
      },
      { text: 'Home' }
    ];
  }

  @action
  setSpaces(options) {
    this.spaces = options;
  }

  <template>
    <EuiBreadcrumbs @breadcrumbs={{this.breadcrumbs}}>
      <:popoverContent as |breadcrumb closePopover|>
        <EuiSelectable
          @options={{this.spaces}}
          @onChange={{this.setSpaces}}
          @searchable={{true}}
          @singleSelection="always"
          @searchProps={{hash placeholder="Filter spaces" compressed=true}}
          @emptyMessage="No spaces available"
          @noMatchesMessage="No spaces found"
          aria-label="Space switcher"
          as |parts|
        >
          <EuiPopoverTitle @paddingSize="s">Select a space</EuiPopoverTitle>
          <EuiPopoverTitle @paddingSize="s"><parts.search /></EuiPopoverTitle>
          <parts.list>
            <:optionPrepend as |space|>
              <EuiAvatar @type="space" @name={{space.label}} @size="s" />
            </:optionPrepend>
          </parts.list>
          <EuiPopoverFooter @paddingSize="s">
            <EuiButton @fullWidth={{true}} @size="s" @iconType="gear" {{on "click" closePopover}}>
              Manage all spaces
            </EuiButton>
          </EuiPopoverFooter>
        </EuiSelectable>
      </:popoverContent>
    </EuiBreadcrumbs>
  </template>
}
```
