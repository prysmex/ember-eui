---
title: Expression
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Expression"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiExpression` builds sentence-like rules and queries, like
**WHEN** `avg()` **OF** `bytes` **IS ABOVE** `100`. Each expression is a
description (the colored, uppercase part) and a value.

```hbs
<EuiExpression @description="when" @value="avg()" />
```

With `@onClick` it is a button with a dashed underline, which usually
opens an `EuiPopover` to edit the value; set `@isActive` while the popover
is open. `@isInvalid` flags a value that needs fixing. `@display="columns"`
stacks expressions with their descriptions aligned.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiExpression

One part of a sentence-like query or rule, e.g. **WHEN** `avg()` or
**IS ABOVE** `100`: a description and a value. With `@onClick` it is a
button, usually opening a popover to edit the value.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@description` | `string` |  | First part, e.g. "when". Use the `<:description>` block for markup. |
| `@value` | `string` |  | Second part, e.g. "avg()". Use the `<:value>` block for markup. |
| `@color` |  | `'success'` | Color of the description: `'subdued'`, `'primary'`, `'success'`, `'accent'`, `'warning'` or `'danger'`. |
| `@uppercase` | `boolean` | `true` | Uppercases the description. |
| `@isActive` | `boolean` |  | Solid underline, e.g. while its popover is open. |
| `@isInvalid` | `boolean` |  | Shows it in danger color with an alert icon. |
| `@onClick` | `(event: MouseEvent) => void` |  | Makes it a `<button>` with a dashed underline. |
| `@display` | `'inline' \| 'columns'` | `'inline'` | `'inline'` (in a sentence) or `'columns'` (description and value in two columns, to stack several). |
| `@descriptionWidth` | `number \| string` | `'20%'` | Width of the description in columns display. |
| `@textWrap` | `'break-word' \| 'truncate'` | `'break-word'` | `'break-word'` or `'truncate'` long values. |

| Block | Description |
| --- | --- |
| `<:description>` | Markup for the description, instead of `@description`. |
| `<:value>` | Markup for the value, instead of `@value`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>` / `<span>`.

</EuiText>
<!-- api:end -->
