---
title: Page header
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Page header"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiPageHeader` is the top of a page: an optional icon and breadcrumbs,
the page title (an `<h1>`), a description, tabs, and actions on the right.

```hbs
<EuiPageHeader
  @pageTitle="Dashboards"
  @iconType="dashboardApp"
  @description="Visualize your data in one place."
  @bottomBorder={{true}}
>
  <:rightSideItems as |Item|>
    <Item><EuiButton @fill={{true}} @iconType="plusInCircle">Create dashboard</EuiButton></Item>
    <Item><EuiButtonEmpty>Manage</EuiButtonEmpty></Item>
  </:rightSideItems>
</EuiPageHeader>
```

Put each action in the yielded `Item` of the `<:rightSideItems>` block
(the first one is rightmost). `@tabs` adds tabs under the title (or makes
the tabs the title, without `@pageTitle`). Inside `EuiPageTemplate`,
pass the same options as its `@pageHeader`.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiPageHeader

The top of a page: breadcrumbs, title (with icon), description, tabs and
actions on the right.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@paddingSize` |  |  | Padding around the header: `'none'`, `'s'`, `'m'` or `'l'`. |
| `@bottomBorder` | `boolean` |  | Adds a border below the header. |
| `@restrictWidth` | `boolean \| 'full' \| number \| string` | `false` (full width) | Max width of the header: `true` for EUI's default, a number in px or any CSS width. |
| `@alignItems` |  | `'center'` | Vertical alignment of the title and the right side items: `'top'`, `'bottom'`, `'center'` or `'stretch'`. |
| `@responsive` | `boolean \| 'reverse'` | `true` | Stacks the right side items under the title on small screens; `'reverse'` puts them above it. |
| `@iconType` |  |  | Icon before the title, e.g. the app's logo. |
| `@breadcrumbs` | `any[]` |  | Breadcrumbs above the title, see `EuiBreadcrumbs`'s `@breadcrumbs`. |
| `@tabs` | `any[]` |  | Tabs under the title (or as the title, without `@pageTitle`): `[{ label: 'Overview', isSelected: true, onClick }, …]`, also taking `id`, `href` and `disabled`. |
| `@description` | `string` |  | Text under the title. Use the `<:description>` block for markup. |
| `@pageTitle` | `string` |  | The page's title (an `<h1>`). Use the `<:pageTitle>` block for markup. |
| `@pageTitleProps` |  |  | Props for the title: `{ className }`. |
| `@style` | `{ [key: string]: string; }` |  | Inline styles, merged with the max width. |

Deprecated: `@rightSideItems` (Has no effect on its own: put the items in the `<:rightSideItems>` block.); `@default` (Has no effect, use the `<:default>` block.).

| Block | Description |
| --- | --- |
| default block | Extra content under the title and description. |
| `<:description>` | The description, instead of `@description`. |
| `<:pageTitle>` | The title, instead of `@pageTitle`. |
| `<:rightSideItems>` | Actions on the right, e.g. buttons. Wrap each in the yielded item: `<:rightSideItems as \|Item\|><Item><EuiButton …/></Item></:rightSideItems>`. |

</EuiText>
<!-- api:end -->
