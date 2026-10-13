---
order: 2
---

# Info

<EuiText>

Most often, callouts are configured to convey semantic meaning such as important information, confirmation, warnings, errors, and highlights.

Use **EuiCallOut** to communicate general information to the user.

</EuiText>

```gjs component
import { EuiCallOut, EuiLink, EuiSpacer } from '@ember-eui/core/components';

<template>
<div>
  <EuiCallOut
    @title="Check it out, here's a really long title that will wrap within a narrower browser"
  >
    <p>
      Here&rsquo;s some stuff that you need to know. We can make this text
      really long so that, when viewed within a browser that&rsquo;s fairly
      narrow, it will wrap, too.
    </p>
    <p>
      And some other stuff on another line, just for kicks. And
      <EuiLink @href="#">here&rsquo;s a link</EuiLink>.
    </p>
  </EuiCallOut>

  <EuiSpacer @size="m" />

  <EuiCallOut @title="Callouts can have only a title." />

  <EuiSpacer @size="m" />

  <EuiCallOut
    @size="s"
    @title="This is a small callout for more non-intrusive but constant messages."
  />
</div>
</template>
```
