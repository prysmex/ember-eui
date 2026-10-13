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


<EuiCallOut @title="Modal vs flyout" @iconType="info" @size="s">
  If your modal content is complex or takes a long time to complete, consider
  using an <strong>EuiFlyout</strong> instead.
</EuiCallOut>

### Focus management

`EuiModal` manages focus for keyboard navigation and accessibility. This
ensures users can navigate modal content effectively, especially those using
screen readers or keyboard-only navigation. When an `EuiModal` is used, it
will automatically:

1. Move focus to the modal when opened
2. Trap focus inside the modal while open
3. Return focus to the trigger element when closed

Use `@initialFocus` (a selector, element or function) to choose what is focused
on open, and `@focusTrapProps` to customize how focus returns: `returnFocus`
is `false` to return focus yourself, or a function that gets the trigger
element and returns `false` to skip the default (for example after focusing
another element). `@focusTrapOptions` gives access to the underlying
focus-trap options.

```hbs
<EuiModal
  @focusTrapProps={{hash returnFocus=this.returnFocus}}
  @onClose={{this.close}}
>
  …
</EuiModal>
```

`EuiConfirmModal` takes the same `@focusTrapProps`, and `@titleProps`
(`className`, `id`, `data-test-subj`) for its title element, e.g. the `id`
for `aria-labelledby`.

<EuiCallOut @title="Manually return focus when the trigger element is removed" @color="warning" @iconType="warning" @size="s">
  If the trigger element is removed from the DOM before the modal closes, focus
  will be "lost" to the document body. In this case, manually return focus to
  an appropriate element.
</EuiCallOut>

### Confirming an action

Use a modal when you need to interrupt a user and ask them to confirm an
action. Structure:

1. **Title** (mandatory)
   - Whenever possible, frame it as a question that provides context for the
     action. Don't use "Are you sure?"
   - Focus the question on what's important to the user and in a way that
     assumes intent from them. For example `Discard 7 changes?` instead of
     `Exit without saving?`
   - Avoid including text variables in the title, especially for things users
     can input without character limits, such as object labels. For example,
     `Apply configuration changes?` instead of `Apply configuration changes to
     Loremipsum-dolorsitamet-consectetur-adipiscing-elit deployment?`
2. **Body** (mandatory)
   - **Cause** (optional): if the context is important to know, add it.
   - **Consequences** (mandatory): let users know what happens if they
     continue. If possible, list the objects that may be impacted. Don't
     repeat the title.
   - **More information** (optional): if necessary, anticipate user questions
     by including a link to a relevant source of information (like docs).
3. **Calls to action** (mandatory)
   - The main action confirms the question asked in the title. If there's
     enough space and it is relevant, include the number of impacted objects
     and their noun. For example `Invite 3 users` instead of `Send invite`.
   - Always provide a secondary CTA that allows users to leave the prompt
     without taking an action. Not all choices are binary: add a third CTA when
     it makes sense for common actions users would want to do.
   - Make sure each CTA is explicit and not ambiguous with the other CTAs next
     to it.

### Confirming a destructive action

Asking to confirm a delete or remove action follows the same principles as the
default pattern, with these additions:

- The main CTA is extra clear on what is about to be deleted with a clear noun,
  in addition to visual clues (`@buttonColor="danger"`).
- The body is unambiguous about what won't be recoverable after the action is
  confirmed.
- Optionally, and depending on the importance of the destructive action, you
  may include an extra confirmation within the body of the modal. If you do so,
  use something generic, such as "delete", that users can copy easily and that
  will remind them of what they are actually deleting.

## Guidelines

A modal says "pay attention to me and nothing else."

- **The header sets the context.** Short and sentence-case, the header should
  indicate what the modal is about.
- **The body is for a single task.** This task should not require a lot of
  explanation or user interaction.
- **Buttons are right-aligned.** The primary action is a filled button, and the
  secondary action is a link button. Labels should use strong action verbs.

### Use a modal to focus on a single action

