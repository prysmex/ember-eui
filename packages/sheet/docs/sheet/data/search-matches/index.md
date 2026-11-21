---
title: Search and match stepping
order: 84
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: search and match stepping"/>
<EuiSpacer @size="l" />

<EuiText>

The sheet does not search: it marks your term (`@highlight`) and rings
your current match (`@currentMatch`), so a search box can step through
the matches with Enter.

## Search matches

The sheet does not search, but it shows your current match:
`@currentMatch={{this.match}}` scrolls that cell into view (below the
header, clear of the frozen fields) and draws a ring inside it
(`--euiSheet-match`), over `@highlight`'s marks. Focus stays in your
search box, so typing goes on. Keep your matches and an index, pass
`matches[index]`, and step on Enter and Shift+Enter; `api.focusCell` is
for when the user leaves the box. A match that is not in `@records` (on
another page, in a collapsed group) or whose field is hidden draws
nothing: change the page, expand the group (`toggleGroup`) or show the
field first; the sheet scrolls to it once its record arrives. An owner
that holds every record lists its matches with `findMatches`:

```js
import { builtInFieldTypes, defaultMessages, findMatches } from '@ember-eui/sheet';

const ctx = { types: builtInFieldTypes, messages: defaultMessages, getRecordId: (r) => r.id };
findMatches(ctx, records, fields, 'ana'); // [{ recordId, fieldId }, …], by row then field
```

It matches what `@highlight` marks: each type's shown text, ignoring
case and accents. An owner that pages gets its matches from its backend.
With groups, list them over the records in display order with every
group expanded (`groupRecords` without `collapsed`), as the "Search
navigation" example does.

## Related

- [EmberSearchUi](/docs/sheet/docs/sheet/data/search-ui)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
