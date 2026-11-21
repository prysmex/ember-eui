---
title: Linked records
order: 37
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: linked records"/>
<EuiSpacer @size="l" />

<EuiText>

A `linkedRecord` field holds records of another table, picked from your
`search` and resolved by your API when they are typed or pasted
(`@onResolve`).

- **Linked record and user**: chips, or an avatar and the name. The
  picker lists `search`'s results (or a user field's `options`), the
  chosen ones first. With `multiple` a pick toggles, as in a
  multi-select; without it a pick saves. A search typed and left without
  a pick is resolved through `@onResolve`.

## Bulk resolve

Pasted (or typed) text that a type cannot read alone, such as names in a
linked-record field, needs your API. With `@onResolve`, a paste writes
what it can at once (other columns, new rows) and shows those cells as
pending, with their text; the sheet then calls `@onResolve` once, with
one request per field and the distinct texts to look up:

```js
onResolve = async (requests, { signal }) => {
  const result = {};
  for (const { fieldId, texts } of requests) {
    const found = await api.lookup(fieldId, texts, { signal }); // [{ id, label }]
    result[fieldId] = Object.fromEntries(
      texts.map((text) => [text, found.find((r) => r.label === text) ?? null])
    );
  }
  return result; // { [fieldId]: { [text]: value or null } }
};
```

Each request is `{ fieldId, texts, cells: [{ text, recordId or tempId,
record }] }`. The resolved cells arrive as a second change set (source
`'resolve'`, patching a new row by its `tempId`), and one Ctrl/Cmd+Z undoes
both. A text answered `null` is a rejection ("could not be resolved"), and
so is every cell of a call whose promise rejects. Writing a pending cell
again (typing, Delete, another paste) drops its result; when no cell of a
call is left pending, or the sheet goes away, the call's `signal` is
aborted. A pending cell whose record leaves `@records` is dropped too.

A field type opts in by returning `{ unresolved: text }` from `parse`. It
may also say how one cell's text splits into texts to look up and how
their values make the cell's value (`resolve: { parts, combine }`); by
default the whole text is one part and its value is the cell's value.

## Related

- [User](/docs/sheet/docs/sheet/field-types/users)
- [All field types](/docs/sheet/docs/sheet/field-types)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
