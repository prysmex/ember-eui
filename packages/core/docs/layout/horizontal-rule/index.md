---
title: Horizontal Rule
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Horizontal Rule"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiHorizontalRule` draws a divider between sections. `@size` makes it
`full` (default), `half` or `quarter` width and `@margin` sets the space
above and below (`none` to `xxl`, `l` by default).

```hbs
<EuiHorizontalRule @margin="m" />
```

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiHorizontalRule

A divider line between sections.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@margin` |  | `'l'` | Space above and below: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'`, `'xl'` or `'xxl'`. |
| `@size` |  | `'full'` | Width: `'full'`, `'half'` or `'quarter'`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<hr>`.

</EuiText>
<!-- api:end -->
