# 09. Load more at the end of the scroll: `@onVisibleRangeChange`

## Why

Big tables should not need a pager. AG Grid's infinite row model and
RevoGrid Pro's infinite scroll load rows as the user scrolls
(`../FEATURE-RESEARCH.md` row 9). Paging is the owner's job, so the sheet
only tells the owner what is on screen. The owner decides when to load
more, and appends.

## API

```ts
interface SheetVisibleRange {
  /** Positions in @records (not grid rows), first and last on screen. */
  first: number;
  last: number;
  /** @records.length, so "near the end" is one comparison. */
  count: number;
}

onVisibleRangeChange?: (range: SheetVisibleRange) => void;
```

```ts
onVisibleRangeChange = ({ last, count }: SheetVisibleRange) => {
  if (this.hasMore && !this.isLoading && last >= count - 20) this.loadMore();
};
```

`@isLoading` already draws a progress bar while the owner loads.

## Behaviour

- It is called after render, whenever `first`, `last` or `count` changed.
  That happens on scroll, on a resize, and when `@records` grows. It is
  called at most once per run loop.
- **Grid rows to record positions.** The rows that are not records are
  skipped, using the row model of batch 3a (`src/core/rows.ts`): group
  headers, add rows and the end add row. `first` is the first record row
  at or after the top visible row; `last` is the last record row at or
  before the bottom one. With no record on screen (only headers), the
  call is skipped.
- With collapsed groups, the positions are still indexes into `@records`,
  so "near the end" works the same way.
- **Appending keeps the user's place.** When `@records` grows at the end,
  the selection and the scroll stay, as today (README, "The sheet's API").

## Code

- `src/-private/visible-range.ts` (new, about 40 lines):
  - `toRecordRange(rendered, rowModel, count)`: pure, and unit-tested;
  - a `changed(previous, next)` check.
- The grid-options getter (today's `virtualizationOptions`,
  `eui-sheet.gts:1400`). It returns `undefined` without a frozen field
  today. With the handler it returns `{ onItemsRendered }`, and keeps
  `overscanColumnCount` when a field is frozen. The grid already reports
  the rendered window after render (`core/.../body.gts:493-511`). About
  15 lines.
- `types.ts`: the type and the argument.

## Tests (`eui-sheet-visible-range-test.gts`)

- **VR1:** on the first render, it gets `first: 0` and `last` equal to the
  last row in view.
- **VR2:** a scroll to the bottom gives `last: count - 1`.
- **VR3:** appending 50 records calls it again with the new `count`. The
  focused cell stays.
- **VR4:** with groups, header rows are not counted: the positions match
  `@records`.
- **VR5:** with a frozen field, the call happens, and the frozen
  overscan is unchanged (the FZ tests still pass).
- **Unit (`visible-range-test.ts`):** `toRecordRange` over a grouped row
  model, including a window of headers only.

## Docs

A section "Loading more as you scroll", and a demo with `localRecords`
that loads 100 records at a time with a delay. The EmberSearchUi connector
could use this to append pages; that is a follow-up, not part of this
batch.

## Risks

- **The grid reports only when it re-renders its window.** A `@records`
  change that does not move the window might not report the new `count`.
  VR3 checks it. If it fails, the sheet also checks after `@records`
  changes.
