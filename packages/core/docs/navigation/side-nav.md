---
title: Side nav
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Side nav"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiSideNav` renders a navigation tree for a page's side bar from
`@items`. Each item has an `id`, a `name`, an `href` or `onClick`, and
optional nested `items`; the item whose id is `@selectedItem` is
highlighted and its parents are opened.

```hbs
<EuiSideNav
  @heading="Settings"
  @selectedItem={{this.current}}
  @items={{this.items}}
  @isOpenOnMobile={{this.navOpen}}
  @toggleOpenOnMobile={{this.toggleNav}}
/>
```

On small screens the nav collapses behind a toggle button
(`@mobileTitle`); keep `@isOpenOnMobile` and flip it in
`@toggleOpenOnMobile`. Item names truncate to one line by default; pass
`@truncate={{false}}` to wrap them all (an item's own `truncate` wins).

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiSideNav

A hierarchical navigation tree for a page's side bar.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@mobileBreakpoints` |  | `['xs', 's']`; pass `[]` to never collapse | Screen sizes showing the nav collapsed behind a toggle button. |
| `@isOpenOnMobile` | `boolean` |  | Whether the collapsed (mobile) nav is open; flip it in `@toggleOpenOnMobile`. |
| `@truncate` | `boolean` |  | Truncates the names of all items to one line (`false` wraps them). An item's own `truncate` wins. Items truncate by default. |
| `@toggleOpenOnMobile` | `(isOpen: boolean) => void` |  | Called by the mobile toggle button with the new open state. |
| `@heading` | `string` |  | Heading above the items (and the toggle text on mobile). |
| `@headingProps` |  |  | Props for the heading: `{ element: 'h2', id, className, screenReaderOnly }`. The heading labels the `<nav>`. |
| `@mobileTitle` | `string` | the heading | Text of the mobile toggle button. |
| `@items` | `Item[]` |  | The navigation tree, see `Item`. |
| `@selectedItem` | `string` |  | Id of the current item: it is highlighted and its parents open. |
| `@renderItem` | `EuiSideNavRenderItem` |  | Replaces the rendering of every item's link, button or text with a component, see `Item.renderItem`. |

Deprecated: `@isOpenMobile` (Use `@isOpenOnMobile` (upstream's name).).

| Block | Description |
| --- | --- |
| `<:heading>` | Custom heading, instead of `@heading`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>` / `<ul>`.

</EuiText>
<!-- api:end -->
