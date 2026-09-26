---
title: List Group
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="List Group"/>

  <EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiListGroup

A list of `EuiListGroupItem`s, e.g. navigation links in a side bar.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@maxWidth` | `boolean \| string` |  | `true` for EUI's default max width, or any CSS width. |
| `@bordered` | `boolean` |  | Adds a border around the list. |
| `@flush` | `boolean` |  | Removes the list's padding. |
| `@gutterSize` | `string` | `'s'` | Space between items: `'none'`, `'s'` or `'m'`. |

| Block | Description |
| --- | --- |
| default block | The `EuiListGroupItem`s. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<ul>`.

### EuiListGroupItem

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@href` | `string` |  | Makes the item a link. |
| `@target` | `string` |  | `target` of the `@href` link. |
| `@onClick` | `(event: MouseEvent) => void` |  | Makes the item a button calling this function. |
| `@label` | `string` |  | The item's text. |
| `@iconType` |  |  | Icon before the text; anything `EuiIcon`'s `@type` accepts. |
| `@isActive` | `boolean` |  | Highlights the item, e.g. the current page. |
| `@isDisabled` | `boolean` |  | Disables the item. |
| `@wrapText` | `boolean` |  | Wraps long text instead of truncating it. |
| `@extraAction` | `ComponentLike` |  | A component rendered at the end of the item, e.g. an `EuiButtonIcon` to pin it (use `(component EuiButtonIcon …)`). |
| `@size` |  | `'m'` | `'xs'`, `'s'`, `'m'` or `'l'`. |
| `@color` |  | `'inherit'` | `'inherit'`, `'primary'`, `'text'`, `'subdued'` or `'ghost'`. |

| Block | Description |
| --- | --- |
| default block | Custom content instead of `@label`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<li>` / `<a>` / `<button>` / `<span>`.

</EuiText>
<!-- api:end -->
