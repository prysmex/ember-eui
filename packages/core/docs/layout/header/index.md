---
title: Header
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Header"/>

<EuiHorizontalRule/>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiHeader

The app's top bar: logo, breadcrumbs, links and actions, arranged in
`EuiHeaderSection`s of `EuiHeaderSectionItem`s.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@theme` | `string` | `'default'` | `'default'` (light) or `'dark'`. |
| `@position` | `string` | `'static'` | `'static'` scrolls with the page; `'fixed'` stays at the top and pads `<body>` for it (the body gets `euiBody--headerIsFixed`). |
| `@sections` |  |  | Builds the header from data instead of the block: sections of text `items` and `breadcrumbs`. Most apps compose it with `EuiHeaderSection`s instead. |

| Block | Description |
| --- | --- |
| default block | `EuiHeaderSection`s (left and right), ignored with `@sections`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiHeaderSection

A group of `EuiHeaderSectionItem`s on one side of the header.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@side` |  | `'left'` | `'left'` or `'right'`. |
| `@grow` | `boolean` | `false` | Takes the remaining space, e.g. for a search bar. |

| Block | Description |
| --- | --- |
| default block | The `EuiHeaderSectionItem`s. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiHeaderSectionItem

One item of an EuiHeaderSection, e.g. a logo, links or a button.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@border` |  | `'left'` | Divider on the `'left'`, `'right'` or `'none'`. |

| Block | Description |
| --- | --- |
| default block | The item's content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiHeaderSectionItemButton

An icon button for the header (e.g. help, notifications, user menu),
with an optional notification dot or count. Give it an `aria-label`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@ref` | `(api: { euiAnimate: () => void }) => void` |  | Called with `{ euiAnimate }`; call `euiAnimate()` to wiggle the button, e.g. when a new notification arrives. |
| `@disabled` | `boolean` |  | Disables the button. |
| `@href` | `string` |  | Renders a link instead of a button. |
| `@onClick` | `(event: MouseEvent) => void` |  | Called on click. |
| `@notification` | `boolean \| number` |  | `true` shows a dot; a number shows a count badge (a dot on small screens). |
| `@notificationColor` |  | `'accent'` | `'accent'` or `'subdued'`. |

| Block | Description |
| --- | --- |
| default block | The button's content, usually an `EuiIcon` or `EuiAvatar`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>` / `<a>`.

### EuiHeaderLogo

The app's logo (and name) linking home, first in the header.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@href` | `string` |  | Where the logo links to, usually `'/'`. |
| `@target` | `string` |  | `target` of the link. |
| `@iconTitle` | `string` |  | Accessible name of the logo. Needed when there is no text in the block. |
| `@iconType` |  | `'logoElastic'` | The logo, anything `EuiIcon`'s `@type` accepts. |

| Block | Description |
| --- | --- |
| default block | The app's name, next to the logo. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<a>`.

### EuiHeaderLinks

A row of `EuiHeaderLink`s that collapses into a popover menu on small
screens.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@popoverBreakpoints` |  | `['xs', 's']`; pass `[]` to never collapse | Screen sizes showing the links in a popover instead of a row. |
| `@gutterSize` |  | `'xs'` | Space between links: `'none'`, `'xs'`, `'s'`, `'m'` or `'l'`. |
| `@panelPaddingSize` |  | `'none'` | Padding of the popover. |

| Block | Description |
| --- | --- |
| default block | The `EuiHeaderLink`s. |

### EuiHeaderLink

A link in `EuiHeaderLinks`: an `EuiButtonEmpty` (all its args apply)
styled for the header.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@isActive` | `boolean` |  | Highlights the link, e.g. for the current page. |

Also takes the args of `EuiButtonEmpty`.

| Block | Description |
| --- | --- |
| default block | The link's text. |

### EuiHeaderBreadcrumbs

EuiBreadcrumbs styled for the header.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@breadcrumbs` (required) |  |  | The breadcrumbs, see `EuiBreadcrumbs`'s `@breadcrumbs`. |

### EuiHeaderAlert

A news or update item, usually listed in a flyout opened from the header.

| Block | Description |
| --- | --- |
| `<:date>` | When it was published. |
| `<:badge>` | A badge next to the date, e.g. `<EuiBadge>7.0</EuiBadge>`. |
| `<:title>` | The title (rendered in an `<h3>` that labels the alert). |
| `<:text>` | The text. |
| `<:action>` | A link to read more. |

</EuiText>
<!-- api:end -->
