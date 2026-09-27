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
edges. Unlike EUI's React version, the panel doesn't navigate between
nested panels; open another popover or change the content yourself.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiContextMenuPanel

A list of `EuiContextMenuItem`s, usually as a popover's content. Unlike
EUI's React version it has no built-in panel navigation.

| Block | Description |
| --- | --- |
| default block | The `EuiContextMenuItem`s (and e.g. `EuiHorizontalRule`s). |

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
| `@icon` (required) |  |  | Icon before the text; anything `EuiIcon`'s `@type` accepts. Pass `'empty'` to align items without an icon with the others. |
| `@iconClasses` | `string` |  | Extra classes for the icon. |
| `@hasPanel` | `boolean` |  | Shows an arrow on the right, for items opening another panel. |

| Block | Description |
| --- | --- |
| default block | The item's text. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<a>` / `<button>`.

</EuiText>
<!-- api:end -->
