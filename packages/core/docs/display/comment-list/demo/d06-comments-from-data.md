---
order: 6
---

# Comments from data

<EuiText>

Like upstream's `comments` prop, **EuiCommentList** accepts an array of comment objects in `@comments`. Each object takes `username`, `event`, `timestamp`, `actions`, `body` (upstream's `children`), `timelineIcon`, `timelineAvatarAriaLabel`, `eventColor`, `eventIcon` and `eventIconAriaLabel`.

Where upstream takes React nodes, an object takes text or a component (a template-only component, or `(component …)` for one with arguments). Comments from `@comments` render first, followed by any **EuiComment** in the block.

</EuiText>

```gjs component
import { EuiBadge, EuiButtonIcon, EuiCommentList, EuiFlexGroup, EuiFlexItem, EuiText, EuiToolTip } from '@ember-eui/core/components';

const CopyAction = <template>
  <EuiToolTip @content="Custom action" @disableScreenReaderOutput={{true}}>
    <EuiButtonIcon aria-label="Custom action" @color="text" @iconType="copy" />
  </EuiToolTip>
</template>;

const Body = <template>
  <EuiText @size="s">
    <p>
      Far out in the uncharted backwaters of the unfashionable end of the
      western spiral arm of the Galaxy lies a small unregarded yellow sun.
    </p>
  </EuiText>
</template>;

const ErrorBody = <template><p>An error occurred sending your message.</p></template>;

const ComplexEvent = <template>
  <EuiFlexGroup @responsive={{false}} @alignItems="center" @gutterSize="xs" @wrap={{true}}>
    <EuiFlexItem @grow={{false}}>added tags</EuiFlexItem>
    <EuiFlexItem @grow={{false}}><EuiBadge>case</EuiBadge></EuiFlexItem>
    <EuiFlexItem @grow={{false}}><EuiBadge>phishing</EuiBadge></EuiFlexItem>
    <EuiFlexItem @grow={{false}}><EuiBadge>security</EuiBadge></EuiFlexItem>
  </EuiFlexGroup>
</template>;

const comments = [
  {
    username: 'janed',
    timelineAvatarAriaLabel: 'Jane Doe',
    event: 'added a comment',
    timestamp: 'on Jan 1, 2020',
    body: Body,
    actions: CopyAction,
  },
  {
    username: 'juanab',
    timelineAvatarAriaLabel: 'Juana Barros',
    actions: CopyAction,
    event: 'pushed incident X0Z235',
    timestamp: 'on Jan 3, 2020',
  },
  {
    username: 'pancho1',
    timelineAvatarAriaLabel: 'Pancho Pérez',
    event: 'edited case',
    timestamp: 'on Jan 9, 2020',
    eventIcon: 'pencil',
    eventIconAriaLabel: 'edit',
  },
  {
    username: 'pedror',
    timelineAvatarAriaLabel: 'Pedro Rodriguez',
    actions: CopyAction,
    event: ComplexEvent,
    timestamp: 'on Jan 11, 2020',
    eventIcon: 'tag',
    eventIconAriaLabel: 'tag',
  },
  {
    username: 'Assistant',
    timelineAvatarAriaLabel: 'Assistant',
    timestamp: 'on Jan 14, 2020, 1:39:04 PM',
    body: ErrorBody,
    actions: CopyAction,
    eventColor: 'danger',
  },
];

<template>
  <EuiCommentList @comments={{comments}} aria-label="Comment list example" />
</template>
```
