---
title: Field types
order: 5
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: field types"/>
<EuiSpacer @size="l" />

<EuiText>

The built-in field types: what each stores, which texts it reads,
its options and its cell; and how text that needs your API is
resolved.

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

A `url` is a web address when its scheme is `http` or `https` (`https://`
is added when it has none) and its host, as written, is `localhost`, an
IPv6 address in brackets, an IPv4 address of four numbers (`192.168.0.1`),
or a name of two or more parts whose last part has a letter
(`example.com`, `ñandú.mx`): `19/11/2026`, `12` and `1.2.3` are not.

Dates are shown as `DD/MM/YYYY` (or `MM/DD/YYYY`) and copied as ISO.
Currencies are shown with `Intl.NumberFormat` and copied as plain numbers;
percentages are shown with `precision` decimals and copied exactly;
durations are shown as `1:30` (whole minutes) or `1:30:15`. Multi-select,
linked-record and user cells copy their labels joined by `, `, quoting a
label that has a comma. Attachment cells copy their URLs (so pasting them
back is rejected: text is not a file).

- **Multi-select**: chips (three, then "+N"). Its editor is a list with
  a search field: a click or Enter toggles an option and the editor stays
  open; Tab or a click elsewhere saves, Escape cancels.
- **Linked record and user**: chips, or an avatar and the name. The
  picker lists `search`'s results (or a user field's `options`), the
  chosen ones first. With `multiple` a pick toggles, as in a
  multi-select; without it a pick saves. A search typed and left without
  a pick is resolved through `@onResolve`.
- **Attachment**: thumbnails (`thumbnailUrl`, or `url` for an `image/*`
  file), else a file icon and the name. The editor (the paperclip button,
  Enter or a double-click) lists the files with links that open them in a
  new tab and remove buttons, and has a file picker when the field has
  `upload`; each upload or removal is saved at once and the editor stays
  open. Files dropped on a cell, or pasted on one, are uploaded too: the
  cell shows as pending, then the new files are added to its value as it
  is then; a failed upload marks the cell "Upload failed". An `upload`
  that calls `onProgress(fraction)` (0 to 1 for the whole call, for
  example from `XMLHttpRequest`'s `upload.onprogress`) shows a 2 px bar
  along the cell's bottom edge and "Uploading… 40%" as its title, and the
  editor and the expanded record show the same value in a progress bar;
  calls after the upload settled or was aborted are ignored. One that
  never calls it shows the cell pending, as before. Only `http:`,
  `https:`, `blob:` and `data:image/` URLs are used as links or images.
- **Rating**: stars. A click on a star sets it, on the current one clears
  it; on a focused cell the digits 0 to `max` set it. No editor.
- **URL, email, phone**: link-styled text. A click on the text opens the
  link in a new tab (`mailto:` and `tel:` for email and phone); a click
  beside it selects the cell as usual. The row menu has "Open link", and
  the expanded record a button next to the box. Only `http:`, `https:`,
  `mailto:` and `tel:` links are opened, so a `javascript:` value opens
  nothing (and fails validation).
- **Date and time**: one stored format, an instant in UTC, so it orders
  as text and any backend reads it; the zone is the field's, not the
  value's. Shown as `DD/MM/YYYY HH:mm` (or the field's order, a 12-hour
  clock, seconds) in `timeZone`, and copied as the ISO string, so a copy
  pasted into another zone's column is the same instant. Typed text is
  never read with `Date` (it depends on the browser's locale). A wall
  clock that does not exist in the zone (the hour skipped when DST
  starts) moves forward by the gap; one that happens twice (when DST
  ends) is the first. An unknown zone name shows the values in UTC and
  makes every value invalid. Typing a digit opens a text input; Enter,
  F2, a double-click or the calendar icon the browser's date-and-time
  picker, in the field's zone. A fill continues one value by a day (the
  same time in the zone), two or more by their step. `date` is unchanged.
- **Button**: a button with the field's text, icon and colour; a click
  on it, or Enter or Space on the selected cell, calls `@onButtonPress`
  with the record (route by `fieldId`), or, without it, opens
  `url(record)` in a new tab. A promise shows a spinner and ignores
  presses until it settles; a rejection's message is the cell's error
  until the next press. `disabled(record)` draws it disabled; with
  neither a handler nor a `url` every button is disabled (and a warning
  says so once). A press is not a change set and is not undoable. It
  copies its text, so a copied range lines up. In the expanded record it
  is a real button.
- **Barcode**: the text in a monospace font. Typing or pasting writes it;
  a USB or Bluetooth scanner types it like a keyboard and presses Enter,
  so a column can be scanned row by row. Where the field can scan (its
  own `scan`, for example a zxing wrapper, or the browser's
  `BarcodeDetector`, in Chromium-based browsers on Android, ChromeOS and
  macOS), the cell has a camera icon: it opens the editor with a scan
  panel, which reads the rear camera until a code decodes and saves it;
  Cancel or Escape stop the camera. The camera needs a secure page and
  the user's permission. The symbology is not stored.
- **Long text**: the lines, clamped to the row height. The editor is a
  text area that starts at the cell, at least 240 px wide, and grows with
  its lines (up to 240 px, then it scrolls). Shift+Enter or Alt+Enter adds
  a line; Enter saves and goes down.

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

</EuiText>