A modal can gather input necessary for continuing the current workflow. This
type of modal works best for a short, focused task. Use input modals
sparingly, they interrupt the user's workflow.

- Do: a save action is a good use case for a modal. The meaning is clear and
  the content is simple.
- Don't: modals aren't the best design solution for multiple steps or complex
  user input. An in-page form is more appropriate.
- **Open a modal on a user action.** Let a user action, such as a button click,
  open a modal. Don't open a modal from a toolbar action, users don't expect it.
- **Avoid scrolling content.** Modal content should fit in a single view. If
  your modal has a lot of detail or a long list of items, consider a different
  solution, such as a form or a table.
- **Don't stack modals.** Opening a modal on top of a modal might mean your
  workflow is too complex. Instead, use a component that supports multiple
  steps, such as a form or steps.

### Use a modal to confirm an action

The most common use of modals is to confirm a user action. This modal should
start with a question, give users enough information to make a decision, and
restate the action in the button label.

- Do: use a modal for confirmation when the user might lose data. For the body
  text, use one to two short sentences that explain the consequences.
- Don't: confirmations aren't good for messages. Toasts are best for success
  messages because they are less disruptive. Error and warning messages often
  appear directly on the page.

### State the action in both the header and button text

- Do: use the same action verbs in the header and button text.
- Don't: use a vague header such as "Are you sure?" or the button labels "Yes"
  and "No."

### Create separate confirmations for single and bulk actions

- Do: asking users to delete a single item should include the item name in the
  title, if possible. Use single quotes around the name if it helps clarify
  meaning.
- Do: for bulk actions, include the number of items in the title.

### Sometimes a header and buttons are enough

You can omit the body if users understand the decision from the header and
button text alone.

- Do: the header alone is enough when the modal asks the user whether to remove
  an index pattern, since data won't be lost.
- Don't: write body text that simply repeats the title. It doesn't add value.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiModal

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
| `@focusTrapProps` | `EuiModalFocusTrapProps` |  | Focus trap options (upstream `focusTrapProps`): `returnFocus`. |
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
| `@titleProps` |  |  | Attributes of the title element (upstream `titleProps`, which is spread onto it): `className`, `id` and `data-test-subj` (replacing the default `confirmModalTitleText`). |
| `@focusTrapProps` |  |  | Focus trap options, as `EuiModal`'s `@focusTrapProps` (`returnFocus`). |
| `@message` | `string` |  | The question or explanation (a `<p>`), e.g. "This can't be undone.". |
| `@cancelButtonText` | `string` |  | Text of the cancel button. Required: there is no default text. |
| `@confirmButtonText` | `string` |  | Text of the confirm button, ideally the action ("Delete report"). Required. |
| `@buttonColor` | `string` | `'primary'` | Color of the confirm button, any `EuiButton` color; `'danger'` for destructive actions. |
| `@defaultFocusedButton` | `'confirm' \| 'cancel'` | the modal itself | The button focused when the modal opens: `'confirm'` or `'cancel'`. |
| `@initialFocus` |  |  | Element to focus when the modal opens, as `EuiModal`'s `@initialFocus` (a CSS selector, an element or a function returning one). Wins over `@defaultFocusedButton`. |
| `@confirmButtonDisabled` | `boolean` |  | Disables the confirm button, e.g. until a checkbox is checked. |
| `@isLoading` | `boolean` |  | Shows a spinner in the confirm button while the action runs. |
| `@maxWidth` |  | `true` | Width cap, as `EuiModal`'s `@maxWidth`. |
| `@outsideClickCloses` | `boolean` | `false` | Clicking the mask around the modal calls `@onCancel`. |
| `@onCancel` (required) | `() => void` |  | Called by the cancel and close buttons and Escape. Close the modal here. |
| `@onConfirm` (required) | `() => void` |  | Called by the confirm button. |

| Block | Description |
| --- | --- |
| `<:title>` | The title, after `@title`. |
| default block | The body, after `@message` (e.g. a checkbox or details). |

</EuiText>
<!-- api:end -->
