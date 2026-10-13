---
order: 2
---

# Screen reader output

<EuiText>

By default, `EuiToolTip` links its content to the trigger via `aria-describedby`, causing screen readers to announce both the trigger's accessible label and the tooltip content. This is the correct behavior when the tooltip provides context not already present in the trigger label.

When the tooltip content **exactly duplicates** the trigger's accessible label, such as an icon button whose `aria-label` and tooltip both say "Edit", set `@disableScreenReaderOutput` to prevent the redundant double-announcement.

</EuiText>

```gjs component
import { EuiButtonIcon, EuiFlexGroup, EuiFlexItem, EuiSpacer, EuiText, EuiToolTip } from '@ember-eui/core/components';

<template>
<EuiFlexGroup @gutterSize='m' @alignItems='center'>
  <EuiFlexItem @grow={{false}}>
    <EuiToolTip @content='Edit'>
      <EuiButtonIcon aria-label='Edit' @iconType='pencil' />
    </EuiToolTip>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiText @size='s'>
      <strong>Without <code>@disableScreenReaderOutput</code></strong><br />
      Screen reader announces: <em>"Edit. Edit"</em>
    </EuiText>
  </EuiFlexItem>
</EuiFlexGroup>

<EuiSpacer @size='m' />

<EuiFlexGroup @gutterSize='m' @alignItems='center'>
  <EuiFlexItem @grow={{false}}>
    <EuiToolTip @content='Edit' @disableScreenReaderOutput={{true}}>
      <EuiButtonIcon aria-label='Edit' @iconType='pencil' />
    </EuiToolTip>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiText @size='s'>
      <strong>With <code>@disableScreenReaderOutput</code></strong><br />
      Screen reader announces: <em>"Edit"</em>
    </EuiText>
  </EuiFlexItem>
</EuiFlexGroup>
</template>
```
