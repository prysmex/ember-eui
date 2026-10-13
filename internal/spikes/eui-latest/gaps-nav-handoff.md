# Navigation and layout gaps handoff

Branch `eui-wave/gaps-nav`. Rows closed in `docs-audit-gaps.md` (removed there).

## Closed

| Component | Added | Ember form |
| --- | --- | --- |
| EuiButton | `@minWidth` | number (px) or CSS length, set inline as `min-inline-size` (upstream `style.minInlineSize`; no default minimum, as upstream) |
| EuiContextMenu | `@height` | fixed height, list scrolls (`fixedHeight` upstream style) |
| EuiContextMenu items | `renderItem` | a component rendered in place of an item (upstream: a function returning a node) |
| | `toolTipProps` | `EuiToolTip` args except `content`; `position` stays `right` (upstream spreads `position: 'right'` after the props); `toolTipTitle` still works, `toolTipProps.title` wins |
| | separator props | `margin` (default `xs`), `size`, `css`, `className`, other keys become attributes |
| | `icon` as element | a non-string `icon` is a component rendered as is, with `euiContextMenu__icon` + the icon styles as `class` (upstream clones `css` onto the element) |
| EuiCollapsibleNavGroup | `@arrowDisplay`, `@paddingSize`, `@buttonElement`, `@onToggle`, `<:extraAction as |isOpen|>` | passed to `EuiAccordion` (extraAction is a block, as the accordion's own API) |
| EuiSideNav items | `isOpen` | overrides the computed open state of that item (upstream: item props spread after `isOpen`) |
| | `icon` as node | a non-string `icon` is a component rendered as is |
| | `renderItem` (item) and `@renderItem` (nav) | component receiving `@href @target @rel @onClick @disabled` + `class`, content in its block; the item's wins |
| EuiSteps | `@firstStepNumber`, `@titleSize`, `@headingElement`, auto-numbering | EuiSteps provides a context; a step without `@step` counts its preceding sibling `.euiStep`s (DOM position, kept current with a MutationObserver) |
| EuiTabbedContent | tab `prepend`, `append`, `href`/`target`/`rel`, `className`, non-string `name` | string or component (new private `EuiNode`); `EuiTab` also got `@prepend` / `@append` |
| EuiPageHeader | `tabsProps`; `breadcrumbProps`, `rightSideGroupProps`, `pageTitleProps`, `iconProps` | each takes `className`, the target component's args and any other key as an attribute (new private modifier `eui-spread-attributes`) |
| EuiPage | `@css` | |
| EuiFlexGroup | any `@tagName` | via `element` |
| EuiFlexGrid | `@css` | |
| EuiHeader | `sections[].items` as strings, components or `{ text }` (kept); `<:sectionItem as |item index|>` block for markup; `sections[].breadcrumbProps` | |

## Skipped (verified against upstream 123.1.0)

- `component` on EuiPage and EuiPageSidebar: neither exists upstream (both hard-code a `div`).
- `height` on a standalone EuiContextMenuPanel: the docs sentence says it works, but the source only forwards it to the `div` as an attribute. Only `EuiContextMenu.height` does anything.

## Behaviour changes (no existing test changed)

- `EuiStep` inside `EuiSteps` without `@step` is now numbered by position (was always `1`). Outside `EuiSteps`, still `1`.
- A non-string `@icon` of `EuiContextMenuItem` is rendered as a component instead of being handed to `EuiIcon` as an SVG component type.

## Files

New: `-private/eui-node.gts`, `-private/eui-spread-attributes.ts`, `-private/eui-steps-context.ts`, `tests/integration/components/eui-gaps-nav-layout-test.gts`, docs `context-menu/demo/d06-scrollable-panel.md`, `side-nav-demo/demo7.md`.
Docs demos adapted: steps 1/4/6, tabs 4/5 (icon-prefixed Hydrogen tab), collapsible-nav demo3 (`extraAction`, `arrowDisplay`), context-menu d01/d04, side-nav demo5, header d02, flex d18, page-header d04, button d01. API tables regenerated.

For the coordinator: `-private/eui-node.gts` and `-private/eui-spread-attributes.ts` are generic; other waves may want them for their `*Props` / node-valued data args.

## Counts

Full core suite: 1669/1669 (1658 + 11 new in `eui-gaps-nav-layout-test.gts`). `ember-tsc`, eslint, `eui-upstream-parity` (353) clean. `styles.generated.ts` unchanged (no style added).
