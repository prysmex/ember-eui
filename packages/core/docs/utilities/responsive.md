<EuiSpacer/>
<EuiPageHeader @pageTitle="Responsive"/>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiShowFor

Renders its content only on the given screen sizes. See EuiHideFor.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@sizes` (required) | `EuiHideForBreakpoints[] \| 'all' \| 'none'` |  | Screen sizes to show the content on: any of `'xs'`, `'s'`, `'m'`, `'l'`, `'xl'`, or `'all'`. E.g. `(array "xs" "s")` shows it only on phones. |

| Block | Description |
| --- | --- |
| default block | The content. |

### EuiHideFor

Renders its content except on the given screen sizes. See EuiShowFor.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@sizes` (required) | `EuiHideForBreakpoints[] \| 'all' \| 'none'` |  | Screen sizes to hide the content on: any of `'xs'`, `'s'`, `'m'`, `'l'`, `'xl'`, or `'all'`. E.g. `(array "xs" "s")` hides it on phones. |

| Block | Description |
| --- | --- |
| default block | The content. |

</EuiText>
<!-- api:end -->
