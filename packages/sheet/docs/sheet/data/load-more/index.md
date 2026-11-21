---
title: Load more
order: 82
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: load more"/>
<EuiSpacer @size="l" />

<EuiText>

The next page loaded as the user scrolls near the end, with
`@onVisibleRangeChange` and `@isLoading`.

## Loading more as you scroll

A large table does not need a pager: load a page, and load the next one
when the user scrolls near the end. The sheet does not page; it tells you
which records are on screen, and you decide when to load more:

```js
onVisibleRangeChange = ({ first, last, count }) => {
  if (this.hasMore && !this.isLoading && last >= count - 20) this.loadMore();
};

async loadMore() {
  this.isLoading = true; // pass it as @isLoading: a progress bar over the grid
  const page = await this.fetchPage(this.fetched); // your own cursor
  this.fetched += page.length;
  this.records = [...this.records, ...page];
  this.isLoading = false;
}
```

`@onVisibleRangeChange` gets `first` and `last`, the first and last
records on screen, and `count`, `@records.length`. They are positions in
`@records`, not grid rows: group headers and add rows are skipped, so
with groups (also collapsed ones) "near the end" is still `last` against
`count`. It is called after render, at most once per run loop, when one
of the three changed: on a scroll, a resize of the grid, and when
`@records` grows. A window with only group headers on screen calls
nothing. It is not called during the render, so the handler can set
state or append records at once.

Keep your own cursor (here `fetched`, or the server's next-page token)
rather than fetching from `@records.length`: the user can delete and
insert rows, which changes the length but not where the next page starts.
Guard the load with your own flag: the sheet calls again while a page is
loading (the user keeps scrolling), and once more with the new `count`
when it arrives. Appending at the end keeps the scroll position, the
selection and the focused cell. An add row at the end of a half-loaded
list is odd: `@canInsert={{false}}` until everything is loaded, as the
"Load more as you scroll" example does.

## Related

- [The example app](/docs/sheet/docs/sheet/example-app): loading more, with groups
- [Large data](/docs/sheet/docs/sheet/data/large-sheet)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
