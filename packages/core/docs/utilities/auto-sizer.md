<EuiSpacer/>
<EuiPageHeader @pageTitle="Auto sizer"/>

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
