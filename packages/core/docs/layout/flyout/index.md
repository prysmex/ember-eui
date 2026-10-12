---
title: Flyout
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Flyout"/>
<EuiSpacer @size="l" />

<EuiText>

A flyout is a panel that slides in from the side of the window, for
details, settings or forms that relate to the page the user is on. Unlike
a modal it can hold longer content, and with `@ownFocus={{false}}` or
`@type="push"` the page stays usable next to it.

```hbs
{{#if this.isOpen}}
  <EuiFlyout @onClose={{this.close}} @size="m" @closeButtonAriaLabel="Close">
    <EuiFlyoutHeader @hasBorder={{true}}>
      <EuiTitle @size="m" @tagName="h2">Edit rule</EuiTitle>
    </EuiFlyoutHeader>
    <EuiFlyoutBody>…</EuiFlyoutBody>
    <EuiFlyoutFooter>
      <EuiButton @fill={{true}} {{on "click" this.save}}>Save</EuiButton>
    </EuiFlyoutFooter>
  </EuiFlyout>
{{/if}}
```

Render the flyout only while it is open and close it in `@onClose`
(called by the close button, Escape, and outside clicks with
`@outsideClickCloses`). Give the close button a label with
`@closeButtonAriaLabel`.

</EuiText>

<EuiHorizontalRule />

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
| `@size` | `number \| string` | `'m'` | Width: `'s'`, `'m'`, `'l'` or `'fill'` (90%), a number in px or any CSS width. |
| `@side` | `'left' \| 'right'` | `'right'` | Side of the window it slides in from (logical: `'right'` is the inline end, so it mirrors in RTL). |
| `@role` | `null \| string` | `'dialog'` (with `aria-modal`); a pushed flyout has no role unless you pass one | `role` of the flyout. `null` for none. |
| `@ownFocus` | `boolean` | `true` | Renders a mask over the page behind the flyout, which closes it when clicked. Without it, the page stays usable. |
| `@outsideClickCloses` | `boolean` | closing on mask clicks only | Without the mask (`@ownFocus={{false}}`), `true` closes the flyout on clicks outside it. With the mask, `false` stops mask clicks from closing it. |
| `@closeButtonPosition` | `'outside' \| 'inside'` | `'inside'` | Close button `'inside'` the flyout's corner or `'outside'` next to it. |
| `@paddingSize` | `'none' \| 's' \| 'm' \| 'l' \| string` | `'l'` | Padding of `EuiFlyoutHeader`, `EuiFlyoutBody` and `EuiFlyoutFooter`: `'none'`, `'s'`, `'m'` or `'l'`. |
| `@hideCloseButton` | `boolean` |  | Hides the close button (e.g. when the flyout has its own). |
| `@closeButtonProps` |  |  | Props for the close button: `{ className, onClick }`. |
| `@closeButtonAriaLabel` | `string` | "Close this dialog" | Accessible label of the close button. |
| `@onClose` | `() => void` |  | Called by the close button, Escape, the mask and outside clicks. Stop rendering the flyout here. Without it there is no close button. |
| `@maxWidth` | `boolean \| number \| string` | `false` | Caps the width: `true` for the size's max width, `false` for none, or a number in px or any CSS width. |
| `@maskProps` | `{ headerZindexLocation?: 'above' \| 'below' }` | `'below'` | Options for the mask: `{ headerZindexLocation: 'above' }` puts the flyout and its mask above a fixed `EuiHeader`. |
| `@type` | `'overlay' \| 'push' \| string` | `'overlay'` | `'overlay'` covers the page; `'push'` pads the page so the flyout sits beside it (on windows at least `@pushMinBreakpoint` wide). |
| `@pushMinBreakpoint` | `number \| EuiBreakpointSize` |  | Minimum window width for `@type="push"`: a theme breakpoint name (`'xs'` to `'xl'`) or px. Smaller windows get an overlay. Defaults to `'l'`. |
| `@hasAnimation` | `boolean` | `true` for overlays and `false` for push flyouts | Slides the flyout in (only when the user allows motion). |
| `@shouldSelfFocus` | `boolean` | `true` | Focuses the flyout itself when it opens. |
| `@focusTrapOptions` |  | allowing outside clicks | Options for the focus trap (focus-trap library), e.g. `{ initialFocus: '#name' }`. |
| `@resizable` | `boolean` | `false` | Adds a resize handle at the flyout's inner edge, dragged or moved with the arrow keys (10px a step). The width is kept as a share of the window and clamped between `@minWidth` and `@maxWidth` (a number in px) and 90% of the window. `EuiFlyoutResizable` is this set to `true`. |
| `@minWidth` | `number` | `0` | Smallest width in px while `@resizable`. |
| `@onResize` | `(width: number) => void` |  | Called with the new width in px after the user resizes (when a drag ends, and on each keyboard step), while `@resizable`. |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

Deprecated: `@isOpen` (Has no effect: render the flyout only while it is open.); `@isDocked` (Has no effect, see EuiCollapsibleNav; use `@type="push"`.); `@dockedBreakpoint` (Has no effect; use `@pushMinBreakpoint`.); `@showButtonIfDocked` (Has no effect.).

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

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@scrollableTabIndex` | `number` | `0`; pass `-1` when the content has focusable elements | `tabindex` of the scrolling wrapper, so keyboard users can scroll it. |

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

### EuiFlyoutResizable

An `EuiFlyout` with a resize handle at its inner edge, dragged or moved
with the arrow keys. Takes all of `EuiFlyout`'s args plus `@minWidth`,
`@maxWidth` (a number in px) and `@onResize`.

Also takes the args of `EuiFlyout`.

### EuiFlyoutMenu

The top menu bar of a flyout: a back button or history, pagination, a
title and icon actions, with the flyout's close button at the end. Place
it first inside an `EuiFlyout`. Upstream's `EuiFlyoutMenu`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@title` | `string` |  | Title of the menu. Hidden from view by default (see `@hideTitle`) but still read by screen readers. |
| `@titleId` | `string` |  | Id of the title element, e.g. for the flyout's `aria-labelledby`. |
| `@hideCloseButton` | `boolean` | `false` | Hides the close button. |
| `@onClose` | `(event: MouseEvent) => void` |  | Called by the close button. Without it the button does nothing. |
| `@showBackButton` | `boolean` | `false` | Shows a back button. |
| `@backButtonProps` | `EuiFlyoutMenuBackButtonProps` |  | Options of the back button, such as `onClick`. |
| `@historyItems` | `EuiFlyoutHistoryItem[]` |  | Entries of the history popover, most recent first: index 0 is where the back button goes. Shown from two entries. |
| `@leadingActions` | `EuiFlyoutMenuAction[]` |  | Actions at the inline start of the bar. |
| `@trailingActions` | `EuiFlyoutMenuAction[]` |  | Actions at the inline end of the bar. |
| `@pagination` | `EuiFlyoutMenuPagination` |  | Previous/next controls and a counter. They replace the back button and history. |
| `@css` | `EuiCss` |  | Extra styles composed last into the menu's class. |

Deprecated: `@hideTitle` (Hides the title visually. Defaults to `true`. Use `EuiFlyoutHeader` for visible titles.); `@customActions` (Use `@trailingActions`, which takes precedence when both are set.).

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
