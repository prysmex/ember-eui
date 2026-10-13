---
order: 2
---

# Timeline item

<EuiText>

Each `EuiTimelineItem` has two parts: an icon on the left side and an event on the right side. To create an item you need the following:

*   `@icon`: main icon that appears on the left side. Can be passed as any icon type string, or use the `<:icon>` named block for custom content (e.g. `EuiAvatar`). It is recommended not to use an element larger than 40x40.
*   The default block: any content as the event.

</EuiText>

```gjs component
import { EuiCode, EuiText, EuiTimeline, EuiTimelineItem } from '@ember-eui/core/components';

<template>
<EuiTimeline aria-label='Timeline item example'>
  <EuiTimelineItem @icon='dot' @iconAriaLabel='Main icon'>
    <EuiText @size='s'>
      <p>
        I'm the block content and you can find the <EuiCode>icon</EuiCode> on the left side.
      </p>
    </EuiText>
  </EuiTimelineItem>
</EuiTimeline>
</template>
```
