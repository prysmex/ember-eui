---
order: 2
---

# Comment

<EuiText>

The **EuiComment** is flexible and adapts the design according to the arguments and blocks passed.

1. `@timelineIcon`: Shows an avatar that should indicate who is the author of the comment. To customize, pass an icon type as `@timelineIcon`, or put an **EuiAvatar** in the `<:timelineIcon>` block. Use in conjunction with `@timelineAvatarAriaLabel` to pass an aria label to the avatar. If no avatar is provided, it will default to an avatar with a `user` icon.
2. `@eventIcon`: Icon that shows before the username. Use in conjunction with `@eventIconAriaLabel` to pass an aria label to the event icon.
3. `<:username>`: Author of the comment.
4. `<:event>`: Describes the event that took place.
5. `<:timestamp>`: Time of occurrence of the event.
6. `<:actions>`: Custom actions that the user can perform from the comment's header. When having multiple actions, consider grouping them in a nested menu system using a **EuiPopover** with a **EuiContextMenu**.
7. `<:body>`: A user message or any custom component.

The following demo shows how you can combine different arguments to create different types of comments events like a regular, update, update with a danger background and a custom one.

</EuiText>
<EuiSpacer />

```hbs template
<EuiFlexGroup @alignItems="center">
  <EuiFlexItem @grow={{false}}>
    <EuiButtonGroup
      @legend="Pick an example"
      @options={{this.toggleButtons}}
      @onChange={{this.setExample}}
      @idSelected={{this.example}}
      @type="single"
      @color="primary"
    />
  </EuiFlexItem>
  {{#if (not (eq this.example "custom"))}}
    <EuiFlexItem @grow={{false}}>
      <EuiSelect
        @options={{this.colors}}
        @value={{this.colorOption}}
        aria-label="eventColor"
        @compressed={{true}}
        {{on "change" this.setColor}}
      >
        <:prepend as |classes|>
          <EuiFormLabel class={{classes}}>eventColor</EuiFormLabel>
        </:prepend>
      </EuiSelect>
    </EuiFlexItem>
  {{/if}}
  <EuiFlexItem>
    {{#if (and (eq this.example "regular") (eq this.colorOption "subdued"))}}
      <span>
        subdued is the default <EuiCode>@eventColor</EuiCode> for regular
        <strong>EuiComment</strong>
      </span>
    {{/if}}
    {{#if (and (eq this.example "update") (eq this.colorOption "transparent"))}}
      <span>
        transparent is the default <EuiCode>@eventColor</EuiCode> for update
        <strong>EuiComment</strong>
      </span>
    {{/if}}
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiCommentList>
  {{#if (eq this.example "regular")}}
    <EuiComment @timelineAvatarAriaLabel="Jane Doe" @eventColor={{this.color}}>
      <:username>janed</:username>
      <:event>added a comment</:event>
      <:timestamp>on Jan 1, 2020</:timestamp>
      <:actions>
        <EuiToolTip @content="Custom action" @disableScreenReaderOutput={{true}}>
          <EuiButtonIcon aria-label="Custom action" @color="text" @iconType="copy" />
        </EuiToolTip>
      </:actions>
      <:body>
        <EuiText @size="s">
          <p>
            Far out in the uncharted backwaters of the unfashionable end of
            the western spiral arm of the Galaxy lies a small unregarded
            yellow sun.
          </p>
        </EuiText>
      </:body>
    </EuiComment>
  {{else if (eq this.example "update")}}
    <EuiComment
      @timelineAvatarAriaLabel="Luis G"
      @eventIcon="tag"
      @eventIconAriaLabel="tag"
      @eventColor={{this.color}}
    >
      <:username>luisg</:username>
      <:event>
        <EuiFlexGroup @responsive={{false}} @alignItems="center" @gutterSize="xs" @wrap={{true}}>
          <EuiFlexItem @grow={{false}}>added tags</EuiFlexItem>
          <EuiFlexItem @grow={{false}}><EuiBadge>case</EuiBadge></EuiFlexItem>
          <EuiFlexItem @grow={{false}}><EuiBadge>phishing</EuiBadge></EuiFlexItem>
          <EuiFlexItem @grow={{false}}><EuiBadge>security</EuiBadge></EuiFlexItem>
        </EuiFlexGroup>
      </:event>
      <:timestamp>22 hours ago</:timestamp>
      <:actions>
        <EuiToolTip @content="Custom action" @disableScreenReaderOutput={{true}}>
          <EuiButtonIcon aria-label="Custom action" @color="text" @iconType="copy" />
        </EuiToolTip>
      </:actions>
    </EuiComment>
  {{else}}
    <EuiComment @timelineAvatarAriaLabel="Pancho Pérez">
      <:username>pancho1</:username>
      <:body>
        <EuiTextArea
          @fullWidth={{true}}
          @value=""
          placeholder="I'm a textarea in a EuiComment"
        />
      </:body>
    </EuiComment>
  {{/if}}
</EuiCommentList>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class CommentDemo extends Component {
  toggleButtons = [
    { id: 'regular', label: 'Regular' },
    { id: 'update', label: 'Update' },
    { id: 'custom', label: 'Custom' },
  ];

  colors = [
    { value: 'subdued', text: 'subdued' },
    { value: 'transparent', text: 'transparent' },
    { value: 'plain', text: 'plain' },
    { value: 'danger', text: 'danger' },
    { value: 'warning', text: 'warning' },
    { value: 'accent', text: 'accent' },
    { value: 'primary', text: 'primary' },
    { value: 'success', text: 'success' },
    { value: 'undefined', text: 'undefined' },
  ];

  @tracked example = 'regular';
  @tracked colorOption = 'subdued';

  get color() {
    return this.colorOption === 'undefined' ? undefined : this.colorOption;
  }

  @action setExample(id) {
    this.example = id;
  }

  @action setColor(event) {
    this.colorOption = event.target.value;
  }
}
```
