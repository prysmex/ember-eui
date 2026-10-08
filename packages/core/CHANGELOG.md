# @ember-eui/core

## 14.1.3

### Patch Changes

- redeploy

## 14.1.2

### Patch Changes

- Group headings in `EuiComboBox` can no longer be selected, and the accordion loading demo has separate controls for `@isLoading` and `@isLoadingMessage`.
- redeploy

## 14.1.1

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
