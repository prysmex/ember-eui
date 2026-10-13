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

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@commonlyUsedRanges` | `DurationRange[]` | EUI's list (Today, This week, Last 15 minutes, …) | Ranges listed as "Commonly used" in the quick select popover: `[{ start: 'now/d', end: 'now/d', label: 'Today' }, …]`. |
| `@customQuickSelectPanels` | `QuickSelectPanel[]` |  | Extra panels at the end of the quick select popover: `[{ title: 'My panel', content: MyPanel }]`. `content` is a component, rendered with `@applyTime`; call it with `{ start, end }` to apply a range (as a quick selection) and close the popover. |
| `@dateFormat` | `string` | `'MMM D, YYYY @ HH:mm:ss.SSS'` | moment format for absolute dates. |
| `@isAutoRefreshOnly` | `boolean` | `false` | Set isAutoRefreshOnly to true to limit the component to only display auto refresh content. |
| `@isDisabled` | `boolean \| { display: string \| ComponentLike }` | `false` | Disables the picker. Pass `{ display }` to also replace the dates with your own content, e.g. `{ display: 'All time' }` (a string or a component), in a disabled button. |
| `@isLoading` | `boolean` |  | Shows the update button's loading state, e.g. while data refreshes. |
| `@isPaused` | `boolean` | `true` | Whether auto refresh is paused (with `@onRefreshChange`). |
| `@width` | `'restricted' \| 'full' \| 'auto'` | `'restricted'` | Sets the overall width by adding sensible min and max widths. - `auto`: fits width to internal content / time string. - `restricted`: static width that fits the longest possible time string   (600px with the update button, 480px without). - `full`: expands to 100% of the container. `@isQuickSelectOnly` forces `'auto'`. |
| `@compressed` | `boolean` |  | Reduces overall height to compressed form size |
| `@locale` | `LocaleSpecifier` |  | Used to localize e.g. month names, passed to `moment` |
| `@onRefresh` |  |  | Called every `@refreshInterval` ms while not `@isPaused` (and by the update button when the range has not changed), with `{ start, end, refreshInterval }`. If it returns a promise, the next call waits for it; if the promise rejects, refreshing stops. |
| `@onRefreshChange` | `ApplyRefreshInterval` |  | Adds the "Refresh every" section to the quick select popover; called with `{ refreshInterval, isPaused }` when the user changes them. |
| `@onTimeChange` (required) |  |  | Callback for when the time changes. |
| `@recentlyUsedRanges` | `DurationRange[]` |  | Ranges listed as "Recently used" in the quick select popover (their `label`, or "start → end"). |
| `@refreshInterval` | `Milliseconds` | `1000` | Refresh interval in milliseconds. |
| `@refreshMinInterval` | `Milliseconds` | `0` | Minimum refresh interval in milliseconds: the refresh interval fields don't go below it. |
| `@refreshIntervalUnits` | `RefreshUnitsOptions` |  | The refresh interval's unit (`'s'`, `'m'` or `'h'`). By default it is rounded up to the largest unit that fits (90 seconds become 2 minutes). To keep the user's unit, store the `intervalUnits` `@onRefreshChange` receives and pass it back here. |
| `@start` | `ShortDate` | `'now-15m'` | Start of the range, as date math (`'now-15m'`, `'now/d'`) or an ISO date. |
| `@end` | `ShortDate` | `'now'` | End of the range, like `@start`. |
| `@minDate` | `Moment` |  | Earliest selectable date (a moment): earlier days are disabled in the calendar and a start before it makes the range invalid. |
| `@maxDate` | `Moment` |  | Latest selectable date (a moment): later days are disabled in the calendar and an end after it makes the range invalid. |
| `@timeFormat` | `string` | `'HH:mm'` | moment format for times in the date picker. |
| `@utcOffset` | `number` |  | UTC offset in minutes for absolute dates, e.g. `-300`. |
| `@showUpdateButton` | `boolean \| 'iconOnly'` | `true` | Set showUpdateButton to false to immediately invoke onTimeChange for all start and end changes; `'iconOnly'` shows a compact button. |
| `@isQuickSelectOnly` | `boolean` |  | Hides the actual input reducing to just the quick select button. |
| `@updateButtonProps` | `EuiSuperUpdateButtonProps` |  | Arguments for the update button: `{ fill, color, size, iconType, iconOnly, className, children, minWidth, showTooltip, toolTipProps, responsive, 'data-test-subj' }` (`children` is a custom label; `responsive` lists the screen sizes where it collapses to its icon, `['xs', 's']` by default, or `false`). They win over the picker's own, e.g. `{ fill: false }`. |
| `@quickSelectButtonProps` | `EuiQuickSelectButtonProps` |  | Props for the quick select button, spread over its defaults: `{ 'aria-label', 'data-test-subj', onClick, onMouseDown, label, iconLeft, iconRight, className, … }`. `on*` functions become event listeners (`onClick` runs after the popover toggles); other unknown keys are set as attributes. |
| `@showTimeWindowButtons` | `boolean \| EuiTimeWindowButtonsConfig` |  | Shows a button group next to the control to shift the time window back and forward and to zoom it out. `true`, or a configuration `{ showZoomOut, showZoomIn, showShiftArrows, zoomFactor }` (zoom in is off by default; `zoomFactor` defaults to `0.5`, also as `'50%'`). |
| `@timeZoneDisplayProps` | `EuiTimeZoneDisplayProps` |  | Shows time zone information in the start/end popovers: `{ timeZone: 'America/Los_Angeles' }` (any IANA name, `'Browser'` or `'UTC'`), plus an optional reference `date` and a `customRender` component (`@nameDisplay`, `@utcOffset`, `@timeZoneName`). Informational only: dates are not converted. |
| `@canRoundRelativeUnits` | `boolean` | `true` | By default relative values are rounded to the largest unit that fits (90 minutes show as "~ 2 hours ago"). `false` keeps the user's units. |
| `@onFocus` | `(event: FocusEvent) => void` |  | Called when the start or end date button gets focus. |

| Block | Description |
| --- | --- |
| `<:customQuickSelectRender>` | Replaces the quick select popover's content (upstream `customQuickSelectRender`). Yields the default panels as components (`quickSelect`, `commonlyUsedRanges`, `recentlyUsedRanges`, `refreshInterval`, `customQuickSelectPanels`) to re-order, omit or mix with your own content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiRefreshInterval

"[switch] Refresh every [5] [minutes]": sets how often data refreshes.
The switch turns refreshing on and off; the interval fields are
disabled while it is off (upstream EUI). `EuiSuperDatePicker` shows it in its quick select popover
when given `@onRefreshChange`; it also works on its own.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@isPaused` | `boolean` | `true` | Whether refreshing is stopped. |
| `@refreshInterval` | `number` | `1000` | The interval in milliseconds. |
| `@minInterval` | `number` | `0` | The smallest interval in milliseconds; edits are raised to it and the number field's `min` follows it. |
| `@intervalUnits` | `Units` |  | Shows the interval in this unit (`'s'`, `'m'` or `'h'`) instead of the largest unit that fits (90 seconds becomes 2 minutes). |
| `@applyRefreshInterval` |  |  | Called with `{ refreshInterval, isPaused }` after a change. |
| `@onRefreshChange` |  |  | Upstream's callback: called like `@applyRefreshInterval`, with the chosen `intervalUnits` as well. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<fieldset>`.

