---
title: Toast
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Toast"/>

<EuiSpacer @size='l' />
<EuiText>

  <p>
Generally, tooltips should provide short, <strong>non-essential</strong>, contextual information, usually naming or describing with more detail. If you need interactive content or anything other than text, we recommend using EuiPopover instead.
  </p>
</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiGlobalToastList

Renders the toasts of the `euiToaster` service. Place it once in the
application template, then show toasts from anywhere:
`this.euiToaster.show({ title: 'Saved', color: 'success' })`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@dismissToast` |  |  | Called when a toast is dismissed (its close button or its time ran out), before it is removed from the `euiToaster` service. |
| `@toastLifeTimeMs` (required) | `number` |  | How long toasts stay, in ms, unless a toast sets its own `toastLifeTimeMs`. Hovering the list pauses the timers. |
| `@side` | `EuiToastSide` | `'right'` | Which side of the browser window the toasts appear on: `'right'` or `'left'`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiToast

A notification card. Usually shown through the `euiToaster` service and
EuiGlobalToastList rather than rendered directly.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@title` | `string` |  | The title of the toast. |
| `@body` | `string` |  | The body text of the toast (markdown with `useMarkdownFormat`). |
| `@color` |  | `'none'` | `'primary'`, `'success'`, `'warning'`, `'danger'` or `'none'`. |
| `@iconType` |  |  | Icon before the title, e.g. `'check'` or `'alert'`. |
| `@onClose` | `() => void` |  | Shows a close button calling this function. |
| `@useMarkdownFormat` | `boolean` |  | Renders `body` as markdown (EuiMarkdownFormat). |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
