---
order: 1
---

# Tooltip

<EuiText>

Wrap `EuiToolTip` around any item that you need a tooltip for and provide the `@content` and optionally the `@title`. The `@position` argument will take a suggested position, but will change it if the tooltip gets too close to the edge of the screen. You can adjust the distance between the tooltip and its anchor using the `@offset` argument. By default, this value is `16`.

</EuiText>

```gjs component
import { EuiIcon, EuiLink, EuiText, EuiToolTip } from '@ember-eui/core/components';

<template>
<EuiText>
  <p>
    This tooltip appears on the
    <EuiToolTip @position='top' @content='Here is some tooltip text'>
      <EuiLink @href='#'>top</EuiLink>
    </EuiToolTip>.
  </p>

  <p>
    This tooltip appears on the
    <EuiToolTip
      @position='left'
      @title='Tooltip titles are optional'
      @content='Here is some tooltip text. Lets add some more content to see how it wraps.'
    >
      <EuiLink @href='#'>left</EuiLink>
    </EuiToolTip>
    and includes the optional title.
  </p>

  <p>
    This tooltip appears on the
    <EuiToolTip @position='right' @content='Here is some tooltip text'>
      <EuiLink @href='#'>right</EuiLink>
    </EuiToolTip>.
  </p>

  <p>
    This tooltip appears on the bottom of this icon:
    <EuiToolTip @position='bottom' @content='Here is some tooltip text'>
      <EuiIcon tabindex='0' @type='warning' @title='Icon with tooltip' />
    </EuiToolTip>
  </p>

  <p>
    This tooltip has a
    <EuiToolTip @position='right' @content='Here is some tooltip text' @offset={{32}}>
      <EuiLink @href='#'>custom offset</EuiLink>
    </EuiToolTip>
  </p>
</EuiText>
</template>
```
