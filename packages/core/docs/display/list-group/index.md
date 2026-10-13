---
title: List Group
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="List Group"/>
<EuiSpacer @size="l" />

<EuiText>

The **EuiListGroup** component is used to present **EuiListGroupItems** in a neatly formatted list. Use the `@bordered` argument for a bordered presentation.

```hbs
<EuiListGroup>
  <EuiListGroupItem @label="Overview" @href="/overview" @iconType="home" @isActive={{true}} />
  <EuiListGroupItem @label="Settings" @href="/settings" @iconType="gear" />
  <EuiListGroupItem @label="Log out" @iconType="exit" @onClick={{this.logOut}} />
</EuiListGroup>
```

An item with `@href` renders a link, with `@onClick` a button, otherwise plain text. `@isActive` highlights the current one.

`EuiPinnableListGroup` adds a pin button to each item, for navigations where users keep favorite pages at the top. It takes the items as an array (`@listItems`) with a `pinned` flag you keep up to date from `@onPinClick`.

</EuiText>

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
| `@maxWidth` | `boolean \| string \| number` | `true` | Limits the list's width: `true` for upstream's default (the form max width, 400px), `false` for none, or any CSS width (numbers are pixels). |
| `@listItems` | `EuiListGroupListItem[]` |  | Items to display, as objects of `EuiListGroupItem` args. When there are any, they are rendered instead of the block's content. |
| `@showToolTips` | `boolean` |  | Shows a tooltip on all items (an item's own `showToolTip` wins). |
| `@bordered` | `boolean` |  | Adds a rounded border around the list. |
| `@color` | `string` | `'text'` | Default `@color` of the items in the block: `'text'`, `'primary'` or `'subdued'`. An item's own `@color` wins. |
| `@wrapText` | `boolean` |  | Default `@wrapText` of the items in the block. |

Deprecated: `@flush` (Has no effect: latest EUI lists have no padding.); `@gutterSize` (Has no effect: latest EUI lists have no item gutters.).

| Block | Description |
| --- | --- |
| default block | The `EuiListGroupItem`s. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<ul>`.

### EuiListGroupItem

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@contentClass` (required) | `string` |  |  |
| `@prependClass` (required) | `string` |  |  |
| `@textClass` (required) | `string` |  |  |
| `@iconType` |  |  |  |
| `@title` | `string` |  |  |
| `@showExternal` (required) | `boolean` |  |  |
| `@newTab` (required) | `boolean` |  |  |
| `@externalIconCss` (required) | `EuiCss` |  |  |
| `@srOnlyClass` (required) | `string` |  |  |

### EuiPinnableListGroup

A list of links (e.g. the pages of an app) where each item can be
pinned, usually to a "Pinned" list at the top of a navigation. You keep
the `pinned` flags; `@onPinClick` is called with the clicked item.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@listItems` (required) | `EuiPinnableListGroupItem[]` |  | The items. |
| `@onPinClick` (required) | `(item: EuiPinnableListGroupItem) => void` |  | Called with the item whose pin was clicked. |
| `@pinTitle` | `(item: EuiPinnableListGroupItem) => string` | "Pin item" | Accessible label of the pin button. |
| `@unpinTitle` | `(item: EuiPinnableListGroupItem) => string` | "Unpin item" | Accessible label of the unpin button. |
| `@bordered` | `boolean` |  | Adds a border around the list. |
| `@maxWidth` |  | `true` | Limits the list's width: `true` for EUI's default (400px), `false` for none, or a CSS width. |
| `@color` | `EuiListGroupItemColor` | `'text'` | Color of the items: `'text'`, `'primary'` or `'subdued'`. |
| `@wrapText` | `boolean` |  | Wraps long item text instead of truncating it. |

Deprecated: `@flush` (Has no effect: latest EUI lists have no padding.); `@gutterSize` (Has no effect: latest EUI lists have no item gutters.); `@size` (Has no effect: latest EUI list items have one size.).

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<ul>`.

</EuiText>
<!-- api:end -->
