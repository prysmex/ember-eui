---
order: 2
---

# Inline edit title

<EuiText>

`EuiInlineEditTitle` renders its read mode text as an `EuiTitle` with the
`@heading` element (`'h1'` to `'h6'`, or `'span'`), and edits it at the
title's `@size`. When read only, the button reads as that heading.

</EuiText>

```hbs template
<EuiInlineEditTitle
  @inputAriaLabel="Edit the page title"
  @heading="h2"
  @defaultValue="Dashboard title"
/>
<EuiSpacer />
<EuiInlineEditTitle
  @inputAriaLabel="Edit the section title"
  @heading="h3"
  @size="xs"
  @defaultValue="A small section title"
/>
```
