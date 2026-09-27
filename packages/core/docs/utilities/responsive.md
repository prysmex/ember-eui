---
title: Responsive
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Responsive"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiShowFor` and `EuiHideFor` render their content only on, or except
on, some screen sizes. The sizes are EUI's breakpoints: `xs` (0–574px),
`s` (575–767px), `m` (768–991px), `l` (992–1199px) and `xl` (1200px and
up).

```hbs
<EuiHideFor @sizes={{array "xs" "s"}}>
  <EuiButton @iconType="plusInCircle">Create dashboard</EuiButton>
</EuiHideFor>
<EuiShowFor @sizes={{array "xs" "s"}}>
  <EuiButtonIcon @iconType="plusInCircle" aria-label="Create dashboard" />
</EuiShowFor>
```

Unlike CSS media queries, the hidden content isn't rendered at all.

</EuiText>

<EuiHorizontalRule />

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
