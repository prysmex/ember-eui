---
title: Context menu
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Context menu"/>
<EuiSpacer @size="l" />

<EuiText>

A context menu is a list of actions, usually in a popover opened from a
button ("Actions", "…"). `EuiContextMenuPanel` holds the items and
`EuiContextMenuItem` is one action: an icon, a label, and a click
handler or a link.

```hbs
<EuiPopover @isOpen={{this.isOpen}} @closePopover={{this.close}} @panelPaddingSize="none">
  <:button>
    <EuiButtonIcon @iconType="boxesHorizontal" aria-label="Actions" {{on "click" this.toggle}} />
  </:button>
  <:content>
    <EuiContextMenuPanel>
      <EuiContextMenuItem @icon="pencil" {{on "click" this.edit}}>Edit</EuiContextMenuItem>
      <EuiContextMenuItem @icon="copy" {{on "click" this.duplicate}}>Duplicate</EuiContextMenuItem>
      <EuiContextMenuItem @icon="trash" {{on "click" this.remove}}>Delete</EuiContextMenuItem>
    </EuiContextMenuPanel>
  </:content>
</EuiPopover>
```

Use `@panelPaddingSize="none"` on the popover so the items reach its
edges. Arrow keys move between the items; `@title` adds a title.

For sub-menus, `EuiContextMenu` takes a flat list of `@panels`: an
item with `panel: id` opens that panel, which slides in with a back
button, and arrow right / left move between panels with the keyboard.

```hbs
<EuiContextMenu @panels={{this.panels}} @initialPanelId={{0}} />
```

```js
panels = [
  {
    id: 0,
    title: 'Actions',
    items: [
      { name: 'Share', icon: 'share', panel: 1 },
      { isSeparator: true },
      { name: 'Delete', icon: 'trash', onClick: () => this.delete() },
    ],
  },
  { id: 1, title: 'Share', items: [{ name: 'Copy link', icon: 'link' }] },
];
```

A panel without `items` renders the `<:content>` block instead (it
yields the panel), e.g. for a small form.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiContextMenu

A menu of panels: items can open another panel (a sub-menu), which
slides in with a back button to return. Usually the content of an
`EuiPopover`. For a single list of items, `EuiContextMenuPanel` is
enough.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@panels` (required) | `EuiContextMenuPanelDescriptor[]` |  | Every panel, flat: an item's `panel` is the id of the panel it opens. |
| `@initialPanelId` (required) | `PanelId` |  | Id of the panel shown first. |
| `@size` | `'s' \| 'm'` | `'m'` | `'s'` for smaller items and titles. |

| Block | Description |
| --- | --- |
| `<:content>` | Content of the panels without `items`; yields the panel. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiContextMenuPanel

A list of `EuiContextMenuItem`s, usually as a popover's content, with
an optional title. Arrow keys move between the items. For menus with
several panels (items opening sub-menus), use `EuiContextMenu`, which
renders these panels for you.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@title` | `string` |  | Title above the items. |
| `@onClose` | `() => void` |  | Makes the title a "back" button calling this function, e.g. to return to the previous panel. |
| `@size` | `'s' \| 'm'` | `'m'` | `'s'` for a smaller title. |
| `@hasFocus` | `boolean` |  | Moves focus into the panel once rendered: to the item at `@initialFocusedItemIndex`, else to its first focusable element when it has no items, else to the panel itself. |
| `@initialFocusedItemIndex` | `number` |  | Index of the item to focus with `@hasFocus`; `-1` focuses the panel. |

| Block | Description |
| --- | --- |
| default block | The `EuiContextMenuItem`s (and e.g. `EuiHorizontalRule`s), or any content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiContextMenuItem

An action in a menu, usually inside an `EuiContextMenuPanel` in an
`EuiPopover`. Add `{{on "click" …}}` for the action.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@layoutAlign` |  | `'center'` | Vertical alignment of the icon and text: `'center'`, `'top'` or `'bottom'`. |
| `@disabled` | `boolean` |  | Disables the item. |
| `@size` |  | `'m'` | `'s'` or `'m'`. |
| `@href` | `string` |  | Renders the item as a link. |
| `@target` | `string` |  | `target` of the `@href` link, e.g. `'_blank'`. |
| `@isLoading` | `boolean` |  | Shows a spinner instead of the icon. |
| `@icon` |  |  | Icon before the text; anything `EuiIcon`'s `@type` accepts. Pass `'empty'` to align items without an icon with the others. |
| `@iconClasses` | `string` |  | Extra classes for the icon. |
| `@hasPanel` | `boolean` |  | Shows an arrow on the right, for items opening another panel. |

| Block | Description |
| --- | --- |
| default block | The item's text. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<a>` / `<button>`.

</EuiText>
<!-- api:end -->
