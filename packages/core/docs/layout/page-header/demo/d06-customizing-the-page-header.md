---
order: 6
---

# Customizing the page header

<EuiText>

The page header content args are helpful args to push content into established Elastic page layout patterns. They are completely optional and by design, inflexible. If you need a layout that does not match these patterns you can pass in your own default block utilizing the `EuiPageHeaderSection` components.

</EuiText>

```gjs component
import { EuiPageHeader, EuiPageHeaderSection, EuiTitle } from '@ember-eui/core/components';

<template>
  <EuiPageHeader @bottomBorder={{true}}>
    <EuiPageHeaderSection>
      <EuiTitle @size="l">
        <h1>Page title</h1>
      </EuiTitle>
    </EuiPageHeaderSection>
    <EuiPageHeaderSection>Page abilities</EuiPageHeaderSection>
  </EuiPageHeader>
</template>
```
