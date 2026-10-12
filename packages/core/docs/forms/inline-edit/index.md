---
title: Inline edit
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Inline edit"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiInlineEditText` and `EuiInlineEditTitle` show text that turns into a
text field when clicked. Read mode is a button showing the text; edit mode
an `EuiFieldText` with save and cancel buttons. **Enter** saves and
**Escape** cancels, and focus returns to the read mode button afterwards.

```hbs
<EuiInlineEditText
  @inputAriaLabel="Edit the description"
  @defaultValue="Click to edit this text"
  @onSave={{this.save}}
/>
```

The input has no visible label, so `@inputAriaLabel` is required. Return
(or resolve to) `false` from `@onSave` to stay in edit mode, for example to
show `@isInvalid` with `@editModeProps.formRowProps.error`; while a promise
is pending, `@isLoading` replaces the buttons with skeletons.

### Shared arguments (`EuiInlineEditCommonArgs`)

| Argument | Type | Description |
| --- | --- | --- |
| `@inputAriaLabel` (required) | `string` | Accessible name of the input. |
| `@defaultValue` | `string` | Initial text (uncontrolled). |
| `@value` / `@onChange` | `string` / `(event) => void` | Controlled text; reset it from `@onCancel`. |
| `@onSave` | `(value) => void \| boolean \| Promise` | Called with the edited text; `false` keeps edit mode. |
| `@onCancel` | `(previousValue) => void` | Called with the read mode text on cancel. |
| `@placeholder` | `string` | Shown while there is no text. |
| `@startWithEditOpen` | `boolean` | Starts in edit mode. |
| `@isLoading` / `@isInvalid` | `boolean` | Edit mode loading / invalid states. |
| `@isReadOnly` | `boolean` | Locks read mode, without the pencil icon. |
| `@readModeProps` | `object` | `onClick`, `buttonRef`, `title`, `aria-describedby`, `data-test-subj` of the read mode button. |
| `@editModeProps` | `object` | `formRowProps` (`error`, `helpText`), `inputProps` (`onChange`, `onKeyDown`, `inputRef`, `name`, `maxLength`, …), `saveButtonProps` / `cancelButtonProps`. |
| `@css` | `EuiCss` | Extra styles composed last into the root class. |

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiInlineEditText

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@size` | `'xs' \| 's' \| 'm'` | `'m'` | Text size: `'xs'`, `'s'` or `'m'`. |

Also takes the args of `EuiInlineEditCommonArgs`.

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiInlineEditTitle

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@size` | `'xxxs' \| 'xxs' \| 'xs' \| 's' \| 'm' \| 'l'` | `'m'` | Title size, as `EuiTitle`'s `@size`. |
| `@heading` (required) | `EuiInlineEditTitleHeading` |  | Heading level of the title. Use `'span'` for text that should only look like a title. |

Also takes the args of `EuiInlineEditCommonArgs`.

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
