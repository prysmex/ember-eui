---
title: All field types
order: 30
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: field types"/>
<EuiSpacer @size="l" />

<EuiText>

The built-in field types: what each stores, which texts it reads and its
options, with every type in two examples. Each type has its own page
next to this one, with a focused example.

## Field types

| Type | Value | Accepted text | Options |
| --- | --- | --- | --- |
| `text` (default) | string | anything | `maxLength`, `pattern`, `patternMessage` |
| `number` | number or `null` | `12`, `-1.5`, `1,234.5` (no exponent, currency or `%`) | `min`, `max`, `decimalSeparator` (`'.'` or `','`) |
| `checkbox` | boolean | `true 1 yes y x ✓ si sí`, `false 0 no n` and empty | |
| `singleSelect` | an option's `value` or `null` | an option's label (any case) or value | `options` (an array or a function of the record), `createOnPaste` |
| `date` | ISO `YYYY-MM-DD` or `null` | `2026-11-19` (also with a time), `2026/11/19`, `19/11/2026`, `19-11-2026`, `19.11.2026` | `dateOrder` (`'dmy'` default, or `'mdy'`), `min`, `max` (ISO) |
| `multiSelect` | an array of option values (`[]` when empty) | labels (any case) or values separated by `,`; a part in double quotes keeps its commas | `options` (an array or a function of the record), `createOnPaste` |
| `linkedRecord` | an array of `{ id, label }` | resolved by `@onResolve`: the text is split on `,` | `search(query, { record, signal })` (the picker's list, a promise), `multiple` (default `true`) |
| `user` | `{ id, label, avatarUrl? }` or `null`; an array with `multiple` | with `options`: a label or an `email` (any case); without: resolved by `@onResolve` | `options` or `search`, `multiple` (default `false`) |
| `attachment` | an array of `{ id, name, url, type?, size?, thumbnailUrl? }` | none: text is rejected; files are uploaded (picker, drop, paste of files) | `upload(files, { record, field, signal, onProgress })`, `accept`, `maxFiles` |
| `currency` | number or `null` | `$1,234.50`, `MXN 12`, `12`: the symbol, the code and spaces are dropped | `currency` (ISO code), `locale`, `precision` (default 2), `min`, `max`, `decimalSeparator` |
| `percent` | a fraction or `null` (`0.25` is 25%) | `25%` or `25` | `precision` (default 0), `min`, `max` (fractions), `decimalSeparator` |
| `duration` | seconds or `null` | `1:30`, `1:30:00`, `1h 30m`, `1.5h`, `45s`, `90` (minutes; seconds with `'h:mm:ss'`) | `durationFormat` (`'h:mm'` default, or `'h:mm:ss'`) |
| `rating` | a whole number from 1 to `max`, or `null` | `0` (none) to `max` | `max` (default 5) |
| `url`, `email`, `phone` | string | anything (checked by validation: a web address, `x@y.z`, digits and `+ ( ) -`) | `maxLength` |
| `longText` | string, with line breaks | anything | `maxLength` |
| `dateTime` | an instant as a UTC ISO string (`2026-11-19T15:30:00.000Z`) or `null` | an ISO string with `Z` or an offset (that instant); an ISO string without one, `19/11/2026 15:30`, `19/11/2026 3:30 pm` (also `-` and `.`, seconds), or a date alone (midnight): in the field's zone | `timeZone` (`'local'` default, `'utc'`, or an IANA name such as `'America/Mexico_City'`), `dateOrder`, `hour12`, `seconds`, `min`, `max` (instants) |
| `button` | none | none: a text is rejected (paste, fill, clear and cut skip the column) | `buttonLabel` (a string or a function of the record; default the label), `icon`, `color` (`'primary'`, `'success'`, `'warning'`, `'danger'`, `'text'`), `disabled(record)`, `url(record)` |
| `barcode` | string or `null` | anything, trimmed | `pattern` (a RegExp source, tested as text fields do), `patternMessage`, `formats` (for a scan), `scan({ formats, signal })` |

Dates are shown as `DD/MM/YYYY` (or `MM/DD/YYYY`) and copied as ISO.
Currencies are shown with `Intl.NumberFormat` and copied as plain numbers;
percentages are shown with `precision` decimals and copied exactly;
durations are shown as `1:30` (whole minutes) or `1:30:15`. Multi-select,
linked-record and user cells copy their labels joined by `, `, quoting a
label that has a comma. Attachment cells copy their URLs (so pasting them
back is rejected: text is not a file).

Array and object values are compared by content (a type's `equals`), so
writing an equal array is no change, and undo is not blocked by an owner
that replaced a value with an equal copy. The sheet never changes a value
in place; your store should not either (fill down, paste and duplicate
may put the same array in two records).

Numbers, dates and checkboxes give their column a grid `schema`, so number
columns are right-aligned and the column menu's sort items read "Sort
Low-High", "Sort Old-New" and "Sort False-True" (text: "Sort A-Z"). An app
type sets `schema` the same way, and may add `toNumber(value)` for
`summarize`. A type's `cell` component also gets `@highlight` (the sheet's
term) to mark matches itself.

## Related

- [Custom field types and editors](/docs/sheet/docs/sheet/field-types/custom-types)
- [Field rules](/docs/sheet/docs/sheet/validation/field-rules): `required`, `min`, `max`, `pattern`
- [Field editor](/docs/sheet/docs/sheet/fields): adding fields from the grid
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
