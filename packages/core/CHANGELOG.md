# @ember-eui/core

## 16.0.5

### Patch Changes

- 6978903: `euiClass` remembers the class it composed, per Emotion cache and styles, so components rendered many times with the same styles (table rows, list items, badges) no longer serialize and hash them on every render: about 10x faster per call for typical args (0.84µs to 0.08µs in a Node benchmark; 5.3µs to 0.1µs for a few large style objects). Serialized styles are remembered by identity and plain objects by content; styles containing functions are serialized as before, and a flushed cache starts over. The classes are the same as before.
- a8fbfc5: Icons can be registered up front: every EUI icon type now has a module, `@ember-eui/core/icons/<type>`, whose default export is its component, and `registerIcons({ cross, search })` from `@ember-eui/core/utils/preload-icons` makes those icons render with the first paint, without the loading placeholder, the fade-in or a request (see the icons' Lazy loading docs). An icon that has loaded or was registered still renders at once, without fading in, everywhere afterwards. The map of icon loaders (one per type, ~700) is now imported with the first icon that has to load instead of with `EuiIcon`, which takes ~46KB (minified; 14KB gzip) off every app that renders an icon: an app rendering one `EuiIcon` loads 160KB of ember-eui up front instead of 206KB. In return, the first icon an app loads (rather than registers) takes one more request.
- f04ba0b: `EuiMarkdownFormat` loads the markdown parser (unified, remark), the code highlighter (refractor and its language list) and the emoji data the first time one renders, and renders its content once they have loaded; later ones render at once. Importing `EuiMarkdownFormat`, or `EuiToast` (which renders markdown bodies), no longer brings them into your bundle: an app rendering one `EuiMarkdownFormat` loads 167KB of ember-eui up front instead of 681KB (minified; 52KB gzip instead of 218KB). Emoji shortcodes no longer go through node-emoji's main module, which required CommonJS `lodash/toArray`: the default emoji plugin reads node-emoji's emoji list directly, with the same results (except that names like `:constructor:` now stay as typed instead of losing their colons). `EuiCode` and `EuiCodeBlock` load the per-language loaders (~35KB) with the first language they need to load, not up front. The loading registers test waiters, so `settled()` and the test helpers wait for it. `remark-emoji` is no longer a dependency; `node-emoji` and `emoticon` are.
- 45028fc: Apps that prefer every icon bundled up front can opt out of lazy icons: call `registerAllIcons()` from `@ember-eui/core/utils/register-all-icons` once (e.g. in `app/app.js`) and no icon loads when it first renders, with no placeholder, fade-in or request. It adds all ~700 icons to the bundle that imports it (~330KB minified, ~130KB gzip). Without it, icons stay lazy.
- e5dd725: EUI's style factories ship as one module per upstream style file instead of a single ~660KB module. Each component imports only the styles it renders, so an app bundles only the styles of the components it uses, and a lazily loaded component (a route-split page, a dynamic `import()`) brings its own styles with it instead of adding them to the app's entry. In a Vite/Embroider app, an entry rendering `EuiButton` with a lazily loaded `EuiDataGrid` route loads 373KB of ember-eui before running instead of 494KB (minified; 121KB gzip instead of 147KB). `@ember-eui/core/utils/eui/styles.generated` still exports every factory.
- f1895a9: Booting ember-eui no longer loads all of CommonJS lodash. `@elastic/eui-theme-borealis` imports `@elastic/eui-theme-common`'s index, which reaches its vis color store and `import { uniqueId } from 'lodash'`; neither package declares itself side-effect free, so every app got ~70KB of minified lodash next to lodash-es. ember-eui now bundles the parts of the two theme packages it uses, from their ES modules, with their lodash imports going to lodash-es; the unused vis color store is left out. Every entry is about 83KB smaller (minified; ~28KB gzip): an app rendering only `EuiEmotionProvider` loads 126KB of ember-eui instead of 209KB, one rendering `EuiButton` 276KB instead of 359KB. The theme packages stay dependencies for their types; imports of them in your own code are not affected.
- Performance improvements

## 16.0.4

### Patch Changes

- fixes

## 16.0.4

### Patch Changes

- 2071e5b: Text props that take text or a component (`EuiRenderNode`, e.g. `EuiToast`'s `@body`) accept an `htmlSafe` string again and render it as HTML, as 14.x toasts did, instead of failing to invoke it as a component. With `@useMarkdownFormat`, an `htmlSafe` toast body is rendered as the HTML it already is, not as markdown.

## 16.0.3

### Patch Changes

- fixes

## 16.0.3

### Patch Changes

- ee57848: `EuiComboBox`: with `@singleSelection={{hash asPlainText=true}}` and a block, the selection is rendered with the block again (as in 14.x, on ember-power-select) while nothing is typed, e.g. enum values shown as an avatar and a translated label instead of the raw value. The block receives the option, then the select. Typing shows the input's text again, so search works as before. The input keeps the option's label as its value, which screen readers announce. Without a block, the input shows the label text, as upstream EUI does. Focusing or clicking the input selects the hidden label, so typing replaces it.
- eb495f9: `EuiComboBox` gains `@ignoreAccents` to match options ignoring accents ("medico" finds "Médico"), as ember-power-select did. It defaults to the app's `euiComboBox.ignoreAccents` in eui-config, else `false` (upstream).
- eb495f9: `EuiComboBox` reads options and selections that are Ember array-likes without `slice()` (e.g. ember-data's `PromiseManyArray`) via `toArray()`, their iterator or their `content`, instead of throwing.

## 16.0.2

### Patch Changes

- fix validated form

## 16.0.1

### Patch Changes

- Memory leak fixes from an audit of every component, and ember-source 7.3.1.

  - The `resizeObserver` modifier keeps one observer per element and disconnects it on teardown. It used to add a new observer on every update without disconnecting the old one; EuiToolTip, EuiInputPopover, EuiCodeBlock, the markdown editor and others use it.
  - `EuiPopover` releases its panel (`panelRef(null)`) and its window resize listener when it closes, and stops its reposition loop when destroyed. `EuiOverlayMask` sends `@maskRef(null)` on teardown. `outsideClickDetector` sets up once.
  - Per-instance values no longer become permanent style classes: `EuiAvatar` image URLs and colors, custom colors on `EuiTextColor` / `EuiText` / `EuiMarkdownFormat` / `EuiToken`, and `EuiAspectRatio` ratios are inline styles, as upstream. Keep `@css` values static and put values that change in `style`.
  - Closing the last flyout with Back resets the flyout manager's z-index counter.
  - Teardown cleanup: drag listeners in the color picker saturation, color stops and data grid body; toast list timers; the shared document `copy` listener of data grids and tables; deferred callbacks in EuiToolTip, EuiRange, EuiDualRange, EuiColorPicker, EuiFocusTrap, the search bar filter and the markdown drop zone; changeset-form validation timers.
  - `EuiComboBox` no longer throws an autotracking assertion when removed while its list is open, and the markdown editor no longer throws `reading 'start'` after formatting.
  - The test suite and docs use ember-source 7.3.1, which releases `renderComponent` renderers with their owner.

## 16.0.0

### Major Changes

- 3e2ae08: `EuiComboBox` now behaves like EUI 123.1.0's by default:

  - Matching ignores case but no longer accents (upstream's matcher); `@isCaseSensitive`, `@matcher` and the new `@optionMatcher` customize it.
  - In multiple selection the selected options are no longer listed, and the list stays open after a choice (`@closeOnSelect` defaults to `true` only for single selection). Single selection keeps its option listed with a check mark.
  - Leaving the combo box with typed text adds it (`@onCreateOption`, or the option it names exactly); text that is not added stays in the input and marks the combo box invalid. Enter adds the typed text too when no option is highlighted, even if it partially matches options.
  - Nothing is highlighted when the list opens (tooltips and `aria-activedescendant` follow the arrow keys); the arrows wrap, Escape keeps the text, Tab is held while an option is highlighted, hovering no longer highlights, and focusing the input opens the list.
  - `@sortMatchesBy="startsWith"` sorts the whole list like upstream, group titles included.
  - Upstream empty states ("{searchValue} doesn't match any options", "There aren't any options available", "You've selected all available options", "{label} has already been added"); `@isLoading` shows the spinner in the list too.
  - The search input is the `combobox` (with `aria-expanded`, `aria-controls`, `aria-haspopup`) and the wrapper is no longer a tab stop; the listbox is labelled "Choose from the following options"; screen reader instructions are read on focus. The enter badge on the highlighted option needs `@onFocusBadge`.
  - New `@async`, `@onSearchChange`, `@optionMatcher` and `@onFocusBadge`, and upstream's `{ label, options }` groups.

  The validated-form and changeset-form combo box fields forward every `EuiComboBox` argument (and the search text to their block), and the changeset field validates again after a custom option is added.

  See "Migrating to Borealis" for the full list.

- Elastic EUI bump

### Minor Changes

- 9379d61: Style every component with current Elastic UI: EUI 123.1.0 with the Borealis 8.1.0 theme, instead of EUI 41.4's Amsterdam CSS. Components build their styles from upstream EUI's style factories and inject them with Emotion at runtime, so the theme stylesheet (`@ember-eui/core/themes/light.css` / `dark.css`) is no longer needed.

  - Render one `EuiEmotionProvider` around the app. The outermost provider injects upstream's global styles (reset, 14px root font size, body colors, focus ring); `@colorMode` switches light/dark, `@borealisOverrides` takes Borealis token overrides and `@highContrastMode` sets contrast. `@globalStyles={{false}}` and `@wrapper={{false}}` opt out of the global styles and the `euiThemeProvider` span.
  - Components take an `@css` argument, composed last into their own class (like upstream's `css` prop). Amsterdam modifier classes (`euiButton--primary`, `euiFlexGroup--gutterLarge`, …) are removed; stable root and element classes are kept.
  - Some defaults follow upstream, e.g. `EuiPanel` has a border and no shadow, `EuiFlexGroup` gutter `m`, `EuiText` size `s`, `EuiLink` color `text` with `rel="noreferrer"`, form rows 400px wide, `EuiTablePagination` 10 rows per page, `EuiPopover` anchored `downLeft` without an arrow, `EuiModal` max width 768px, and `EuiForm` focuses its error callout.
  - Icons are EUI 123.1.0's set (698 names); every previous name still resolves through legacy aliases. App icons registered in `euiIcon.icons` now win over EUI icons of the same name.
  - `EuiNotificationEvent`, `EuiSuggest`, `EuiColorStops` and `EuiControlBar` were removed upstream: they keep working but are deprecated until 16.0.0 (`ember-eui.<file>.removed-upstream`).
  - `EuiPageTemplate` follows upstream's composable API (`<EuiPageTemplate as |T|>` with `T.Header`, `T.Section`, `T.EmptyPrompt`, `T.BottomBar` and `T.Sidebar`, plus `@panelled`, `@bottomBorder`, `@offset`, `@restrictWidth`). The previous `@template` / named-blocks API keeps working but is deprecated until 16.0.0 (`ember-eui.eui-page-template-legacy.removed-upstream`).
  - Theming: a root `EuiEmotionProvider` without `@colorMode` / `@highContrastMode` follows the OS (`prefers-color-scheme`, `prefers-contrast`, `forced-colors`), as upstream `EuiProvider`. `@highContrastMode` accepts `true`. The root provider publishes the theme's semantic tokens as CSS variables (`--eui-color-text-subdued`, …). `@css` and the other `*Css` args also accept a theme function (`({ euiTheme }) => styles`), and `@ember-eui/core/theming` exports the helpers for styling app components.
  - New upstream features: EuiFlyout session management (`@session`, Beta upstream) and `@flyoutMenuProps`; EuiButtonGroup child buttons and segmented/selection variants; `hasAriaDisabled` on buttons; per-breadcrumb popovers; EuiSelectable, EuiComboBox and EuiSuperDatePicker props from EUI 123.1.0.
  - Small behaviour changes to match upstream: `EuiHeaderBreadcrumbs` defaults to `@type="application"`; `EuiSuperDatePicker` `@onRefreshChange` also reports `intervalUnits`.
  - Smaller upstream alignments: `EuiPageTemplate`'s `T.BottomBar` always ends up at the end of the main content; `EuiImage` attributes go on the `<img>` (**breaking**: use `@wrapperProps` for the `<figure>`); focusing `EuiSelectable`'s search no longer makes an option current; the super date picker's date buttons show their title in a tooltip and the time zone label is a `span`; delimited fields default to a `sortRight` icon labelled "to" instead of `→`; extra keys of `EuiSelectable @searchProps`, `EuiTabbedContent` tabs, `EuiImage @wrapperProps` and `EuiCard` `betaBadgeProps.anchorProps` become attributes. New: `EuiText @component`, `EuiDatePickerRange @showTimeSelect`, `EuiTreeView <:icon>`.
  - More upstream props across display, navigation, layout, forms and tables (e.g. `EuiBasicTable` column `valign` / multi-line `truncateText` / sticky actions, `EuiTable` `@stickyHeader`, `EuiInMemoryTable` custom panels, `EuiCheckbox` `readOnly`, `EuiSteps` numbering, rich content in list groups, cards, timelines, toasts, tree views and headers). An `EuiStep` without `@step` is now numbered by its position; `EuiToolTip` repositions on scroll only with `@repositionOnScroll`, as upstream.
  - Last upstream interaction alignments: pressing `EuiComboBox`'s chevron moves focus to it (closing keeps focus there; leaving from it closes the list), `@onBlur` fires only when focus leaves the combo box, and pills get the option's other keys as attributes, its label as `title`, and a "Change" button for options with `onClick`; `EuiSelectable`'s `aria-label` / `aria-describedby` name the search and the listbox instead of the root; `EuiBadge` with `@iconOnClick` and `@onClick`/`@href` puts its attributes (except `class` / `style`) on the text button; `EuiListGroup @wrapText` reaches only `@listItems`, and a list item's block is its tooltip content and `title`; a pushed flyout nested in a managed flyout does not push.
  - Layering: the `EuiComboBox` list stacks like upstream's input popover (its anchor's z-index + 2000) instead of a fixed 99999, so option tooltips show above it; tooltips never stack below their anchor. Popover panels and combo box lists opened inside a modal, flyout or popover now count as inside its focus trap (inputs in them keep focus).
  - Color palettes follow upstream 123.1.0: `euiPaletteColorBlind`, `euiPaletteColorBlindBehindText`, `euiPaletteForStatus`, `euiPaletteForTemperature`, `euiPaletteComplementary`, `euiPaletteRed`/`Green`/`SkyBlue`/`Yellow`/`Orange`/`Cool`/`Warm`/`Gray` read the Borealis vis colors (so the default categorical palette is now teal/blue/pink instead of the Amsterdam green/blue/pink set, and the status, temperature, cool, warm and gray gradients change), take upstream's `colors` option, and have theme-aware `useEuiPalette*(context, …)` versions that follow color mode and high contrast. `euiPaletteColorBlindBehindText` is no longer brightened (like upstream). `euiPaletteComplimentary`, `euiPaletteNegative`, `euiPalettePositive`, `euiPaletteForLightBackground` and `euiPaletteForDarkBackground` are deprecated until 16.0.0 (upstream dropped them). `EuiColorPicker`'s default swatches now follow the theme's vis colors.
  - Upstream props closed after an automated audit of every component: button-like components forward EuiButton/EuiButtonEmpty args (`@contentProps`, `@textProps`, `@isLoading`, …); popover and flyout pass-throughs (`anchorProps`, `popoverProps`, `inputPopoverProps`, `tooltipProps`, EuiTourStep's popover args, EuiCollapsibleNav's flyout args); data-driven `@steps`, `@toasts` and context menu `@items` next to the blocks; and props across forms, date pickers, lists and display components. Behaviour now matching upstream: `EuiComboBox` closes its list on scroll, `EuiFlyout` includes fixed headers in its focus trap, `EuiCollapsibleNav` defaults `@session` to `'never'`, `EuiKeyPadMenuItem`'s beta badge tooltip wraps the item, a disabled `EuiAutoRefreshButton` uses `aria-disabled`, `EuiToolTip @onBlur` fires, and context menu links get a secure `rel` and the external icon for `_blank`.
  - Every package's `LICENSE.md` now has the MIT text its `package.json` declares; parts derived from EUI keep Elastic's license (see `NOTICE.md`).

  See the "Migrating to Borealis" guide (`/docs/migrating-to-borealis`) for the upgrade steps and the full list of changed defaults.

## 15.0.0

### Major Changes

- a749bc4: Require Ember 7.1 and Node.js 20.19 or newer. Upgrade development and testing to Ember and Ember CLI 7.3, and replace ember-element-helper with Ember's native element keyword.

  Dynamic elements no longer receive the helper's automatic `ember-view` class or generated ID. Pass an explicit `id` if needed.

### Patch Changes

- fixes

## 14.1.4

### Patch Changes

- page template

## 14.1.3

### Patch Changes

- redeploy

## 14.1.2

### Patch Changes

- Group headings in `EuiComboBox` can no longer be selected, and the accordion loading demo has separate controls for `@isLoading` and `@isLoadingMessage`.
- redeploy

## 14.1.1

## 8.0.69

### Patch Changes

- bug fix in valdiated form

## 8.0.68

### Patch Changes

- fixes

## 8.0.67

### Patch Changes

- fix service and combo box
- 30a1d7f: Use `inject as service` from `@ember/service` again. The bare `service` export only exists in Ember 4.1+, so on older Ember versions `@service` was `undefined` and loading a component failed with "decorator is not a function".

## 8.0.66

### Patch Changes

- c37c14b: EuiComboBox with groups: choosing an option selected the wrong item (often a
  whole group, shown as an empty pill).
- 6f269da: EuiComboBox: the input no longer shifts right inside EuiText (or anywhere
  lists are styled), and ember-power-select's screen reader announcement
  ("3 results") no longer shows under the options. Both fixes are in
  `@ember-eui/core/styles/ember-eui.css`.
- 00421f6: EuiComboBox's options list shows above modals and flyouts again: its
  z-index is now set through ember-basic-dropdown's
  `--ember-basic-dropdown-content-z-index`, so it no longer depends on which
  stylesheet loads last.
- Publush last fixes

## 14.1.0

### Minor Changes

- fixes and docs
- 646cdcb: Add the EUI 41 components that were missing, each with a docs page and tests:
  EuiSuperSelect, EuiSelectable (and its templates), EuiSuggest, the color
  components (EuiColorPicker, EuiColorPalettePicker, EuiColorStops, ...),
  EuiTour, EuiResizableContainer, EuiRefreshInterval (EuiSuperDatePicker now
  refreshes automatically), the table building blocks, and drag and drop
  (EuiDragDropContext, EuiDroppable, EuiDraggable).

  Drag and drop is built on Atlassian's pragmatic drag and drop, so
  `@atlaskit/pragmatic-drag-and-drop` and its auto scroll package are new
  dependencies (installed with core; nothing to add to the app).

- 8d277d4: EuiCode, EuiCodeBlock and EuiMarkdownFormat load each syntax highlighting
  language the first time it is used, instead of bundling all of refractor's
  ~280 languages (about 580 KB minified) with the first code component. Code
  shows as plain text until its language has loaded, then highlights;
  `settled()` waits for it in tests. HTML/XML, CSS and JavaScript are built in
  and need no loading.
- 646cdcb: EuiPopover focuses `@initialFocus` (an element, a selector or a function
  returning an element) once its panel is positioned and visible, also without
  `@ownFocus`, so opening a popover no longer scrolls the page to an element
  that was not placed yet.

  Behaviour change: a popover with `@ownFocus` and no `@initialFocus` now
  focuses the first focusable element in it, as EUI does, instead of the
  panel. Pass `@initialFocus` to choose another element.

### Patch Changes

- ec6c8de: EuiBadge and EuiAvatar no longer load chroma-js (about 43 KB minified): the
  palette they color with is kept precomputed.
- 646cdcb: - EuiFormRow points its control's `aria-describedby` at the help text and
  errors, and gives help texts unique ids.
  - Labelled icons (header logo, icon tip, links, notifications) are announced
    by screen readers; EuiIcon `@title` and `@aria-label` name the icon.
  - EuiContextMenuItem `@layoutAlign` aligns the icon and the text.
  - Export the public components missing from `@ember-eui/core/components`.
- 75b9d33: - Keyboard drags move the item past items of any height (or width), also
  on zoomed pages.
  - `settled()` waits for an opening EuiPopover to set its focus, so tests
    can assert the focus right after opening it.
- 3e32853: Declare `sideEffects` so apps bundle only the components they import:
  importing one component from `@ember-eui/core/components` no longer pulls
  in the whole library (e.g. EuiButton alone: ~43 KB of core code instead of
  ~680 KB, minified, before the lazily loaded icons).

## 14.0.0

### Major Changes

- VITE

## 13.0.5

### Patch Changes

- re-release

## 13.0.4

### Patch Changes

- re-release v8-master

## 13.0.3

### Patch Changes

- fix

## 13.0.2

### Patch Changes

- pass in classes

## 13.0.1

### Patch Changes

- bump ember-power-select

## 13.0.0

### Major Changes

- Removes @glimmer/tracking from package json

## 12.0.13

### Patch Changes

- re-lease

## 12.0.12

### Patch Changes

- releave v8

## 12.0.11

### Patch Changes

- release

## 12.0.10

### Patch Changes

- relase

## 12.0.9

### Patch Changes

- release

## 12.0.8

### Patch Changes

- release

## 12.0.7

## 8.0.65

### Patch Changes

- pass down match trigger width

## 8.0.64

### Patch Changes

- general typings fixes and mutation observer

## 8.0.63

### Patch Changes

- try to fix mobile clcik

## 8.0.62

### Patch Changes

- EuiComboBox had some issues with html output and css, also we had the need to support always showing the creationOption UI for certain scnearios, so we added a new arg, alwaysShowCreateOption to always display it when createOption arg is also passed in

## 8.0.61

### Patch Changes

- Fixes

## 8.0.60

### Patch Changes

- pass in classnames

## 8.0.59

### Patch Changes

- re-release

## 8.0.58

### Patch Changes

- minor leaks

## 8.0.57

### Patch Changes

- leaks

## 8.0.56

### Patch Changes

- fix memory in accordion

## 8.0.55

### Patch Changes

- fix memory

## 8.0.54

### Patch Changes

- fix translations for markdown-editor

## 8.0.53

### Patch Changes

- fix add size argument to eui-markdown-format and eui-markdown-editor

## 8.0.52

### Patch Changes

- fix helpText and event delegation for validated-form

## 8.0.51

### Patch Changes

- fix

## 12.0.6

### Patch Changes

- release

## 12.0.5

### Patch Changes

- feat adds eui-wrapping-popover

## 12.0.4

### Patch Changes

- release v8-master

## 12.0.3

### Patch Changes

- releasing changes from v8

## 12.0.2

### Patch Changes

- Fix build for vite apps

## 12.0.1

### Patch Changes

- Fix eui-combo-box

## 12.0.0

### Major Changes

- Update blueprints and everything basically to make it work with ember source 6.2.0

## 11.0.3

### Patch Changes

- re-release v8

## 11.0.2

### Patch Changes

- Release v8

## 11.0.1

### Patch Changes

- release v8into master

## 11.0.0

### Major Changes

- release

## 10.0.9

### Patch Changes

- nump

## 10.0.8

### Patch Changes

- release

## 10.0.7

### Patch Changes

- release

## 10.0.6

### Patch Changes

- Fixes

## 10.0.5

### Patch Changes

- bump

## 10.0.4

### Patch Changes

- FIxbuild

## 10.0.3

### Patch Changes

- fix declarations

## 10.0.2

### Patch Changes

- try fixing build

## 10.0.1

### Patch Changes

- 82b1bf1: Fix build

## 10.0.0

### Major Changes

- 3540301: Modernized build

## 9.0.1

### Patch Changes

- 3166c2e: releasing types

## 9.0.0

### Major Changes

- 52128dc: BREAKING, changeset form is now built with other v2 addon bleupints, just like ValidatedForm

### Minor Changes

- 882f3aa: Allow passing compressed to ValidatedForm

## 8.0.15

### Patch Changes

- # Fix searchMessage styling

## 8.1.0

### Minor Changes

- 157b860: Fixes issues

## 8.0.50

### Patch Changes

- adds hooks

## 8.0.49

### Patch Changes

- fix

## 8.0.48

### Patch Changes

- Adds eui-wrapping-popover component

## 8.0.47

### Patch Changes

- feat: allow helpText customization through validated form eui-form-row comoposition

## 8.0.46

### Patch Changes

- fix types

## 8.0.45

### Patch Changes

- Allow uiPlugins for eui-markdown-editor

## 8.0.44

### Patch Changes

- fix

## 8.0.43

### Patch Changes

- fixes

## 8.0.42

### Patch Changes

- Fix EuiIcon not rendering icons as components via useComponent argument

## 8.0.41

### Patch Changes

- Adds euiComboBox.customOptionText token to euiI18n for creating options

## 8.0.40

### Patch Changes

- do not use polyfill

## 8.0.39

### Patch Changes

- add more EuiI18n tokens for EuiComboBox

## 8.0.38

### Patch Changes

- fix build for combobox

## 8.0.37

### Patch Changes

- add eui-i18n token for eui-combo-box loadingMessage

## 8.0.36

### Patch Changes

- Pass more options to the wrapped eui-combo-box

## 8.0.35

### Patch Changes

- Fixes

## 8.0.34

### Patch Changes

- Fix passign down all tab attrs through euipageheader down to eui tabs

## 8.0.33

### Patch Changes

- Release style fix

## 8.0.32

### Patch Changes

- rm uneeded type

## 8.0.31

### Patch Changes

- docs

## 8.0.29

### Patch Changes

- fix build

## 8.0.28

### Patch Changes

- typings for accordion

## 8.0.27

### Patch Changes

- fix typings for eui-superdate-picker

## 8.0.26

### Patch Changes

- ts fixes

## 8.0.25

### Patch Changes

- ts

## 8.0.24

### Patch Changes

- Fix combobox and popover

## 8.0.23

### Patch Changes

- Docs and memory safe

## 8.0.22

### Patch Changes

- Try to fix nested popovers

## 8.0.21

### Patch Changes

- optional

## 8.0.20

### Patch Changes

- Try republisjhing

## 8.0.19

### Patch Changes

- Set some sensible defaults for eui-date-popover-button

## 8.0.18

### Patch Changes

- Protects from undefined

## 8.0.17

### Patch Changes

- default timeOptions for super-date-picker

## 8.0.16

### Patch Changes

- 23ea57c: Adds the ability to customize how superdatepicker button triggets looks like

## 8.0.14

### Patch Changes

- Removes duplicate EuiFormControlLayout

## 8.0.13

### Patch Changes

- Release again

## 8.0.12

### Patch Changes

- Pass isInvalid to trigger input component

## 8.0.11

### Patch Changes

- Export types and typescript bugs, fix using className in eui-toolip

## 8.0.10

### Patch Changes

- 72bac0d: Fixes EuiI18n

## 8.0.9

### Patch Changes

- TS

## 8.0.8

### Patch Changes

- Pass in pageTitleProps

## 8.0.7

### Patch Changes

- 7c5f2d3: typescript typings

## 8.0.6

### Patch Changes

- Bump ember-power-select

## 8.0.5

### Patch Changes

- 3647895: Replaces usage of ember-unique-id-helper-polyfill for a private helper for it to work in 4.4 onwards

## 8.0.4

### Patch Changes

- 63dc3c8: Docs and bump ember-auto-improt

## 8.0.3

### Patch Changes

- d68a28d: Allow consumers to import from @ember-eui/core/components, helpers, and modifiers

## 8.0.2

### Patch Changes

- a9a4fdc: Fix typings in EuiFlyout

## 8.0.1

### Patch Changes

- bea54d8: updated build tooling with turbo

## 8.0.1-beta.0

### Patch Changes

- bea54d8: updated build tooling with turbo

## 8.0.0

### Patch Changes

- e2a3437: lots of configuration for managing the repo
