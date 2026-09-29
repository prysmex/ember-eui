---
title: Color picker
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Color picker"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiColorPicker` is a color field: a text input showing the color that
opens a popover to pick it from a saturation square, a hue slider and
swatches.

```hbs
<EuiColorPicker @color={{this.color}} @onChange={{this.setColor}} />
```

```js
@tracked color = '#D36086';
setColor = (text, { hex, rgba, isValid }) => (this.color = text);
```

You keep the color: `@onChange` gets the text as typed or picked, and
`{ hex, rgba, isValid }`. The format follows `@color`: a hex string
(`'#D36086'`) or `'r, g, b'` (`'211, 96, 134'`); `@format` forces one.

- `@mode`: `'default'`, `'picker'` (no swatches), `'swatch'` (only
  swatches) or `'secondaryInput'`.
- `@swatches` replaces the default color-blind safe palette.
- `@showAlpha` adds an opacity slider (colors then have an alpha channel).
- `@display="inline"` shows the picker itself, without the field.
- The `<:button>` block replaces the field with your own trigger (it
  yields the toggle function), e.g. an `EuiColorPickerSwatch`.
- `@isClearable` adds a clear button; `@placeholder` shows while empty.

With the keyboard: Enter or arrow down open the popover, arrow down again
moves into it, the arrow keys move in the square, and Enter confirms.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiColorPicker

A color field: a text input showing the color (hex or `r, g, b`) that
opens a popover to pick it from a saturation square and a hue slider,
and from swatches. You keep the color: `@onChange` gets the new text and
`{ hex, rgba, isValid }`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@color` | `string` |  | The color: a hex string (`'#D36086'`), `'r, g, b'`, or `''`. |
| `@onChange` (required) |  |  | Called with the new color text and `{ hex, rgba, isValid }`. |
| `@mode` |  | `'default'` | `'default'` (square, hue and swatches), `'picker'` (no swatches), `'swatch'` (only swatches) or `'secondaryInput'` (only the text field set by `@secondaryInputDisplay`). |
| `@display` | `'default' \| 'inline'` |  | `'default'` (a field opening a popover) or `'inline'` (the picker itself). |
| `@swatches` | `string[]` | EUI's color-blind safe palette | The swatches. |
| `@showAlpha` | `boolean` |  | Adds an opacity slider; the color can then have an alpha channel. |
| `@format` | `'hex' \| 'rgba'` | the format of `@color` | `'hex'` or `'rgba'` output. |
| `@secondaryInputDisplay` | `'top' \| 'bottom' \| 'none'` | `'none'` | A text field inside the popover: `'top'`, `'bottom'` or `'none'`. |
| `@isClearable` | `boolean` |  | Adds a button clearing the color. |
| `@placeholder` | `string` | "Transparent" | Placeholder while empty. |
| `@compressed` | `boolean` |  | Smaller field. |
| `@fullWidth` | `boolean` |  | Takes the container's full width. |
| `@disabled` | `boolean` |  | Disables it. |
| `@readOnly` | `boolean` |  | Read-only: the popover does not open. |
| `@isInvalid` | `boolean` |  | Invalid look. |
| `@id` | `string` |  | `id` of the input. |
| `@onFocus` | `() => void` |  | Called when the popover opens. |
| `@onBlur` | `() => void` |  | Called when the field loses focus or the popover closes. |

| Block | Description |
| --- | --- |
| `<:button>` | A custom trigger instead of the field (e.g. a swatch button); yields the function toggling the popover. |
| `<:prepend>` | Content before the field; yields the class to put on it. |
| `<:append>` | Content after the field; yields the class to put on it. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiColorPickerSwatch

A button showing a color, to pick it; the swatches of `EuiColorPicker`.
Add `{{on "click" …}}` to handle the choice.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@color` | `string` |  | The color: a hex string or `'r, g, b(, a)'`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>`.

### EuiHue

The hue slider of `EuiColorPicker` (0 to 359), with the rainbow track.
Rendered for you by the color picker.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@hue` | `number` | `1` | The hue, 0 to 359. |
| `@hex` | `string` |  | The current color as hex, announced to screen readers. |
| `@id` | `string` |  | Prefix of the input's id. |
| `@onChange` (required) | `(hue: number) => void` |  | Called with the new hue. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<input>`.

### EuiSaturation

The saturation / value square of `EuiColorPicker`: drag (or use the
arrow keys) to pick how vivid and how light the color is. Rendered for
you by the color picker.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@color` | `HSV` | `[1, 0, 0]` | The color as HSV: `[hue, saturation, value]`. |
| `@hex` | `string` |  | The current color as hex, for screen readers. |
| `@id` | `string` |  | Prefix of the ids inside. |
| `@onChange` (required) | `(color: HSV) => void` |  | Called with the new `[hue, saturation, value]`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
