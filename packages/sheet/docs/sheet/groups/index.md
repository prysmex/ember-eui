---
title: Groups and loading more
order: 8
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: groups and loading more"/>
<EuiSpacer @size="l" />

<EuiText>

Records drawn in groups from the groups you pass, and the next page
loaded as the user scrolls near the end.

## Group by

The sheet draws groups; it never groups. Like a sort or a page, grouping
is a query, and it is yours: you pass the headers in `@groups` and the
records of the expanded groups in `@records`, in display order. The
sheet tells you what the user asked for: `@onGroupByChange` from the
column menu, `@onGroupToggle` from a header. `localRecords` does all of
it for local data:

```gjs
import { EuiSheet, localRecords } from '@ember-eui/sheet';

class Tasks extends Component {
  store = localRecords(TASKS, {
    getRecordId: (task) => task.id,
    fields: FIELDS,
    groupBy: [{ field: 'status', direction: 'asc' }],
    summaries: { hours: 'sum' }
  });

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.view.records}}
      @groups={{this.store.view.groups}}
      @groupBy={{this.store.groupBy}}
      @onGroupByChange={{this.store.setGroupBy}}
      @onGroupToggle={{this.store.toggleGroup}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
    />
  </template>
}
```

`store.view` is `{ records, groups }`, regrouped whenever the records,
the group-by or the collapsed groups change (`store.collapsedGroups`, a
set of keys). It needs `fields`: they are how it finds each level's
type. Without a group-by it is the records and no groups.

### The contract

```ts
interface SheetGroupBy { field: string; direction: 'asc' | 'desc' } // one per level, outermost first

interface SheetGroup {
  key: string;          // your id for the group: unique, the same after a re-query
  depth: number;        // 0 for the outermost level: the group belongs to @groupBy[depth]
  value: unknown;       // the value its records share; a record added to the group gets it
  label?: string;       // default: the field type's format(value), or "(Empty)"
  count: number;        // records in the group in your whole data (all pages, collapsed or not)
  loaded?: number;      // how many of @records, taken in order, are directly under it (default 0)
  collapsed?: boolean;  // drawn closed: its records are not in @records, its child groups not in @groups
  summary?: Record<string, string>; // text per field id, in the header row under that column
  rowNumberStart?: number; // the row number of its first loaded record
  continued?: boolean;  // it began on an earlier page: the label says so
}
```

The sheet walks `@groups` once: a header row for the group, then its next
`loaded` records of `@records`, then, when inserting is allowed, the group
is expanded and it is a leaf (the next group is not deeper), an add row.
It reads nothing from the records: it compares no value, counts nothing
and reorders nothing, so the counts are yours. That is also why an edit
of the group field does not move the record at once: the sheet shows
your last answer until you group again (`localRecords` regroups at once).
If the `loaded` add up to fewer than `@records`, the rest are drawn in the
last group and a debug warning (`ember-eui.sheet.groups-loaded-mismatch`)
names both numbers; no record is lost or hidden.

| Case | What you pass |
| --- | --- |
| Expanded, fully loaded | `count: 12, loaded: 12` |
| Collapsed | `collapsed: true, count: 12` (no `loaded`); its 12 records are not in `@records` |
| An empty group you choose to list | `count: 0`: a header and, when inserting is allowed, an add row |
| Records with an empty value | `value: null`: label "(Empty)" |
| Starts on this page, continues on the next | `count: 40, loaded: 15` |
| Continues from the previous page | `count: 40, loaded: 25, continued: true, rowNumberStart: 16` |
| Two levels | the parent `{ depth: 0, count: 30 }` (no `loaded`), then its children `{ depth: 1, loaded: … }` |
| A collapsed parent | the parent with `collapsed: true`; its children are not listed |

### In the grid

- **Header rows.** As tall as a record row, on one opaque background:
  the label (indented 16 px per level), the count and "(continued)".
  The label stays in view on horizontal scroll. Each field's cell shows
  `summary[fieldId]`, subdued and right-aligned. The footer bar
  (`@summary`) stays the whole view's.
- **Toggle.** Only with `@onGroupToggle`: a chevron before the label. A
  click on it or on the title, or Enter or Space on a focused header,
  calls `@onGroupToggle(key, !collapsed)`. Focus stays on the header
  when your new `@groups` move it.
- **Column menu.** With `@onGroupByChange`: "Group by this field" calls
  it with `[{ field, direction: 'asc' }]`, and on a field of `@groupBy`
  "Remove grouping" calls it with `[]`. Not on a field with
  `groupable: false`. A second level comes from your own control, with
  the blocks' `setGroupBy`. The group field may be hidden.
