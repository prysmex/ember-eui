---
title: Color palette picker
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Color palette picker"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiColorPalettePicker` picks a color palette, e.g. for a chart, showing
each palette as a bar of colors. `EuiColorPaletteDisplay` is that bar on
its own, to show a palette anywhere.

```hbs
<EuiColorPalettePicker
  @palettes={{this.palettes}}
  @valueOfSelected={{this.palette}}
  @onChange={{this.setPalette}}
/>

<EuiColorPaletteDisplay @palette={{this.colors}} @type="gradient" />
```

A palette is `{ value, title, type, palette }`: `type` is `'fixed'`
(solid blocks), `'gradient'` or `'text'` (an option that is only its
title, like "Custom"); `palette` is an array of colors or of
`{ stop, color }` stops. The palette utilities (`euiPaletteColorBlind`,
`euiPaletteForStatus`, `euiPaletteCool`, …) give ready-made palettes.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiColorPalettePicker

A select of color palettes (e.g. for charts), showing each palette as a
bar of colors. Built on `EuiSuperSelect`; each option shows the title
(EuiText `xs`) above the palette, as upstream.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@palettes` (required) | `EuiColorPalettePickerPalette[]` |  | The palettes to choose from. |
| `@valueOfSelected` | `string` |  | Value of the selected palette. |
| `@onChange` (required) | `(value: string) => void` |  | Called with the chosen palette's value. |
| `@selectionDisplay` | `'palette' \| 'title'` | `'palette'` | Show the selected palette as its `'palette'` (colors) or its `'title'`. |
| `@compressed` | `boolean` |  | Smaller, for dense forms. |
| `@fullWidth` | `boolean` |  | Takes the container's full width. |
| `@isInvalid` | `boolean` |  | Invalid look. |
| `@isLoading` | `boolean` |  | Shows a spinner. |
| `@disabled` | `boolean` |  | Disables the select. |
| `@readOnly` | `boolean` |  | Read-only: the list does not open. |
| `@isOpen` | `boolean` | closed until the user opens it | Controls whether the list is open (upstream `isOpen`, from EuiSuperSelect). |
| `@itemClassName` | `string` |  | Class for each option in the list (EuiSuperSelect `itemClassName`). |
| `@popoverProps` |  |  | Props of the list's EuiInputPopover (EuiSuperSelect `popoverProps`), e.g. `(hash panelClassName="…" repositionOnScroll=true)`. |

| Block | Description |
| --- | --- |
| `<:prepend>` | Content before the picker (upstream's `prepend`), e.g. a label or an icon; yields the class to put on it. |
| `<:append>` | Content after the picker (upstream's `append`); yields the class to put on it. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>`.

### EuiColorPaletteDisplay

Shows a color palette as a bar: `'fixed'` blocks of solid color or a
`'gradient'`, e.g. to preview the palette of a chart.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@palette` (required) | `(string \| ColorStop)[]` |  | The colors: an array of colors (evenly spread), or of `{ stop, color }` color stops. |
| `@type` | `'fixed' \| 'gradient'` | `'fixed'` | `'fixed'` (solid blocks) or `'gradient'`. |
| `@size` | `'xs' \| 's' \| 'm'` | `'s'` | Height of the bar: `'xs'`, `'s'` or `'m'`. |
| `@title` | `string` |  | Name of the palette, read by screen readers. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>`.

</EuiText>
<!-- api:end -->
