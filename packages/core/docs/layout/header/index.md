---
title: Header
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Header"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiHeader` is the app's top bar: logo, breadcrumbs, search, links and
action buttons (help, notifications, the user menu). It is divided into
`EuiHeaderSection`s (left and right), each holding
`EuiHeaderSectionItem`s.

```hbs
<EuiHeader @position="fixed">
  <EuiHeaderSection @side="left">
    <EuiHeaderSectionItem>
      <EuiHeaderLogo @iconType="logoElastic" @href="/">Acme</EuiHeaderLogo>
    </EuiHeaderSectionItem>
    <EuiHeaderSectionItem>
      <EuiHeaderBreadcrumbs @breadcrumbs={{this.breadcrumbs}} />
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
  <EuiHeaderSection @side="right">
    <EuiHeaderSectionItem>
      <EuiHeaderSectionItemButton aria-label="Help">
        <EuiIcon @type="help" />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
</EuiHeader>
```

`@position="fixed"` keeps it at the top while the page scrolls;
`@theme="dark"` is for app-wide navigation. `EuiHeaderLinks` holds text
links and collapses them into a menu on small screens.

</EuiText>

<EuiHorizontalRule />

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
| `@theme` | `'default' \| 'dark' \| (string & {})` | `'default'` | `'default'` follows the light/dark theme; `'dark'` always renders a dark header (upstream's pseudo dark theme for logo, links and buttons). |
| `@position` | `'static' \| 'fixed' \| (string & {})` | `'static'` | `'static'` scrolls with the page; `'fixed'` stays at the top. Fixed headers stack below each other, set the `--euiFixedHeadersOffset` CSS variable on `<html>` to their total height, give `<body>` the `euiBody--headerIsFixed` class and pad `<body>` by that offset. |
| `@sections` | `EuiHeaderSections` |  | Builds the header from data instead of the block: per section, one `EuiHeaderSection` of text `items`, then optional `breadcrumbs`. Most apps compose it with `EuiHeaderSection`s instead. |

| Block | Description |
| --- | --- |
| default block | `EuiHeaderSection`s (left and right), ignored with `@sections`. |
| `<:sectionItem>` | With `@sections`: renders each item of a section's `items` (yielded as given) instead of the text or component, e.g. for markup. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiHeaderSection

A group of `EuiHeaderSectionItem`s on one side of the header.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@side` | `'left' \| 'right'` | `'left'` | `'left'` or `'right'`. A right section is pushed to the end with `margin-inline-start: auto` (start/end in RTL). |
| `@grow` | `boolean` | `false` | Takes the remaining space, e.g. for a search bar. |

| Block | Description |
| --- | --- |
| default block | The `EuiHeaderSectionItem`s. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiHeaderSectionItem

One item of an EuiHeaderSection, e.g. a logo, links or a button.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |


Deprecated: `@border` (Has no effect: latest EUI removed the item dividers (`'left'`, `'right'`, `'none'`).).

| Block | Description |
| --- | --- |
| default block | The item's content. Without a block nothing is rendered, as upstream. |

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
| `@notification` | `boolean \| number \| string` |  | `true` shows a dot; a number shows a count badge, which becomes a dot below the theme's `m` breakpoint (as upstream; formerly only `xs`). |
| `@notificationColor` |  | `'accent'` | `'accent'`, `'subdued'` or `'success'`. |

| Block | Description |
| --- | --- |
| default block | The button's content, usually an `EuiIcon` or `EuiAvatar`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>` / `<a>`.

### EuiHeaderLogo

The app's logo (and name) linking home, first in the header.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@href` | `string` |  | Where the logo links to, usually `'/'`. A `javascript:` URL is dropped. |
| `@target` | `string` |  | `target` of the link. |
| `@rel` | `string` |  | Merged into upstream's secure `rel` (`noreferrer`, plus `noopener` for `_blank`). |
| `@iconTitle` | `string` |  | Accessible name of the logo. Needed when there is no text in the block. |
| `@iconType` |  | `'logoElastic'` | The logo, anything `EuiIcon`'s `@type` accepts. |
| `@logoType` | `'glyph' \| 'horizontal'` |  | `'glyph'` (default) is the Elastic glyph (or `@iconType`); `'horizontal'` is the full Elastic logo with its wordmark, 24px tall. `@iconTitle` is its accessible name, `'Elastic'` by default. |

| Block | Description |
| --- | --- |
| default block | The app's name, next to the logo. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<a>`.

### EuiHeaderLinks

A row of `EuiHeaderLink`s that collapses into a popover menu on small
screens.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@popoverBreakpoints` | `EuiResponsiveSizes` | `['xs', 's']`; pass `[]` to never collapse | Screen sizes showing the links in a popover instead of a row (theme breakpoints, evaluated with CSS media queries), or `'all'` / `'none'`. |
| `@gutterSize` | `EuiHeaderLinksGutterSize` | `'s'`, as upstream (formerly `'xs'`) | Space between links: `'none'`, `'xxs'`, `'xs'`, `'s'`, `'m'` or `'l'`. |
| `@panelPaddingSize` |  | `'s'`, as upstream (formerly `'none'`) | Padding of the popover. |
| `@popoverButtonIconType` |  | `'apps'` | Icon of the popover button. |
| `@popoverButtonAriaLabel` | `string` | `'Open menu'` | Accessible name of the popover button. |
| `@popoverButtonProps` | `EuiHeaderLinksPopoverButtonProps` |  | Props for the popover's button (upstream `popoverButtonProps`), see {@link EuiHeaderLinksPopoverButtonProps}. `iconType` wins over `@popoverButtonIconType` and an `aria-label` over `@popoverButtonAriaLabel`; `onClick` is called before the menu toggles. |
| `@popoverProps` | `EuiHeaderLinksPopoverProps` |  | Props for the mobile menu's EuiPopover (upstream `popoverProps`), see {@link EuiHeaderLinksPopoverProps}. `panelPaddingSize` wins over `@panelPaddingSize`. |

| Block | Description |
| --- | --- |
| default block | The `EuiHeaderLink`s. Yields a function closing the mobile menu, like upstream's render-prop children. |

### EuiHeaderLink

A link in `EuiHeaderLinks`: an `EuiButtonEmpty` (all its args apply)
styled for the header. Upstream `EuiHeaderLink` has no styles of its own;
`EuiHeader @theme="dark"` recolors `.euiHeaderLink` and
`.euiHeaderLink-isActive`.

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
| `@max` | `number \| null` |  | Collapses the breadcrumbs past this number into a "…" item. Defaults to `4` (not `5` as in `EuiBreadcrumbs`); `0` or `null` shows all. |
| `@truncate` | `boolean` | `true`, as upstream | Keeps the breadcrumbs on one line, truncating each. |

Also takes the args of `EuiBreadcrumbs`.

| Block | Description |
| --- | --- |
| `<:popoverContent>` | See `EuiBreadcrumbs`' `<:popoverContent>`. |

### EuiHeaderAlert

A news or update item, usually listed in a flyout opened from the header.

| Block | Description |
| --- | --- |
| `<:date>` | When it was published. |
| `<:badge>` | A badge next to the date, e.g. `<EuiBadge>7.0</EuiBadge>`. |
| `<:title>` | The title (rendered in an `<h3>` that labels the alert). |
| `<:text>` | The text. |
| `<:action>` | A link to read more, e.g. an `EuiLink`. |

</EuiText>
<!-- api:end -->
