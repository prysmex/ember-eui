---
title: Key pad menu
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Key pad menu"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiKeyPadMenu` is a grid of large square buttons with an icon and a
label, e.g. an app switcher in a header popover. Wrap each
`EuiKeyPadMenuItem` in the yielded `Key` (a list item).

```hbs
<EuiKeyPadMenu as |Key|>
  <Key>
    <EuiKeyPadMenuItem @label="Discover" @href="/discover">
      <EuiIcon @type="discoverApp" @size="l" />
    </EuiKeyPadMenuItem>
  </Key>
</EuiKeyPadMenu>
```

Items can also be checkable (radios or checkboxes) inside a menu with
`@checkable`, and show a beta badge.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiKeyPadMenu

A grid of large square buttons (`EuiKeyPadMenuItem`s), e.g. an app
switcher in a header popover.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@checkable` |  |  | Makes the menu a `<fieldset>` of radios or checkboxes (items with `@checkable`): `true`, or `{ legend }` for a visible legend and/or `{ ariaLegend }` for an `aria-label`. |

Deprecated: `@iconType` (Has no effect.).

| Block | Description |
| --- | --- |
| default block | The items. Wrap each in the yielded `<Key>` (an `<li>`), except for checkable menus: `as \|Key\|` → `<Key><EuiKeyPadMenuItem …/></Key>`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<ul>` / `<fieldset>`.

### EuiKeyPadMenuItem

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@checkable` | `'single' \| 'multi' \| 'label'` |  | Makes the item a `<label>` with a checkbox (`'multi'`, or the legacy `'label'`) or a radio (`'single'`, share a `@name`) inside a checkable EuiKeyPadMenu. |
| `@href` | `string` |  | Makes the item a link. A `javascript:` URL disables the item. |
| `@isDisabled` | `boolean` |  | Disables the item. |
| `@isSelected` | `boolean` |  | Selected state: `aria-pressed` on buttons (omitted when not set), `aria-current` on links, `checked` on checkable items. |
| `@label` | `string` |  | Text under the icon. |
| `@name` | `string` |  | `name` of the radio or checkbox. |
| `@value` | `string` |  | `value` of the radio. |
| `@onChange` | `(id: string, value?: string \| Event) => void` |  | Called when a checkable item changes, with its id (and value for radios). Buttons use `{{on "click" …}}`. |
| `@betaBadgeLabel` | `string` |  | Shows a beta badge with the first letter of this label (full label on hover). |
| `@betaBadgeIconType` |  |  | Icon in the beta badge instead of the letter. |
| `@betaBadgeTooltipContent` | `string` |  | Tooltip of the beta badge. |
| `@id` | `string` | a random id | Id of the checkable input. |
| `@target` | `string` |  | `target` of the `@href` link. |
| `@rel` | `string` |  | `rel` of the link; `noreferrer` (and `noopener` for `_blank`) is added. |

| Block | Description |
| --- | --- |
| default block | The icon, e.g. `<EuiIcon @type="discoverApp" @size="l" />`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>` / `<a>` / `<label>`.

</EuiText>
<!-- api:end -->
