---
title: Fields and custom types
order: 6
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: fields and custom types"/>
<EuiSpacer @size="l" />

<EuiText>

Adding, editing and deleting fields from the grid, your own header
menu items, and your own cells, editors and types.

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
  ([Presentation state](/docs/sheet/docs/sheet/layout#presentation-state)) and with your `@fieldActions` just before
  Delete. Nothing is inserted to
  the left of the first field and the first field cannot be deleted (it
  stays first). Duplicate calls `@onFieldCreate` at once, with the
  field's draft, the label "Name copy", the next index and `copyOf`: you
  decide whether values are copied. Delete asks first.
- **Your items** (`@fieldActions`) come after the sheet's items and
  before Delete field, on every visible field; disable one on the
  fields it does not apply to with `isDisabled(field)`. `onSelect(field)`
  runs once the menu has closed and focus is back on the header's menu
  button, so your own dialog can take focus:

  ```js
  fieldActions = [
    { id: 'history', label: 'Show history', icon: 'clock', onSelect: (field) => this.openHistory(field.id) },
    { id: 'sum', label: 'Summarize', isDisabled: (field) => field.type !== 'number', onSelect: (field) => this.summarize(field) },
  ];
  ```

  The columns are built from the array: keep it stable (not created in a
  template), as `@fieldTypes`.
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

### In the field editor

A type can name itself in the field editor's type select with `label`
(default: the built-in name, "Single line text", "Single select", …) and
add its own part of the editor with `fieldOptions`, a component that gets
`draft`, `field` (on edit), `messages` and `onChange(patch)`, which merges
keys into the draft. List the type in `@creatableFieldTypes` to offer it.
`linkedRecord`, `user` and `attachment` are not offered by default: they
need `search` or `upload` functions, which a draft cannot hold; list them
and complete the field in your handler.

</EuiText>
