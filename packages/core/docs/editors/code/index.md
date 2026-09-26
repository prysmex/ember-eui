---
title: Code
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Code"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiCode` shows inline code and `EuiCodeBlock` multi-line code, both
with syntax highlighting for a `@language` (`js`, `ts`, `html`, `css`,
`json`, `bash`, `hbs`, `sql`, …; unknown languages are shown as plain
text).

```hbs
<p>Run <EuiCode>pnpm install</EuiCode> first.</p>

<EuiCodeBlock @language="json" @isCopyable={{true}} @lineNumbers={{true}}>
  {{this.config}}
</EuiCodeBlock>
```

Pass the code as text (e.g. a string property); it is highlighted as the
content changes. `EuiCodeBlock` can add a copy button (`@isCopyable`),
line numbers (optionally highlighted), a max height with a full screen
button (`@overflowHeight`) and virtualized rendering for very long code
(`@isVirtualized`). These components display static code; for editing
code, use a code editor.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiCode

Inline code with syntax highlighting: `<EuiCode @language="js">const a = 1;</EuiCode>`.
For multi-line code use EuiCodeBlock.

Also takes the args of `EuiCodeSharedProps`.

| Block | Description |
| --- | --- |
| default block | The code, as text. |

### EuiCodeBlock

Multi-line code with syntax highlighting, optional copy button, line
numbers and full screen view:
`<EuiCodeBlock @language="js" @isCopyable={{true}}>{{this.code}}</EuiCodeBlock>`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@paddingSize` | `PaddingSize` | `'l'` | Padding around the code: `'none'`, `'s'`, `'m'` or `'l'`. |
| `@fontSize` | `FontSize` | `'s'` | `'s'`, `'m'` or `'l'`. |
| `@whiteSpace` | `'pre' \| 'pre-wrap'` | `'pre-wrap'` | Specify how `white-space` inside the element is handled. `pre` respects line breaks/white space but doesn't force them to wrap the line `pre-wrap` respects line breaks/white space but does force them to wrap the line when necessary. |
| `@isCopyable` | `boolean` |  | Displays an icon button to copy the code snippet to the clipboard. |
| `@lineNumbers` | `boolean \| LineNumbersConfig` |  | Displays line numbers. Optionally accepts a configuration object for setting the starting number and visual highlighting ranges: `{ start: 100, highlight: '1, 5-10, 20-30, 40' }` |
| `@overflowHeight` | `number \| string` |  | Sets the maximum container height. Accepts a pixel value (`300`) or a percentage (`'100%'`) Ensure the container has calcuable height when using a percentage |
| `@isVirtualized` | `boolean` |  | Renders code block lines virtually. Useful for improving load times of large code blocks. When using this configuration, `overflowHeight` is required and `whiteSpace` can only be `pre`. |

Also takes the args of `EuiCodeSharedProps`.

| Block | Description |
| --- | --- |
| default block | The code, as text (e.g. a string from your component). |

</EuiText>
<!-- api:end -->
