---
title: Accordion
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Accordion"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiAccordion` shows and hides content under a clickable title. It is
deliberately unstyled (no borders or backgrounds), so it fits anywhere:
settings sections, advanced options in forms, FAQs.

```hbs
<EuiAccordion @id="advanced-options" @paddingSize="m">
  <:buttonContent>Advanced options</:buttonContent>
  <:content>
    <EuiFormRow @label="Timeout"><EuiFieldNumber @value={{30}} /></EuiFormRow>
  </:content>
</EuiAccordion>
```

- The trigger and the content are linked for screen readers; `@id` sets
  the content's id if you need to reference it.
- The trigger's content goes in `<:buttonContent>` and the collapsible
  content in `<:content>`.
- It starts closed (`@initialIsOpen={{true}}` opens it) and manages its own
  state; to control it, pass `@forceState` (`"open"` / `"closed"`) and
  update it in `@onToggle`.
- `@extraAction={{true}}` renders the `<:extraAction>` block on the right,
  e.g. a delete button.

<EuiCallOut @title="Flex groups inside accordions" @size="s">
  <p>
    <strong>EuiFlexGroup</strong>'s negative margins can create scrollbars
    inside accordions. Use an <code>@paddingSize</code> at least as large as
    the flex group's gutter.
  </p>
</EuiCallOut>

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiAccordion

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@id` | `string` | a generated id | Id of the collapsible content region; the trigger's `aria-controls` points to it. |
| `@element` | `'div' \| 'fieldset'` | `'div'` | Element wrapping the accordion. With `'fieldset'` the trigger renders as a `<legend>`, for accordions that group form controls. |
| `@role` | `string` | `'group'` (upstream); pass `'region'` for landmark-worthy sections | ARIA role of the content region. |
| `@buttonClassName` | `string` |  | Class that will apply to the trigger for the accordion. |
| `@buttonProps` |  |  | Extra props for the trigger: `id` (defaults to a generated id), `className`, `data-test-subj`, `paddingSize` (`'s'`, `'m'` or `'l'`) to pad the trigger (not on the arrow's side), and `css`: extra styles composed last into the trigger's class (upstream `buttonProps.css`). |
| `@buttonElement` | `TriggerElement` |  | Element of the trigger: `'button'` (default) or `'div'`, e.g. when the trigger content holds interactive elements. A non-button trigger makes the arrow the focusable control. Always `'legend'` when `@element="fieldset"`. |
| `@arrowProps` | `{ className?: string; css?: EuiCss; }` |  | Extra props for the arrow's EuiButtonIcon: `className` and `css`. |
| `@buttonContentClassName` | `string` |  | Class that will apply to the trigger content for the accordion. |
| `@buttonContent` | `string` |  | Text content of the trigger. Use the `<:buttonContent>` block for markup; the block wins when both are given. |
| `@extraAction` | `boolean` |  | Set to `true` to render the `<:extraAction>` block, right aligned next to the trigger (e.g. a delete button). The block is ignored without it. |
| `@initialIsOpen` | `boolean` | `false` | The accordion will start in the open state. |
| `@onToggle` | `(isOpen: boolean) => void` |  | Called with the new open state (`true` = open) when the trigger or arrow is clicked. With `@forceState`, use it to update the state you control. |
| `@paddingSize` | `EuiAccordionPaddingSize` | `'none'` | Padding around the content: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or `'xl'`. |
| `@borders` | `EuiAccordionBorders` | `'none'` | Borders around the accordion: `'none'`, `'horizontal'` (top and bottom) or `'all'`. Adjacent bordered accordions share one border. |
| `@arrowDisplay` | `'left' \| 'right' \| 'none'` | `'left'` | Placement of the arrow indicator, or `'none'` to hide it (only possible when the trigger is a button). |
| `@forceState` | `'closed' \| 'open'` |  | Controls the open state from outside: `'open'` or `'closed'`. Clicking the trigger then only calls `@onToggle`; update `@forceState` there. |
| `@isLoading` | `boolean` | `false` | Shows a loading spinner in place of the `<:extraAction>` block. |
| `@isLoadingMessage` | `boolean \| string` | `false` (the content stays visible) | While `@isLoading`, replace the content with a spinner and a message: `true` for "Loading" (i18n token `euiAccordionChildrenLoading.message`), or a string for your own message. |
| `@isDisabled` | `boolean` | `false` | Disables the trigger and the arrow (greyed out, not clickable). |
| `@childClassName` | `string` |  | Class for the element wrapping the content (`.euiAccordion__children`). |
| `@triggerClassName` | `string` |  | Class for the row holding the arrow, trigger and extra action. |

Deprecated: `@isOpen` (Has no effect, use `@initialIsOpen` or `@forceState`.); `@childContentClassName` (Has no effect, use `@childClassName`.).

| Block | Description |
| --- | --- |
| `<:buttonContent>` | The trigger's content (usually a title); yields whether it is open. |
| `<:content>` | The collapsible content. |
| `<:extraAction>` | Rendered next to the trigger when `@extraAction={{true}}`; yields whether it is open. |

</EuiText>
<!-- api:end -->
