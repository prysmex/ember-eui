---
order: 4
---

# Icons

<EuiText>

Icons can also be displayed instead of initials or images. When simply passing an `@iconType`, it will both size and color appropriately based on the other **EuiAvatar** arguments. To customize these specifically, pass `@iconSize` and `@iconColor`.

If your icon has multiples or custom colors like a logo, you can keep the default `@iconColor` by passing `null`. Otherwise it will get the appropriate contrast acceptable variant. Just ensure that you also are providing an accessible background color to match that of the icon's color.

</EuiText>

```gjs component
import { EuiAvatar, EuiSpacer, EuiTitle } from '@ember-eui/core/components';

<template>
<EuiTitle @size="xs"><h2>Avatar colors and sizes</h2></EuiTitle>
<EuiSpacer />
<EuiAvatar @size="s" @name="Small size" @iconType="managementApp" />
&emsp;
<EuiAvatar @size="m" @name="Medium size" @iconType="managementApp" />
&emsp;
<EuiAvatar @size="l" @color="subdued" @name="Large" @iconType="managementApp" />
&emsp;
<EuiAvatar @size="xl" @color="plain" @name="Plain color" @iconType="managementApp" />
<EuiSpacer />
<EuiTitle @size="xs"><h2>Icon colors and sizes</h2></EuiTitle>
<EuiSpacer />
<EuiAvatar @name="Avatar color" @iconType="managementApp" @color="#BD10E0" />
&emsp;
<EuiAvatar
  @name="Custom iconColor"
  @iconType="managementApp"
  @color="#E6F1FA"
  @iconColor="primary"
/>
&emsp;
<EuiAvatar
  @name="Null iconColor"
  @iconType="managementApp"
  @color="#D3DAE6"
  @iconColor={{null}}
/>
&emsp;
<EuiAvatar @name="Large iconSize" @iconType="managementApp" @iconSize="l" />
</template>
```
