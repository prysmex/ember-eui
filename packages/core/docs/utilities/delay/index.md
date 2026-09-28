---
title: Delay
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Delay"/>
<EuiSpacer @size="l" />

<EuiText>

Two helpers that keep loading indicators from flashing when things are
fast:

- **`EuiDelayRender`** renders its content only after `@delay` ms (500 by
  default): a spinner for a request that takes 100ms never appears.
- **`EuiDelayHide`** keeps its content for at least `@minimumDuration` ms
  (1000 by default) once it appears, even if `@hide` becomes true sooner:
  a "Saving…" message stays long enough to be read.

```hbs
{{#if this.isLoading}}
  <EuiDelayRender><EuiLoadingSpinner /></EuiDelayRender>
{{/if}}

<EuiDelayHide @hide={{not this.isSaving}}>
  <EuiCallOut @title="Saving…" />
</EuiDelayHide>
```

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiDelayRender

Renders its content only after a delay, e.g. a loading indicator that
should not flash when loading is fast.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@delay` | `number` | `500` | Milliseconds to wait before rendering. |

| Block | Description |
| --- | --- |
| default block | Rendered once the delay has passed. |

### EuiDelayHide

Keeps its content shown for a minimum time once it appears, even if
`@hide` becomes true sooner, e.g. so a fast loading indicator does not
flash.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@hide` | `boolean` |  | Hides the content (once it has been shown for the minimum time). |
| `@minimumDuration` | `number` | `1000` | Milliseconds the content stays at least. |

| Block | Description |
| --- | --- |
| default block | The content. |

</EuiText>
<!-- api:end -->
