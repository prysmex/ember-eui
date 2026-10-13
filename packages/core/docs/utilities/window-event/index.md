---
title: Window events
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Window events"/>
<EuiSpacer @size="l" />

<EuiText>

**EuiWindowEvent** declaratively adds an event listener to the `window` for as long as it is rendered. It removes the listener when it is torn down (and re-subscribes when `@event` or `@handler` change), so you cannot leave one behind.

```hbs
{{#if this.isTracking}}
  <EuiWindowEvent @event="mousemove" @handler={{this.onMouseMove}} />
{{/if}}
```

Window listeners are global and can conflict with others. The safest way to avoid conflicts is `event.stopPropagation()` at the lowest, most specific level where you respond to a DOM event: the event never reaches the window and the **EuiWindowEvent** handler is not called. For listeners on one element, use `{{on}}`.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiWindowEvent

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@event` (required) | `keyof WindowEventMap \| (string & {})` |  | The window event name, e.g. `'keydown'` or `'mousemove'`. |
| `@handler` (required) | `(event: any) => void` |  | Called with the event for as long as the component is rendered. |

</EuiText>
<!-- api:end -->
