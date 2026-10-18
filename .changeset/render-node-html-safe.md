---
'@ember-eui/core': patch
---

Text props that take text or a component (`EuiRenderNode`, e.g. `EuiToast`'s `@body`) accept an `htmlSafe` string again and render it as HTML, as 14.x toasts did, instead of failing to invoke it as a component. With `@useMarkdownFormat`, an `htmlSafe` toast body is rendered as the HTML it already is, not as markdown.
