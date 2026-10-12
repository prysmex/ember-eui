---
title: Modal
---
<EuiSpacer/>
<EuiPageHeader @pageTitle="Modal"/>
<EuiSpacer @size="l" />

<EuiText>

A modal focuses the user on a **short** task or decision: it covers the
page with a mask and traps keyboard focus until it closes. For longer
content or forms that benefit from keeping the page in view, use a
flyout; for yes/no questions, `EuiConfirmModal`.

```hbs
{{#if this.isOpen}}
  <EuiModal @onClose={{this.close}}>
    <EuiModalHeader>
      <EuiModalHeaderTitle>
        <EuiTitle @size="m" @tagName="h1">Rename dashboard</EuiTitle>
      </EuiModalHeaderTitle>
    </EuiModalHeader>
    <EuiModalBody>…</EuiModalBody>
    <EuiModalFooter>
      <EuiButtonEmpty {{on "click" this.close}}>Cancel</EuiButtonEmpty>
      <EuiButton @fill={{true}} {{on "click" this.save}}>Save</EuiButton>
    </EuiModalFooter>
  </EuiModal>
{{/if}}
```

Render the modal only while it is open (`{{#if}}`) and close it in
`@onClose`, which the close button and the Escape key call. Clicking the
mask closes it only with `@clickOutsideToClose={{true}}`, since modals
usually hold an important decision. Always offer a button that closes
the modal.

</EuiText>

<EuiHorizontalRule />

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

The modal is a `role="dialog"` with `aria-modal="true"`, described by a
screen reader hint and, unless you pass `aria-label`/`aria-labelledby`,
labelled by its `EuiModalHeaderTitle`. Pass `role="alertdialog"` for
destructive confirmations.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@onClose` | `(e: Event) => void` |  | Called by the close button, Escape and (with `@clickOutsideToClose`) clicks on the mask. Stop rendering the modal here. |
| `@closeButtonAriaLabel` | `string` | "Close this dialog" | Accessible label of the close button. |
| `@maxWidth` | `boolean \| number \| string` | `true` | `true` for EUI's default max width (the `m` breakpoint, 768px), `false` for none (the window width), a number in px or any CSS width (e.g. `'800px'`). |
| `@clickOutsideToClose` | `boolean` |  | Clicking the mask around the modal calls `@onClose`. |
| `@outsideClickCloses` | `boolean` |  | Same as `@clickOutsideToClose` (upstream name). |
| `@initialFocus` | `FocusTarget` | the modal itself | The element focused when the modal opens: a selector, an element or a function returning one. |
| `@isFocusTrapActive` | `boolean` | `true` | Traps keyboard focus inside the modal. |
| `@shouldSelfFocus` | `boolean` | `true` | Focuses the modal itself when it opens. |
| `@isFocusTrapPaused` | `boolean` |  | Pauses the focus trap, e.g. while a nested popover has focus. |
| `@focusTrapOptions` |  |  | Options for the focus trap (focus-trap library), e.g. `{ initialFocus: '#name' }` to focus a field when it opens. Outside clicks reach the mask and Escape is left to the modal by default. |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

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

The title of an EuiModal, styled like upstream's `EuiTitle size="m"`.
EuiModal is labelled by it unless you give the modal an `aria-label` or
`aria-labelledby`.

| Block | Description |
| --- | --- |
| default block | The title text. Wrap it in a heading (e.g. `<h1>`) for the page outline; the heading inherits the title's styles. |

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
| `@title` | `string` |  | Title of the modal (an `<h1>`). Use the `<:title>` block for markup. |
| `@message` | `string` |  | The question or explanation (a `<p>`), e.g. "This can't be undone.". |
| `@cancelButtonText` | `string` |  | Text of the cancel button. Required: there is no default text. |
| `@confirmButtonText` | `string` |  | Text of the confirm button, ideally the action ("Delete report"). Required. |
| `@buttonColor` | `string` | `'primary'` | Color of the confirm button, any `EuiButton` color; `'danger'` for destructive actions. |
| `@defaultFocusedButton` | `'confirm' \| 'cancel'` | the modal itself | The button focused when the modal opens: `'confirm'` or `'cancel'`. |
| `@confirmButtonDisabled` | `boolean` |  | Disables the confirm button, e.g. until a checkbox is checked. |
| `@isLoading` | `boolean` |  | Shows a spinner in the confirm button while the action runs. |
| `@maxWidth` |  | `true` | Width cap, as `EuiModal`'s `@maxWidth`. |
| `@onCancel` (required) | `() => void` |  | Called by the cancel and close buttons and Escape. Close the modal here. |
| `@onConfirm` (required) | `() => void` |  | Called by the confirm button. |

| Block | Description |
| --- | --- |
| `<:title>` | The title, after `@title`. |
| default block | The body, after `@message` (e.g. a checkbox or details). |

</EuiText>
<!-- api:end -->
