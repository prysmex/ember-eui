---
title: Modal
---
<EuiSpacer/>
<EuiPageHeader @pageTitle="Modal"/>

<EuiSpacer @size="l" />

<EuiText>
  A modal works best for focusing users' attention on a <strong>short</strong> amount of content and getting them to make a decision. Use it to temporarily interrupt a user’s current task and block interactions to the content below it. If your modal content is more complex, or requires considerable time to complete, consider using an EuiFlyout instead.
</EuiText>

<EuiHorizontalRule/>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiModal

A dialog over the page, with a mask behind it. Render it only while
open: `{{#if this.isOpen}}<EuiModal @onClose={{…}}>…</EuiModal>{{/if}}`.
For yes/no questions use EuiConfirmModal.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@onClose` | `(e: Event) => void` |  | Called by the close button, Escape and (with `@clickOutsideToClose`) clicks on the mask. Stop rendering the modal here. |
| `@maxWidth` | `boolean \| string` | the content's width | `true` for EUI's default max width, or any CSS width (e.g. `'800px'`). |
| `@clickOutsideToClose` | `boolean` |  | Clicking the mask around the modal calls `@onClose`. |
| `@isFocusTrapActive` | `boolean` | `true` | Traps keyboard focus inside the modal. |
| `@shouldSelfFocus` | `boolean` | `true` | Focuses the modal itself when it opens. |
| `@isFocusTrapPaused` | `boolean` |  | Pauses the focus trap, e.g. while a nested popover has focus. |
| `@focusTrapOptions` |  |  | Options for the focus trap (focus-trap library), e.g. `{ initialFocus: '#name' }` to focus a field when it opens. |

| Block | Description |
| --- | --- |
| default block | `EuiModalHeader`, `EuiModalBody` and `EuiModalFooter`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiModalHeader

The top of an EuiModal.

| Block | Description |
| --- | --- |
| default block | An `EuiModalHeaderTitle`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiModalHeaderTitle

The title of an EuiModal.

| Block | Description |
| --- | --- |
| default block | The title text (wrap it in a heading, e.g. `<h1>`). |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiModalBody

The scrolling content of an EuiModal.

| Block | Description |
| --- | --- |
| default block | The content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiModalFooter

The bottom of an EuiModal, with its buttons (right aligned).

| Block | Description |
| --- | --- |
| default block | The buttons, e.g. an `EuiButtonEmpty` to cancel and an `EuiButton @fill={{true}}`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiConfirmModal

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@title` | `string` |  | Title of the modal. Use the `<:title>` block for markup. |
| `@message` | `string` |  | The question or explanation, e.g. "This can't be undone.". |
| `@cancelButtonText` | `string` |  | Text of the cancel button. Required: there is no default text. |
| `@confirmButtonText` | `string` |  | Text of the confirm button, ideally the action ("Delete report"). Required. |
| `@buttonColor` | `string` | `'primary'` | Color of the confirm button, any `EuiButton` color; `'danger'` for destructive actions. |
| `@confirmButtonDisabled` | `boolean` |  | Disables the confirm button, e.g. until a checkbox is checked. |
| `@isLoading` | `boolean` |  | Shows a spinner in the confirm button while the action runs. |
| `@onCancel` (required) | `() => void` |  | Called by the cancel and close buttons and Escape. Close the modal here. |
| `@onConfirm` (required) | `() => void` |  | Called by the confirm button. |

| Block | Description |
| --- | --- |
| `<:title>` | The title, after `@title`. |
| default block | The body, after `@message` (e.g. a checkbox or details). |

</EuiText>
<!-- api:end -->
