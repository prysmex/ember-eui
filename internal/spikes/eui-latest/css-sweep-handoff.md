# CSS sweep handoff (`@css` on migrated components)

Branch `eui-wave/css-sweep`. This is a cross-cutting cleanup after all families were ported. Migrated components that callers style now take `@css`. Workarounds callers used without it are removed.

## `@css` contract

`@css?: EuiCss` is composed **last** into the component's own Emotion class, like upstream's `css` prop. It is documented like EuiIcon's. Styles stay in `@cached` getters, and factories go through `useEuiBorealisStyles`.

## Components that gained `@css`

| Component | Where it lands |
| --- | --- |
| EuiText, EuiTitle, EuiButton, EuiButtonEmpty, EuiBadge, EuiBetaBadge, EuiNotificationBadge, EuiFlexGroup, EuiFlexItem, EuiAvatar, EuiBeacon, EuiLoadingSpinner, EuiPopoverTitle, EuiPopoverFooter, EuiFlyout, EuiModal, EuiFormLabel, EuiFormControlLayout, EuiHorizontalRule, EuiLink, EuiBreadcrumbs, EuiAccordion | root |
| EuiFieldNumber | the `<input>` (upstream `className`/`css` target) |
| EuiCheckbox, EuiRadio | the wrapper `div.euiCheckbox` / `div.euiRadio`, where upstream's `css` lands |
| EuiPopover | `@css` on the root, plus the new **`@panelCss`** on the panel (upstream `panelProps.css`). The private `@rootCss` is kept and composed before `@css`. EuiInputPopover and EuiWrappingPopover forward both. |
| EuiToolTip | `@css` on the tooltip (through the private EuiToolTipPopover `@css`), plus the new **`@anchorCss`** on the anchor (upstream `anchorProps.css`) |
| EuiButton, EuiButtonEmpty | also **`@contentCss`** on the content wrapper (upstream `contentProps.css`) |
| EuiFormControlLayout | `@css` is now public (`EuiCss`, it was a private array). New **`@iconColor`** and **`@iconCss`** (upstream `icon.color` / `icon.css`) go to `@icon`'s EuiIcon through EuiFormControlLayoutIcons/CustomIcon. The private `@wrapperCss` is now `EuiCss`. |

`EuiBreadcrumbs`' root had no Emotion class. It only gets one when `@css` is passed.

## Workarounds removed

All are equivalent unless the list says otherwise. Each one swaps a second class, a doubled-specificity (`&&`) class, a descendant rule, a wrapper or a copied composition for the child's `@css`:

- **Doubled specificity / `composedOver`.** These are now `@css`:
  - EuiPageBody to EuiPanel
  - EuiCollapsibleNav to EuiFlyout
  - EuiHeaderSectionItemButton to EuiButtonEmpty; its notification EuiIcon dot drops its `&&` media rules
  - EuiHeaderLinks to EuiPopover
  - EuiHeaderBreadcrumbs to EuiBreadcrumbs
  - EuiPageHeaderContent: top/left/right to EuiFlexGroup/EuiFlexItem, and the title icon to EuiIcon `@css` (was `@iconClasses`)
  - EuiConfirmModal to EuiModal
  - EuiComboBoxPill to EuiBadge (`pillClass` and `&&` are gone)

  `composedOver` is deleted from `utils/eui/page-layout.ts`.
- **Wrappers removed** (DOM change):
  - EuiModal: `span.euiModal__closeIconWrapper`
  - EuiFlyout: `span.euiFlyout__closeButtonWrapper`
  - EuiCallOut: the dismiss `span`
  - EuiTourStep: `div.euiTour__beaconWrapper`
  - EuiGlobalToastList: the count badge `span`, and the clear-all `div.euiGlobalToastListItem` (EuiButton is now the list item, as upstream)
  - EuiQuickSelect: the wrapper div around the time-window EuiFlexGroup
  - Date popover now tab: the padded wrapper div (the padding is now EuiText `@css`)
- **Copied child styles** (now the real child with `@css`):
  - EuiSelectableMessage now renders `<EuiText @color="subdued" @size="xs" @css>`.
  - EuiCallOut and EuiEmptyPrompt render a real `EuiPanel`. `utils/eui/content-blocks.ts` (`euiPanelSurfaceCss`) is deleted.
  - Tour header/footer (`-private/eui-tour-parts.gts`) render EuiPopoverTitle, EuiPopoverFooter and EuiTitle with `@css`.
  - Toast and notification event titles render `EuiTitle @css`.
  - EuiMarkdownFormat now uses the exported `euiTextReset` from `eui-text.gts` plus a `table` reset. Its copy is removed.
- **Second classes and `@panelClassName` / `@anchorClassName` on migrated children** (now `@css`):
  - EuiTourStep: `@panelCss`. Plain `euiTour` panel class kept.
  - EuiButtonGroupButton: tooltip `@anchorCss`. Plain class names kept.
  - EuiBreadcrumbs items: EuiLink and the collapsed item's EuiPopover.
  - EuiPaginationButton and the pagination arrow button.
  - EuiPagination compressed EuiText.
  - EuiSideNav: heading EuiTitle, mobile toggle EuiButtonEmpty plus `@contentCss`. The content class used to race with the button's own `justify-content`.
  - EuiKeyPadMenu: legend EuiFormLabel.
  - EuiKeyPadMenuItem: EuiBetaBadge, and EuiCheckbox/EuiRadio through `@css` instead of an Emotion class in `@containerClass`.
  - EuiDescribedFormGroup: EuiFlexItem ×2 and EuiText.
  - EuiCallOut: EuiIcon ×2 and EuiTitle.
  - EuiPageContent to EuiPanel.
  - EuiSkipLink to EuiButton.
  - EuiImage close EuiIcon.
  - EuiStep title EuiTitle.
  - EuiStepNumber EuiIcon.
  - EuiCollapsibleNavGroup to EuiAccordion.