- **Adding.** Each expanded leaf group has its own add row, and the add
  row at the end is not drawn. A click or Enter on it inserts one record
  after the group's last loaded record, with `@newRecordValues` under the
  group's values (the group's and each ancestor's field: the group's
  win) and the insert's `groupKey`. Shift+Enter, the row menu's insert
  above and below, and Duplicate do the same for the record's group. A
  paste on a group's add row inserts every line into that group (with
  `@newRecordValues`, above: the group's last loaded record); a paste
  from a record that runs past the last record inserts the rest into the
  last record's group (with `@newRecordValues`, above: the last record).
- **Row numbers.** One more than the previous record's, from
  `@rowNumberOffset + 1`; a group's `rowNumberStart` restarts the count
  (`groupRecords` sets it, counting the records of collapsed groups, so
  the numbers are positions in the whole view). `@rowLabel` gets that
  number. Headers and add rows have none.
- **Selecting.** A range is over records: Shift+arrows, a drag and the
  fill handle step over headers, and the outline is drawn per group.
  Copy gives no line for a header; a paste fills the following records
  across groups. Ctrl/Cmd+A selects every record. Checkboxes: headers
  have none; Shift+click across a header checks the records between,
  and the header checkbox checks the loaded records.
- **Keys and the mouse on a header.** The arrows pass through it and
  keep the column. A header keeps no range: typing, F2, Delete, paste and
  Shift+Enter do nothing there, and a click or a Shift+click on it
  focuses it and drops the range. PageUp, PageDown, Ctrl+Home and
  Ctrl+End never land on a header, from a cell or a row number. There is
  no row menu on a header: a right-click shows the browser's.
- **Undo, redo.** By record id. A record in a collapsed group is not in
  `@records`: while some group is collapsed, its undo or redo is emitted
  anyway (you still have the record) without the "changed since" check,
  and nothing is selected. Without a collapsed group nothing changes: a
  change on another page is skipped and kept ([Undo and redo](/docs/sheet/docs/sheet/editing#undo-and-redo)).
- **Expanded record.** Previous and next go over `@records`: from a
  group's last record to the next group's first.
- **The API.** `focusCell` does nothing for a record of a collapsed
  group: expand the group first.

The header's cells are grid cells with an `aria-label` ("Status: Open,
12") and, with a toggle, `aria-expanded`; the row is not a `treegrid`
row. Not checked with a screen reader yet.

### Helpers

From `@ember-eui/sheet`, plain functions:

- `groupRecords(ctx, records, { groupBy, fields, collapsed?, summaries?,
  rowNumberOffset? })` gives `{ records, groups }` for an owner that has
  every record (`localRecords.view` is this). Two values are one group
  when the type's `copyText` gives the same text; groups are ordered by
  the type's `compare`, reversed for `'desc'`; keys are `field:text`
  joined by `/` per level (`status:Open/owner:Ana`). It sets `count`,
  `loaded`, `rowNumberStart`, `collapsed` and, with `summaries`, each
  group's `summary` (`summarize` over its records). An owner that pages
  must not call it on a page.
- `applyChangeSetToGroups(groups, records, changeSet, getRecordId)` keeps
  `count` and `loaded` right after a change set (an insert by its
  `groupKey`, else its anchor's group; a delete; a move), until your next
  query.
- `pageGroups(records, groups, groupKeyOf, { offset })` fills `loaded`
  and `continued` of your backend's headers for one page of records.

With EmberSearchUi, `EuiSheetSearch` passes `@groups`, `@groupBy`,
`@onGroupByChange` and `@onGroupToggle` to the sheet. `@groups` may be a
function of the driver's snapshot (your backend's group counts in
`aggregations`, the page's results for `loaded`): the connector keeps it
next to its stable results and runs `applyChangeSetToGroups` on it with
each change set, until Re-apply. Your handlers write the group-by and the
collapsed keys with `driver.setExtension`, which your backend reads. The
driver itself has no group-by yet.

### Cost

Grouping keeps column virtualization: a header's label is the row's
first rendered cell, made sticky by CSS, so no column has to stay
mounted. Measured in the sheet's own test (FZ13: 10,000 records in 200
groups, 30 fields, headless Chromium, 20 scroll steps of 600 px, the
fastest of two rounds):

| | Cells rendered | Ungrouped | Grouped |
| --- | --- | --- | --- |
| Not frozen | 72 | 45.9 ms | 43.5 ms |
| Frozen | 372 | 193.6 ms | 204.8 ms |

That run was on a quiet machine. Two more, under load from other work,
gave 0.75 to 1.26 times the ungrouped time, either way: the difference is
noise. So grouping costs about what not grouping costs. (The frozen
rows of that table are from before the frozen grid rendered only the
frozen columns and the columns in view; it now renders 72 cells there
too: [Frozen field](/docs/sheet/docs/sheet/large-data#performance-with-frozen-fields).) A change of `@groups` rebuilds
the row model and one class entry per header and add row (200 groups:
400 entries).

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

</EuiText>
