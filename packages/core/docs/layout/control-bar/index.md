---
title: Control bar
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Control bar"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiControlBar` is a dark bar of controls at the bottom of the window or
of a container, like an editor's toolbar or a console: breadcrumbs, text,
buttons, icons and tabs. Tabs usually open a content area above the bar
(`@showContent`, with the content in the block).

```hbs
<EuiControlBar @controls={{this.controls}} @showContent={{this.isOpen}}>
  <pre>{{this.output}}</pre>
</EuiControlBar>
```

Each control is an object with a `controlType`: `'button'`, `'icon'`
(a button with `onClick` or `href`, else a plain icon), `'tab'`,
`'text'`, `'breadcrumbs'`, `'divider'` or `'spacer'` (pushes the
following controls to the right).

By default the bar is fixed to the bottom of the window (rendered at the
end of `<body>`, which gets a bottom padding so nothing is hidden under
it). `@position="absolute"` or `"relative"` keeps it inside a positioned
container. `@leftOffset` / `@rightOffset` leave room for side panels.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiControlBar

A dark bar of controls at the bottom of the page (or of a container),
e.g. an editor's toolbar or a code console: buttons, icons, text,
breadcrumbs and tabs that open a content area above it.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@controls` (required) | `EuiControlBarControl[]` |  | The controls, from left to right. |
| `@showContent` | `boolean` |  | Shows the content (the default block) above the controls. |
| `@size` | `'s' \| 'm' \| 'l'` | `'l'` | Height of the content area: `'s'`, `'m'` or `'l'`. |
| `@position` | `'fixed' \| 'absolute' \| 'relative'` | `'fixed'` | `'fixed'` (bottom of the window, rendered at the end of `<body>`), `'absolute'` or `'relative'` (inside a positioned container). |
| `@leftOffset` | `number \| string` | `0` | Space on the left, e.g. for a side navigation. |
| `@rightOffset` | `number \| string` | `0` | Space on the right. |
| `@maxHeight` | `number \| string` |  | Maximum height of the bar with its content. |
| `@showOnMobile` | `boolean` |  | Keeps the bar on small screens (hidden there by default). |
| `@bodyClassName` | `string` |  | Class added to `<body>` while a fixed bar is shown. |
| `@landmarkHeading` | `string` | "Page level controls" | Accessible name of the bar's region. |

| Block | Description |
| --- | --- |
| default block | Content shown above the controls while `@showContent`. |

</EuiText>
<!-- api:end -->
