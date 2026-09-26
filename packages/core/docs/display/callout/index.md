---
title: CallOut
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Callout"/>

<EuiSpacer />
  <EuiText>
  <p>
   <strong>EuiCallOut</strong> contains a message directly related to content on the page. This includes general information, success, warning, and error messages.</p><p><strong>Keep these guidelines in mind:</strong></p><ul><li>Minimize the number of callouts per page.</li><li>Stack callouts in the order in which they require users' attention: error, warning, info, and then success.</li><li>Offer only one action per callout and ensure it's an action users can perform quickly.</li><li>If the callout has a permanent spot in the UI, but needs to be less obstructive, set the <EuiCode @language="text">size</EuiCode> property to <EuiCode @language=="text">s</EuiCode> (small).</li><li>Use an <EuiCode @language="text">icon</EuiCode> prop if it adds context.</li></ul>
</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiCallOut

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@title` | `string` |  | Title in the callout's header. Use the `<:title>` block for markup. |
| `@heading` |  | a `<span>` | Renders the title as a heading element, e.g. `'h2'`, so it appears in the page outline. |
| `@iconType` |  |  | Icon before the title (only shown with a title), e.g. `'alert'`, `'check'` or `'help'`. |
| `@size` |  | `'m'` | `'s'` or `'m'`. |
| `@color` |  | `'primary'` | `'primary'`, `'success'`, `'warning'` or `'danger'`. |
| `@textColor` |  | the text color | Color of the body text, any `EuiText` color. |
| `@iconSize` |  | `'m'` | Size of the title icon. |

| Block | Description |
| --- | --- |
| `<:title>` | The title, instead of `@title`. |
| `<:body>` | The body; same as the default block. |
| default block | The body, e.g. paragraphs and buttons. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
