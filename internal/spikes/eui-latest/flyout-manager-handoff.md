# EuiFlyout session management (flyout manager) and flyout menu props

Branch `eui-wave/flyout-manager`, target EUI 123.1.0 / Borealis 8.1.0.
Upstream calls the feature Beta; the docs mark it so.

## API added to `EuiFlyout`

- `@session`: `'start' | 'inherit' | 'never' | undefined`, routed as in
  upstream `flyout.tsx`: `start` makes a main flyout (new session);
  `inherit` with an active session makes a child (standard flyout
  otherwise); unset and nested in another flyout's block while a session is
  active makes a child; anything else is the standard flyout, unchanged
  (all existing flyout tests pass unmodified).
- `@historyKey` (Symbol), `@onActive`, `@hasChildBackground`.
- `@flyoutMenuProps` (title, titleId, iconType, hideTitle, hideCloseButton,
  showBackButton, backButtonProps, historyItems, leading/trailing/custom
  actions, pagination) and `@flyoutMenuDisplayMode` (`auto`/`always`), on
  standard and managed flyouts. The menu replaces the close button and labels
  the flyout (`aria-labelledby` joined with the caller's).
- `@container` (element, getter or selector; `null` = viewport and above
  fixed headers): position/size/min width from the container rect, the mask
  clipped to it, push padding on the container, container width for push
  breakpoints and resize clamping. Nested flyouts inherit the parent's
  container (the "Child flyout inheritance" doc section).
- `@focusTrapProps`: `returnFocus` (`false` or a function returning `false`
  skips returning focus) and `shards`.
- `@onClose(event, { reason })`: `close-button`, `escape`, `outside-click`,
  `navigation-back`, `navigation-cascade` (upstream's second argument).
- `EuiFlyoutMenu` without `@onClose` closes the flyout it is in (upstream
  `EuiFlyoutMenuContext`). The standalone `EuiFlyoutMenu` child keeps working.

## Design

- Store: `services/eui-flyout-manager.ts` (`service:eui-flyout-manager`, now in
  package.json app-js) is upstream's `getFlyoutManagerStore()`: tracked
  `state` replaced on every dispatch through the ported reducer, `historyItems`
  recomputed when sessions change, `CLOSE_SESSION` events, `subscribe`,
  `consumeCloseMeta`, and the bound actions (`setPagination`, `goBack`,
  `goToFlyout`, `closeAllFlyouts`, …). It also runs upstream's
  `useApplyFlyoutLayoutMode` effects (window resize listener only while a
  main flyout is open, container ResizeObserver, `setLayoutMode`,
  `setReferenceWidth`). `-private/eui-flyout-context.ts#euiFlyoutManager`
  registers the service on the owner if the app's resolver lacks it.
- Pure ports under `utils/eui/flyout-manager/`: `const`, `types`, `actions`,
  `reducer` (verbatim + `!` for `noUncheckedIndexedAccess`), `validation`,
  `selectors` (hooks → functions of the state), `layout-mode`
  (`getWidthFromSize`, `getDesiredLayoutMode`), `activity-stage`
  (`getFlyoutActivity`, `getStageTransition`, `getNextStage`), `history`
  (`computeHistoryItems`).
- Nesting: EuiFlyout `@provide`s `EUI_FLYOUT_CONTEXT` (ember-provide-consume-
  context, like the theme); consumers get parent detection, the menu's close
  and the inherited container.
- EuiFlyout stays one component: `level` (`main`/`child`/`null`) is derived
  from args, the parent context and the service's `hasActiveSession`; a route
  change re-renders the flyout (`{{#each}}` keyed on the level), like
  upstream's component switch. Upstream's EuiFlyoutMain/Child/ManagedFlyout
  are getters and modifiers in `eui-flyout.gts`: registration (title from
  `flyoutMenuProps.title`, else `aria-label`, else "Unknown Flyout"),
  removal detection (`onClose` with the stamped reason), `onActive`, width
  reporting, activity stages + `animationend`, `--euiFlyoutMainWidth`,
  managed push padding, size defaults/validation (throws like upstream),
  child position (`right: var(--euiFlyoutMainWidth, Wpx)` / stacked z-index),
  z-index (session `zIndex`, children one below), main border with a child,
  side-by-side child without `role`/`aria-modal` and with the main flyout as a
  focus-trap container, Escape closing the child first.
- Styles: generator entries `euiManagedFlyoutStyles` (stage factory) and
  `euiMainFlyoutStyles`, parity-tested (incl. a `stage()` test over every
  stage/side/level), used via `useEuiBorealisStyles` in `@cached` getters.
- Effects that read manager state use `-private/value-modifier.ts` (re-runs
  only when an argument's value changes) and are applied directly on the
  element (not curried in `{{#let}}`), so a dispatch does not reinstall the
  focus trap or observers. Manager updates from modifiers are deferred to
  `afterRender`; ResizeObserver-driven updates to the next frame
  (`-private/next-frame.ts`, test-waiter aware), like upstream's observer.

## Ember differences

- One owner-scoped service instead of a module singleton (cross-React-root
  sharing is moot); `hasActiveSession` is a tracked flag set only on change.
- A managed flyout of a backgrounded (hidden) session does not close on
  Escape. Upstream's check only looks at the current session's child, so
  Escape closes every open main flyout at once; here only the visible one.
- `session="never"` nested in a managed flyout is a standard flyout (registers
  for z-index). Upstream's `EuiFlyoutIsManagedProvider` wraps the children of
  managed flyouts, so such a nested flyout is treated as "in a managed
  context" (no unmanaged registration, session z-index).
- Several flyouts sharing a container: the service reference-counts it
  (`useContainer`); upstream's last cleanup can clear a container another
  flyout still uses.
- The session title from `aria-label` is read from the element when the
  flyout registers (Ember cannot read `...attributes`); changing it later does
  not rename the session. There is no `id` override of the flyout id (upstream
  `id` prop); managed flyouts get `id` = their manager id before
  `...attributes`.
- Standard flyouts register with the manager for z-index (upstream does too):
  a flyout opened while another flyout or session is open stacks 2 (or 3 per
  session) levels higher. A single flyout is unchanged.
- `container` inheritance follows the upstream docs; the 123.1.0 source has no
  such context (it relies on component defaults).

## Not ported

- `EuiFlyoutManager` provider / `useFlyoutManager` hooks: the service is the
  API. `componentDefaults` container (no Ember component defaults).
- `focusTrapProps.closeOnMouseup`, `includeSelectorInFocusTrap`,
  `includeFixedHeadersInFocusTrap` (fixed headers are not added as focus-trap
  shards; existing behavior kept), `scrollContainerRef`, scroll-lock deferral
  for push padding (the Ember flyout has no scroll lock).
- `shouldAnimate` stages (upstream always passes `false`).
- The orphan-child error path is ported (logs and renders nothing) but is not
  reachable through routing, so it has no test.
- Focus-trap shards are read when the trap installs (ember-focus-trap ignores
  later `additionalElements`), so switching side-by-side ↔ stacked while a
  child is open keeps the original trap containers.

## Tests and checks (2026-10-13)

- `tests/helpers/jest-compat.ts`: describe/it/expect/jest.fn over QUnit, so
  upstream suites port nearly verbatim (`tests/unit/flyout-manager/`):
  reducer, actions, validation, store (service), plus hand ports of
  selectors, layout_mode and activity_stage (hooks → pure functions and
  service listener/container tests).
- `tests/integration/components/eui-flyout-manager-test.gts` (17): routing and
  data attributes, child beside the main (position, z-index, border,
  background, a11y, focus in/out, Escape), A→B with Back and `onActive`,
  history popover jump, historyKey isolation and group close, stacked layout
  in a narrow container, flyoutMenuProps + display mode + labelling, placed
  menu closing, store pagination override, `session="never"`, returnFocus,
  container bounds/mask/min widths/inheritance/`null`, push padding on a
  container, and upstream's background-close, cascade, menu-props and
  session-sibling (`--euiFlyoutMainWidth`, no clamp) cases.
- Full core suite 1540/1540 (main 1344 + 196 new). ember-tsc pass. ESLint on
  changed files pass. Parity 352/352. API docs regenerated (1 page). Docs
  demo blocks parse (content-tag + @glimmer/syntax) and were smoke-rendered in
  the test harness (session, history key, container, menu demos); the site
  build was not run.

## Docs

`packages/core/docs/layout/flyout/`: d10/d11 now use `@flyoutMenuProps`
(mirroring upstream), d12 shows `EuiFlyoutMenu` placed in the block, new
d14 (menu display mode), d15 (Session management, Beta: A/B + child; adds a
shared `@historyKey` because without one upstream's demo shows no Back
button), d16 (historyKey), d17 (container). Index: returnFocus and closing
reasons. No new top-level page. The EuiFlyout row is removed from
docs-audit-gaps.md.
