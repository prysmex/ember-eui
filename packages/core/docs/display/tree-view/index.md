---
title: Tree view
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Tree view"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiTreeView` shows a hierarchy that opens and closes, like folders and
files or sections and pages. Pass the nodes as `@items`, each with an
`id`, a `label`, and optional `children`, `icon` and `iconWhenExpanded`.

```hbs
<EuiTreeView @items={{this.items}} aria-label="Project files" />
```

```js
items = [
  {
    id: 'src',
    label: 'src',
    icon: 'folderClosed',
    iconWhenExpanded: 'folderOpen',
    isExpanded: true,
    children: [{ id: 'app', label: 'app.js', icon: 'document' }],
  },
];
```

Clicking a node with children opens or closes it; its `callback`
(if any) is called too. With the keyboard, up and down move between
nodes, right opens and left closes. Give the tree an `aria-label`.
`@expandByDefault` opens everything at first, `@showExpansionArrows`
adds arrows, and `@display="compressed"` makes it smaller.

</EuiText>

<EuiSpacer />

<EuiText>

`EuiTreeView` is not meant to be used as primary navigation; for that we recommend using `EuiSideNav`. It does not accept content directly but requires an array of nodes through `@items`. Each node requires a `label` and a unique `id`. The `icon` accepts any icon type, and `iconWhenExpanded` sets a different icon for the open state. Use the nodes' `children` to nest more nodes. To show an `EuiToken` for a node, pass a component as its `icon` (e.g. `(component EuiToken iconType="tokenString")`), or render every node's icon yourself in the `<:icon as |node isExpanded|>` block (upstream's per-node icon element): it renders inside the icon wrapper of each node that has an `icon` or `iconWhenExpanded`.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiTreeView

A hierarchy of nodes (folders and files, sections and pages) that open
and close. Arrow keys move between nodes (up and down) and open or close
them (right and left). Give it an `aria-label`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@items` (required) | `EuiTreeViewNode[]` |  | The top-level nodes; each may have `children`. |
| `@display` | `'default' \| 'compressed'` |  | `'default'` or `'compressed'` (smaller text and spacing). |
| `@expandByDefault` | `boolean` |  | Opens every node that has children. |
| `@showExpansionArrows` | `boolean` |  | Shows an arrow before nodes that have children. |

| Block | Description |
| --- | --- |
| `<:label>` | Renders a node's label yourself; yields the node. |
| `<:icon>` | Renders the icon of each node that has an `icon` (or an `iconWhenExpanded`) yourself, inside its icon wrapper (upstream's per-node icon element). Yields the node and whether it is open. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<ul>`.

</EuiText>
<!-- api:end -->
