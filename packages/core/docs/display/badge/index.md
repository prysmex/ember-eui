---
title: Badge
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Badge"/>
<EuiHorizontalRule />
<EuiText>

  <p>
<strong>EuiBadges</strong> are used to focus on important bits of information. Although they will automatically space themselves if you use them in a repetitive fashion it is good form to wrap them using a <strong>EuiBadgeGroup</strong> so that they will wrap when width is constrained (as seen below).
  </p>
</EuiText>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiBadge

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@color` |  | `'default'` | `'default'`, `'hollow'`, `'primary'`, `'success'`, `'accent'`, `'warning'`, `'danger'` or any hex color (`'#DA8B45'`); the text color is picked for contrast. |
| `@iconType` |  |  | Icon shown in the badge, anything `EuiIcon`'s `@type` accepts. |
| `@iconSide` | `'left' \| 'right'` | `'left'` | Side of the text the icon is on. |
| `@iconOnClick` | `() => void` |  | Makes the icon a separate button calling this function, e.g. an "x" to remove the badge. Requires `@iconType` and `@iconOnClickAriaLabel`. |
| `@iconOnClickAriaLabel` | `string` |  | Accessible label (and hover title) of the `@iconOnClick` button. |
| `@isDisabled` | `boolean` |  | Disables the badge's buttons and links and greys it out. |
| `@onClick` | `() => void` |  | Makes the badge (or its text, when it has an `@iconType`) a button calling this function. |
| `@onClickAriaLabel` | `string` |  | Accessible label of the `@onClick` button, when the text alone does not describe the action. |
| `@href` | `string` |  | Makes the badge (or its text, when it has an `@iconType`) a link. |
| `@target` | `string` |  | `target` of the `@href` link, e.g. `'_blank'` (only without `@iconType`). |
| `@closeButtonProps` |  |  | Extra props for the `@iconOnClick` button. |

Deprecated: `@iconUseSvg` (Has no effect, see `EuiIcon`.).

| Block | Description |
| --- | --- |
| default block | The badge's text. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>` / `<a>` / `<span>`.

### EuiBetaBadge

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@label` | `string` |  | The badge's text, e.g. `'Beta'`, or a single letter (rendered as a circle). Also its hover title. The default block replaces it. |
| `@title` | `string` |  | Hover title when there is no `@label` (e.g. with `@iconType`), and the title of the `@tooltipContent` tooltip. |
| `@iconType` |  |  | Renders an icon instead of `@label` (icon-only badge). Give it a `@title` so it has a name. |
| `@color` |  | `'hollow'` | `'hollow'`, `'accent'` or `'subdued'`. |
| `@size` |  | `'m'` | `'s'` or `'m'`. |
| `@tooltipPosition` |  | `'top'` | Where the `@tooltipContent` tooltip appears: `'top'`, `'right'`, `'bottom'` or `'left'`. |
| `@tooltipContent` | `string` |  | Shows a tooltip with this text on hover, e.g. what "Beta" means here. |
| `@onClickAriaLabel` | `string` |  | Accessible label of the badge when it is a link or button (`@href` / `@onClick`). |
| `@href` | `string` |  | Makes the badge a link. |
| `@target` | `string` |  | `target` of the `@href` link, e.g. `'_blank'`. |
| `@rel` | `string` |  | `rel` of the `@href` link, e.g. `'noopener'`. |
| `@onClick` | `(event: MouseEvent) => void` |  | Makes the badge a button calling this function. |

| Block | Description |
| --- | --- |
| default block | Custom content instead of `@label` / `@iconType`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>`.

### EuiBadgeGroup

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@gutterSize` |  | `'xs'` | Space between the badges, `'xs'` or `'s'`. |

| Block | Description |
| --- | --- |
| default block | Wrap each badge in the yielded `item` so the group can space and wrap them: `<group.item><EuiBadge>…</EuiBadge></group.item>`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiNotificationBadge

A small count badge, e.g. unread notifications on a header button.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@size` |  | `'s'` | `'s'` or `'m'`. |
| `@color` |  | `'accent'` | `'accent'` or `'subdued'`. |

| Block | Description |
| --- | --- |
| default block | The count, e.g. `3`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>`.

</EuiText>
<!-- api:end -->
