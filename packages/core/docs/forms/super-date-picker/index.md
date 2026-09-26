---
title: Super date picker
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Super date picker"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiSuperDatePicker` picks a time range for dashboards and logs: absolute
dates, relative ranges ("last 15 minutes", "today") or "now", with a quick
select menu of commonly and recently used ranges and optional auto
refresh.

```hbs
<EuiSuperDatePicker
  @start={{this.start}}
  @end={{this.end}}
  @onTimeChange={{this.changeTime}}
/>
```

```js
@tracked start = 'now-15m';
@tracked end = 'now';

@action changeTime({ start, end, isInvalid }) {
  if (isInvalid) return;
  this.start = start;
  this.end = end;
}
```

`@start` and `@end` are **date math** strings (`now-15m`, `now/d` for the
start of today, `now-1w/w`…) or ISO dates. Resolve them to real dates with
`@elastic/datemath` when querying, e.g. `dateMath.parse(start)` and
`dateMath.parse(end, { roundUp: true })`.

Pass `@onRefreshChange` (with `@isPaused` and `@refreshInterval`) to add
auto refresh, and `@onRefresh` to be called on each tick.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiSuperDatePicker

EuiSuperDatePicker picks a time range (absolute dates, relative like
"last 15 minutes", or "now") with a quick select popover and optional
auto refresh, as in Kibana. `@onTimeChange` receives date math strings.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@commonlyUsedRanges` | `DurationRange[]` | EUI's list (Today, This week, Last 15 minutes, …) | Ranges listed as "Commonly used" in the quick select popover: `[{ start: 'now/d', end: 'now/d', label: 'Today' }, …]`. |
| `@dateFormat` | `string` | `'MMM D, YYYY @ HH:mm:ss.SSS'` | moment format for absolute dates. |
| `@isAutoRefreshOnly` | `boolean` | `false` | Set isAutoRefreshOnly to true to limit the component to only display auto refresh content. |
| `@isDisabled` | `boolean` | `false` | Disables the picker. |
| `@isLoading` | `boolean` |  | Shows the update button's loading state, e.g. while data refreshes. |
| `@isPaused` | `boolean` | `true` | Whether auto refresh is paused (with `@onRefreshChange`). |
| `@width` | `'restricted' \| 'full' \| 'auto'` | `'restricted'` | Sets the overall width by adding sensible min and max widths. - `auto`: fits width to internal content / time string. - `restricted`: static width that fits the longest possible time string. - `full`: expands to 100% of the container. |
| `@compressed` | `boolean` |  | Reduces overall height to compressed form size |
| `@locale` | `LocaleSpecifier` |  | Used to localize e.g. month names, passed to `moment` |
| `@onRefresh` |  |  | Callback for when the refresh interval is fired. EuiSuperDatePicker will only manage a refresh interval timer when onRefresh callback is supplied If a promise is returned, the next refresh interval will not start until the promise has resolved. If the promise rejects the refresh interval will stop and the error thrown |
| `@onRefreshChange` | `ApplyRefreshInterval` |  | Callback for when the refresh interval changes. Supply onRefreshChange to show refresh interval inputs in quick select popover |
| `@onTimeChange` (required) |  |  | Callback for when the time changes. |
| `@refreshInterval` | `Milliseconds` | `1000` | Refresh interval in milliseconds. |
| `@start` | `ShortDate` | `'now-15m'` | Start of the range, as date math (`'now-15m'`, `'now/d'`) or an ISO date. |
| `@end` | `ShortDate` | `'now'` | End of the range, like `@start`. |
| `@timeFormat` | `string` | `'HH:mm'` | moment format for times in the date picker. |
| `@utcOffset` | `number` |  | UTC offset in minutes for absolute dates, e.g. `-300`. |
| `@showUpdateButton` | `boolean \| 'iconOnly'` | `true` | Set showUpdateButton to false to immediately invoke onTimeChange for all start and end changes; `'iconOnly'` shows a compact button. |
| `@isQuickSelectOnly` | `boolean` |  | Hides the actual input reducing to just the quick select button. |

</EuiText>
<!-- api:end -->
