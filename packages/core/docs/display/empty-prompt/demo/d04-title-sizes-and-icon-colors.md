---
order: 4
---

# Title sizes and icon colors

<EuiText>

Other customization options include changing the `@titleSize` to any of the **EuiTitle** sizes and `@iconColor`. When using an application or solution logo as the `@iconType`, you can reset to the multi-tone colors with `@iconColor="default"`.

</EuiText>

```gjs component
import { EuiButton, EuiEmptyPrompt } from '@ember-eui/core/components';
import { array } from '@ember/helper';

const ActionButton1 = <template><EuiButton @color="primary">Add a case</EuiButton></template>;

<template>
<EuiEmptyPrompt
  @iconType="securityAnalyticsApp"
  @iconColor="default"
  @title="Start adding cases"
  @titleSize="xs"
  @body="Add a new case or change your filter settings."
  @actions={{array ActionButton1}}
/>
</template>
```
