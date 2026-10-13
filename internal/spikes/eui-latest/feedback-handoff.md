# Feedback family migration handoff (Accordion, Toast, GlobalToastList, Comment*, NotificationEvent*)

Branch `eui-wave/feedback`. Target EUI 123.1.0 / Borealis 8.1.0.

Status: **In progress**, ported and tested. All family tests pass. The full core suite does not pass yet: it has two failures that predate this branch (see Checks), so the rows are not marked Migrated. Once those two content-blocks assertions are fixed on the base, the rows can be flipped to Migrated without further changes.

## Files

- Components (all in `packages/core/src/components/`):
  - `eui-accordion.gts`, `eui-toast.gts` and `eui-global-toast-list.gts`.
  - `eui-comment.gts`, `eui-comment-list.gts` and `eui-comment-timeline.gts`.
  - `eui-notification-event.gts` and `-messages`, `-meta`, `-read-button`, `-read-icon`.
  - All are Glimmer classes with `@cached` class getters, except `eui-comment-timeline.gts` and the thin `EuiComment` wrapper, which stay template-only and compute no styles.
  - Factories are read only through `useEuiBorealisStyles`. Theme-less timeline factories are hoisted to module scope.
- `packages/core/src/utils/eui/notification-event.ts` (new): Borealis-token styles for the notification event. Upstream 123 has no `EuiNotificationEvent`; it was removed upstream, so there is nothing to extract (see Unresolved).
- `scripts/generate-eui-styles.mjs`: new `// feedback` block with 16 entries. Regenerated `styles.generated.ts` and `upstream-sources.json`. The worktree path comments were normalized to `node_modules/…`, and a regenerate+normalize is byte-identical.
  - `euiAccordionStyles`, `euiAccordionChildrenStyles`, `euiAccordionChildWrapperStyles`, `euiAccordionArrowStyles`, `euiAccordionButtonStyles`
  - `euiToastStyles`, `euiToastHeaderStyles`, `euiGlobalToastListStyles`, `euiGlobalToastListItemStyles`
  - `euiNotificationIconStyles`
  - `euiCommentEventStyles`, `euiCommentEventHeaderStyles`, `euiCommentEventBodyStyles`
  - `euiTimelineStyles`, `euiTimelineItemStyles`, `euiTimelineItemEventStyles`, `euiTimelineItemIconStyles`
- `scripts/eui-upstream-parity.test.mjs`: the same 16 factories were added to the `factories` map, so each runs through the 12-configuration matrix.
- Tests: new `packages/core/tests/integration/components/eui-feedback-test.gts`, module `Borealis feedback`, with 16 computed-style and behavior tests. Legacy tests were updated as listed below.
- API docs regenerated for accordion, toast, comment-list and notification-event.
  - `--check` also lists `icons`, `panel` and `button`. Those pages are stale on the base (from the `@css` commit) and were left untouched because they are outside this family.

## API and default changes (latest-only)

### EuiAccordion

