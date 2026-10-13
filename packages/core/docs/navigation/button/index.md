---
title: Button
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Button"/>
<EuiSpacer @size="l" />

<EuiText>

Buttons trigger actions. EUI has four kinds, from most to least prominent:

| Component | Use it for |
| --- | --- |
| `EuiButton @fill={{true}}` | The primary action of a page, form or modal (one per view). |
| `EuiButton` | Secondary actions. |
| `EuiButtonEmpty` | Low-prominence actions: cancel, "show more", actions in dense UIs and toolbars. |
| `EuiButtonIcon` | Icon-only actions (edit, delete, settings). Always give it an `aria-label`. |
| `EuiButtonGroup` | A set of toggle buttons, picking one option or several. |

```hbs
<EuiButton @fill={{true}} @iconType="save" {{on "click" this.save}}>Save</EuiButton>
<EuiButtonEmpty {{on "click" this.cancel}}>Cancel</EuiButtonEmpty>
<EuiButtonIcon @iconType="trash" @color="danger" aria-label="Delete" {{on "click" this.remove}} />
```

Actions are attached with `{{on "click" …}}`; with `@href` the button
renders as a link instead. `@isLoading` shows a spinner and disables the
button, `@isDisabled` greys it out. In forms, use `@type="submit"` on the
submit button.

</EuiText>

