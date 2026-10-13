---
order: 4
---

# Comment event actions

<EuiText>

There are scenarios where you might want to allow the user to perform `actions` related to each comment. Some common `actions` include: editing, deleting, sharing and copying. To add custom actions to a comment, use the `<:actions>` block. These will be placed to the right of the metadata in the comment's header. We recommend using an **EuiButtonIcon** to trigger an action. When having multiple actions, consider grouping them in a nested menu system using a **EuiPopover** with a **EuiContextMenu**.

</EuiText>

```hbs template
<EuiCommentList aria-label="Actions">
  <EuiComment @timelineAvatarAriaLabel="Jane Doe">
    <:username>janed</:username>
    <:event>added a comment</:event>
    <:timestamp>on Jan 1, 2020</:timestamp>
    <:actions>
      <EuiPopover
        @isOpen={{this.isPopoverOpen}}
        @closePopover={{this.closePopover}}
        @panelPaddingSize="none"
        @anchorPosition="leftCenter"
      >
        <:button>
          <EuiToolTip @content="Actions" @disableScreenReaderOutput={{true}}>
            <EuiButtonIcon
              aria-label="Actions"
              @iconType="boxesVertical"
              @size="xs"
              @color="text"
              {{on "click" this.togglePopover}}
            />
          </EuiToolTip>
        </:button>
        <:content>
          <EuiContextMenuPanel>
            <EuiContextMenuItem @icon="pencil" {{on "click" this.closePopover}}>Edit</EuiContextMenuItem>
            <EuiContextMenuItem @icon="share" {{on "click" this.closePopover}}>Share</EuiContextMenuItem>
            <EuiContextMenuItem @icon="copy" {{on "click" this.closePopover}}>Copy</EuiContextMenuItem>
          </EuiContextMenuPanel>
        </:content>
      </EuiPopover>
    </:actions>
    <:body>
      <EuiText @size="s">
        <p>This comment has custom actions available. See the upper right corner.</p>
      </EuiText>
    </:body>
  </EuiComment>

  <EuiComment
    @timelineAvatarAriaLabel="System"
    @timelineIcon="dot"
    @eventColor="danger"
  >
    <:username>system</:username>
    <:event>pushed a new incident <EuiLink>malware detection</EuiLink></:event>
    <:timestamp>on Jan 2, 2020</:timestamp>
    <:actions>
      <EuiToolTip @content="Copy alert link" @disableScreenReaderOutput={{true}}>
        <EuiButtonIcon aria-label="Copy alert link" @iconType="link" @size="xs" @color="text" />
      </EuiToolTip>
      <EuiToolTip @content="Show the alert details in a flyout">
        <EuiButtonIcon
          aria-label="Show details"
          @iconType="external"
          @size="xs"
          @color="text"
          {{on "click" this.toggleFlyout}}
        />
      </EuiToolTip>
    </:actions>
  </EuiComment>
</EuiCommentList>

{{#if this.isFlyoutVisible}}
  <EuiFlyout @ownFocus={{true}} @onClose={{this.toggleFlyout}} aria-labelledby="commentFlyoutTitle">
    <EuiFlyoutHeader @hasBorder={{true}}>
      <EuiTitle @size="m"><h2 id="commentFlyoutTitle">Malware detection alert</h2></EuiTitle>
    </EuiFlyoutHeader>
    <EuiFlyoutBody>
      <EuiText>
        <p>Use a flyout to show more details related to your comment event.</p>
      </EuiText>
    </EuiFlyoutBody>
  </EuiFlyout>
{{/if}}
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class CommentActionsDemo extends Component {
  @tracked isPopoverOpen = false;
  @tracked isFlyoutVisible = false;

  @action togglePopover() {
    this.isPopoverOpen = !this.isPopoverOpen;
  }

  @action closePopover() {
    this.isPopoverOpen = false;
  }

  @action toggleFlyout() {
    this.isFlyoutVisible = !this.isFlyoutVisible;
  }
}
```
