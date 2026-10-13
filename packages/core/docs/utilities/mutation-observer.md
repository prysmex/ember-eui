---
title: Mutation observer
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Mutation observer"/>
<EuiSpacer @size="l" />

<EuiText>

**EuiMutationObserver** is a wrapper around the
[Mutation Observer API](https://developer.mozilla.org/docs/Web/API/MutationObserver)
which allows watching for DOM changes to elements and their children. It
takes the same configuration object as the browser API to describe what to
watch for, and fires the callback when that mutation happens.

In Ember EUI it is the `mutation-observer` modifier (instead of upstream's
render prop component and its `ref` callback): put it on the element you
wish to observe.

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

