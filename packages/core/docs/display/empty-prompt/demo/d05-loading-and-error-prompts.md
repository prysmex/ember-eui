---
order: 5
---

# Loading and error prompts

<EuiText>

Empty prompts can also be used to emulate loading and error states, by utilizing the same patterns.

For **loading** states, instead of passing a `@iconType`, you can provide a custom icon in the `<:icon>` block and pass in one of our loading components.

</EuiText>

```gjs component
import { EuiCode, EuiEmptyPrompt, EuiLoadingLogo, EuiSpacer, EuiText } from '@ember-eui/core/components';

<template>
<EuiEmptyPrompt @title="Loading Dashboards">
  <:icon>
    <EuiLoadingLogo @logo="logoKibana" @size="xl" />
  </:icon>
</EuiEmptyPrompt>
<EuiSpacer @size="l" />
<EuiText>
  <p>For <strong>error</strong> states, you can simply set the <EuiCode>@color</EuiCode> to <EuiCode>danger</EuiCode>.</p>
</EuiText>
<EuiSpacer />
<EuiEmptyPrompt
  @iconType="error"
  @color="danger"
  @title="Unable to load your dashboards"
  @body="There was an error loading the Dashboard application. Contact your administrator for help."
/>
</template>
```
