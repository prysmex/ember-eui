---
title: Live regions
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Live regions"/>
<EuiSpacer @size="l" />

<EuiText>

Live regions tell screen reader users about changes they cannot see. Both
components render their block into a hidden element and announce its text;
nothing is shown on screen.

- **`EuiScreenReaderLive`** announces its content every time its text
  changes, e.g. "3 results" after a search. It alternates between two live
  regions so consecutive messages are read reliably.
  `@focusRegionOnTextChange` moves focus to it instead, for page or route
  changes.
- **`EuiLiveAnnouncer`** announces a one-off message when it is inserted
  (and when its text changes), then clears it after `@clearAfterMs`
  (2000ms), e.g. "Saved" after an action.

```hbs
<EuiScreenReaderLive>{{this.results.length}} results</EuiScreenReaderLive>

{{#if this.saved}}
  <EuiLiveAnnouncer>Changes saved</EuiLiveAnnouncer>
{{/if}}
```

Both default to `role="status"` with `aria-live="polite"`; pass
`@role="alert"` and `@ariaLive="assertive"` only for urgent messages.
`EuiCallOut` and `EuiBanner` take `@announceOnMount` to announce
themselves through `EuiLiveAnnouncer`.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiScreenReaderLive

Announces its content to screen readers whenever the content's text
changes, without showing it (upstream `EuiScreenReaderLive`), e.g. "3
results" after a search. For a one-off message that is announced once
and then cleared, use `EuiLiveAnnouncer`.

Like upstream, it renders two live regions and alternates between them on
every change, so consecutive announcements are read reliably. The block is
rendered into a `hidden` element and its text is what gets announced.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@isActive` | `boolean` | `true` | Whether screen readers are made aware of the content. |
| `@role` | `EuiLiveRegionRole` |  | `role` of both live regions, e.g. `'status'` or `'alert'`. Defaults to `'status'`. |
| `@ariaLive` | `EuiAriaLive` | `'polite'` | `aria-live` of both live regions: `'polite'`, `'assertive'` or `'off'`. |
| `@focusRegionOnTextChange` | `boolean` | `false` | Focuses the region when the text changes (and on insert), so screen readers read it out. Use it for navigation or page changes, where moving focus back to a known place is desired. |

| Block | Description |
| --- | --- |
| default block | The content to announce. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiLiveAnnouncer

Announces a message to screen readers once, e.g. feedback after an
action, then clears it (upstream `EuiLiveAnnouncer`). The message is not
shown. It is announced when the component is inserted and again whenever
its text changes. For content that stays in sync with the page, e.g. a
result count, use `EuiScreenReaderLive`.

The block is rendered into a `hidden` element; its text is copied into
the live region.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@clearAfterMs` | `number \| false` | `2000` | Clears the live region after this many ms (it is still read if it is cleared meanwhile), or `false` to keep the message. |
| `@isActive` | `boolean` | `true` | Whether screen readers announce the message (`aria-live="off"` otherwise). |
| `@role` | `EuiLiveRegionRole` | `'status'` | `role` of the live region. |
| `@ariaLive` | `EuiAriaLive` | `'polite'` | `aria-live` of the live region: `'polite'`, `'assertive'` or `'off'`. |

| Block | Description |
| --- | --- |
| default block | The message. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
