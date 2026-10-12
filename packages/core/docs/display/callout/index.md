---
title: CallOut
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Callout"/>

<EuiSpacer />
  <EuiText>
  <p>
   <strong>EuiCallOut</strong> contains a message directly related to content on the page. This includes general information, success, warning, and error messages.</p><p><strong>Keep these guidelines in mind:</strong></p><ul><li>Minimize the number of callouts per page.</li><li>Stack callouts in the order in which they require users' attention: error, warning, info, and then success.</li><li>Offer only one action per callout and ensure it's an action users can perform quickly.</li><li>If the callout has a permanent spot in the UI, but needs to be less obstructive, set the <EuiCode @language="text">@size</EuiCode> property to <EuiCode @language=="text">s</EuiCode> (small).</li><li>Use an <EuiCode @language="text">icon</EuiCode> argument if it adds context.</li></ul>
</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiCallOut

A colored box drawing attention to a message, e.g. a warning or a success notice.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@title` | `string` |  | Title in the callout's header. Use the `<:title>` block for markup. |
| `@heading` |  | `'p'` | Tag of the title, e.g. `'h2'` so it appears in the page outline: `'h1'`–`'h6'` or `'p'`. |
| `@text` | `string` |  | Main text, rendered inline after the title in small callouts. Use the default (or `<:body>`) block for other content. |
| `@iconType` |  |  | Icon before the content, e.g. `'warning'`, `'check'` or `'question'`. Without it, a default icon matching `@color` is shown. |
| `@size` | `EuiCallOutSize` | `'m'` | `'s'` or `'m'`. |
| `@color` | `EuiCallOutColor` | `'primary'` | `'primary'`, `'success'`, `'warning'` or `'danger'`. Other values fall back to `'primary'`. |
| `@textColor` |  | `'default'` | Color of the body text, any `EuiText` color. |
| `@iconSize` |  | `'m'` for small callouts, `'l'` otherwise | Size of a custom `@iconType`. |
| `@onDismiss` | `(event: MouseEvent) => void` |  | Renders a dismiss (cross) button in the top end corner; called when it is clicked. |
| `@dismissButtonAriaLabel` | `string` | "Dismiss this callout" (i18n token `euiCallOut.dismissAriaLabel`) | Accessible label of the dismiss button. |
| `@announceOnMount` | `boolean` | `false` | Announces the title, text and body to screen readers when the callout is inserted (through `EuiLiveAnnouncer`). Use it only when the callout is feedback to a user action, not on page load. |

| Block | Description |
| --- | --- |
| `<:title>` | The title, instead of `@title`. |
| `<:body>` | The body; same as the default block. |
| default block | The body, e.g. paragraphs or a list. |
| `<:actions>` | Actions, e.g. `<EuiButton @size="s">` and `<EuiButtonEmpty @size="s">`. Laid out beside the content in wide callouts. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
