---
title: Copy
---

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

`@tooltipProps` takes EuiToolTip's args for the tooltip, e.g. a block
anchor for a full-width button (as upstream's icon tables do):

</EuiText>

```gjs component
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { EuiButton, EuiCopy } from '@ember-eui/core/components';

<template>
  <EuiCopy
    @textToCopy="#54B399"
    @beforeMessage="Click to copy"
    @afterMessage="#54B399 copied"
    @tooltipProps={{hash display="block" position="bottom"}}
    as |copy|
  >
    <EuiButton @fullWidth={{true}} {{on "click" copy}}>#54B399</EuiButton>
  </EuiCopy>
</template>
```

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
| `@tooltipProps` |  |  | EuiToolTip args for the tooltip (upstream `tooltipProps`), e.g. `(hash position="bottom" anchorProps=(hash data-test-subj="copy"))`. Every EuiToolTip arg except `content` and `onMouseOut` is supported; `onBlur` is called before the copied message resets. |

Deprecated: `@anchor` (Has no effect: the tooltip is anchored to the block's content.).

| Block | Description |
| --- | --- |
| default block | The element triggering the copy; call the yielded function from it: `as \|copy\|` → `<EuiButton {{on "click" copy}}>Copy</EuiButton>`. |

</EuiText>
<!-- api:end -->
