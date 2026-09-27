<EuiSpacer/>
<EuiPageHeader @pageTitle="Collapsible nav"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiCollapsibleNav` is an app's main navigation in a flyout on the side,
opened from a button in the header. With `@isDocked={{true}}` it stays
open beside the page on large screens (from `@dockedBreakpoint`).

```hbs
<EuiCollapsibleNav @isOpen={{this.navIsOpen}} @onClose={{this.closeNav}}>
  <:button as |navButton|>
    <EuiHeaderSectionItemButton aria-label="Toggle navigation" {{navButton}} {{on "click" this.toggleNav}}>
      <EuiIcon @type="menu" @size="m" />
    </EuiHeaderSectionItemButton>
  </:button>
  <:content>
    <EuiCollapsibleNavGroup @isCollapsible={{true}} @iconType="logoKibana">
      <:title>Analytics</:title>
      <:content>
        <EuiListGroup>…</EuiListGroup>
      </:content>
    </EuiCollapsibleNavGroup>
  </:content>
</EuiCollapsibleNav>
```

Apply the yielded `navButton` modifier to the toggle button: it wires the
`aria-controls` / `aria-expanded` attributes. Group links with
`EuiCollapsibleNavGroup`s, which can collapse.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiCollapsibleNav

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@id` | `string` | a random id | Id of the nav flyout, which the button controls. |
| `@isOpen` | `boolean` |  | Shows the navigation flyout. Toggle it from the `<:button>` block's button and set it to `false` in `@onClose`. |
| `@isDocked` | `boolean` | `false` | Keeps navigation flyout visible and push `<body>` content via padding, on windows at least `@dockedBreakpoint` wide. |
| `@dockedBreakpoint` | `EuiBreakpointSize \| number` | `'l'` | Named breakpoint (`'xs'`, `'s'`, `'m'`, `'l'`, `'xl'`) or pixel value: the minimum window width for docking. |
| `@showButtonIfDocked` | `boolean` | `false` | Keeps the display of toggle button when in docked state. |
| `@as` (required) | `string` | `'nav'` | Tag of the flyout. |
| `@size` |  | `320px` | Width of the nav, a number in px or any CSS width. |
| `@side` | `'left' \| 'right'` | `'left'` | Side of the window: `'left'` or `'right'`. |
| `@role` | `null \| string` | none (the `<nav>` is a landmark) | `role` of the flyout. |
| `@ownFocus` | `boolean` | `true` | Traps focus in the open (not docked) nav. |
| `@outsideClickCloses` | `boolean` | `true` | Clicking outside the open nav calls `@onClose`. |
| `@closeButtonPosition` | `'outside' \| 'inside'` | `'outside'` | Close button `'outside'` or `'inside'` the flyout (hidden while docked). |
| `@paddingSize` | `string` | `'none'` | Padding inside the nav, any `EuiFlyout` padding size. |
| `@onClose` (required) |  |  | Called to close the nav (close button, Escape, outside click). |

Deprecated: `@children` (Has no effect, use the `<:content>` block.).

| Block | Description |
| --- | --- |
| `<:button>` | The toggle button, usually an `EuiHeaderSectionItemButton`. Apply the yielded modifier to it for the `aria-controls` / `aria-expanded` attributes: `<:button as \|navButton\|><EuiButton {{navButton}} …>`. Hidden while docked unless `@showButtonIfDocked`. |
| `<:content>` | The navigation, e.g. `EuiCollapsibleNavGroup`s and `EuiListGroup`s. |

### EuiCollapsibleNavGroup

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@id` | `string` | a random id | Id of the group. |
| `@titleElement` | `string` | `'h3'` | Tag of the title, e.g. `'h2'` or `'div'`. |
| `@isCollapsible` | `boolean` |  | Makes the group an accordion that opens and closes from its title (needs a `<:title>` block). |
| `@initialIsOpen` | `boolean` | `true` | Whether a collapsible group starts open. |
| `@iconType` |  |  | Icon before the title; anything `EuiIcon`'s `@type` accepts. |
| `@iconSize` |  | `'l'` | Size of the icon. |
| `@titleTagName` |  | `'h3'` | Same as `@titleElement`, limited to `EuiTitle`'s tags. |
| `@titleSize` |  | `'xxs'` | Size of the title, any `EuiTitle` size. |
| `@background` | `string` | `'none'` | Background of the group: `'none'`, `'light'` or `'dark'`. |

| Block | Description |
| --- | --- |
| `<:title>` | The group's title; without it the group has no heading. |
| `<:content>` | The group's links, e.g. an `EuiListGroup`. |

</EuiText>
<!-- api:end -->
