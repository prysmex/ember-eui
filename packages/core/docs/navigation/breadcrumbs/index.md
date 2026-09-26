---
title: Breadcrumbs
---

<EuiPageHeader @pageTitle="Breadcrumbs"/>

<EuiHorizontalRule/>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiBreadcrumbs

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@responsive` | `boolean \| EuiBreadcrumbResponsiveMaxCount` | off | Shows fewer breadcrumbs on smaller screens, collapsing the ones in the middle into a "…" popover. `true` uses `{ xs: 1, s: 2, m: 4 }` (at most 1 breadcrumb on extra small screens, 2 on small, 4 on medium); pass an object with any of the `xs`, `s`, `m`, `l`, `xl` keys for your own limits (a missing key falls back to `@max`). Never shows more than `@max`. |
| `@truncate` | `boolean` | `true` | Forces all breadcrumbs to single line and truncates each breadcrumb to a particular width, except for the last item. |
| `@max` | `number \| null` | `5`; pass `0` or `null` to always show all breadcrumbs | Collapses the breadcrumbs in the middle past this number into a single "…" item that opens a popover with them. |
| `@breadcrumbs` (required) | `EuiBreadcrumb[]` |  | The breadcrumbs, from the root to the current page: `[{ text: 'Home', href: '/' }, { text: 'Users', onClick: … }, { text: 'Jane' }]`. The last one is the current page. |

</EuiText>
<!-- api:end -->
