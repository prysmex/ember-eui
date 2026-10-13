# Upstream prop gaps: popover- and flyout-based props

Branch `eui-wave/props-popovers` (5 feature/test commits + docs + this
handoff). Every prop was checked against EUI v123.1.0 source first.
Tests: new `tests/integration/components/eui-popover-flyout-props-test.gts`
(19 tests). Full core suite **1993/1993** (main was 1974). ember-tsc clean,
eslint clean on changed files, parity test 357/357, styles generator and
API docs regenerated (11 pages).

## Closed, per component (for docs-audit-gaps.md)

- **EuiToolTip** `@anchorProps`: `className`, `css`, `style` (upstream's
  object of CSS properties, or a string/SafeString; `@anchorStyle` wins),
  `on<Event>` functions as listeners (e.g. `onMouseEnter`/`onMouseLeave`,
  next to the tooltip's own), any other key as an attribute (`id` overrides
  the `-wrapper` id, as upstream's spread order). Also fixed: `@onBlur` was
  documented but never called; it now runs when the anchor loses focus (not
  on `@isShown` changes), as upstream.
- **EuiIconTip** `@anchorProps`, `@offset`, `@repositionOnScroll`,
  `@disableScreenReaderOutput` (passed to EuiToolTip).
- **EuiBetaBadge** `@anchorProps`: on the tooltip anchor with
  `@tooltipContent`, otherwise on a wrapping `span` (`className`, `css`,
  `style`, attributes).
- **EuiCopy** `@tooltipProps`: every EuiToolTip arg except `content` /
  `onMouseOut`; `onBlur` runs and then the copied message resets; the copied
  state sets `disableScreenReaderOutput` (upstream).
- **EuiKeyPadMenuItem** `@betaBadgeTooltipProps` (EuiToolTip args except
  title/content). **EuiKeyPadMenu** `checkable.legendProps` (`className`,
  `css`, attributes). The audit's remaining `EuiKeyPadMenu checkable` entry
  is a false positive (see below).
- **EuiColorPalettePicker** `@isOpen`, `@itemClassName`, `@popoverProps`
  (EuiSuperSelect pass-through). **EuiColorPicker** `@popoverZIndex`.
- **EuiHeaderLinks** `@popoverProps` (all EuiPopover args except
  `button`/`closePopover`, they replace the defaults; `className` on the
  root, `css` composed after the media-query css) and `@popoverButtonProps`
  (EuiHeaderSectionItemButton args `ref`, `disabled`, `href`, `notification`,
  `notificationColor`, plus `iconType`; `onClick` runs before the toggle;
  other keys, e.g. `aria-label`, `data-test-subj`, are attributes). Only
  args that exist on main are used.
- **EuiRange / EuiDualRange** `@inputPopoverProps`: EuiInputPopover args
  except `isOpen`, `closePopover`, `disableFocusTrap`, `ownFocus`,
  `popoverScreenReaderText`, `fullWidth` (upstream's Omit); `className` on
  the popover root. New exported type `EuiRangeInputPopoverProps`.
- **EuiTourStep**: `attachToAnchor`, `buffer`, `container`, `display`,
  `focusTrapProps`, `hasArrow` (defaults to the beacon), `initialFocus`,
  `insert` (not with `@anchor`), `isOpen` (wins over `isStepOpen`, as
  upstream's spread), `offset` (default 10 with beacon+arrow), `ownFocus`
  (default false), `panelClassName` (added to `euiTour`), `panelPaddingSize`,
  `panelProps` (its `css` composed after the tour's), `panelStyle`,
  `popoverScreenReaderText`, `repositionOnScroll`, `repositionToCrossAxis`,
  `onPositionChange`, plus `@css` (on the panel, as upstream). `arrowChildren`
  is a `<:arrowChildren>` block replacing the beacon.
  EuiWrappingPopover now forwards `panelProps`, `focusTrapProps`,
  `onPositionChange` (needed by the `@anchor` variant).
- **EuiFlyout** `@includeFixedHeadersInFocusTrap` (default `true`),
  `@includeSelectorInFocusTrap` (string or list; elements found when the
  trap is created), `@pushAnimation` (deprecated no-op; upstream ignores it
  too). The description adds "You can still continue tabbing through other
  global page landmarks." when shards were found, as upstream.
- **EuiFlyoutMenu** `@iconType`: accepted and ignored, as upstream (the
  flyout reads it from `@flyoutMenuProps` for the history menu).
- **EuiCollapsibleNav**: `closeButtonProps`, `container`,
  `flyoutMenuDisplayMode`, `flyoutMenuProps`, `focusTrapProps` (the toggle
  button is always added to `shards`, as upstream's `buttonRef`),
  `hasAnimation`, `hasChildBackground`, `historyKey`,
  `includeFixedHeadersInFocusTrap`, `includeSelectorInFocusTrap`,
  `maskProps`, `maxWidth`, `minWidth`, `onActive`, `onResize`,
  `pushAnimation`, `resizable`, `session` (defaults to `'never'`, as
  upstream).
- **EuiCollapsibleNavGroup**: `arrowProps`, `borders`, `buttonClassName`
  (replaces `euiCollapsibleNavGroup__heading`, upstream spread order),
  `buttonContent` (string; replaces the title row, upstream spread order),
  `buttonContentClassName`, `buttonProps`, `element`, `forceState`,
  `isDisabled`, `isLoading`, `isLoadingMessage`, `role`, `childClassName`,
  `triggerClassName` (collapsible groups, EuiAccordion pass-through) and
  `iconProps` (`color`, `css`, `title`, `className`, other keys as
  attributes).
- **EuiComboBox** `inputPopoverProps`: `closeOnScroll` (**default true**,
  as upstream's combo box: after 500ms, a scroll of the page or of an
  element containing the input closes the list; scrolling the list or the
  input does not), `repositionOnScroll` (accepted; the basic-dropdown list
  always follows the input, `false` is not supported), `offset` (gap in px),
  `buffer` / `container` (bound the list horizontally; default buffer 16
  only when one of them is given), `onPanelResize(width)` (input width, at
  least `panelMinWidth`, on render and input resize), `className` and other
  keys as attributes of the combo box root (upstream's popover root wraps
  the input). The consumer's `@calculatePosition` is still used, wrapped.
  The validated-form / changeset-form API is unchanged.
- **EuiComboBoxPill** `@onClickAriaLabel` (default "Change").

## Skipped

- EuiComboBox `inputPopoverProps.isLoading`: not an EuiInputPopover /
  EuiPopover prop in 123.1.0. `panelRef` / `popoverRef`: ref props (brief).
- EuiComboBox `renderOption`: covered by the default block (yields option,
  index, search value); upstream's third argument
  (`OPTION_CONTENT_CLASSNAME`) is not yielded.
- EuiCollapsibleNav `hideCloseButton`, `pushMinBreakpoint`: upstream sets
  them after `{...rest}` (`navIsDocked`, `dockedBreakpoint`), so they have no
  effect there either.
- EuiKeyPadMenu `checkable`: already an arg. The audit script attributes
  the module's first `declare const X: TemplateOnlyComponent<…>` (the private
  `KeyComponent`) to the file's component, so it sees only `default`. Fix in
  `scripts/upstream-prop-audit.mjs` (prefer the default export) if wanted.

## Behaviour changes (upstream-faithful)

- EuiComboBox closes its list on page/container scroll by default.
- EuiFlyout: fixed `EuiHeader`s are focus-trap shards by default; the
  screen reader description gains the "global page landmarks" sentence when
  there are shards (also for side-by-side child flyouts).
- EuiCollapsibleNav: toggle button is a focus-trap shard; `session` is
  `'never'` (a nav inside a managed flyout no longer joins its session).
- EuiBetaBadge without tooltip: always wrapped in a `span` (upstream DOM).
- EuiKeyPadMenuItem with `@betaBadgeLabel`: the EuiToolTip (title = label,
  content = `@betaBadgeTooltipContent`) wraps the whole item; the badge is
  `aria-hidden` and its title is the letter (upstream). Previously the badge
  itself was a focusable tooltip anchor inside the button.
- EuiToolTip `@onBlur` is now called.
No existing test assertion had to change.

## For the coordinator

- Update docs-audit-gaps.md: remove the EuiComboBox `inputPopoverProps`
  row (keep a note: no `panelRef`/`popoverRef`, `repositionOnScroll` always
  on, horizontal-only bounds) and the "Popover-based props" / "Flyout-based
  props" rows; remove EuiCollapsibleNavGroup, EuiComboBoxPill
  `onClickAriaLabel` and EuiFlyoutMenu `iconType` from "Component-specific";
  EuiComboBox `renderOption` from "Probably covered by blocks".
- The changeset was not edited (shared file); suggested line: "EuiComboBox
  closes its list on scroll (upstream `closeOnScroll`); EuiFlyout includes
  fixed headers in its focus trap; EuiKeyPadMenuItem's beta badge tooltip
  wraps the item."
- Docs: new demos `display/tool-tip/demo/d10-anchor-props.md`,
  `forms/combo-box/demo/d26-input-popover-props.md`, a `@tooltipProps` demo
  in `utilities/copy.md`; migration guide's combo box Known gap narrowed.
