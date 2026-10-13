---
order: 2
---

# Showing on focus

<EuiText>

If the wrapped element is <strong>focusable</strong>, you must use the <EuiCode>@showOnFocus</EuiCode> argument to visibly show the element to all users when focused.

<em>Tab through the following example with your keyboard to verify the element is visible on focus.</em>

</EuiText>

<EuiSpacer />

```gjs component
import { EuiButtonIcon, EuiLink, EuiScreenReaderOnly, EuiText, EuiToolTip } from '@ember-eui/core/components';

<template>
<EuiText>
  <p>
    This link is visible to all on focus:
    <EuiScreenReaderOnly @showOnFocus={{true}}>
      <EuiLink @href='#/utilities/accessibility'>Link text</EuiLink>
    </EuiScreenReaderOnly>
  </p>
  <p>
    This tooltip + button is visible on focus within:
    <EuiScreenReaderOnly @showOnFocus={{true}}>
      <span>
        <EuiToolTip @content='Information'>
          <EuiButtonIcon @iconType='info' aria-label='Information' />
        </EuiToolTip>
      </span>
    </EuiScreenReaderOnly>
  </p>
</EuiText>
</template>
```
