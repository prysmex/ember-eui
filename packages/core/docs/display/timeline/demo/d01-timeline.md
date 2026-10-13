---
order: 1
---

# Timeline

<EuiText>

The `EuiTimeline` component standardizes the way a timeline thread is displayed. Render an `EuiTimelineItem` for each event, or pass `@items` for simple text events, and `EuiTimeline` will generate a timeline thread.

</EuiText>

```gjs component
import { EuiText, EuiTimeline, EuiTimelineItem } from '@ember-eui/core/components';

<template>
<EuiTimeline aria-label='Project beta timeline'>
  <EuiTimelineItem @icon='email' @iconAriaLabel='Invitation'>
    <EuiText @size='s'>
      <p>
        <strong>janet@elastic.co</strong> was invited to the project.
      </p>
    </EuiText>
  </EuiTimelineItem>
  <EuiTimelineItem @icon='pencil' @iconAriaLabel='Edited'>
    <EuiText @size='s'>
      <p>
        The project was renamed to <strong>Revenue Dashboard</strong>.
      </p>
    </EuiText>
  </EuiTimelineItem>
  <EuiTimelineItem @icon='folder' @iconAriaLabel='Project closed'>
    <EuiText @size='s'>
      <p>The project was archived.</p>
    </EuiText>
  </EuiTimelineItem>
</EuiTimeline>
</template>
```
