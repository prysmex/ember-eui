---
order: 1
---

# Menu in a popover

<EuiText>

Close the popover when an item is chosen. Items with `@href` render as
links.

</EuiText>

```hbs template
<EuiPopover
  @isOpen={{this.isOpen}}
  @closePopover={{this.close}}
  @panelPaddingSize="none"
  @anchorPosition="downLeft"
>
  <:button>
    <EuiButton @iconType="arrowDown" @iconSide="right" {{on "click" this.toggle}}>
      Actions
    </EuiButton>
  </:button>
  <:content>
    <EuiContextMenuPanel>
      <EuiContextMenuItem @icon="pencil" {{on "click" (fn this.choose "Edit")}}>
        Edit
      </EuiContextMenuItem>
      <EuiContextMenuItem @icon="copy" {{on "click" (fn this.choose "Duplicate")}}>
        Duplicate
      </EuiContextMenuItem>
      <EuiContextMenuItem @icon="share" @href="#" {{on "click" (fn this.choose "Share")}}>
        Share (a link)
      </EuiContextMenuItem>
      <EuiHorizontalRule @margin="none" />
      <EuiContextMenuItem @icon="trash" {{on "click" (fn this.choose "Delete")}}>
        Delete
      </EuiContextMenuItem>
    </EuiContextMenuPanel>
  </:content>
</EuiPopover>
<EuiSpacer @size="s" />
<EuiText @size="s" @color="subdued"><p>Last action: {{if this.last this.last "none"}}</p></EuiText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class ContextMenuDemo extends Component {
  @tracked isOpen = false;
  @tracked last;

  @action
  toggle() {
    this.isOpen = !this.isOpen;
  }

  @action
  close() {
    this.isOpen = false;
  }

  @action
  choose(name, event) {
    event.preventDefault();
    this.last = name;
    this.isOpen = false;
  }
}
```
