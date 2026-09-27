---
order: 2
---

# Item options

<EuiText>

- `@icon` takes any icon; pass `"empty"` to keep items without an icon
  aligned with the others.
- `@size="s"` makes an item smaller, for dense menus.
- `@disabled` disables it, `@isLoading` shows a spinner instead of the
  icon, and `@hasPanel` adds an arrow for items that open more options.
- `@layoutAlign` aligns the icon with the `top` or `bottom` of multi-line
  items (`center` by default).

</EuiText>

```hbs template
<EuiPanel @paddingSize="none" @hasBorder={{true}} style="max-width: 320px;">
  <EuiContextMenuPanel>
    <EuiContextMenuItem @icon="empty">No icon, still aligned</EuiContextMenuItem>
    <EuiContextMenuItem @icon="gear" @size="s">Small item</EuiContextMenuItem>
    <EuiContextMenuItem @icon="lock" @disabled={{true}}>Disabled</EuiContextMenuItem>
    <EuiContextMenuItem @icon="download" @isLoading={{true}}>Preparing download…</EuiContextMenuItem>
    <EuiContextMenuItem @icon="apps" @hasPanel={{true}}>More options</EuiContextMenuItem>
    <EuiContextMenuItem @icon="iInCircle" @layoutAlign="top">
      A long item whose text wraps onto several lines, with its icon aligned to the top
    </EuiContextMenuItem>
  </EuiContextMenuPanel>
</EuiPanel>
```
