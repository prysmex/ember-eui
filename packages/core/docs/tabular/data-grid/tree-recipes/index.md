---
title: Data grid tree recipes
order: 14
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid tree recipes"/>
<EuiSpacer @size="l" />

<EuiCallOut @title="Ember EUI extension" @iconType="info">
  Part of the nested rows and grouping guide. See the
  <a href="/docs/core/docs/tabular/data-grid/grouping">overview</a>.
</EuiCallOut>

<EuiSpacer />

<EuiText>

Patterns built from the documented options. None of them needs grid
internals: the grid shows `rows`, and you own the data.

## Lazy loading children

Mark rows whose children aren't loaded yet with `hasChildren: true` (or a
`hasChildren(row)` option) so they get a toggle. When `onExpandedChange`
reports a newly expanded id, load its children and replace the row with a
copy that has `children`. Until then you can show a placeholder child
("Loading…"). Give rows stable ids: the expanded state is kept by id while
`rows` changes.

```js
onExpandedChange = async (ids) => {
  for (const id of ids) {
    if (!this.loaded.has(id)) {
      this.loaded.add(id);
      const children = await fetchChildren(id);
      this.rows = replaceRow(this.rows, id, (row) => ({ ...row, children }));
    }
  }
};
```

## File explorer

Icons by type, an open folder icon for expanded folders, and formatted
sizes. The "Name" renderer reads the row's tree state (`cell.rowTree`), so
the expansion stays uncontrolled.

## Org chart

Flat rows from an HR export (`id`, `managerId`), mapped with `getParentId`,
with avatars and titles, expanded by default.

## Filtering a tree

Filter while keeping the ancestors of matches (so every match stays in
context) and expanding them, so matches are visible right away. Filter the
data and pass the result as `rows`. The grid needs nothing special.

</EuiText>

<EuiHorizontalRule />
