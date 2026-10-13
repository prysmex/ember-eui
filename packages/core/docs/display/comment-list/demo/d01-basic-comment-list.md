---
order: 1
---

# Basic comment list

<EuiText>

Use **EuiCommentList** to display a list of **EuiComment**s. Each comment is an **EuiComment** inside the list, and its parts are given as the named blocks `<:username>`, `<:event>`, `<:timestamp>`, `<:actions>` and `<:body>`. To render comments from data instead, pass an array to `@comments` (see the "Comments from data" example).

</EuiText>

```gjs component
import { EuiBadge, EuiButtonIcon, EuiComment, EuiCommentList, EuiFlexGroup, EuiFlexItem, EuiText, EuiToolTip } from '@ember-eui/core/components';

<template>
<EuiCommentList aria-label="Comment list example">
  <EuiComment @timelineAvatarAriaLabel="Jane Doe">
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
          Far out in the uncharted backwaters of the unfashionable end of the
          western spiral arm of the Galaxy lies a small unregarded yellow sun.
        </p>
      </EuiText>
    </:body>
  </EuiComment>

  <EuiComment @timelineAvatarAriaLabel="Juana Barros">
    <:username>juanab</:username>
    <:event>pushed incident X0Z235</:event>
    <:timestamp>on Jan 3, 2020</:timestamp>
    <:actions>
      <EuiToolTip @content="Custom action" @disableScreenReaderOutput={{true}}>
        <EuiButtonIcon aria-label="Custom action" @color="text" @iconType="copy" />
      </EuiToolTip>
    </:actions>
  </EuiComment>

  <EuiComment
    @timelineAvatarAriaLabel="Pancho Pérez"
    @eventIcon="pencil"
    @eventIconAriaLabel="edit"
  >
    <:username>pancho1</:username>
    <:event>edited case</:event>
    <:timestamp>on Jan 9, 2020</:timestamp>
  </EuiComment>

  <EuiComment
    @timelineAvatarAriaLabel="Pedro Rodriguez"
    @eventIcon="tag"
    @eventIconAriaLabel="tag"
  >
    <:username>pedror</:username>
    <:event>
      <EuiFlexGroup @responsive={{false}} @alignItems="center" @gutterSize="xs" @wrap={{true}}>
        <EuiFlexItem @grow={{false}}>added tags</EuiFlexItem>
        <EuiFlexItem @grow={{false}}><EuiBadge>case</EuiBadge></EuiFlexItem>
        <EuiFlexItem @grow={{false}}><EuiBadge>phishing</EuiBadge></EuiFlexItem>
        <EuiFlexItem @grow={{false}}><EuiBadge>security</EuiBadge></EuiFlexItem>
      </EuiFlexGroup>
    </:event>
    <:timestamp>on Jan 11, 2020</:timestamp>
    <:actions>
      <EuiToolTip @content="Custom action" @disableScreenReaderOutput={{true}}>
        <EuiButtonIcon aria-label="Custom action" @color="text" @iconType="copy" />
      </EuiToolTip>
    </:actions>
  </EuiComment>

  <EuiComment @timelineAvatarAriaLabel="Assistant" @eventColor="danger">
    <:username>Assistant</:username>
    <:timestamp>on Jan 14, 2020, 1:39:04 PM</:timestamp>
    <:actions>
      <EuiToolTip @content="Custom action" @disableScreenReaderOutput={{true}}>
        <EuiButtonIcon aria-label="Custom action" @color="text" @iconType="copy" />
      </EuiToolTip>
    </:actions>
    <:body><p>An error occurred sending your message.</p></:body>
  </EuiComment>
</EuiCommentList>
</template>
```
