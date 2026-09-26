---
title: Code
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Code"/>

<EuiSpacer @size='l' />

<EuiCallOut>
  <:body>
    <strong>EuiCode</strong> and <strong>EuiCodeBlock</strong> are intended to render static lines or blocks of code in <strong>read-only</strong> contexts. If you need capabilities to edit, or want to print long code (e.g., printing JSON from an API), we recommend installing a version of Monaco. If you are building within the Kibana platform, you can use their CodeEditor.
  </:body>
</EuiCallOut>

<EuiText>
<p>
  The <strong>EuiCode</strong> and <strong>EuiCodeBlock</strong> components support <a href="https://prismjs.com/#supported-languages" target="_blank">all language syntaxes</a> supported by the <EuiCode>prism</EuiCode> <a href="https://prismjs.com" target="_blank">library</a>. The language prop can also be omitted to simply render formatted but unhighlighted code.
</p>
<p>
  JSX code (often React) has distinct language syntaxes from the base JavaScript and TypeScript languages. For these instances, use <EuiCode @language="jsx">@language="jsx"</EuiCode> or <EuiCode @language="tsx">@language="tsx"</EuiCode>.
</p>
</EuiText>

<EuiHorizontalRule />
<EuiSpacer/>

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
