---
order: 5
---

# Disabled

<EuiText>

While **EuiAvatar** doesn't accept any interactive behaviors itself, you can create a visually presented disabled avatar by adding `@isDisabled` when placed within a disabled element.

</EuiText>

```gjs component
import { EuiAvatar } from '@ember-eui/core/components';

<template>
<div>
  <EuiAvatar
    @size="m"
    @type="space"
    @name="Disabled"
    @initials="Di"
    @initialsLength={{2}}
    @isDisabled={{true}}
  />
  &emsp;
  <EuiAvatar
    @size="m"
    @type="user"
    @name="User"
    @initials="En"
    @initialsLength={{2}}
    @isDisabled={{true}}
  />
  &emsp;
  <EuiAvatar
    @size="m"
    @name="Cat"
    @imageUrl="https://picsum.photos/id/40/64"
    @isDisabled={{true}}
  />
  &emsp;
  <EuiAvatar
    @size="m"
    @name="Management"
    @iconType="managementApp"
    @isDisabled={{true}}
  />
</div>
</template>
```
