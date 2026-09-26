---
title: Flyout
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Flyout"/>

<EuiHorizontalRule/>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiFlyout

A panel sliding in from the side of the window, for details or forms
that keep the page context. Render it only while open:
`{{#if this.isOpen}}<EuiFlyout @onClose={{…}}>…</EuiFlyout>{{/if}}`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@closeAriaLabel` | `string` |  | Same as `@closeButtonAriaLabel`. |
| `@isFocusTrapActive` | `boolean` | `true` | Traps keyboard focus inside the flyout. |
| `@as` | `string` | `'div'` | Tag of the flyout, e.g. `'nav'` or `'aside'`. |
| `@size` | `number \| string` | `'m'` | Width: `'s'`, `'m'` or `'l'`, a number in px or any CSS width. |
| `@side` | `'left' \| 'right'` | `'right'` | Side of the window it slides in from. |
| `@role` | `null \| string` | `'dialog'` | `role` of the flyout. |
| `@ownFocus` | `boolean` | `true` | Renders a mask over the page behind the flyout, which closes it when clicked. Without it, the page stays usable. |
| `@outsideClickCloses` | `boolean` | `false` | Clicking outside the flyout calls `@onClose`. |
| `@closeButtonPosition` | `'outside' \| 'inside'` | `'inside'` | Close button `'inside'` the flyout's corner or `'outside'` next to it. |
| `@paddingSize` | `string` | `'l'` | Padding of `EuiFlyoutHeader`, `EuiFlyoutBody` and `EuiFlyoutFooter`: `'none'`, `'s'`, `'m'` or `'l'`. |
| `@hideCloseButton` | `boolean` |  | Hides the close button (e.g. when the flyout has its own). |
| `@closeButtonProps` |  |  | Props for the close button: `{ className, onClick }`. |
| `@closeButtonAriaLabel` | `string` |  | Accessible label of the close button, e.g. "Close this dialog". |
| `@onClose` | `() => void` |  | Called by the close button, Escape, the mask and outside clicks. Stop rendering the flyout here. Without it there is no close button. |
| `@maxWidth` | `boolean \| number` | `false` | Caps the width: `true` for EUI's default max width, or a number in px. |
| `@type` | `string` | `'overlay'` | `'overlay'` covers the page; `'push'` pads the page so the flyout sits beside it (on windows at least `@pushMinBreakpoint` wide). |
| `@pushMinBreakpoint` | `number \| EuiBreakpointSize` | `'l'` | Minimum window width for `@type="push"`: a named breakpoint (`'xs'` to `'xl'`) or px. Smaller windows get an overlay. |
| `@shouldSelfFocus` | `boolean` | `true` | Focuses the flyout itself when it opens. |
| `@focusTrapOptions` |  | allowing outside clicks | Options for the focus trap (focus-trap library), e.g. `{ initialFocus: '#name' }`. |

Deprecated: `@isOpen` (Has no effect: render the flyout only while it is open.); `@isDocked` (Has no effect, see EuiCollapsibleNav; use `@type="push"`.); `@dockedBreakpoint` (Has no effect; use `@pushMinBreakpoint`.); `@showButtonIfDocked` (Has no effect.); `@maskProps` (Has no effect.).

| Block | Description |
| --- | --- |
| default block | Usually `EuiFlyoutHeader`, `EuiFlyoutBody` and `EuiFlyoutFooter`. |

### EuiFlyoutHeader

The top of an EuiFlyout, usually with an `EuiTitle`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@hasBorder` | `boolean` |  | Adds a border between the header and the body. |

| Block | Description |
| --- | --- |
| default block | The title, e.g. `<EuiTitle @size="m" @tagName="h2">Details</EuiTitle>`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiFlyoutBody

The scrolling main content of an EuiFlyout.

| Block | Description |
| --- | --- |
| `<:banner>` | Content pinned above the scrolling body, e.g. an `EuiCallOut`. |
| `<:content>` | The body; same as the default block. |
| default block | The body. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiFlyoutFooter

The bottom bar of an EuiFlyout, usually with its buttons.

| Block | Description |
| --- | --- |
| default block | Usually an `EuiFlexGroup` with close/cancel and primary buttons. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