<EuiHorizontalRule />

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
| `@contentCss` | `EuiCss` |  | Extra styles composed last into the class of the element wrapping the icon and text (upstream's `contentProps.css`). |
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
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

Deprecated: `@useComponent` (Not needed: a component passed as `@iconType` is rendered.); `@useSvg` (Has no effect, see `EuiIcon`.).

| Block | Description |
| --- | --- |
| default block | The button's text. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>` / `<a>` / `<label>`.

### EuiButtonEmpty

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@isLoading` | `boolean` |  | Shows a spinner instead of the icon and disables the button. |
| `@size` | `'xs' \| 's' \| 'm'` | `'m'` | `'xs'`, `'s'` or `'m'`. |
| `@iconSize` |  | `'m'` (always `'s'` for `@size="xs"`) | Size of the icon. |
| `@color` | `string` | `'primary'` | `'primary'`, `'accent'`, `'accentSecondary'`, `'success'`, `'warning'`, `'danger'`, `'text'`, `'neutral'` or `'risk'`. `'ghost'` is still accepted and renders as `'text'` (latest EUI dropped it): wrap it in a dark `EuiEmotionProvider`. |
| `@iconType` |  |  | Icon next to the text; anything `EuiIcon`'s `@type` accepts. |
| `@iconSide` |  | the left side | `'right'` puts the icon after the text. |
| `@iconClasses` | `string` |  | Extra classes for the icon. |
| `@textClasses` | `string` |  | Classes for the element wrapping the text. |
| `@contentClasses` | `string` |  | Classes for the element wrapping the icon and text. |
| `@contentCss` | `EuiCss` |  | Extra styles composed last into the class of the element wrapping the icon and text (upstream's `contentProps.css`). |
| `@flush` | `'left' \| 'right' \| 'both'` |  | Removes the padding on `'left'`, `'right'` or `'both'` sides, to align the text with content above or below it. |
| `@href` | `string` |  | Renders an `<a>` link instead of a `<button>` (a disabled or loading button stays a `<button>`). |
| `@target` | `string` |  | `target` of the `@href` link, e.g. `'_blank'`. |
| `@isDisabled` | `boolean` |  | Disables the button and greys it out. |
| `@type` | `string` | `'button'` | `type` of the `<button>`, e.g. `'submit'`. |
| `@isSelected` | `boolean` |  | For toggle buttons: sets `aria-pressed` to `"true"` / `"false"`. Leave it undefined for regular buttons. |
| `@disabled` | `boolean` |  | Same as `@isDisabled`. |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

Deprecated: `@useSvg` (Has no effect, see `EuiIcon`.); `@useComponent` (Not needed: a component passed as `@iconType` is rendered.).

| Block | Description |
| --- | --- |
| default block | The button's text. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<a>` / `<button>`.

### EuiButtonIcon

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |
| `@iconType` |  |  | The icon; anything `EuiIcon`'s `@type` accepts. An icon-only button has no visible text, so always pass an `aria-label="…"` (or `aria-labelledby`) describing the action; a warning is logged otherwise. |
| `@iconSize` |  | `'m'` | Size of the icon. |
| `@iconClasses` | `string` |  | Extra classes for the icon. |
| `@href` | `string` |  | Renders an `<a>` link instead of a `<button>` (a disabled or loading button stays a `<button>`). |
| `@target` | `string` |  | `target` of the `@href` link, e.g. `'_blank'`. |
| `@isDisabled` | `boolean` |  | Disables the button and greys it out. |
| `@isLoading` | `boolean` |  | Replaces the icon with a loading spinner and disables the button. |
| `@isSelected` | `boolean` |  | For toggle buttons: sets `aria-pressed` to `"true"` / `"false"`. Leave it undefined for regular buttons. |
| `@display` | `'empty' \| 'base' \| 'fill'` | `'empty'` | `'empty'` (just the icon), `'base'` (light background) or `'fill'` (solid background). |
| `@color` | `string` | `'primary'` | `'primary'`, `'accent'`, `'accentSecondary'`, `'success'`, `'warning'`, `'danger'`, `'text'`, `'neutral'` or `'risk'`. `'ghost'` is still accepted and renders as `'text'` (latest EUI dropped it): wrap it in a dark `EuiEmotionProvider`. |
| `@size` | `'xs' \| 's' \| 'm'` | the `euiButtonIcon.size` config, or `'xs'` | Size of the button: `'xs'` (24px), `'s'` (32px) or `'m'` (40px). |
| `@type` | `'button' \| 'submit' \| 'reset'` | `'button'` | `type` of the `<button>`. |
| `@disabled` | `boolean` |  | Same as `@isDisabled`. |

Deprecated: `@useSvg` (Has no effect, see `EuiIcon`.); `@useComponent` (Not needed: a component passed as `@iconType` is rendered.).

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>` / `<a>`.

### EuiButtonGroup

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |
| `@buttonSize` | `'s' \| 'm' \| 'compressed'` | `'s'` | `'s'`, `'m'`, or `'compressed'` (for forms, e.g. inside an `EuiFormRow` with `@display="rowCompressed"`). |
| `@color` |  | `'text'` | Color of the selected buttons: `'text'`, `'primary'`, `'accent'`, `'accentSecondary'`, `'success'`, `'warning'`, `'danger'`, `'neutral'` or `'risk'`. `'ghost'` is still accepted and renders as `'text'` (latest EUI dropped it). |
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

### EuiSplitButton

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@size` | `'xs' \| 's' \| 'm'` | `'m'` | `'s'` or `'m'` (32/40px). |
| `@color` | `string` |  | `'primary'`, `'accent'`, `'accentSecondary'`, `'neutral'`, `'success'`, `'warning'`, `'risk'`, `'danger'` or `'text'`. Defaults to `'primary'`. |
| `@fill` | `boolean` | `false` | Solid background. |
| `@isDisabled` | `boolean` |  | Disables both actions. |
| `@isLoading` | `boolean` |  | Shows a loading spinner in both actions and disables them. |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

| Block | Description |
| --- | --- |
| default block | The two actions, in this order: `<split.ActionPrimary>` then `<split.ActionSecondary>`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiSplitButtonActionPrimary

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@isIconOnly` | `boolean` |  | Renders an `EuiButtonIcon` (pass an `aria-label`). |
| `@iconType` |  |  | Icon; anything `EuiIcon`'s `@type` accepts. |
| `@iconSide` |  |  | `'right'` puts the icon after the text. |
| `@iconSize` |  |  | Size of the icon. |
| `@isDisabled` | `boolean` |  | Disables this action (the split button's `@isDisabled` also does). |
| `@disabled` | `boolean` |  | Same as `@isDisabled`. |
| `@isLoading` | `boolean` |  | Shows a spinner and disables this action. |
| `@isSelected` | `boolean` |  | For toggle buttons: sets `aria-pressed`. |
| `@href` | `string` |  | Renders an `<a>` link. |
| `@target` | `string` |  | `target` of the `@href` link. |
| `@type` | `'button' \| 'submit' \| 'reset'` | `'button'` | `type` of the `<button>`. |
| `@tooltipProps` | `EuiSplitButtonTooltipProps` |  | Wraps the action in an `EuiToolTip` with these arguments. |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). |

| Block | Description |
| --- | --- |
| default block | The button's text. |

### EuiSplitButtonActionSecondary

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@iconType` |  |  | Icon; anything `EuiIcon`'s `@type` accepts. Always `chevronSingleDown` with `@popoverProps`. Pass an `aria-label` describing the action. |
| `@iconSize` |  |  | Size of the icon. |
| `@isDisabled` | `boolean` |  | Disables this action (the split button's `@isDisabled` also does). |
| `@disabled` | `boolean` |  | Same as `@isDisabled`. |
| `@isLoading` | `boolean` |  | Shows a spinner and disables this action. |
| `@isSelected` | `boolean` |  | For toggle buttons: sets `aria-pressed`. |
| `@href` | `string` |  | Renders an `<a>` link. |
| `@target` | `string` |  | `target` of the `@href` link. |
| `@type` | `'button' \| 'submit' \| 'reset'` | `'button'` | `type` of the `<button>`. |
| `@tooltipProps` | `EuiSplitButtonTooltipProps` |  | Wraps the action in an `EuiToolTip` with these arguments. |
| `@popoverProps` | `EuiSplitButtonPopoverProps` |  | Anchors an `EuiPopover` to the action with these arguments (default `anchorPosition`: `'downCenter'`); the block is its content. |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). |

| Block | Description |
| --- | --- |
| default block | The popover content (with `@popoverProps`). |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>` / `<a>`.

</EuiText>
<!-- api:end -->
