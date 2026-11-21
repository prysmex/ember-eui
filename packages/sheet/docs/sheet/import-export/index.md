---
title: CSV export
order: 90
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: CSV export"/>
<EuiSpacer @size="l" />

<EuiText>

CSV out with `toCsv`: the records you choose, the fields in order, the
texts a copy gives, with formulas escaped.

## Export to CSV

The sheet has no export button: put one in `<:toolbar>` and call `toCsv`
with the records you want (usually all of them, not only a loaded page)
and the fields in order (the block's `fields`, plus `hiddenFields` if you
want those too):

```js
import { builtInFieldTypes, defaultMessages, toCsv } from '@ember-eui/sheet';

exportCsv = (sheet) => {
  const ctx = { types: { ...builtInFieldTypes, ...this.fieldTypes }, messages: defaultMessages };
  const text = toCsv(ctx, this.records, sheet.fields, { delimiter: ',' });
  // the BOM tells Excel the file is UTF-8, so accents survive
  const blob = new Blob(['﻿' + text], { type: 'text/csv;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = 'records.csv';
  link.click();
  URL.revokeObjectURL(url);
};
```

```hbs
<:toolbar as |sheet|>
  <EuiButtonEmpty @iconType="exportAction" {{on "click" (fn this.exportCsv sheet)}}>Export CSV</EuiButtonEmpty>
</:toolbar>
```

`ctx` is the `{ types, messages }` that `summarize` takes, with your
`@fieldTypes` merged over the built-ins. Each cell is the text a copy
gives (the type's `copyText`, else its `format`): dates as ISO, a
multi-select as its labels joined by `, `, attachments as their URLs.
Cells with the delimiter, a `"` or a line break are quoted (RFC 4180),
lines end with `\r\n`, and the first line has the labels (`headers:
false` leaves it out). `delimiter: ';'` suits Excel where the decimal
mark is a comma.

**Formulas.** A spreadsheet runs a cell that starts with `=`, `@`, `+` or
`-` as a formula, so a value typed as `=HYPERLINK(…)` could do something
when the file is opened (a CSV injection). With `escapeFormulas` (the
default) such a cell gets a leading `'`: a text that starts with `=`,
`@`, a tab or `\r`, or with `+` or `-` and is not a number as written
(`-5`, `+52 81 1234 5678` and `-12.5%` stay as they are). The rule looks only at the text, so it is
the same for every type. Pass `escapeFormulas: false` to write the texts
as they are (for a file that only a program reads).

Excel files (`.xlsx`) are not covered: that needs a library. Give your
library `rangeMatrix`'s texts (the same cells as `toCsv`).

## Related

- [CSV paste and import](/docs/sheet/docs/sheet/import-export/csv-import)
- [The import screen](/docs/sheet/docs/sheet/import-export/import-screen)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
