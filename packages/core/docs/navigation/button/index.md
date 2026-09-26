---
title: Button
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Button"/>
<EuiSpacer @size="l" />

<EuiText>
  <p> EUI provides many types, colors and configurations of buttons. The one best suited for you context depends on placement, prominence, and state. For primary and secondary actions it is best to use the basic <strong>EuiButton</strong>. For tertiary or low prominence actions, use <strong>EuiButtonempty</strong>.</p>
  <p>Be sure to read the full button usage guidelines.</p>
</EuiText>

<EuiHorizontalRule/>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiButton

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@color` | `string` | `'primary'` | `'primary'`, `'accent'`, `'success'`, `'warning'`, `'danger'`, `'ghost'` (for dark backgrounds) or `'text'`. |
| `@contentClasses` | `string` |  | Classes for the element wrapping the icon and text. |
| `@disabled` | `boolean` |  | Same as `@isDisabled`. |
| `@fill` | `boolean` | `false` (light background) | Solid background, for the primary action of a page or form. |
| `@fullWidth` | `boolean` |  | Stretches the button to its container's width. |
| `@href` | `string` |  | Renders an `<a>` link instead of a `<button>` (a disabled or loading button stays a `<button>`). |
| `@iconClasses` | `string` |  | Extra classes for the icon. |
| `@iconSide` |  | the left side | `'right'` puts the icon after the text. |
| `@iconSize` |  | `'m'` | Size of the icon. |
| `@iconType` |  |  | Icon next to the text; anything `EuiIcon`'s `@type` accepts. |
| `@isLoading` | `boolean` |  | Shows a spinner instead of the icon and disables the button. |
| `@isSelected` | `boolean` |  | For toggle buttons: sets `aria-pressed="true"` while selected. |
| `@size` | `string` | `'m'` | `'s'` or `'m'`. |
| `@target` | `string` |  | `target` of the `@href` link, e.g. `'_blank'`. |
| `@textClasses` | `string` |  | Classes for the element wrapping the text. |
| `@type` | `string` | `'button'` | `type` of the `<button>`, e.g. `'submit'` in a form. |
| `@element` | `string` | `'a'` with `@href`, `'button'` otherwise | Tag to render, e.g. `'label'` for a file input trigger. |
| `@isDisabled` | `boolean` |  | Disables the button and greys it out. |

Deprecated: `@useComponent` (Not needed: a component passed as `@iconType` is rendered.); `@useSvg` (Has no effect, see `EuiIcon`.).

| Block | Description |
| --- | --- |
| default block | The button's text. |

### EuiButtonEmpty

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@isLoading` | `boolean` |  | Shows a spinner instead of the icon and disables the button. |
| `@size` |  | `'m'` | `'xs'`, `'s'` or `'m'`. |
| `@iconSize` |  | `'m'` (`'s'` for `@size="xs"`) | Size of the icon. |
| `@color` |  | `'primary'` | `'primary'`, `'danger'`, `'text'`, `'ghost'`, `'warning'` or `'success'`. |
| `@iconType` |  |  | Icon next to the text; anything `EuiIcon`'s `@type` accepts. |
| `@iconSide` |  | the left side | `'right'` puts the icon after the text. |
| `@iconClasses` | `string` |  | Extra classes for the icon. |
| `@textClasses` | `string` |  | Classes for the element wrapping the text. |
| `@contentClasses` | `string` |  | Classes for the element wrapping the icon and text. |
| `@flush` |  |  | Removes the padding on `'left'`, `'right'` or `'both'` sides, to align the text with content above or below it. |
| `@href` | `string` |  | Renders an `<a>` link instead of a `<button>` (a disabled or loading button stays a `<button>`). |
| `@target` | `string` |  | `target` of the `@href` link, e.g. `'_blank'`. |
| `@isDisabled` | `boolean` |  | Disables the button and greys it out. |
| `@type` | `string` | `'button'` | `type` of the `<button>`, e.g. `'submit'`. |
| `@isSelected` | `boolean` |  | For toggle buttons: sets `aria-pressed` to `"true"` / `"false"`. Leave it undefined for regular buttons. |
| `@disabled` | `boolean` |  | Same as `@isDisabled`. |

Deprecated: `@useSvg` (Has no effect, see `EuiIcon`.); `@useComponent` (Not needed: a component passed as `@iconType` is rendered.).

| Block | Description |
| --- | --- |
| default block | The button's text. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<a>` / `<button>`.

### EuiButtonIcon

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@iconType` |  |  | The icon; anything `EuiIcon`'s `@type` accepts. An icon-only button has no visible text, so always pass an `aria-label="…"` describing the action. |
| `@iconSize` |  | `'m'` | Size of the icon. |
| `@iconClasses` | `string` |  | Extra classes for the icon. |
| `@href` | `string` |  | Renders an `<a>` link instead of a `<button>`. |
| `@target` | `string` |  | `target` of the `@href` link, e.g. `'_blank'`. |
| `@isDisabled` | `boolean` |  | Disables the button and greys it out. |
| `@isSelected` | `boolean` |  | For toggle buttons: sets `aria-pressed="true"` while selected. |
| `@display` |  | `'empty'` | `'empty'` (just the icon), `'base'` (light background) or `'fill'` (solid background). |
| `@color` |  | `'primary'` | `'primary'`, `'accent'`, `'success'`, `'warning'`, `'danger'`, `'ghost'` or `'text'`. |
| `@size` |  | the `euiButtonIcon.size` config, or `'xs'` | Size of the button: `'xs'`, `'s'` or `'m'`. |
| `@type` | `'button' \| 'submit' \| 'reset'` | `'button'` | `type` of the `<button>`. |
| `@disabled` | `boolean` |  | Same as `@isDisabled`. |

Deprecated: `@useSvg` (Has no effect, see `EuiIcon`.); `@useComponent` (Not needed: a component passed as `@iconType` is rendered.).

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>` / `<a>`.

### EuiButtonGroup

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@buttonSize` | `'s' \| 'm' \| 'compressed'` | `'s'` | `'s'`, `'m'`, or `'compressed'` (for forms, e.g. inside an `EuiFormRow` with `@display="rowCompressed"`). |
| `@color` |  | `'text'` | Color of the selected buttons: `'primary'`, `'text'`, `'ghost'`, `'success'`, `'warning'` or `'danger'`. |
| `@isFullWidth` | `boolean` |  | Stretches the group, and its buttons evenly, to its container's width. |
| `@isDisabled` | `boolean` |  | Disables every option. |
| `@type` | `'single' \| 'multi'` | `'single'` | `'single'`: one option selected at a time, set with `@idSelected` (radio buttons). `'multi'`: each option toggles, set with `@idToSelectedMap`. |
| `@legend` | `string` |  | Describes the group for screen readers (visually hidden legend). Required for accessibility. |
| `@name` | `string` | a random id | `name` of the radio inputs (single selection). |
| `@className` | `string` |  | Extra class(es) for the fieldset. |
| `@isIconOnly` |  |  | Shows only the options' icons; their labels stay for screen readers. |
| `@onChange` (required) |  |  | Called with the clicked option's `id` (and its `value` for `'single'`). Update `@idSelected` / `@idToSelectedMap` here. |
| `@idSelected` | `Option['id']` |  | Id of the selected option (`@type="single"`). |
| `@idToSelectedMap` |  |  | Selected state by option id, e.g. `{ bold: true, italic: false }` (`@type="multi"`). |
| `@options` | `Array<Option>` |  | The buttons: `[{ id: 'left', label: 'Left', iconType: 'editorAlignLeft' }]`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<fieldset>`.

</EuiText>
<!-- api:end -->
