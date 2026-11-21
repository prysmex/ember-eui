---
title: Field actions and menus
order: 51
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: field actions and menus"/>
<EuiSpacer @size="l" />

<EuiText>

The header menu of each field: the sheet's own items (sort, group,
filter, hide, fit, edit), which a field can turn off, and your own items
with `@fieldActions`.

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

## Related

- [Field editor](/docs/sheet/docs/sheet/fields)
- [Hide, reorder, resize, freeze](/docs/sheet/docs/sheet/fields/columns)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
