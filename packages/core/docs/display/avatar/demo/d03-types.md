---
order: 3
---

# Types

<EuiText>

The avatar `@type`, which primarily defines the shape, is a keyword and can be `"user"` (default) or `"space"` (for workspaces).

</EuiText>

```gjs component
import { EuiAvatar, EuiSpacer, EuiTitle } from '@ember-eui/core/components';

<template>
<div>
  <EuiTitle @size="xs"><h3>Spaces</h3></EuiTitle>
  <EuiSpacer />
  <EuiAvatar @size="s" @type="space" @name="Kibana" />
  &emsp;
  <EuiAvatar @type="space" @name="Leonardo Space" />
  &emsp;
  <EuiAvatar @size="l" @type="space" @name="Default" />
  &emsp;
  <EuiAvatar @size="xl" @type="space" @name="Engineering Space" />
</div>
</template>
```
