---
title: Inner text
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Inner text"/>
<EuiSpacer @size="l" />

<EuiText>

When you need the text content of an element whose children may be wrapped or interspersed with other components (for example to use a truncated label as its `title`), use **EuiInnerText**. It yields a function to call with the target element and the element's current `innerText`, which updates when the content changes (it uses a mutation observer). In Ember the yielded function is attached with a render modifier such as `{{didInsert}}`; upstream's React `ref` and `useInnerText` hook have no separate Ember counterpart.

```hbs
<EuiInnerText as |ref innerText|>
  <span {{didInsert ref}} title={{innerText}}>…</span>
</EuiInnerText>
```

`@fallback` is the text used when the element's text cannot be read.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiInnerText

Tracks the text content of an element, e.g. to use a truncated label's
full text as its `title`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@fallback` | `string` | `''` | Text used when the element's text cannot be read. |

| Block | Description |
| --- | --- |
| default block | Yields a function to call with the element to track (e.g. with `did-insert`) and its current text. |

</EuiText>
<!-- api:end -->
