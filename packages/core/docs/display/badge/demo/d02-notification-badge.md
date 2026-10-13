---
order: 2
---

# Notification badge

<EuiText>

**EuiNotificationBadge** should be used to showcase the number of notifications, alerts, or hidden selections. This badge type is commonly used in the **EuiHeader** and **EuiFilterButton** components.

</EuiText>

```gjs component
import { EuiFlexGroup, EuiNotificationBadge } from '@ember-eui/core/components';

<template>
<EuiFlexGroup @responsive={{false}} @gutterSize="s">
  <EuiNotificationBadge>1</EuiNotificationBadge>
  <EuiNotificationBadge @color="success">2</EuiNotificationBadge>
  <EuiNotificationBadge @color="subdued">3</EuiNotificationBadge>
</EuiFlexGroup>
</template>
```
