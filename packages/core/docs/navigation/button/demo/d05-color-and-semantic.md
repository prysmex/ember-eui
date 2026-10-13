---
order: 5
---

# Color and semantic

<EuiText>

Buttons come in various colors, with `primary`, `text`, or `danger` being typical choices. `primary` is the default. `danger`, `warning`, and `success` buttons convey specific meanings:

- **Danger**: negative, destructive action, critical attention.
- **Warning**: caution, extra attention.
- **Success**: positive, successfully-completed action, least attention.

Do not override button styles. EUI provides arguments to manage color, size, and state to cover various use cases, ensuring consistent interactions.

</EuiText>

```gjs component
import { EuiButton, EuiFlexGroup, EuiFlexItem, EuiSpacer, EuiText } from '@ember-eui/core/components';

<template>
<EuiFlexGroup @responsive={{false}} @gutterSize="s" @alignItems="flexStart">
  <EuiFlexItem @grow={{false}}>
    <EuiButton @color="danger">Danger</EuiButton>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButton @color="warning">Warning</EuiButton>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButton @color="success">Success</EuiButton>
  </EuiFlexItem>
</EuiFlexGroup>

<EuiSpacer />

<EuiText>

**Avoid direct use** of semantic buttons unless they are part of existing EUI components. Direct use of `danger` (red) buttons is limited to confirming **destructive** outcomes, like deleting data, to maintain its elevated meaning. `success` (green) buttons indicate **unsaved or unprocessed** changes (draft or dirty state) to mitigate work loss. **Do not rely solely on color** for meaning; include a label or icon for accessibility and clarity.

</EuiText>
</template>
```
