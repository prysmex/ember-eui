---
title: Resize observer
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Resize observer"/>
<EuiSpacer @size="l" />

<EuiText>

The `resize-observer` modifier calls `onResize` with the element's new
`{ width, height }` whenever its size changes (a
[ResizeObserver](https://developer.mozilla.org/docs/Web/API/ResizeObserver)).

```hbs
<div {{resize-observer onResize=this.sizeChanged}}>…</div>
```

In `.gjs`/`.gts`: `import { resizeObserver } from '@ember-eui/core/modifiers';`.

</EuiText>

<EuiHorizontalRule />

