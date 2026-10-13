---
title: Pretty duration
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Pretty duration"/>
<EuiSpacer @size="l" />

<EuiText>

Upstream's `PrettyDuration` component and `usePrettyDuration` hook turn a start and end date (timestamps like `2018-01-17T18:57:57.149Z` or relative times like `now-15m`) into a human friendly string, using the `dateFormat` and, optionally, a list of `quickRanges` to name known ranges.

Ember EUI has no standalone `PrettyDuration` component or hook, and there is nothing to import for it. The duration display is part of **EuiSuperDatePicker**, which shows the selected range (for example "Last 15 minutes") and the quick ranges for you; see its page. Its i18n strings (`euiPrettyDuration.*`) go through the `eui-i18n` service like every other EUI string.

If you need a range as text elsewhere, format the two dates with your date library (moment, date-fns, `Intl.DateTimeFormat`) and `@elastic/datemath` for relative values such as `now-15m`.

</EuiText>

<EuiSpacer />
