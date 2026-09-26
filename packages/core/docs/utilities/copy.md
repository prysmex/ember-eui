<EuiSpacer/>
<EuiPageHeader @pageTitle="Copy"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiCopy` copies text to the clipboard from any element and shows a
tooltip. It yields a `copy` function to call on click:

```hbs
<EuiCopy @textToCopy={{this.apiKey}} @beforeMessage="Click to copy" @afterMessage="Copied!" as |copy|>
  <EuiButtonIcon @iconType="copyClipboard" aria-label="Copy the API key" {{on "click" copy}} />
</EuiCopy>
```

Without the component, call `copyToClipboard(text)` from
`@ember-eui/core/utils/copy-to-clipboard`; it returns whether it worked.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiCopy

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@textToCopy` (required) | `string` |  | Text that will be copied to clipboard when copy function is executed. |
| `@beforeMessage` | `string` |  | Tooltip message displayed before copy function is called, e.g. "Click to copy". No tooltip without it. |
| `@afterMessage` | `string` |  | Tooltip message displayed after copy function is called that lets the user know that 'textToCopy' has been copied to the clipboard, e.g. "Copied". |

Deprecated: `@anchor` (Has no effect: the tooltip is anchored to the block's content.).

| Block | Description |
| --- | --- |
| default block | The element triggering the copy; call the yielded function from it: `as \|copy\|` → `<EuiButton {{on "click" copy}}>Copy</EuiButton>`. |

</EuiText>
<!-- api:end -->
