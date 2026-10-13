---
order: 2
---

# Initials

<EuiText>

The initials displayed in the avatar try to be smart based on the name argument. If the name contains spaces, it will display the first character of each word, **always maxing out at 2 characters**. You can customize this by passing a combination of `@initialsLength` and/or `@initials` arguments. However, the avatar will still always max out at 2 characters.

</EuiText>

```gjs component
import { EuiAvatar, EuiFlexGroup, EuiSpacer, EuiTitle } from '@ember-eui/core/components';

<template>
<EuiTitle @size="xs"><h3>Single vs multi-word</h3></EuiTitle>
<EuiSpacer />
<EuiFlexGroup @responsive={{false}} @gutterSize="xs">
  <EuiAvatar @name="Single" />
  <EuiAvatar @name="Two Words" />
  <EuiAvatar @name="More Than Two Words" />
  <EuiAvatar @name="lower case" @casing="lowercase" />
</EuiFlexGroup>
<EuiSpacer />
<EuiTitle @size="xs"><h3>Custom</h3></EuiTitle>
<EuiSpacer />
<EuiFlexGroup @responsive={{false}} @gutterSize="xs">
  <EuiAvatar @name="Kibana" @initialsLength={{2}} @casing="capitalize" />
  <EuiAvatar @name="Leonardo Dude" @initialsLength={{1}} />
  <EuiAvatar @name="Not provided" @initials="?" />
  <EuiAvatar
    @name="Engineering User"
    @initials="En"
    @casing="none"
    @initialsLength={{2}}
  />
</EuiFlexGroup>
</template>
```
