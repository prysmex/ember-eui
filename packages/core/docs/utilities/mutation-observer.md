---
title: Mutation observer
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Mutation observer"/>
<EuiSpacer @size="l" />

<EuiText>

The `mutation-observer` modifier calls a function when an element's
content or attributes change (a
[MutationObserver](https://developer.mozilla.org/docs/Web/API/MutationObserver)).

```hbs
<div {{mutation-observer onMutation=this.contentChanged observerOptions=(hash childList=true subtree=true)}}>
  …
</div>
```

In `.gjs`/`.gts`, import it:
`import { mutationObserver } from '@ember-eui/core/modifiers';`.
`observerOptions` takes the MutationObserver options (`childList`,
`subtree`, `attributes`, `characterData`); `onMutation` receives the
mutation records.

</EuiText>

<EuiHorizontalRule />

