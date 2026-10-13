---
order: 4
---

# Button as link

<EuiText>

Use `EuiButton` for actions and `EuiLink` for text-based navigation. Buttons and links have different semantic and technical implications. Buttons accept `@href` (renders as `<a>`) or an `{{on "click"}}` handler (renders as `<button>`). Using both simultaneously is generally not recommended. If you are creating a purely text-based link, use `EuiLink` instead.

</EuiText>

```gjs component
import { EuiButton, EuiButtonEmpty, EuiFlexGroup, EuiFlexItem } from '@ember-eui/core/components';

<template>
<EuiFlexGroup @responsive={{false}} @wrap={{true}} @gutterSize="s" @alignItems="center">
  <EuiFlexItem @grow={{false}}>
    <EuiButton @href="#using-href-and-onclick">Button with href</EuiButton>
  </EuiFlexItem>

  <EuiFlexItem @grow={{false}}>
    <EuiButtonEmpty @href="#using-href-and-onclick">
      Empty button with href
    </EuiButtonEmpty>
  </EuiFlexItem>
</EuiFlexGroup>
</template>
```
