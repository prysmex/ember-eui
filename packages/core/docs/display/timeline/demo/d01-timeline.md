---
order: 1
---

# Timeline

<EuiText>

The `EuiTimeline` component standardizes the way a timeline thread is displayed. Pass `@items`, or render an `EuiTimelineItem` for each event, and `EuiTimeline` will generate a timeline thread.

An item of `@items` takes `icon` (an icon type, or a component for custom content), `iconAriaLabel`, `verticalAlign` and its content in `children`: text, or a component for rich content like the paragraphs below (upstream's `children` node). `content` is the older name for text-only content.

</EuiText>

```gjs component
import { EuiText, EuiTimeline } from '@ember-eui/core/components';

const Invited = <template>
  <EuiText @size='s'>
    <p>
      <strong>janet@elastic.co</strong> was invited to the project.
    </p>
  </EuiText>
</template>;

const Renamed = <template>
  <EuiText @size='s'>
    <p>
      The project was renamed to <strong>Revenue Dashboard</strong>.
    </p>
  </EuiText>
</template>;

const Archived = <template>
  <EuiText @size='s'>
    <p>The project was archived.</p>
  </EuiText>
</template>;

const items = [
  { icon: 'email', iconAriaLabel: 'Invitation', children: Invited },
  { icon: 'pencil', iconAriaLabel: 'Edited', children: Renamed },
  { icon: 'folder', iconAriaLabel: 'Project closed', children: Archived },
];

<template>
  <EuiTimeline @items={{items}} aria-label='Project beta timeline' />
</template>
```
