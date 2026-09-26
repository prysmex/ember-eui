---
title: Accordion
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Accordion"/>
<EuiSpacer @size="l" />

<EuiCallOut
@title='Take care when including flex group content within accordions'>
<:body>
<EuiText @size='s'>
<strong>EuiFlexGroup's</strong>
negative margins can sometimes create scrollbars within
<strong>EuiAccordion</strong>
because of the overflow tricks used to hide content. If you run into this
issue make sure your paddingSize prop is large enough to account for the
<EuiCode>gutterSize</EuiCode>
of any nested flex groups.
</EuiText>
</:body>
</EuiCallOut>

<EuiHorizontalRule/>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiAccordion

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@id` | `string` |  | Id of the collapsible content region; the trigger's `aria-controls` points to it. Give each accordion a unique id. |
| `@element` | `'div' \| 'fieldset'` | `'div'` | Element wrapping the accordion. With `'fieldset'` the trigger renders as a `<legend>`, for accordions that group form controls. |
| `@buttonClassName` | `string` |  | Class that will apply to the trigger for the accordion. |
| `@buttonProps` | `CommonArgs` |  | Extra props for the trigger: `id` (defaults to a generated id) and `className`. |
| `@arrowProps` | `{ className?: string; }` |  | Extra props to pass to the EuiButtonIcon containing the arrow. |
| `@buttonContentClassName` | `string` |  | Class that will apply to the trigger content for the accordion. |
| `@extraAction` | `Component \| boolean` |  | Set to `true` to render the `<:extraAction>` block, right aligned next to the trigger (e.g. a delete button). The block is ignored without it. |
| `@initialIsOpen` | `boolean` | `false` | The accordion will start in the open state. |
| `@onToggle` | `(isOpen: boolean) => void` |  | Called with the new open state (`true` = open) when the trigger or arrow is clicked. With `@forceState`, use it to update the state you control. |
| `@paddingSize` | `EuiAccordionPaddingSize` | `'none'` | Padding around the content: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or `'xl'`. |
| `@arrowDisplay` | `'left' \| 'right' \| 'none'` | `'left'` | Placement of the arrow indicator, or `'none'` to hide it (only possible when the trigger is a button). |
| `@forceState` | `'closed' \| 'open'` |  | Controls the open state from outside: `'open'` or `'closed'`. Clicking the trigger then only calls `@onToggle`; update `@forceState` there. |
| `@isLoading` | `boolean` | `false` | Shows a loading spinner in place of the `<:extraAction>` block. |
| `@isLoadingMessage` | `boolean \| Component` | `false` (the content stays visible) | While `@isLoading`, replace the content with a spinner and a message: `true` for "Loading...", or a string for your own message. |
| `@childClassName` | `string` |  | Class for the element wrapping the content. |
| `@triggerClassName` | `string` |  | Class for the row holding the arrow, trigger and extra action. |

Deprecated: `@buttonElement` (Has no effect: the trigger is a `<button>`, or a `<legend>` when `@element="fieldset"`.); `@buttonContent` (Has no effect, use the `<:buttonContent>` block for the trigger's content.); `@isOpen` (Has no effect, use `@initialIsOpen` or `@forceState`.); `@childContentClassName` (Has no effect, use `@childClassName`.).

| Block | Description |
| --- | --- |
| `<:buttonContent>` | The trigger's content (usually a title); yields whether it is open. |
| `<:content>` | The collapsible content. |
| `<:extraAction>` | Rendered next to the trigger when `@extraAction={{true}}`; yields whether it is open. |

</EuiText>
<!-- api:end -->
