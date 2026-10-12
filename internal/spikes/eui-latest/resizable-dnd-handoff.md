# Resizable container + drag and drop migration handoff

Status: **In progress (ready for merge)**. The family's own tests all pass. The full core suite in this worktree is 852/853. The one failure is outside this family and fails the same way on the untouched base commit `9e3d1e09`; see Unresolved 1. Rows stay `In progress` until the coordinator confirms a fully green suite after the merge.

## Files

- Components:
  - `packages/core/src/components/eui-resizable-container.gts`
  - `eui-resizable-container/button.gts`
  - `eui-resizable-container/panel.gts`
  - `eui-resizable-container/collapse-button.gts` (now a class with an `@cached` `css` getter)
  - `eui-draggable.gts`
  - `eui-droppable.gts`
  - `eui-drag-drop-context.gts` is unchanged: it has no styles upstream and its behavior is kept.
- `packages/core/src/-private/resizable.ts`:
  - The unused `PANEL_PADDING` table is removed. Minimum padding now comes from the theme via `euiPaddingSize`.
  - The collapsed-panel lookup uses `[data-collapsed]` instead of the removed class.
- Generator: a `// resizable-dnd` block in `scripts/generate-eui-styles.mjs` with these entries:
  - `euiResizableContainerStyles`
  - `euiResizableButtonStyles`
  - `euiResizableCollapseButtonStyles`
  - `euiResizablePanelStyles`
  - `euiResizablePanelContentStyles`
  - `euiDraggableStyles`
  - `euiDraggableItemStyles`
  - `euiDroppableStyles`
- Regenerated files: `styles.generated.ts` and `upstream-sources.json`. 206 factories in total.
- Parity (`scripts/eui-upstream-parity.test.mjs`):
  - The six function factories are in `factories`, checked in 12 theme configurations.
  - A new `deepEqual` test covers the static container and panel objects.
- Tests:
  - New: `packages/core/tests/integration/components/eui-resizable-dnd-test.gts`, with 13 tests.
  - Updated: `eui-resizable-container-test.gts` and `eui-drag-drop-test.gts` (see below).
- Docs: only the generated API sections changed, in `docs/layout/resizable-container/index.md` and `docs/layout/drag-and-drop/index.md`.
- API docs for four files outside this family were already stale on the base and are left untouched: icons, list-group, panel and button.

## API and default changes

### Resizable container

