---
order: 6
---

# Skip link

<EuiText>

The <strong>EuiSkipLink</strong> component allows users to bypass navigation, or ornamental elements, and quickly reach the main content of the page. It requires a <EuiCode>@destinationId</EuiCode> which should match the <EuiCode>id</EuiCode> of your main content. If your ID does not correspond to a valid element, the skip link will fall back to focusing the <EuiCode>&lt;main&gt;</EuiCode> tag on your page, if it exists.

<em>Tab through the following section to verify the Skip to content button is visible on focus.</em>

</EuiText>

<EuiSpacer />

```gjs component
import { EuiSkipLink, EuiText } from '@ember-eui/core/components';

<template>
<EuiText id='skip-link-example'>
  <p>The following skip links are only visible on focus:</p>
  <EuiSkipLink
    @destinationId='skip-link-example'
    @overrideLinkBehavior={{true}}
  >
    Skips to this example container
  </EuiSkipLink>
  <EuiSkipLink @destinationId='' @overrideLinkBehavior={{true}}>
    Falls back to main container
  </EuiSkipLink>
</EuiText>
</template>
```
