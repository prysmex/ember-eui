---
title: Popover
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Popover"/>
<EuiSpacer @size="l" />

<EuiText>

A popover is a small panel anchored to a button: menus, pickers, short
forms or extra information. You keep whether it is open and close it in
`@closePopover`, which EUI calls on Escape and on clicks outside.

```hbs
<EuiPopover
  @isOpen={{this.isOpen}}
  @closePopover={{this.close}}
  @anchorPosition="downLeft"
>
  <:button>
    <EuiButton @iconType="arrowDown" @iconSide="right" {{on "click" this.toggle}}>
      Actions
    </EuiButton>
  </:button>
  <:content>
    <EuiContextMenuPanel>
      <EuiContextMenuItem @icon="copy" {{on "click" this.duplicate}}>Duplicate</EuiContextMenuItem>
      <EuiContextMenuItem @icon="trash" {{on "click" this.remove}}>Delete</EuiContextMenuItem>
    </EuiContextMenuPanel>
  </:content>
</EuiPopover>
```

The popover traps focus while open (focusing its panel), repositions
itself to stay on screen and flips when there is no room.
`EuiPopoverTitle` and `EuiPopoverFooter` add a header and footer;
`EuiInputPopover` attaches a popover as wide as an input.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiPopover

A floating panel anchored to a button, e.g. a menu or a small form. You
control `@isOpen` and close it in `@closePopover`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@portalRef` | `(ref: HTMLElement) => void` |  | Callback to have a reference to the portal element |
| `@anchorClassName` | `string` |  | Class name passed to the direct parent of the button |
| `@anchorPosition` | `PopoverAnchorPosition` | `'downLeft'` (upstream EUI default) | Where the popover opens relative to the button: `'upCenter'`, `'upLeft'`, `'upRight'`, `'downCenter'`, `'downLeft'`, `'downRight'`, `'leftCenter'`, `'leftUp'`, `'leftDown'`, `'rightCenter'`, `'rightUp'` or `'rightDown'`. It flips when there is no room. |
| `@attachToAnchor` | `boolean` |  | Style and position alteration for arrow-less, left-aligned attachment. Intended for use with inputs as anchors, e.g. EuiInputPopover |
| `@button` | `HTMLElement` |  | Element to align the popover to, instead of the `<:button>` block's content. |
| `@buttonRef` | `(e: HTMLDivElement) => unknown` |  | Called with the element wrapping the `<:button>` block. |
| `@closePopover` (required) | `() => void` |  | Called to close the popover (Escape, clicks outside); set `@isOpen` to `false` here. |
| `@container` | `HTMLElement` |  | Restrict the popover's position within this element |
| `@display` | `PopoverDisplay` | `'inlineBlock'` | CSS display of the popover's root: `'inlineBlock'`, `'block'` or any CSS `display` value. |
| `@hasArrow` | `boolean` | `false` (upstream EUI default) | Show an arrow pointing to the anchor. |
| `@initialFocus` | `FocusTarget \| false` |  | The element to focus when the popover opens: a DOM node, a selector (for `document.querySelector()`) or a function returning a node. It is focused once the panel is positioned and visible (so the page does not scroll to a panel still being placed), also without `@ownFocus`. `false` focuses nothing. |
| `@insert` |  |  | Passed directly to EuiPortal for DOM positioning. Both properties are required if prop is specified |
| `@isOpen` | `boolean` | `false` | Whether the popover is open. Toggle it from the `<:button>` block's button. |
| `@ownFocus` | `boolean` | `true` | Traps tab focus within the popover contents. |
| `@panelClassName` | `string` |  | Custom class added to the panel containing the popover contents |
| `@panelPaddingSize` | `PanelPaddingSize` | `'m'` | Padding of the popover: `'none'`, `'s'`, `'m'` or `'l'` (`'xs'` and `'xl'` are discouraged upstream). |
| `@panelStyle` | `{ [i: string]: string }` |  | Inline styles for the panel (positioning styles win). |
| `@popoverScreenReaderText` | `string` |  | Extra screen reader text, announced with the panel (with `@ownFocus` it follows the default "You are in a dialog…" instructions). |
| `@panelRef` | `(e: HTMLElement \| null) => unknown` |  | Called with the popover's panel element (`null` when it closes). |
| `@popoverRef` | `(e: HTMLElement) => unknown` |  | Called with the popover's root element. |
| `@shouldAccountForOtherPopovers` | `boolean` | `true` | When not `false`, a popover opened from inside another popover positions itself relative to that one. |
| `@repositionOnScroll` | `boolean` |  | When `true`, the popover's position is re-calculated when the user scrolls, this supports having fixed-position popover anchors |
| `@repositionToCrossAxis` | `boolean` | `true` | Whether the popover may move to the cross axis (e.g. from below to the side of the anchor) when there is no room. |
| `@css` | `EuiCss` |  | Extra styles composed last into the root's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |
| `@panelCss` | `EuiCss` |  | Extra styles composed last into the panel's class (like upstream's `panelProps.css`). Prefer this to `@panelClassName` for styles. |
| `@zIndex` | `number` |  | By default, popover content inherits the z-index of the anchor component; pass `zIndex` to override |
| `@onTrapDeactivation` | `() => void` |  | Function callback for when the focus trap is deactivated |
| `@offset` | `number` |  | Distance away from the anchor that the popover will render. Defaults to `0` with an arrow and `4` without (upstream). |
| `@buffer` | `number \| [number, number, number, number]` |  | Minimum distance between the popover and the bounding container; Pass an array of 4 values to adjust each side differently: `[top, right, bottom, left]` Default is 16 |
| `@ariaLabel` | `string` |  | Provide a name to the popover panel |
| `@ariaLabelledBy` | `string` |  | Alternative option to `aria-label` that takes an `id`. Usually takes the `id` of the popover title |
| `@tabindex` | `string \| number` | `'0'` | `tabindex` of the panel. |
| `@shouldSelfFocus` | `boolean` | `true` | Focuses the panel itself when it opens. |
| `@isFocusTrapPaused` | `boolean` |  | Pauses the focus trap, e.g. while a nested popover has focus. |
| `@focusTrapOptions` |  |  | Options for the focus trap (focus-trap library). |
| `@mutationObserverOptions` |  | watching the panel's subtree | What content changes reposition the popover (MutationObserver options). |

Deprecated: `@arrowChildren` (Has no effect, use the `<:arrowChildren>` block.).

| Block | Description |
| --- | --- |
| `<:button>` | The element opening the popover, e.g. `<EuiButton {{on "click" (set this "isOpen" true)}}>`. |
| `<:content>` | The popover's content. |
| `<:arrowChildren>` | Content inside the arrow (rarely needed). |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiPopoverTitle

The title of an EuiPopover (separated by a border).

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@paddingSize` | `EuiPopoverPanelPaddingSize` | the containing EuiPopover's `@panelPaddingSize` | Padding: `'none'`, `'s'`, `'m'` or `'l'`. |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

