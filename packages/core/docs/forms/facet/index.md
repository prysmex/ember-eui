---
title: Facet
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Facet"/>
<EuiSpacer @size="l" />

<EuiText>

Facets filter a list by one value at a time and show how many items have
it, like the filters beside search results. `EuiFacetButton` is one facet
and `EuiFacetGroup` lays several out in a column or in wrapping rows.

```hbs
<EuiFacetGroup>
  <EuiFacetButton @quantity={{12}} @isSelected={{true}} {{on "click" …}}>
    Errors
  </EuiFacetButton>
</EuiFacetGroup>
```

Handle clicks with `{{on "click" …}}` and set `@isSelected` on the active
facets. The `<:icon>` block adds an icon or avatar before the name (give
it the class `euiFacetButton__icon`); `@isLoading` replaces the count with
a spinner.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiFacetButton

A button to filter by one value (a facet), usually with the number of
matching items. Put several in an `EuiFacetGroup`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@quantity` | `number` |  | Number of matching items, shown in a badge. |
| `@isSelected` | `boolean` |  | Selected look: bold text and an accent badge. |
| `@isDisabled` | `boolean` |  | Disables the button. |
| `@isLoading` | `boolean` |  | Replaces the quantity with a spinner and disables the button. |

| Block | Description |
| --- | --- |
| default block | The facet's name. |
| `<:icon>` | An icon or avatar before the name; give it the class `euiFacetButton__icon`, e.g. `<EuiIcon class="euiFacetButton__icon" … />`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>`.

### EuiFacetGroup

Lays out `EuiFacetButton`s in a column or in wrapping rows.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@layout` | `'vertical' \| 'horizontal'` | `'vertical'` | `'vertical'` (a column) or `'horizontal'` (wrapping rows). |
| `@gutterSize` | `'none' \| 's' \| 'm' \| 'l'` | `'m'` | Space between buttons: `'none'`, `'s'`, `'m'` or `'l'`. |

| Block | Description |
| --- | --- |
| default block | The `EuiFacetButton`s. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>` / `<span>`.

</EuiText>
<!-- api:end -->