- **Descendant rules from a parent** (now `@css`):
  - EuiCard: description EuiText, EuiBetaBadge.
  - EuiComment: event EuiAvatar.
  - EuiAccordion: loading EuiLoadingSpinner.
  - EuiFilterButton: EuiNotificationBadge.
  - EuiFacetButton: quantity EuiNotificationBadge. The icon rule stays, because the icon is caller block content.
  - EuiFilterSelectItem: content EuiFlexItem truncation.
  - EuiColorPicker: icon color through `@iconColor`, swatch stroke through `@iconCss`. The `--euiColorPickerIconColor` inline variable is gone.
- **EuiRangeInput:** `min-inline-size` now goes through EuiFieldNumber `@css`. The auto width stays inline, as upstream. Upstream's `inline-size: auto` is deliberately left out so `@autoSize={{false}}` keeps the field width.

### Not strictly equivalent (intended upstream parity, explicitly requested)

- **EuiFlyout close button** now also gets `closeButtonLookCss`:
  - `inside`: transparent background. This was already transparent through `display="empty"`.
  - `outside`: the upstream XL shadow and `animation: none !important`.
- **EuiContextMenuItem** passes upstream `euiContextMenu__icon` (`flex-shrink: 0`) to the icon/spinner and `euiContextMenuItem__arrow` (`align-self: flex-end`) to the panel arrow. On the EuiIcon this is a no-op. The spinner and arrow gain those declarations.

## Tests changed because DOM changed

- `eui-content-blocks-test` ("callout dismiss button"): the positioned element is now the button itself, not `button.parentElement`. The DOM-order checks match `button` instead of a wrapper containing one.
- `eui-feedback-test` ("global toast list"): the count badge is `[data-test-subj=…].euiNotificationBadge` (same element), and the clear-all button itself is sticky and carries `euiGlobalToastListItem`.
- `eui-misc-display-test` (2 tour tests): the beacon styles are read from `.euiTour__beacon` itself, and the test asserts that no wrapper exists.
- `eui-modal-flyout-test` (modal, flyout): the close buttons are direct children of the modal/flyout and positioned themselves. The flyout test also asserts the `outside` shadow.
- `eui-date-pickers-test`: assertions added that the time-window buttons are the EuiFlexGroup and the now-tab padding is on EuiText. No existing assertion changed.

New file: `tests/integration/components/eui-css-arg-test.gts` (34 tests).
- Coverage: every component above (including `@panelCss`, `@anchorCss`, `@contentCss`, `@iconCss`) renders a conflicting caller declaration with the caller's rule inserted **before** the component and again **after** it, each time with a fresh value. Each test asserts that the caller value wins, and that without `@css` the component's own value differs.
- Separate tests cover EuiToolTip `@css`, EuiFormControlLayout `@iconColor`, and CallOut/EmptyPrompt rendering a real EuiPanel with a single Emotion class.

## Checks

- `ember-tsc --noEmit`: clean.
- `eslint` on all changed files: clean.
- `node scripts/generate-api-docs.mjs`: 21 pages updated; `--check` clean.
- `node --test scripts/eui-upstream-parity.test.mjs`: 304 pass, 0 fail.
- Core suite (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **1085 tests, 1085 pass, 0 fail**. The first full run before test updates was 1051 tests, 1045 pass, 6 fail; all 6 were the wrapper DOM changes above.

## Left as is

- **Not workarounds.** These would add styles that are missing today, so they are not equivalent, and they were not done:
  - EuiCardSelect `euiCardSelectStyles` on EuiButton (a visual no-op).
  - The markdown footer upload-error EuiButtonEmpty radius.
  - Table pagination `eui-xScroll` on EuiFlexGroup.
  - Color picker swatch/hue/saturation tooltips (now possible with `@anchorCss`).
- **Combo box empty states.** The padding/centering stays on the `div.euiComboBoxOptionsList` wrapper rather than EuiText. Moving it changes which element is padded, including the create-option hover box.
- **Markdown task-list checkbox.** The rule targets the Ember plugin wrappers (`:has(+ …)` between siblings), not the EuiCheckbox root, so `@css` cannot express it.
- **Titles that clone EuiTitle styles onto other tags.** EuiCard's title (supports `span`), EuiQuickSelectPanel's title (`span`/`legend` with a reset), and EuiCollapsibleNavGroup's title. EuiTitle has no `span` tag.
- **Second Emotion classes on children that still lack `@css`.** Candidates for a follow-up:
  - EuiContextMenu to EuiContextMenuPanel (`position: absolute`).
  - EuiStepHorizontal to EuiStepNumber.
  - EuiCheckboxGroup/EuiRadioGroup to EuiFormFieldset.
  - EuiPageTemplate's `eui-fullHeight`/`eui-yScroll` utility classes on EuiPage/EuiPageBody/EuiPageContent/EuiPageContentBody/EuiFlexGroup/EuiFlexItem.
  - EuiPageTemplate's bottom bar class on EuiBottomBar.
- EuiResizableContainer's yielded Panel still has no `@css` passthrough (nobody needs it yet).
