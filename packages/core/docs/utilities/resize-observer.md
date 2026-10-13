---
title: Resize observer
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Resize observer"/>
<EuiSpacer @size="l" />

<EuiText>

**EuiResizeObserver** is a wrapper around the [Resize Observer API](https://developer.mozilla.org/docs/Web/API/ResizeObserver) which allows watching for changes to the content rectangle of DOM elements. Unlike the mutation observer, it does not take parameters, but it does fire a more efficient and informative callback when resize events occur.

In Ember EUI it is the `resize-observer` modifier (it replaces both the render prop component and the `useResizeObserver` hook). It calls `onResize` with the element's new
`{ width, height }` whenever its size changes (a
[ResizeObserver](https://developer.mozilla.org/docs/Web/API/ResizeObserver)).

```hbs
<div {{resize-observer onResize=this.sizeChanged}}>…</div>
```

In `.gjs`/`.gts`: `import { resizeObserver } from '@ember-eui/core/modifiers';`.

</EuiText>

<EuiHorizontalRule />

