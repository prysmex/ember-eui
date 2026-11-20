# 04. A block below the fields of the expanded record

## Why

NocoDB, Baserow and Teable show comments and change history in the
expanded record (search snippets only, `../FEATURE-RESEARCH.md` row 4).
Comments and history stay out of the sheet (V03 14.3): the sheet stores
neither. A block gives the app a place to show its own.

## API

```hbs
<EuiSheet … >
  <:recordFooter as |record sheet|>
    <MyComments @recordId={{record.id}} />
  </:recordFooter>
</EuiSheet>
```

- `record`: the expanded record.
- `sheet`: the block API, the same one the toolbar gets.

## Behaviour

- It is drawn after the fields (and the hidden fields), with a divider, in
  the flyout and in the modal.
- The previous and next arrows change `record`, and the block re-renders
  with the new one.
- It is inside the flyout's or modal's focus trap, so its inputs and
  buttons work with the keyboard.
- The record form's keys (Enter, Escape, typing to edit a box) apply only
  to the form's boxes. A keydown in the block is the block's.

## Code

- `record-shells.gts`: the shell yields `to="footer"` inside a
  `euiSheetRecord__footer` div, only when `@hasFooter` is true. About
  10 lines.
- The component template passes `@hasFooter={{has-block "recordFooter"}}`
  and a `<:footer>` block that yields `to="recordFooter"` with
  `expandedRecordValue` and `blockApi` (`eui-sheet.gts:6917-6919`).
  About 10 lines.
- `styles.ts`: the divider and the spacing.

## Tests (`eui-sheet-record-footer-test.gts`)

- **RF1:** the block renders with the expanded record, in the flyout and
  in the modal.
- **RF2:** the next arrow re-renders it with the next record.
- **RF3:** typing in an input of the block types there: it does not open a
  field editor, and Escape there does not close the record.
- **RF4:** without the block, the record's DOM is as in v0.3.

## Docs

The "Expanded record" section: the block and an example that lists the
app's comments. The docs say the sheet stores no comments.

## Risks

RF3 is the one to watch. If the record form's key handler sits on the
shell rather than on the form, it must check that the event came from a
box.
