---
title: Toast
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Toast"/>
<EuiSpacer @size="l" />

<EuiText>

Toasts are short messages that appear in a corner of the window, e.g.
"Dashboard saved" or an error from a background task, and disappear
after a while. Render `EuiGlobalToastList` once (in the application
template) and add toasts from anywhere with the `euiToaster` service:

```hbs
{{! app/templates/application.hbs }}
<EuiGlobalToastList @toastLifeTimeMs={{6000}} />
```

```js
import { service } from '@ember/service';

@service euiToaster;

save() {
  // …
  this.euiToaster.show({
    title: 'Dashboard saved',
    color: 'success',
    iconType: 'check',
  });
}
```

A toast takes a `title`, an optional `body` (markdown with
`useMarkdownFormat: true`), a `color` (`primary`, `success`, `warning`,
`danger`) and an `iconType`; `toastLifeTimeMs` overrides how long it
stays. Hovering the list pauses the timers. Keep toasts for information
that can be missed; for errors the user must act on, use a callout.


Toasts should be used for ephemeral, live actions (think **save complete**
or **something just finished right now**). They should not be used for
historical actions (**your report built 30 minutes ago**), so a user should
never be greeted with toasts when starting a session.

## Guidelines

- Use a toast for a timely, brief message about the current action.
- Most often, it is a single line of text. A toast stays on screen for a few seconds, and users should be able to read it in 6 to 7 seconds; avoid long paragraphs and titles.
- A toast should have at most two actions, usually just one with a one-word label. For more actions, or an action important enough to interrupt the user, use a modal.
- Each `color` shows a matching icon. Use `iconType` only to override it with something more specific to the context.
- Display one toast at a time; do not stack them.
- Keep messages short. For create, add, delete, remove and save, include the object type, the object name if available, and the past tense of the action, e.g. "User 'Casey Smith' was added". Do not include "successfully", it is implied, and for several objects include the count, not the names.
- When the content needs more room, use the toast for a summary and an action button that leads to the full message.

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
| `@dismissToast` |  |  | Called when a toast is dismissed (its close button or its time ran out, after the fade out), before it is removed from the `euiToaster` service. "Clear all" calls it for every toast. |
| `@toastLifeTimeMs` (required) | `number` |  | How long toasts stay, in ms, unless a toast sets its own `toastLifeTimeMs`. Hovering or focusing the list pauses the timers. Each toast's highlight bar counts this time down. |
| `@side` | `EuiToastSide` | `'right'` | Which side of the browser window the toasts appear on: `'right'` or `'left'`. Below the `m` breakpoint the list spans the window. |
| `@showClearAllButtonAt` | `number \| false` | `3` | Shows a "Clear all" button once there are at least this many toasts; `0` (or `false`) hides it. |
| `@onClearAllToasts` | `() => void` |  | Called after "Clear all" dismissed every toast. |
| `@showNotificationBadge` | `boolean` | `false` | Shows a badge with the number of toasts. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiToast

A notification card. Usually shown through the `euiToaster` service and
EuiGlobalToastList rather than rendered directly.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@title` | `string` |  | The title of the toast. |
| `@body` | `string` |  | The body text of the toast (markdown with `useMarkdownFormat`); upstream calls it `text`. |
| `@color` | `EuiToastColor \| 'none'` | `'primary'` | `'primary'`, `'success'`, `'warning'` or `'danger'`: the highlight bar and default icon. `'none'` (Ember only) renders a neutral toast without a highlight or default icon. |
| `@iconType` |  |  | Icon before the content, e.g. `'check'` or `'warning'`, colored like the highlight. Without it, a notification icon matching `@color` is shown. |
| `@onClose` | `() => void` |  | Shows a dismiss (cross) button calling this function. |
| `@useMarkdownFormat` | `boolean` |  | Renders `body` as markdown (EuiMarkdownFormat). |
| `@actionProps` |  |  | Action buttons below the content: `primary` renders an `EuiButton`, `secondary` an `EuiButtonEmpty`, both small and in the toast's color. |
| `@animationMs` | `number` |  | Duration of the highlight bar's countdown animation, in ms (set by EuiGlobalToastList to the toast's lifetime). Runs only when motion is allowed (`prefers-reduced-motion: no-preference`). |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

| Block | Description |
| --- | --- |
| default block | Extra content below the body text. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
