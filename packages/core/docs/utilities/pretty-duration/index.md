---
title: Pretty duration
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Pretty duration"/>
<EuiSpacer @size="l" />

<EuiText>

**EuiPrettyDuration** (upstream's `PrettyDuration`) turns a start and end date into a human friendly text, using `@dateFormat` and, optionally, a list of `@quickRanges` to name known ranges. The dates are timestamps like `2018-01-17T18:57:57.149Z` or relative times like `now-15m`. It renders text only, no element, so it can sit inside any text.

* A range matching a quick range is shown with its label (`now/d` to `now/d` is "Today"). Without `@quickRanges` the commonly used ranges of **EuiSuperDatePicker** are used.
* A relative range ending or starting at `now` is "Last 15 minutes" or "Next 2 days", and "rounded to the day" when it is rounded.
* Anything else is "{start} to {end}" with both dates in `@dateFormat`.

Its i18n strings (`euiPrettyDuration.*`) go through the `euiI18n` service like every other EUI string.

For JavaScript there is the `prettyDuration` function (upstream's `usePrettyDuration`) and `showPrettyDuration`, which tells whether a range has a pretty form. They are the ones **EuiSuperDatePicker** uses:

```js
import { prettyDuration } from '@ember-eui/core/utils/pretty-duration';

prettyDuration(this.euiI18n, {
  timeFrom: 'now-15m',
  timeTo: 'now',
  dateFormat: 'MMM D, YYYY'
}); // 'Last 15 minutes'
```

</EuiText>

<EuiSpacer />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiPrettyDuration

Renders a start and end date as a human friendly text (upstream's
`PrettyDuration`): a matching quick range's label ("Today"), a relative
duration ("Last 15 minutes", "Next 2 days rounded to the day"), otherwise
"{start} to {end}". Renders text only, no element.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@timeFrom` (required) | `ShortDate` |  | The start: a timestamp (`2018-01-17T18:57:57.149Z`) or a relative time (`now-15m`). |
| `@timeTo` (required) | `ShortDate` |  | The end, in the same formats as `@timeFrom`. |
| `@quickRanges` | `DurationRange[]` | the commonly used ranges of EuiSuperDatePicker | Quick ranges whose label is used when they match the start and end. |
| `@dateFormat` | `string` | `'MMM D, YYYY @ HH:mm:ss.SSS'` | moment format of absolute dates. |

</EuiText>
<!-- api:end -->
