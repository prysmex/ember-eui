---
title: Auto sizer
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Auto sizer"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiAutoSizer` measures the space its parent gives it and yields the
width and height in pixels, for content that needs explicit sizes (e.g.
virtualized lists or charts). The parent must have a size.

```hbs
<div style="height: 300px;">
  <EuiAutoSizer as |size|>
    <MyChart @width={{size.width}} @height={{size.height}} />
  </EuiAutoSizer>
</div>
```

`@disableHeight` / `@disableWidth` measure only one dimension and
`@onResize` is called with the new size.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiAutoSizer

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@className` | `string` |  | Optional custom CSS class name to attach to root AutoSizer element. |
| `@defaultHeight` | `number` |  | Default height to use for initial render; useful for SSR |
| `@defaultWidth` | `number` |  | Default width to use for initial render; useful for SSR |
| `@disableHeight` | `boolean` |  | Disable dynamic :height property |
| `@disableWidth` | `boolean` |  | Disable dynamic :width property |
| `@nonce` | `string` |  | Nonce of the inlined stylesheet for Content Security Policy |
| `@onResize` | `(size: Size) => void` |  | Callback to be invoked on-resize |
| `@style` | `Record<string, string>` |  | Optional inline style |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