| Block | Description |
| --- | --- |
| default block | The title text. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiPopoverFooter

The footer of an EuiPopover (separated by a border).

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@paddingSize` | `EuiPopoverPanelPaddingSize` | the containing EuiPopover's `@panelPaddingSize` | Padding: `'none'`, `'s'`, `'m'` or `'l'`. |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

| Block | Description |
| --- | --- |
| default block | E.g. a full width button. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiInputPopover

A popover attached below an input and as wide as it, e.g. for a custom
picker. Takes EuiPopover's args (`@isOpen`, `@closePopover`, …).

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@disableFocusTrap` | `boolean` | `false` (Tab cycles through the popover, closing after its last element) | Lets focus leave the popover; Tab then closes it. |
| `@fullWidth` | `boolean` | `false` | Stretches the input (and popover) to its container's width. Otherwise the popover is at most the form max width (upstream). |
| `@panelMinWidth` | `number` | `0` | Minimum width of the panel, when the input is narrower. |
| `@onPanelResize` | `(width?: number) => void` |  | Called with the popover's new width when the input resizes. |

Deprecated: `@input` (Has no effect, use the `<:input>` block.); `@inputRef` (Has no effect.).

| Block | Description |
| --- | --- |
| `<:input>` | The input the popover attaches to; open it on focus or typing. |
| `<:content>` | The popover's content, as wide as the input. |

### EuiWrappingPopover

An EuiPopover anchored to an element that already exists in the page
(passed as `@button`), e.g. one rendered outside Ember. Takes
EuiPopover's args.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@button` | `HTMLElement` |  | The existing element to anchor the popover to. |
| `@onWrappingDestroy` | `() => void` |  | Called when the popover is destroyed. |
| `@portalRef` | `(ref: HTMLElement) => void` |  | Called with the portal element wrapping the button. |
| `@popoverPortalRef` | `(ref: HTMLElement) => void` |  | Called with the popover's portal element. |

Also takes the args of `EuiPopover`.

| Block | Description |
| --- | --- |
| default block | The popover's content. |
| `<:arrowChildren>` | Content on the popover's arrow (e.g. a beacon). |

</EuiText>
<!-- api:end -->
