---
title: Field editor
order: 50
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: field editor"/>
<EuiSpacer @size="l" />

<EuiText>

Adding, editing, duplicating and deleting fields from the grid: the "+"
column, the header menu and the field editor. Fields are your data
model, so each is an intent you handle.

## Fields

The owner owns `@fields`. Adding, editing, duplicating and deleting a
field from the grid are three intents, as in Airtable's grid; each
handler shows its own controls, and without it there are none (there is
no local fallback: fields are your data model). A bare app passes
`localRecords`' handlers:

```hbs
<EuiSheet
  @fields={{store.fields}}
  @records={{store.records}}
  @getRecordId={{this.getId}}
  @onChange={{store.apply}}
  @onFieldCreate={{store.createField}}
  @onFieldUpdate={{store.updateField}}
  @onFieldDelete={{store.deleteField}}
/>
```

- **The "+" column** (with `@onFieldCreate`) is the last header: a click,
  or Enter or Space on it (ArrowRight from the last header reaches it),
  opens the field editor to add a field at the end. Its body cells are
  empty: a click there selects the row's last field, and ArrowRight and
  End stop at the last field.
- **The column menu** has Edit field, Duplicate field, Insert left,
  Insert right and Delete field (last, in red), after "Fit to content"
  ([Presentation state](/docs/sheet/docs/sheet/more/full-screen#fit-to-content)) and with your `@fieldActions` just before
  Delete. Nothing is inserted to
  the left of the first field and the first field cannot be deleted (it
  stays first). Duplicate calls `@onFieldCreate` at once, with the
  field's draft, the label "Name copy", the next index and `copyOf`: you
  decide whether values are copied. Delete asks first.

- **The field editor** opens under the header it belongs to: the name
  (required; Enter saves), the type (`@creatableFieldTypes`, each labelled
  by `type.label`), the type's options (a select's options and colours, a
  currency's code and decimals, a percent's decimals, a rating's stars, a
  date's day/month order, a duration's format), a description and
  Required. Escape and Cancel close it and focus the header; a click
  outside or a scroll of the grid cancels it. `@fieldEditor` replaces its
  content: your component gets `mode` (`'create'` or `'edit'`), `field`,
  `draft`, `types`, `isSaving`, `error`, `onSave(draft)`, `onCancel()`,
  `messages` and `themeClass`.

The **draft** is plain data: `{ label, type, description?, required?,
...type options }`, without `id` and without the parts that are
functions (`options(record)`, `validate`): the editor hides those, so
`{ ...previous, ...draft }` keeps them. Build the field from it (`{ id,
...draft }` on create), pass the new `@fields`, and for a create put it
at `after` (the visible field before it) or `index` (among the visible
fields). A handler that returns a promise keeps the editor open and busy;
when the promise rejects, the editor stays open and shows
`error.message` (a name your server refused).

**Changing a type changes no value.** The cells show the stored values
through the new type, whatever they are. To convert them, apply
`convertField(ctx, records, previous, next)`: the change set that writes
each value as the new type reads it, through the paste path (the old
type's copy text, then the new type's `parse`). What could be pasted
converts; what could not becomes empty, with a `rejected` entry (the
text and the reason) so you can say what was lost; select options a
`createOnPaste` field would create are in `newOptions`.
`localRecords.updateField` does exactly that and keeps the change set in
`log`.

**Field operations are not undoable from the sheet**: undo holds values
by record and field, and only you have every value of a deleted field.
When a field leaves `@fields` and `@hiddenFields`, or its type changes,
the sheet drops that field from its undo history (an entry left empty is
removed), its rejected texts and pending cells, and closes an editor on
it. You can make them undoable in your own UI.

## Related

- [Field actions and menus](/docs/sheet/docs/sheet/fields/field-actions)
- [Custom field types and editors](/docs/sheet/docs/sheet/field-types/custom-types): a type's part of the field editor
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
