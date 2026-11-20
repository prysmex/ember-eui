# 03. App items in the header menu

## Why

Apps have field-level actions, like "Summarize by", "Lock field" or
"Show history". Today an app can add row-menu items (`@rowActions`) but
not header-menu items. AG Grid's column menu and Glide's header hooks
allow it (`../FEATURE-RESEARCH.md` row 3).

## API

```ts
/** An app item of the header (column) menu (`@fieldActions`). */
export interface SheetFieldAction<T = any> {
  id: string;
  label: string;
  /** An EUI icon type. */
  icon?: string;
  color?: 'danger';
  /** Disables the item on this field. */
  isDisabled?: (field: EuiSheetField<T>) => boolean;
  onSelect: (field: EuiSheetField<T>) => void;
}
```

`@fieldActions={{this.fieldActions}}` takes the same shape as
`SheetRowAction`, with a field instead of records.

## Behaviour

- The items come after the sheet's own items (sort, filter, the field
  items) and before "Delete field", in the order given.
- They are on every visible field. An app that wants an item on some
  fields only disables it on the others, as with `@rowActions`.
- `onSelect` runs after the menu has closed and returned focus, the same
  way as the sheet's items (`next(...)`).
- `data-test-subj` is `euiSheetFieldAction-<id>-<fieldId>`.

## Code

- `types.ts`: the interface, and `fieldActions?` in the signature.
- The header-menu module (today's `fieldMenuItems`,
  `eui-sheet.gts:1238`): about 20 lines that map each action to an
  `additional` item, inserted before Delete.

## Tests (`eui-sheet-field-actions-test.gts`)

- **FA1:** an action shows in every field's menu, and a click calls
  `onSelect` with that field.
- **FA2:** `isDisabled` disables it on one field only.
- **FA3:** it sits before "Delete field" when `@onFieldDelete` is passed.
- **FA4:** focus is back on the header button when `onSelect` runs.

## Docs

One row in the arguments table, and one example next to `@rowActions`.

## Risks

None known. It reuses the grid's `additional` column actions, which the
sheet already uses. They take `isDisabled`
(`core/.../column-actions.gts:33`).
