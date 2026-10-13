---
order: 9
---

# Horizontal logo

<EuiText>

`EuiHeaderLogo` shows the Elastic glyph by default. `@logoType="horizontal"`
shows the full Elastic logo with its wordmark instead (24px tall). `@iconTitle`
is its accessible name, "Elastic" by default. The artwork is the Elastic
logo, a trademark of Elasticsearch B.V.

</EuiText>

```gjs component
import { EuiHeader, EuiHeaderSection, EuiHeaderSectionItem, EuiHeaderLogo } from '@ember-eui/core/components';

<template>
  <EuiHeader>
    <EuiHeaderSection>
      <EuiHeaderSectionItem>
        <EuiHeaderLogo @href="#" @logoType="horizontal" />
      </EuiHeaderSectionItem>
    </EuiHeaderSection>
  </EuiHeader>
</template>
```