- **Content region role.** It is now `role="group"`, the upstream default; it was `region`. A new `@role` argument overrides it.
- **Closed and open state.**
  - When closed, the region is `inert` and has an inline `block-size: 0px`.
  - When open, its height is the measured content height (offsetHeight via ResizeObserver, so CSS transforms don't distort it). The inline property was `height`.
  - The height and opacity transition only runs under `prefers-reduced-motion: no-preference`.
  - An initially open accordion has no transition until its first close, as upstream.
- **Focus.** The region is no longer focused when the accordion opens, and its `tabindex="-1"` is gone. This matches upstream 123.
- **Arrow.**
  - The class is now `euiAccordion__arrow`, the upstream name. The classes `euiAccordion__iconButton*` are removed.
  - It uses `@color="text"` and always gets `aria-hidden`, `aria-labelledby` and `tabindex` as upstream does.
  - Rotation and margins are composed through `EuiButtonIcon @css`.
  - The icon is `arrowRight`, because upstream's `chevronSingleRight` is not in Ember's icon set.
  - `@arrowProps.css` is new.
- **New arguments:**
  - `@borders`: `none`, `horizontal` or `all`. Adjacent bordered accordions share one border.
  - `@isDisabled`
  - `@buttonProps.paddingSize`, `@buttonProps.css` and `@buttonProps.data-test-subj`
- **Trigger.**
  - `@buttonElement` works now; it used to be a deprecated no-op. With `"div"`, the arrow becomes the focusable control, as in the docs demo d09.
  - `@buttonContent` (a string) is rendered when there is no `<:buttonContent>` block.
- **Loading.** The default loading message is now "Loading", from the i18n token `euiAccordionChildrenLoading.message`. It used to be "Loading...". The message is rendered in an EuiText `s`.
- **Removed:**
  - The legacy padding wrapper div and the `euiAccordion--padding*` classes. Upstream padding is applied on `.euiAccordion__children`.

### EuiToast

- **Default color.** It is now `primary` (upstream); it was `none`. `@color="none"` is kept as an Ember-only neutral toast with a transparent highlight and no default icon.
- **Default icon.** Without `@iconType`, a default notification icon matching the color is always shown, using the same glyph mapping as EuiCallOut. A custom `@iconType` gets the `borderStrong<Color>` color.
  - Upstream's 20px notification icon size is applied via `@css`. Tests don't assert icon pixel sizes.
- **Structure follows upstream:**
  - A decor element (`.euiToastDecor`) draws the highlight.
  - The title is a `p.euiTitle.euiToastHeader__title` with `data-test-subj="euiToastHeader__title"`. The `.euiToastHeader` wrapper and `--withBody` are removed.
  - The body is `.euiToast__text` inside `[data-test-subj=euiToastBody]`.
  - The dismiss button is an `EuiButtonIcon` with `data-test-subj="toastCloseButton"` and `aria-label` from `euiToast.dismissToast`. The class `.euiToast__closeButton` is removed.
  - DOM order is title, dismiss button, then body, as upstream.
- **New arguments:**
  - `@actionProps`: `{ primary, secondary }`, each `{ children, onClick, href, data-test-subj }`. Primary renders an EuiButton, secondary an EuiButtonEmpty.
  - `@animationMs`: the countdown animation, behind euiCanAnimate.
  - `@css`
  - A default block, rendered as `.euiToast__additionalContent`.
- **CSS variables.** They are set through a class, not inline `style`, so the caller's `style` attribute is kept.

### EuiGlobalToastList

- **Role.** It is now `role="log"` (upstream); it was `region`. The inline `padding:0px` style is gone: the list renders no whitespace when empty, so upstream's `:not(:empty)` rules apply.
- **Item styles.** These include the show animation and the dismissed fade. They are composed into each toast via EuiToast `@css`.
- **New arguments:**
  - `@showClearAllButtonAt`, default 3. This is a **visible default change**: three or more toasts now show a "Clear all" button.
  - `@onClearAllToasts`
  - `@showNotificationBadge`, which positions the badge through a wrapper.
- **Timer behavior:**
  - Focus inside a toast pauses the timers, using `focusin`/`focusout`. It used to listen for non-bubbling `focus`/`blur`.
  - Hover and focus are tracked separately, so removing a focused toast does not resume timers while the list is hovered.
  - Pause and resume skip timers that are already paused or already running.
  - Toasts present at construction are no longer scheduled twice. Before, the insert hook replaced the first timer without clearing it.
  - Scroll pinning only follows user scrolling, as upstream.
- **Toast lifetime.** Each toast receives `@animationMs`, set to its effective lifetime.

### EuiComment, EuiCommentList and EuiCommentTimeline

- **List markup.** `EuiCommentList` is now an `<ol role="list">` (EuiTimeline) with `@gutterSize` (`m`, `l` or `xl`; default `l`). Its Element type changed from `HTMLDivElement` to `HTMLOListElement`. `EuiComment` is an `<li>`, so its Element type is now `HTMLLIElement`.
- **Comment type.** It is derived from the blocks, as upstream does. `@type` is deprecated and has no effect.
  - **regular** (body plus event elements): a bordered `<figure>` with a `<figcaption>`.
  - **update** (no body): a `div` with a transparent panel.
  - **custom** (only a body): no header.
  - A comment with only a username and no event, timestamp, actions or icon has no header, as upstream.
- **Timeline avatar.** It is a subdued `EuiAvatar.euiCommentAvatar` with the `user` icon, or `@timelineIcon`. The legacy `dot` icon for updates is gone.
- **New arguments:** `@eventColor`, `@eventIcon`, `@eventIconAriaLabel` and `@timelineAvatarAriaLabel`.
- **Removed classes:** `euiComment--update`, `--hasBody`, `euiCommentTimeline*` and `euiCommentEvent--*`. The `data-type` attribute replaces them.

### EuiNotificationEvent family (no upstream counterpart)

- **Styles.** They are written with Borealis tokens and follow the last upstream layout:
  - a flex row with a separator between consecutive events
  - EuiTitle `xs` titles that are bold when unread and regular when read
  - xs subdued time
  - the context menu pinned to the end corner using logical inset
  - the "more messages" accordion button in primary text
  - read indicators drawn as a hollow subdued dot via `@css`
- **Removed modifier classes:** `euiNotificationEvent--withReadState`, `euiNotificationEvent__title--isRead`, `euiNotificationEventReadButton--isRead`, `euiNotificationEventReadIcon--isRead` and `euiNotificationEventMeta--hasContextMenu`.
- **Title markup.** The title heading carries `euiTitle` and the styles. A link title keeps the `euiNotificationEvent__title` class and `id` on the link.
- **Meta.** It has a new `@eventName`, and the menu button gets `aria-label="Menu for <title>"`. It had no accessible name before. The meta signature is renamed to `EuiNotificationEventMetaSignature`, and the old name is kept as a deprecated alias.

## Legacy test assertions changed

- `eui-accordion-test`:
  - Inline `height` → `blockSize`, because upstream uses the logical inline size.
  - `[role="region"]` → `[role="group"]`, the upstream default role.
- `eui-toast-test`:
  - `euiToastHeader--withBody` and `svg.euiToastHeader__icon` → `[data-test-subj=euiToastBody] .euiToast__text` and `svg[data-icon-type=check]`.
  - `.euiToast__closeButton` → `[data-test-subj="toastCloseButton"]`, the upstream test subject.
- `eui-global-toast-list-test`: the close-button selector changed the same way.
- `eui-comment-test`:
  - `euiComment--hasBody` and `--update` → `.euiCommentEvent[data-type]`.
  - `.euiCommentTimeline svg` → `.euiCommentAvatar svg[data-icon-type]`.
- `eui-notification-event-test`:
  - `--withReadState` → the read indicator wrapper exists.
  - `--hasContextMenu` → the menu button exists.
  - Read icon `--isRead` → `title="Read"`.
  - Title `--isRead` → computed `font-weight: 400`.

## Checks (2026-10-12, worktree, Chromium 130, CI=true, binaries run directly)

- `node --test scripts/eui-upstream-parity.test.mjs`: **136/136**, up from 120 before (16 new factory matrices).
- `node scripts/generate-eui-styles.mjs`: extracts 157 factories and helpers.
  - `--check` reports "Stale generated artifact" in the worktree, as expected because of the node_modules symlink paths.
  - A regenerate plus path normalization is byte-identical to the committed files.
- `ember-tsc --noEmit`: pass. ESLint on all changed sources and tests: pass.
- `node scripts/generate-api-docs.mjs --check`: the four family pages are current. It still reports `icons`, `panel` and `button`, which are stale on the base and outside this family.
- Filtered run (family, legacy family tests and collapsible nav, which uses EuiAccordion): **38/38**.
- Full core suite: **717 tests, 714 pass, 3 fail.**
  1. and 2. `Borealis content blocks: empty prompt defaults …` and `… empty prompt colors …` assert `euiIcon--subdued`, a class the migrated EuiIcon no longer emits. These are pre-existing on the base: neither the test, EuiEmptyPrompt nor EuiIcon is touched here, and they fail identically in a filtered rerun.
  3. `eui-table: table pagination` hit a browser timeout. The Chromium log shows an allocation failure (errno 12) while other agents were building. It **passes on rerun** (`eui-table|content blocks` filter: 19/21, with only the two content-blocks failures).
- Not run (coordinator): rollup build, site build/acceptance, showcase.

## Unresolved

1. **Base fix needed (coordinator):** `eui-content-blocks-test.gts` still asserts `euiIcon--subdued` (an icon × content-blocks merge leftover). Fix it, rerun the suite, then flip these rows to Migrated.
2. **NotificationEvent has no upstream source in 123.** Its styles are a token-based reconstruction, not an extraction. Upstream deprecated the component in favor of composing EuiPanel, EuiTitle and EuiContextMenu. Decide whether to keep or deprecate it.
3. **Missing `@css` on migrated children.** Avatar, LoadingSpinner, Title, NotificationBadge and Button lack `@css`, so these pieces use child rules or wrappers instead:
   - comment event-avatar margin: a `> .euiCommentEvent__headerEventIcon` rule
   - accordion loading-spinner margin: a `> .euiAccordion__spinner` rule
   - toast-list badge position: a wrapper span
   - clear-all sticky position: the wrapper item
   - toast and notification titles: built as `euiTitle` elements instead of `<EuiTitle @css>`

   **Suggestion (coordinator):** add `@css` to EuiAvatar, EuiTitle, EuiLoadingSpinner, EuiNotificationBadge and EuiButton.
4. **Icons.** The upstream `chevronSingleRight` (accordion) and notification icons (`infoFill`, `checkCircleFill`, `warningStatic`, `errorFill`) are not in Ember's icon set.
5. **Comment header.** Upstream removes the header panel's contrast border via `& > .euiPanel`. Ember's panel root class differs, so this is done via EuiPanel `@css`.
6. **Toast timers.** `utils/timer.ts` uses Ember `later`, so `settled()` waits for toast lifetimes. Tests hover the list (which pauses the timers) before settling.

## Next step

Coordinator: fix item 1, merge, then regenerate in the main checkout. Then run the full suite and the site build. Flip the rows to Migrated.
