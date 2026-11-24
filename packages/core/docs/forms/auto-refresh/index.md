---
title: Auto refresh
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Auto refresh"/>
<EuiSpacer @size="l" />

<EuiText>

For when you only need the auto refresh part of a
[super date picker](/docs/core/docs/forms/super-date-picker): a control
that sets whether data refreshes on its own, and how often. These
components only hold the setting. Keep `@isPaused` and
`@refreshInterval` (milliseconds) in sync from `@onRefreshChange`, and run
the refresh yourself, e.g. with a timer.

```hbs
<EuiAutoRefresh
  @isPaused={{this.isPaused}}
  @refreshInterval={{this.refreshInterval}}
  @onRefreshChange={{this.onRefreshChange}}
/>
```

```js
@tracked isPaused = true;
@tracked refreshInterval = 1000;

@action onRefreshChange({ isPaused, refreshInterval }) {
  this.isPaused = isPaused;
  this.refreshInterval = refreshInterval;
}
```

`@onRefreshChange` also gets `intervalUnits`, the unit the user chose
(`'s'`, `'m'` or `'h'`). The interval is shown in the largest unit that
fits (90 seconds as 2 minutes); to keep the user's unit, pass it back as
`@intervalUnits`.

`EuiSuperDatePicker` shows the same "Refresh every" fields at the end of
its quick select menu when it is given `@onRefreshChange`, and with
`@isAutoRefreshOnly={{true}}` it shows only `EuiAutoRefresh`.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

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
| `@isInvalid` | `boolean` |  | Invalid state: danger border, warning icon and `aria-invalid`. |
| `@isLoading` | `boolean` |  | Shows a spinner in the input. |

| Block | Description |
| --- | --- |
| `<:append>` | Content after the input (upstream `append`), e.g. an `EuiFormAppend`; yields the class to put on it and the input id. |

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
| `@isDisabled` | `boolean` |  | Disables the button. It stays focusable (`aria-disabled`) so that its tooltip still shows, unless `@hasAriaDisabled={{false}}`. |
| `@hasAriaDisabled` | `boolean` | `@isDisabled` (upstream) | With `@isDisabled`, renders `aria-disabled="true"` instead of the native `disabled` attribute. |
| `@shortHand` | `boolean` | `false` | Reduces the time unit to a single letter. |
| `@color` |  | `'text'` | `EuiButtonEmpty` color. |
| `@size` |  | `'s'` | `EuiButtonEmpty` size. |
| `@flush` |  |  | `EuiButtonEmpty` flush. |
| `@isLoading` | `boolean` |  | Shows the loading spinner and disables the button. |
| `@contentProps` |  |  | `EuiButtonEmpty`'s `@contentProps` (upstream's `contentProps`). |
| `@textProps` |  |  | `EuiButtonEmpty`'s `@textProps` (upstream's `textProps`). |
| `@css` | `EuiCss` |  | Extra styles composed last into the button's class. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>` / `<a>`.

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

</EuiText>
<!-- api:end -->
