# 08. Cell colour by a rule: `@cellColor`

## Why

Overdue dates, failed checks and statuses should stand out at a glance.
Handsontable, AG Grid, Glide and RevoGrid Pro colour cells by a rule, and
so does NocoDB, from search snippets only (`../FEATURE-RESEARCH.md`
row 6). Batch 4 colours a whole row with a bar; this does it per cell.

## API

```ts
cellColor?: (record: T, field: EuiSheetField<T>) => SheetRowColor | undefined;
```

```hbs
<EuiSheet @cellColor={{this.cellColor}} … />
```

```ts
cellColor = (task: Task, field: EuiSheetField<Task>) =>
  field.id === 'due' && task.due && task.due < today ? 'danger' : undefined;
```

- It returns the same colours as batch 4's `@rowColor` (`SheetRowColor`,
  V03 10.2): a theme name or any CSS colour.
- The owner decides the rule. The sheet only draws the colour.

## Behaviour

- **How it is drawn.** A 3 px bar along the cell's bottom edge, drawn by
  the cell's `::after` (`content: ''`, absolute, `bottom: 0`, the colour
  from a `--euiSheet-cellMark` property set on the cell). Not a
  `box-shadow`: the error border (`styles.ts:26`), batch 4's row bar and
  the frozen edge (`styles.ts:175-176`) are all `box-shadow`s, and a
  second one on the same cell would replace them. The grid's own `::after`
  ring is already switched off on data cells (`styles.ts:20`), so the
  pseudo-element is free. It is not a background either, for D10's reasons (a
  background fights hover, the selection and the frozen cells' opaque
  backgrounds, and needs a contrast check per theme). The bottom edge
  keeps it apart from the row bar on the left. The user chose the bottom
  bar over coloured text (README, "Decided").
- Named colours use batch 4's `--euiSheet-row<Name>` tokens, so dark mode
  follows.
- Colour alone carries no name: the cell's `aria-label` does not change.
  An app that needs the meaning to be read out puts it in a field or in
  `@cellErrors`.
- A cell with an error keeps its red border, and the colour bar stays.
  The first field's cell with batch 4's row bar (no row numbers) keeps
  both: the bar on the left, the mark at the bottom.

## Performance (the gate)

`@cellColor` is called once per rendered cell, on each render. That is the
first per-cell hook since the decision of 2026-11-19, so it is measured:

- **CC-perf:** FZ9's scroll measurement (30 fields, the same steps), run
  with a `@cellColor` that colours every third cell, and run without it.
- The time per scroll step must stay within 10 % of the run without it.
  If it does not, cache the colour per record and field until `@records`
  or `@cellColor` changes, then measure again.
- The docs say: keep it cheap, with no lookups across rows.

## Code

- The cells module, where batch 4 puts the row colour's `setCellProps`.
  The data cell's props get one more class and style. About 25 lines.
- `styles.ts`: the bar, about 4 lines.
- `types.ts`: the argument.

## Tests (`eui-sheet-cell-color-test.gts`)

- **CC1:** a named colour draws the bar with that token.
- **CC2:** a CSS colour is used as given.
- **CC3:** `undefined` leaves the cell as in v0.3 (no class, no style).
- **CC4:** a new `@records` with a changed value updates the bar.
- **CC5:** dark mode resolves the named token to the dark value.
- **CC6:** an invalid cell with a colour shows both its red border and the
  mark (computed styles of the cell and of its `::after`).
- **CC7:** with `@rowColor`, `@rowNumbers={{false}}` and a colour on the
  first field, both the row bar and the cell mark are drawn.
- **CC-perf**, as above. Its numbers go in the results file.

## Docs

The "Theme" section: the argument, the example, and the performance note.

## Risks

- **The perf gate.** See above.
- **The bottom bar may be hard to see at short row height.** The demo
  shows it at every row height.
