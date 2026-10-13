---
title: Badge
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Badge"/>
<EuiHorizontalRule />
<EuiText>

**EuiBadge** highlights key pieces of information. While badges will space themselves automatically when used repeatedly, it's best practice to wrap them in an **EuiBadgeGroup**. This ensures they wrap properly when space is limited (as shown below).

</EuiText>

<EuiHorizontalRule />

<EuiText>

## Guidelines

### Choosing pre-GA badges

Using badges in the interface allows to indicate upcoming features and product innovations available for testing and to set user expectations about the maturity, (non-)support, and stability of a feature.

When a feature becomes available for users before being officially Generally Available (GA), it is marked using a badge. A badge can have a default and a short form (with a simple icon). With both forms, a tooltip text explains what this means for the feature to help users get the correct expectations.

Features don't necessarily go through each stage defined in this document. For example, it can start with Beta, or it can start with Technical preview and be announced as GA next.

Such badges rely on the **EuiBetaBadge** component.

| Stage | Technical preview | Beta | GA |
| ---- | ---- | ---- | ---- |
| Description | Experimental features that may not be kept or that may change fundamentally. | Features nearing GA that are not expected to fundamentally change for GA. | Features that are officially supported for production usage. |
| Default label | `TECHNICAL PREVIEW` | `BETA` | N/A |
| Short label (for navigation and contextual menus) | `flask` icon | `beta` icon | N/A |
| Tooltip | `This functionality is experimental and not supported. It may change or be removed at any time.` | `This functionality is still under development and not ready for production usage.` | N/A |
| User expectations and perception | Unstable. For testing an innovation. Bugs and breaking changes are perceived as normal. | Fairly stable. For evaluating or testing an awaited feature. The feature is **almost** ready. There might be some bugs and UX/API refinements. | Production-ready. The feature is ready for production workloads. |

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
