---
title: Breadcrumbs
---

<EuiPageHeader @pageTitle="Breadcrumbs"/>
<EuiSpacer @size="l" />

<EuiText>

Breadcrumbs show where the current page sits in the app's hierarchy and
link back up. Pass them as an array, from the root to the current page:

```hbs
<EuiBreadcrumbs @breadcrumbs={{array
  (hash text="Home" href="/")
  (hash text="Users" onClick=this.goToUsers)
  (hash text="Jane Cooper")
}} />
```

Each breadcrumb has a `text` and an `href` or `onClick` (the last one,
the current page, usually has neither). Long trails collapse the middle
breadcrumbs into a "…" popover past `@max` (5 by default), and
`@responsive={{true}}` shows fewer on small screens. In `EuiHeader` use
`EuiHeaderBreadcrumbs`.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiBreadcrumbs

A `<nav aria-label="Breadcrumbs">` trail of links to the current page.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@responsive` | `boolean \| EuiBreadcrumbResponsiveMaxCount` | `true`, as upstream; `false` turns it off | Shows fewer breadcrumbs on smaller screens, collapsing the ones in the middle into a "…" popover. `true` uses `{ xs: 1, s: 2, m: 4 }` (at most 1 breadcrumb on extra small screens, 2 on small, 4 on medium); pass an object with any of the `xs`, `s`, `m`, `l`, `xl` keys for your own limits (a missing key falls back to `@max`). Never shows more than `@max`. |
| `@truncate` | `boolean` | `true` | Forces all breadcrumbs to a single line and truncates each breadcrumb to 160px, except the last one, which fills the remaining space. |
| `@max` | `number \| null` | `5`; pass `0` or `null` to always show all breadcrumbs | Collapses the breadcrumbs in the middle past this number into a single "…" item that opens a popover with them. |
| `@type` | `EuiBreadcrumbsType` |  | `'page'` (default) separates breadcrumbs with slashes; `'application'` renders them as connected arrow-shaped chips, for the top of an app. |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |
| `@lastBreadcrumbIsCurrentPage` | `boolean` | `true` | Marks the last breadcrumb as the current page (`aria-current="page"`). |
| `@breadcrumbs` (required) | `EuiBreadcrumb[]` |  | The breadcrumbs, from the root to the current page: `[{ text: 'Home', href: '/' }, { text: 'Users', onClick: … }, { text: 'Jane' }]`. |

| Block | Description |
| --- | --- |
| `<:popoverContent>` | Content of the popover of every breadcrumb with `popoverContent: true`; yields the breadcrumb and a `closePopover` function. |

</EuiText>
<!-- api:end -->