- **Container**
  - Uses the upstream `display:flex; width:100%`, with `flex-direction: column` when vertical.
  - New `@onResizeStart(trigger: 'pointer' | 'key')` and `@onResizeEnd()`, as upstream:
    - A key resize starts on the first non-repeat arrow keydown.
    - It ends on keyup of that arrow or on blur.
    - A pointer resize ends on mouseup, or on mouseleave (Ember's existing engine).
- **Button**
  - Upstream styles: 16px wide, with a `-8px` margin on each side, so it takes no room.
  - Grab handle: two 1px × 12px lines in `darkestShade`. They grow into one primary line on hover and focus, over a 10% primary background on focus.
  - New args:
    - `@indicator`: `'handle'` (default) or `'border'`.
    - `@alignIndicator`: `center`, `start` or `end`.
    - `@accountForScrollbars`: `before`, `after` or `both`.
  - **Disabled resizers are hidden** (`display:none`), as upstream. This includes the resizer next to a collapsed panel.
  - **aria-label defaults now use upstream text:** "Press the left or right arrow keys to adjust panels size" and "Press the up or down arrow keys…". The i18n tokens are unchanged.
- **Panel**
  - Wrapper: upstream `position: relative`. When collapsed it gets `overflow: hidden`. `@wrapperPadding` is a real theme padding.
  - Content `EuiPanel` gets the upstream content styles through `@css`: height 100%, the scrollbar mixin plus `overflow-y: auto` when scrollable, hidden children when collapsed, and a `min-width`/`min-height` of `size.l` for collapsible panels. In high contrast it has no border.
  - **New `@hasBorder`, default `false` (upstream).** The migrated `EuiPanel` defaults to `true`, so without this argument resizable panels would have gained a border.
  - `@hasShadow` only shows with `@color="plain"`, per `EuiPanel`'s rules.
  - **Legacy classes removed:** `euiResizablePanel--first/middle/last/collapsible/padding*` and `euiResizablePanel-isCollapsed`. They are replaced by upstream's `data-position` and `data-collapsed="true"` attributes. The `euiResizablePanel` and `euiResizablePanel__content` classes are kept.
- **Collapse button**
  - The root class is now upstream's `euiResizableCollapseButton`. It was `euiResizableToggleButton` with `--*` modifiers.
  - It is now an empty text `EuiButtonIcon` in every state. It used to be fill/ghost while open.
  - While open, it uses the `emptyShade` surface with an xs shadow and straddles the panel edge (logical inset and margin, so it flips in RTL). It is screen-reader-only until its resizer or the button itself has focus.
  - When collapsed it fills the whole collapsed area, with radius 0 and full height.
  - Icons are still the `menu*` arrows: upstream's `transition{Left,Right,Top,Bottom}{In,Out}` icons are not in the Ember icon set yet (see Unresolved 3).

### Drag and drop

- **Droppable**
  - Upstream styles:
    - Background transition over `animation.slow`.
    - `dragDropDraggingBackground` while an item of its type is dragged and drops are enabled.
    - `dragDropDraggingOverBackground` while hovered.
    - `grow`/`noGrow`, and spacing s/m/l = 2/4/8px.
  - **`@withPanel` now renders a real `EuiPanel`** (shadow, `@hasBorder={{false}}`, `paddingSize="none"`, droppable styles via `@css`). It used to be a class on a div.
  - **Legacy classes removed:** `euiDroppable--*` and `--isDragging*`. Upstream's `euiDroppable-isDisabled` is kept.
- **Draggable**
  - Upstream styles:
    - Focus outline moves to the item.
    - `z-index: levels.toast` while dragging.
    - Clone sources get `transform: none !important`.
    - `@isRemovable` makes transitions near-instant.
    - Spacing matches the droppable's.
    - The item gets shadow m while dragging, and `cursor: not-allowed` when disabled.
  - **Legacy classes removed:** `euiDraggable--*` and `euiDraggable__item--*`. The disabled item class is now upstream's `euiDraggable__item-isDisabled`.
  - The dragging state is exposed through `aria-pressed`.
- **New draggable args (upstream semantics)**
  - `@hasInteractiveChildren`: the wrapper becomes `role="group"` and is not focusable.
  - `@customDragHandle="custom"`:
    - The wrapper has no role and no tabindex.
    - The `dragHandle` modifier makes the handle a `role="button"` with `tabindex="0"`, unless the caller set them.
    - It lifts the item with the keyboard.
  - `aria-pressed` is only set on the `role="button"` wrapper. `aria-roledescription` is only set when there is a role.
- **Behavior fix:** a key pressed in an interactive descendant (input, button, link, select, contenteditable, …) no longer lifts the item. The custom handle is the exception. This mirrors react-beautiful-dnd's interactive-element blocking.
- **Kept:** the pragmatic-dnd engine, keyboard lifting/moving/dropping, auto scroll, the item wrapper `div.euiDraggable__item`, `data-test-subj`, and all events and results.

### Audited and not added

- **`aria-valuenow` / `aria-controls`:** upstream's resize button is a plain `<button>` with only an `aria-label`, so none were added.
- **`usePortal`:** not applicable, because the pointer ghost is the native drag image.

## Existing tests updated

- **`eui-resizable-container-test.gts`**
  - Each removed modifier-class assertion is now a semantic or computed check:
    - `--horizontal` and `--vertical` → computed `flex-direction` and `cursor`.
    - `--first` and `--last` → `data-position`.
    - `-isCollapsed` → `data-collapsed`.
    - `euiResizableToggleButton--after` → `.euiResizableCollapseButton` is the panel's last child.
  - The aria-label strings follow the upstream defaults.
- **`eui-drag-drop-test.gts`**
  - Each removed class is now a computed or aria check:
    - Spacing m/s → padding 4px/2px.
    - `withPanel` → `data-eui-panel`.
    - `noGrow` → `flex-grow: 0`.
    - `--isDragging` → `aria-pressed`.
    - `--isDraggingType` and `--isDraggingOver` → a non-transparent list background.
  - The disabled item class is renamed to upstream's.
  - Two 450ms waits were added before the background checks, because the upstream background transitions over 350ms.
  - Nothing else was weakened.

## New test coverage (`eui-resizable-dnd-test.gts`)

- **Layout**
  - Horizontal: measured 30/70 widths; the button takes no room and is centered on the edge; button size, margins, z-index and reset; handle pseudo-element size and color; attributes.
  - Vertical: stacked heights and button/handle geometry; ArrowDown resizes and horizontal arrows are ignored.
- **Button options:** `@indicator`, `@alignIndicator` and `@accountForScrollbars` update reactively on the same element.
- **Panel options:**
  - Every `paddingSize` and `wrapperPadding`, scrollable on and off, `hasBorder` (via `::after`), shadow, color and radius.
  - The same elements are kept across changes.
- **Keyboard and callbacks**
  - Focus background and line, ±10px per key, held-key repeat, never below `minSize`.
  - Start and end callbacks for key, blur and pointer; sizes reported in percent.
- **Collapse buttons**
  - Placement after and before; screen-reader-only until shown; surface, shadow and centering offsets; position `top`.
  - Collapsing: 24px, a hidden disabled resizer, a full-height button, no padding. Expanding restores the size.
  - Vertical before/middle offsets.
- **Themes and directions**
  - Light/dark follow the nearest provider, with the same element; sibling isolation.
  - JS-object overrides: `size.base` and mode-specific `colors.*.darkestShade`.
  - RTL placement.
  - High contrast: preferred removes the content border, uses a thick primary focus line and no focus background; forced uses the `border.color` line and `forced-color-adjust: none`.
- **Drag and drop**
  - Spacing none/s/m/l on both components, reactive and on the same elements; `grow`; `withPanel` as a real panel (plain, shadowed, borderless, spacing beats panel padding, panel radius).
  - States during a keyboard drag: over, same-type, other-type and drop-disabled backgrounds; dragged z-index and shadow; disabled cursor; `isRemovable` transition; all states cleared on cancel.
  - Focus outline moves to the item.
  - Roles for button, group (with interactive children) and fully custom handles; keys typed in an input don't lift the item; the handle lifts it.
  - Dark versus light sibling tokens; a `size.xs` override.

## Checks (2026-10-12, this worktree)

Environment: Node 22, binaries run directly, Chromium 130 with `CI=true`.

| Check | Result |
| --- | --- |
| `ember-tsc --noEmit` | pass |
| ESLint, changed components and tests | pass |
| `node scripts/generate-eui-styles.mjs --check` | pass |
| `node --test scripts/eui-upstream-parity.test.mjs` | **177/177** |
| `node scripts/generate-api-docs.mjs` | only this family's two docs regenerated; four unrelated docs were already stale on base and are left alone |
| Filtered `resiz` | **21/21**, run twice |
| Filtered `drag` | **16/16** |
| Full core suite | **853 tests, 852 pass, 1 fail**, see Unresolved 1 |

## Unresolved

1. **Pre-existing failure, outside this family.** `Borealis header family: EuiCollapsibleNav: overlay vs docked…` gets z-index 1000 where 6000 (`levels.navigation`) is expected.
   - It fails the same way when this branch's `src` and `tests` changes are temporarily reverted to base `9e3d1e09`.
   - It looks like a header × modal-flyout merge interaction, and none of those files import this family. Coordinator to fix.
2. **Client-rect units.** The resize engine measures in client-rect pixels: `getBoundingClientRect` for both panels and container. This is unchanged.
   - Under a CSS transform, such as the scaled test container, keyboard steps and the 24px collapsed size are screen pixels, not CSS pixels. The tests measure in the same unit.
   - Upstream mixes the two units: ResizeObserver CSS px for the container and client rects for the panels.
3. **Icons.** Upstream collapse icons `transition{Left,Right,Top,Bottom}{In,Out}` are missing from the Ember icon map (`utils/css-mappings/eui-icon.ts`); the icon family owns it. Swap them in `collapse-button.gts` once they're available.
4. **Hover states** (handle → line, `mediumShade` on hover) are only verified at the CSS level, through the factory and parity tests. A browser check needs trusted pointer hover.
5. **No `@css` on the yielded `Panel`.** The content panel already forwards `...attributes`. Add `@css` passthrough if callers need it.

## Next step

Coordinator: merge, regenerate in the main checkout and run parity, fix the header/collapsible-nav z-index failure, and run the full core suite. If it is green, mark the seven rows `Migrated`. Then do a visual pass of the resizable container and drag-and-drop docs demos.