### EuiAutoRefresh

A read-only text input showing the auto refresh state ("Off", "5 minutes")
with an "Auto refresh" prepend button; both open a popover with
`EuiRefreshInterval`. Upstream's `EuiAutoRefresh`; for a compact button use
`EuiAutoRefreshButton`. Attributes land on the input.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@isPaused` | `boolean` | `true` | Whether refreshing is paused. |
| `@refreshInterval` | `number` | `1000` | The interval in milliseconds. |
| `@minInterval` | `number` | `0` | The smallest allowed interval in milliseconds. |
| `@intervalUnits` | `'s' \| 'm' \| 'h'` |  | By default the unit is rounded up to the next largest one (90 seconds becomes 2 minutes). Pass `'s'`, `'m'` or `'h'` to fix it. |
| `@onRefreshChange` (required) | `OnRefreshChange` |  | Called with `{ isPaused, refreshInterval, intervalUnits }` when the user changes the refresh settings. |
| `@isDisabled` | `boolean` |  | Disables the input and its button. |
| `@readOnly` | `boolean` | `true` | The input is read-only by default because its value is edited in the popover. |
| `@fullWidth` | `boolean` |  | Stretches the input to its container's width. |
| `@compressed` | `boolean` |  | Compressed input, for dense forms. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<input>`.

### EuiAutoRefreshButton

A button showing the auto refresh state ("Auto refresh is off", "5 minutes")
that opens a popover with `EuiRefreshInterval` to change it. Upstream's
`EuiAutoRefreshButton`; for a text input look-alike use `EuiAutoRefresh`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@isPaused` | `boolean` | `true` | Whether refreshing is paused. |
| `@refreshInterval` | `number` | `1000` | The interval in milliseconds. |
| `@minInterval` | `number` | `0` | The smallest allowed interval in milliseconds. |
| `@intervalUnits` | `'s' \| 'm' \| 'h'` |  | By default the unit is rounded up to the next largest one (90 seconds becomes 2 minutes). Pass `'s'`, `'m'` or `'h'` to fix it. |
| `@onRefreshChange` (required) | `OnRefreshChange` |  | Called with `{ isPaused, refreshInterval, intervalUnits }` when the user changes the refresh settings. |
| `@isDisabled` | `boolean` |  | Disables the button (it stays focusable, as `aria-disabled`). |
| `@shortHand` | `boolean` | `false` | Reduces the time unit to a single letter. |
| `@color` |  | `'text'` | `EuiButtonEmpty` color. |
| `@size` |  | `'s'` | `EuiButtonEmpty` size. |
| `@flush` |  |  | `EuiButtonEmpty` flush. |
| `@isLoading` | `boolean` |  | Shows the loading spinner and disables the button. |
| `@css` | `EuiCss` |  | Extra styles composed last into the button's class. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>` / `<a>`.

</EuiText>
<!-- api:end -->
