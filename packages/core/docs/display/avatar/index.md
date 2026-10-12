---
title: Avatar
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Avatar"/>
<EuiHorizontalRule />
<EuiText>

  <p>

The <strong>EuiAvatar</strong> component typically creates a user icon. It will accept <EuiCode>@name</EuiCode> (required) and <EuiCode>image</EuiCode> arguments and will configure the display and accessibility as needed. By default, the background colors come from the set of colors used for visualizations. Otherwise you can pass a hex value to the <EuiCode>@color</EuiCode> argument.

  </p>
</EuiText>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiAvatar

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@name` | `string` |  | Full name of the user or space. Used as the accessible label and the hover title, for the initials and to pick a background color. |
| `@color` | `string \| null` | one of the theme's visualization colors, picked from `@name`; the text color is chosen for contrast | Background color as a hex value (`'#DA8B45'`), `'plain'` (the page's background color), `'subdued'` (a light gray), or `null` (the default gray). |
| `@iconColor` | `string \| null` | the text color picked for the background; `null` keeps the icon's own colors (for multi-color logos) | Color of the `@iconType` icon, any `EuiIcon` color. |
| `@iconSize` |  | `@size` | Size of the `@iconType` icon. |
| `@iconType` |  |  | Shows an icon instead of initials, e.g. `'logoElastic'` for a space. Anything `EuiIcon`'s `@type` accepts. |
| `@imageUrl` | `string` |  | Image shown as the avatar (as a background image), instead of initials. |
| `@initials` | `string` |  | Custom initials (max 2 characters) instead of the ones computed from `@name`. |
| `@isDisabled` | `boolean` |  | Greys the avatar out and hides it from assistive technology. |
| `@size` | `EuiAvatarSize` |  | `'s'` (24px), `'m'` (32px), `'l'` (40px) or `'xl'` (64px). Defaults to `'m'`. |
| `@type` | `EuiAvatarType` | `'user'` | `'user'` renders a circle, `'space'` a rounded square. |
| `@casing` | `EuiAvatarCasing` | `'uppercase'` for users and `'none'` for spaces | Text transform of the initials: `'capitalize'`, `'uppercase'`, `'lowercase'` or `'none'`. |
| `@initialsLength` | `1 \| 2` | the number of words in the name, up to 2 | Number of initials to compute from `@name`, `1` or `2`. |
| `@initialLength` | `1 \| 2` |  | Same as `@initialsLength` (the former name). |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
