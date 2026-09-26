<EuiSpacer/>
<EuiPageHeader @pageTitle="Side nav"/>

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
| `@isOpenMobile` | `boolean` |  | Whether the collapsed (mobile) nav is open. |
| `@toggleOpenOnMobile` | `() => void` |  | Called by the mobile toggle button with the new open state. |
| `@heading` | `string` |  | Heading above the items (and the toggle text on mobile). |
| `@headingProps` |  |  | Props for the heading: `{ element: 'h2', id, className, screenReaderOnly }`. |
| `@mobileTitle` | `string` | the heading | Text of the mobile toggle button. |
| `@items` | `Item[]` |  | The navigation tree, see `Item`. |
| `@selectedItem` | `string` |  | Id of the current item: it is highlighted and its parents open. |

| Block | Description |
| --- | --- |
| `<:heading>` | Custom heading, instead of `@heading`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>` / `<ul>`.

</EuiText>
<!-- api:end -->
