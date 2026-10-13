# Display gaps handoff (branch `eui-wave/gaps-display`)

Closes the display rows of [docs-audit-gaps.md](docs-audit-gaps.md) against EUI 123.1.0.
Every gap was checked against the upstream source first; all of them exist there.

## Shared helpers (new, private)

- `src/-private/eui-render-node.gts`: Ember's stand-in for a React node passed as a prop.
  `EuiRenderNode` = text or a component (template-only component, class, or `(component …)`).
  The `<EuiRenderNode @value=…/>` view renders text as is and invokes a component.
- `src/-private/eui-maybe-tool-tip.gts`: wraps its block in `EuiToolTip` when given upstream-style
  `tooltipProps` (an object of `EuiToolTip` args). Used by `EuiListGroupItem` and `EuiCallOut`.

## What was closed

| Component | Change |
| --- | --- |
| EuiListGroup | `@listItems` (objects of item args, replaces the block when non-empty, as upstream), `@showToolTips`. |
| EuiListGroupItem | `@showToolTip`, `@toolTipText`, `@toolTipProps` (right position, label as content, `euiListGroupItemTooltipStyles`, disabled cursor, no native `title` while a tooltip shows, as upstream). Group context carries `showToolTips`. |
| EuiImage | `<:caption>` block for rich captions (figure `aria-label` is the caption's text through `EuiInnerText`, also in full screen); `@width` on the image(s); `@wrapperProps` (`className`, `css`, `style`, `id`, `role`, `aria-label`, `data-test-subj`). |
| EuiCommentList | `@comments` array (`username`, `event`, `timestamp`, `actions`, `body` for upstream's `children`, `timelineIcon` string or component, avatar label, event color/icon). Rendered before the block, as upstream. `aria-label` already worked through `...attributes` (test added). `EuiCommentItem` is now exported from `eui-comment.gts`. |
| EuiCallOut | `@actionProps.primary/secondary`: small `EuiButton`/`EuiButtonEmpty` in the callout color, `euiCallOutAction` class, `onClick`, `href`, `target`, `rel`, `iconType`, `isDisabled`, `isLoading`, `tooltipProps`. Rendered before the `<:actions>` block. |
| EuiCard | `betaBadgeProps` `color`, `href`, `target`, `rel`, `onClick`, `onClickAriaLabel`, `iconType`, `size`, `alignment`, `css` (explicit color wins; a disabled card greys only plain badges); `@hasBorder`; `@image` as a component. |
| EuiTimeline | `@items[].children` is text or a component; `icon` is an icon type or a component; `content` still works (children win). |
| EuiTourStep | `@anchor` (selector, element or function; uses `EuiWrappingPopover`, found on the next tick as upstream), `@zIndex`, `@footerAction` (component or array of components; the block wins). `EuiWrappingPopover` got an `arrowChildren` block pass-through (additive) for the beacon. `useEuiTour` not added: `EuiTour` already yields the same state and actions. |
| EuiToolTip | `@repositionOnScroll` (capture scroll listener, added and removed with the arg). |
| EuiTextDiff | `@timeout` (seconds, default 0.1, `0` = none), `@insertComponent`, `@deleteComponent`, plus upstream's `@sameComponent` (tag name or component). |
| EuiToast / toaster | `body` can be a component (markdown still needs text). |
| EuiTreeView | `icon`, `iconWhenExpanded` accept a component (e.g. an `EuiToken`) next to icon type strings. |
| EuiCodeBlock | `lineNumbers.annotations` values are text or components. `utils/code/utils.ts` annotation types widened to `unknown`. |

## Ember choices

- React nodes become either a named block (`EuiImage` `<:caption>`) where a block is natural, or a
  text-or-component value where the data is passed as an object (`@comments`, `@items`, toaster,
  tree nodes, annotations, card `image`). A component with arguments is `(component Foo a=1)`; in a
  gjs demo a small factory (`const tokenIcon = (token) => <template>…</template>`) works.
- `EuiImage` `...attributes` still land on the `<figure>`, not on the `<img>` as upstream; this was
  not changed to keep existing callers working. `@wrapperProps` and `@width` cover the gap.

## Behaviour changes (upstream-faithful)

- EuiToolTip no longer repositions on scroll by default. `EuiTooltipPopover` listened to scroll
  always; upstream listens to resize only and exposes `repositionOnScroll` (default `false`).
  Opt in with `@repositionOnScroll={{true}}` for fixed anchors or scrollable containers.
  No existing test asserted the old behaviour.
- EuiListGroupItem with a tooltip drops its native `title` (upstream `shouldRenderTitle`).
- `EuiTimelineItemData.content` became optional (type only).

No existing test assertion was changed.

## Skipped / not done

- `EuiCallOut` action `popoverProps` (upstream `withEuiPopover`) not ported.
- `EuiCard` `betaBadgeProps.anchorProps` / generic HTML attributes not ported (only the listed props).
- `EuiImage` rest props to the `<img>` (see above).
- `EuiTreeView` `icon` as a component only: no `<:icon>` block (a block cannot be keyed per node).

## Docs

Demos re-added or adapted: list group (listItems, tooltips), image (rich caption, width), comment list
(`@comments`), callout actions, card (image element, beta badge variants, bordered), timeline (items
with children), tour (anchor, zIndex), tooltip (fixed element), text diff (custom elements), toast
(rich bodies), tree view (tokens as icons), code block (rich annotation). API tables regenerated;
closed rows removed from docs-audit-gaps.md.

## Checks


- `ember-tsc --noEmit`: clean. `eslint` on all changed files: clean.
- Core suite: 1696/1696 (main was 1658; 38 new tests). Filtered family run: 72/72.
- Generator / parity: no style entries added, untouched. No new public components, so no rollup `package.json` change.
