<EuiSpacer/>
<EuiPageHeader @pageTitle="Portal"/>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiPortal

Renders its content at the end of `<body>` (or next to `@insert`'s
element), e.g. for overlays that must escape `overflow: hidden`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@insert` |  |  | Renders the portal next to an element instead of at the end of `<body>`: `{ sibling: element, position: 'before' \| 'after' }`. |
| `@portalRef` | `(ref: HTMLElement) => void` |  | Called with the portal's element. |

| Block | Description |
| --- | --- |
| default block | The content to move. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
