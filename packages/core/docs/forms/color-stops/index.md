---
title: Color stops
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Color stops"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiColorStops` edits a gradient made of color stops, each a value and a
color, e.g. to color a map or a heat map by value.

```hbs
<EuiColorStops
  @label="Map colors"
  @colorStops={{this.stops}}
  @onChange={{this.setStops}}
  @min={{0}}
  @max={{100}}
/>
```

```js
@tracked stops = [
  { stop: 0, color: '#54B399' },
  { stop: 50, color: '#D6BF57' },
];
setStops = (stops, isInvalid) => (this.stops = stops);
```

- Drag a stop to move it; click it to edit its value and color (or
  remove it); click the track to add a stop there.
- With the keyboard: focus the track, up and down select stops, left and
  right move the selected one, Enter opens it (or, on the track, adds a
  stop), Backspace removes it and Escape goes back to the track.
- Without `@min` / `@max` the track grows with the stops.
- `@stopType` is `'gradient'` (colors blend), `'fixed'` (each color until
  the next stop) or `'stepped'` (`@stepNumber` blended steps).
- `@onChange` also tells whether any stop is invalid (an empty value or
  color); keep the stops anyway so the user can fix them.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiColorStops

An editable gradient: a track with color stops (a value and a color
each) to drag, click to edit, add (click the track) and remove, e.g. to
color a map or a chart by value. You keep the stops: `@onChange` gets
the new ones and whether any is invalid.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@colorStops` (required) | `ColorStop[]` |  | The stops: `[{ stop: 0, color: '#54B399' }, …]`. |
| `@onChange` (required) |  |  | Called with the new stops and whether any stop is invalid. |
| `@label` (required) | `string` |  | Accessible name, e.g. "Map colors". |
| `@min` | `number` |  | Lowest stop value; by default the track follows the stops. |
| `@max` | `number` |  | Highest stop value; by default the track follows the stops. |
| `@stopType` | `'gradient' \| 'fixed' \| 'stepped'` | `'gradient'` | `'gradient'` (colors blend), `'fixed'` (each color until the next stop) or `'stepped'` (`@stepNumber` blended steps). |
| `@stepNumber` | `number` | `10` | Number of steps with `@stopType="stepped"`. |
| `@addColor` | `string` | EUI's second visualization color | Color of new stops. |
| `@mode` | `'default' \| 'swatch' \| 'picker'` |  | Color picker of each stop: `'default'`, `'swatch'` or `'picker'`. |
| `@swatches` | `string[]` |  | Swatches of the stops' color pickers. |
| `@showAlpha` | `boolean` |  | Colors may have an alpha channel. |
| `@disabled` | `boolean` |  | Disables it. |
| `@readOnly` | `boolean` |  | Stops can be inspected but not changed. |
| `@compressed` | `boolean` |  | Smaller track. |
| `@fullWidth` | `boolean` |  | Takes the container's full width. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
