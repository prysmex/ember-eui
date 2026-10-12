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
| `@paddingSize` | `EuiPagePaddingSize` | `'none'` | Padding: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or `'xl'`. Inline padding goes on the header, block padding on its content (see `@bottomBorder`). |
| `@bottomBorder` | `boolean \| 'extended'` |  | Adds a border below the content (`true`, within the max width) or across the whole header (`'extended'`). With no padding, a `true` border also gets an `l` bottom padding, as upstream. Title + tabs headers get the border unless this is `false`. |
| `@restrictWidth` | `boolean \| number \| string` | `false` | Max width of the header's content, centered: `true` for EUI's default (1200px), a number in px or any CSS width. The header itself stays full width. |
| `@color` | `string` | `'transparent'` | Background: `'transparent'`, `'plain'`, `'subdued'`, … (EuiPanel colors). |
| `@alignItems` |  | stretching the items (centered for a header with only a default block) | Vertical alignment of the title and the right side items: `'top'`, `'bottom'`, `'center'` or `'stretch'`. |
| `@responsive` | `boolean \| 'reverse'` | `true` | Stacks the right side items under the title below the theme's `m` breakpoint; `'reverse'` puts them above it. |
| `@iconType` |  |  | Icon before the title, e.g. the app's logo. |
| `@breadcrumbs` | `any[]` |  | Breadcrumbs above the title, see `EuiBreadcrumbs`'s `@breadcrumbs`. |
| `@tabs` | `any[]` |  | Tabs under the title (or as the title, without `@pageTitle`): `[{ label: 'Overview', isSelected: true, onClick }, …]`, also taking `id`, `href` and `disabled`. |
| `@description` | `string` |  | Text under the title. Use the `<:description>` block for markup. |
| `@pageTitle` | `string` |  | The page's title (an `<h1>`). Use the `<:pageTitle>` block for markup. |
| `@pageTitleProps` |  |  | Props for the title: `{ className }`. |
| `@style` | `{ [key: string]: string; }` |  | Inline styles of the header (the max width goes on its content). |

Deprecated: `@rightSideItems` (Has no effect on its own: put the items in the `<:rightSideItems>` block.); `@default` (Has no effect, use the `<:default>` block.).

| Block | Description |
| --- | --- |
| default block | Extra content under the title and description. |
| `<:description>` | The description, instead of `@description`. |
| `<:pageTitle>` | The title, instead of `@pageTitle`. |
| `<:rightSideItems>` | Actions on the right, e.g. buttons. Wrap each in the yielded item: `<:rightSideItems as \|Item\|><Item><EuiButton …/></Item></:rightSideItems>`. |

</EuiText>
<!-- api:end -->
