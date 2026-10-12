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
| `@color` | `EuiBadgeNamedColor \| string` | `'default'` | `'default'`, `'hollow'`, `'primary'`, `'accent'`, `'neutral'`, `'success'`, `'warning'`, `'risk'`, `'danger'` or any CSS color (`'#DA8B45'`, `'rgb(…)'`); custom colors get a text color picked for contrast. |
| `@fill` | `boolean` | `false` | Named colors only: the stronger, filled variant of the color. |
| `@iconType` |  |  | Icon shown in the badge, anything `EuiIcon`'s `@type` accepts. |
| `@iconSide` | `'left' \| 'right'` | `'left'` | Side of the text the icon is on (logical, so it flips in RTL). |
| `@iconOnClick` | `(event: MouseEvent) => void` |  | Makes the icon a separate button calling this function, e.g. an "x" to remove the badge. Requires `@iconType` and `@iconOnClickAriaLabel`. |
| `@iconOnClickAriaLabel` | `string` |  | Accessible label (and hover title) of the `@iconOnClick` button. |
| `@isDisabled` | `boolean` |  | Disables the badge's buttons and links and greys it out. |
| `@onClick` | `(event: MouseEvent) => void` |  | Makes the badge (or its text, with `@iconOnClick`) a button calling this function. |
| `@onClickAriaLabel` | `string` |  | Accessible label of the `@onClick` button, when the text alone does not describe the action. |
| `@href` | `string` |  | Makes the badge (or its text, with `@iconOnClick`) a link. |
| `@target` | `string` |  | `target` of the `@href` link, e.g. `'_blank'`. |
| `@rel` | `string` |  | `rel` of the `@href` link. `noreferrer` (and `noopener` for `_blank`) is always added. |
| `@closeButtonProps` |  |  | Extra props for the `@iconOnClick` button. |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

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
| `@iconType` |  |  | Renders an icon instead of `@label` (icon-only, circular badge). Give it a `@title` so it has a name. |
| `@color` | `'hollow' \| 'accent' \| 'subdued' \| 'warning'` | `'hollow'` | `'hollow'`, `'accent'`, `'subdued'` or `'warning'`. |
| `@size` | `'s' \| 'm'` | `'m'` | `'s'` or `'m'`. |
| `@alignment` | `'baseline' \| 'middle'` | `'baseline'` | Vertical alignment (`vertical-align`), `'baseline'` or `'middle'`. |
| `@tooltipPosition` |  | `'top'` | Where the `@tooltipContent` tooltip appears: `'top'`, `'right'`, `'bottom'` or `'left'`. |
| `@tooltipContent` | `string` |  | Shows a tooltip with this text on hover, e.g. what "Beta" means here. |
| `@onClickAriaLabel` | `string` |  | Accessible label of the badge when it is a link or button (`@href` / `@onClick`). |
| `@href` | `string` |  | Makes the badge a link. |
| `@target` | `string` |  | `target` of the `@href` link, e.g. `'_blank'`. |
| `@rel` | `string` |  | `rel` of the `@href` link. `noreferrer` (and `noopener` for `_blank`) is always added. |
| `@onClick` | `(event: MouseEvent) => void` |  | Makes the badge a button calling this function. |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

| Block | Description |
| --- | --- |
| default block | Custom content instead of `@label` / `@iconType`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>` / `<a>` / `<button>`.

### EuiBadgeGroup

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@gutterSize` | `'none' \| 'xs' \| 's'` | `'xs'` | Space between the badges, `'none'`, `'xs'` or `'s'`. |

| Block | Description |
| --- | --- |
| default block | Wrap each badge in the yielded `item` so the group can space and wrap them: `<group.item><EuiBadge>…</EuiBadge></group.item>`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiNotificationBadge

A small count badge, e.g. unread notifications on a header button.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@size` | `'s' \| 'm'` | `'s'` | `'s'` or `'m'`. |
| `@color` | `'accent' \| 'subdued' \| 'success'` | `'accent'` | `'accent'`, `'subdued'` or `'success'`. |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

| Block | Description |
| --- | --- |
| default block | The count, e.g. `3`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>`.

</EuiText>
<!-- api:end -->
