# Ember Eui Changelog

### Master

### 0.3.5

🚀 Enhancements
- Made `<EuiChangesetForm::Fields::FieldComboBox />` more manual but more flexible, now you have to passdown `@selectedOptions` and `@onChange`


### 0.3.4

🐛 Bug / Fixes
- Remove hardcoded @searchEnabled from `<EuiComboBox />`

### 0.3.3

🐛 Bug / Fixes
- Remove default searchField from `<EuiChangesetForm::Fields::FieldComboBox />`

### 0.3.2

🐛 Bug / Fixes
- Pass down @rows to `<EuiChangesetForm::Fields::FieldTextArea />`

### 0.3.1

🐛 Bug / Fixes
- Change name of generated components file for imports.

### 0.3.0

🚀 Enhancements
- Adds ability to use `<EuiIcon />` inside `<EuiAvatar />`, the downside is an small override on the css, this should be removed later on when we have time to bump elastic-eui styles.

### 0.2.8

🐛 Bug / Fixes
- `<EuiChangesetForm::Fields::FieldComboBox />` now sets string for singleSelection instead of array of 1 position

### 0.2.7

🚀 Enhancements
- Fixes performance issues and bugs around ember-changeset, we currently depend on a PR [ember-changeset](https://github.com/poteto/ember-changeset/pull/586)

🐛 Bug / Fixes
- Adds `ember-composable-helpers` to dependencies
- renamed `@onInput` to `@onChange` for `<EuiChangesetForm::Fields::FieldRangeSlider />`

### 0.2.6

🚀 Enhancements
- Adds `toArray` for changeset-form checkbox group

### 0.2.5

🚀 Enhancements
- `@valueKey` and `@labelKey` for `<EuiCheckboxGroup />` and `<EuiRadioGroup />` so you don't have to map to { id, value }

### 0.2.4

🚀 Enhancements
- Moves splattributes to the wrapped field for changeset-form

### 0.2.3

🐛 Bug / Fixes
- Add `<EuiFormRow />` to changeset-form/fields/switch

### 0.2.2

🐛 Bug / Fixes
- Typo in ChangesetForm NumberField => FieldNumber

### 0.2.1

🐛 Bug / Fixes
- Bugfixes in `<EuiFlexGrid />` and `<EuiPage />`

### 0.2.0

🚀 Enhancements
- Changeset Form Components
- `<EuiComboBox />` Added to changeset-form package


### 0.1.29

🚀 Enhancements
- `<EuiComboBox />` first iteration

### 0.1.28

🐛 Bug / Fixes
- Remove html type attribute from `<EuiTextArea />` underlaying `<textarea>`

### 0.1.27

🚀 Enhancements
- Block for `<EuiBetaBadge />`

### 0.1.26

🐛 Bug / Fixes
- Add optional helper on "onClose" toasts actions
- Fix deploys

### 0.1.24

🐛 Bug / Fixes
- Optional chaining for changeset access in changeset-form base field

### 0.1.23

🚀 Enhancements
- `<EuiCard />` don't show description markup if there's no description block or arg

### 0.1.22

🐛 Bug / Fixes
- Updates internal `this.value` if `@value` changes for `<EuiFieldSearch />`

### 0.1.21

🐛 Bug / Fixes
- Fix `arg-or-default` for id on `<EuiChangesetForm />`

### 0.1.20

🚀 Enhancements

- Adds id to the `<EuiChangesetForm />` and all the underlaying components

### 0.1.19

🐛 Bug / Fixes
- Adds splattributes to `<EuiChangesetForm />`

### 0.1.18

🐛 Bug / Fixes
- Guards for name.length `<EuiAvatar />`

### 0.1.16

🐛 Bug / Fixes
- Adds `@value` to input when controlOnly is `true`
- Adds placeholder and autofocus to changeset fields

### 0.1.15

🐛 Bug / Fixes
- `<EuiGlobalToastList />` Remove padding when empty as expected
- `<EuiChangesetForm />` Rename all fields names for consistency
- - Ej. `<Form.PasswordField />` to `<Form.FieldPassword />`

### 0.1.13

🚀 Enhancements

Addons
- `@ember-eui/pikaday`

### 0.1.12

🚀 Enhancements
- expose hasSubmitted for changeset-form

Components

- `<EuiToast>`
- `<EuiGlobalToastList>`

Services

- `EuiToasterService`

### 0.1.11

🐛 Bug / Fixes
- `<EuiCard />` `<:icon>` block fixes

### 0.1.10

🐛 Bug / Fixes
- Add ember-set-body-class to @ember-eui/core `dependencies`
### 0.1.9

🐛 Bug / Fixes
- EuiOverlayMask bugfixes
### 0.1.7

📝 Documentation
- Minor fixes
### 0.1.6

📝 Documentation
- Revamp/extract docs to include changeset-form addon, we no longer use the dummy app, instead use site.

### 0.1.5

🚀 Enhancements

- Added `<:icon>` named block to `<EuiCard />`

### 0.1.4

🐛 Bug / Fixes

- Fixes lots of named blocks issues with wrapped fields

🚀 Enhancements

- Added `<:title>` and `<:description>` named block to `<EuiCard />`

Components

- `<EuiChangesetForm::Fields::DualRangeSliderField>`

### 0.1.1

`Breaking`: moved project to monorepo. Now you should install from `@ember-eui/core`

🚀 Enhancements

Components

- `<EuiCheckableCard>`

Packages
- Added `changeset-form` inspired by [@frontile/changeset-form](https://github.com/josemarluedke/frontile/tree/master/packages/changeset-form)


### 0.0.57

🐛 Bug / Fixes

- Move `ember-style-modifier` to deps

### 0.0.56

🚀 Enhancements

Components

- `<EuiToolTip>`
- `<EuiToolTipPopover>`
- `<EuiIconTip>`

Dependencies

- - `ember-set-body-class`

🐛 Bug / Fixes

- Remove a few console logs
- Rename a few classes
- Use ts for every component

### 0.0.55

🚀 Enhancements

Components

- `<EuiRangeHighlight>`
- `<EuiRangeInput>`
- `<EuiRangeLabel>`
- `<EuiRangeLevels>`
- `<EuiRangeSlider>`
- `<EuiRangeThumb>`
- `<EuiRangeTicks>`
- `<EuiRangeTooltip>`
- `<EuiRangeTrack>`
- `<EuiRangeWrapper>`
- `<EuiRange>`
- `<EuiDualRange>`

Modifiers

Convert all to Typescript.

- `{{resize-observer}}`
- `{{simple-style}}`
- `{{on-event-simulate-event}}`

Helpers

- `{{cast-to}}`
- `{{create-event}}`
- `{{get-range-tick}}`

New deps

- `ember-style-modifier`
- `lodash-es`

- `<EuiPage>` Support paddingSize prop

🐛 Bug / Fixes

- `<EuiBottomBar>` Use EuiPortal

### 0.0.54

🚀 Enhancements

Components

- `<EuiPopover>`
- `<EuiPopoverFooter>`
- `<EuiPopoverTitle>`
- `<Portal>`

Modifiers

- `{{outside-click-detector}}`
- `{{mutation-observer}}`

🐛 Bug / Fixes

- `<EuiListGroupItem>` Fix DOM structure and styles
- `{{screen-reader-only}}` bugfixes

### 0.0.53

🐛 Bug / Fixes

- Fix Search field demo

### 0.0.52

🚀 Enhancements

- `<EuiBottomBar>`
- `<EuiFieldSearch>`
- `<EuiFilePicker>`

### 0.0.51

🚀 Enhancements

Components

- `<EuiCheckbox>`
- `<EuiCheckboxGroup>`
- `<EuiFieldNumber>`
- `<EuiFieldPassword>`
- `<EuiFieldText>`
- `<EuiFormControlLayoutClearButton>`
- `<EuiFormControlLayoutClearCustomIcon>`
- `<EuiFormControlLayoutDelimited>`
- `<EuiFormControlLayoutIcons>`
- `<EuiFormControlLayout>`
- `<EuiFormErrorText>`
- `<EuiFormFielset>`
- `<EuiFormHelpText>`
- `<EuiFormLegend>`
- `<EuiFormRow>`
- `<EuiForm>`
- `<EuiRadioGroup>`
- `<EuiRadio>`
- `<EuiSelect>`
- `<EuiSwitch>`
- `<EuiTextArea>`
- `<EuiTextArea>`

Helpers

- `{{nullish}}`
- `{{starts-with}}`

Modifiers

- `{{invalidate-indeterminate}}`
- `{{screen-reader-only}}`
- `{{validatable-control}}`

🐛 Bug / Fixes

- `<EuiText>` `@grow` defaults to true
- `<EuiCard>` selectable bugfixes
- Prevent inline style of maxWidth as undefined on modal
- Fix EuiCollapsibleNavGroup title styling

🏠 Internal

- Refactor `class-names` helper for more clarity and perceived performance(?)

### 0.0.50

🚀 Enhancements

- `<EuiListGroup>`
- `<EuiListGroupItem/>`

### 0.0.49

🚀 Enhancements

- `<EuiFlyout>`
- `<EuiCommentList/>`

### 0.0.48

🐛 Bug / Fixes

- Update package.json to ember-svg-jar github:betocantu93/ember-svg-jar#ember-eui-hbs

### 0.0.47

🐛 Bug / Fixes

- Fix default `focus-trap`

### 0.0.46

🚀 Enhancements

- Add `@iconClasses` to buttons

### 0.0.45

🚀 Enhancements

- Add `{{yield}}` to `<EuiButtonIcon>` useful for stuff like adding tooltips or so

### 0.0.44

🐛 Bug / Fixes

- Add missing `{{yield}}` to `<EuiHeaderLink />`

🚀 Enhancements

- Allow defaulting to always use `<Svg/>` component from `ember-svg-jar`, you can still override with `@useSvg={{false}}` to render an icon as img

```ts
config['@ember-eui/core']['eui-icon'].useSvg;
```

### 0.0.43

🐛 Bug / Fixes

- Add missing `{{on "clicks"}}` for `<EuiButton />` around the codebase

### 0.0.42

🚀 Enhancements

- Use `{{on "click"}}` instead of `@onClick` for `<EuiButton />` `<EuiButtonEmpty/>` `<EuiButtonIcon />`

### 0.0.41

🐛 Bug / Fixes

- Add missing colors to `<EuiButtonEmpty />`

### 0.0.40

🚀 Enhancements

- `<EuiTabs />`
- `<EuiTabbedContent />`
- Husky for prettier

### 0.0.39

🚀 Enhancements

- `<EuiSteps />`

### 0.0.38

🚀 Enhancements

- `<EuiProgress />`

### 0.0.37

🚀 Enhancements

- `<EuiLoadingContent />`
- Allow @useSvg to force `<EuiIcon/>` to use `<Svg>` from ember-svg-jar

### 0.0.36

🚀 Enhancements

- Accept `@type` for `<EuiButton />` to avoid a bug with merging `...attributes`

### 0.0.35

🐛 Bug / Fixes

- Change onClick to `@onClick` in most clickable components

### 0.0.34

🏠 Internal

- Added netlify link for opensource

### 0.0.33

🏠 Internal

- Locks @elastic/eui version to 31.0.0
- Updates icon mappings

### 0.0.32

🚀 Enhancements

- Docfy docs
- EuiCollapsibleNav

### 0.0.31

🚀 Enhancements

- Customize focusTrapOptions for `focus-trap` helper inside <EuiModal />

### 0.0.30

🏠 Internal

- Bump ember-svg-jar

### 0.0.29

- Fix inline-styles and <EuiModal /> type with restrictWidth, should be maxWidth

### 0.0.28

- Add ember-in-element-polyfill

### 0.0.27

- Move `ember-keyboard` and `ember-focus-trap` from devDependencies to dependencies

### 0.0.26

- Rename <Text /> component to <TextBlock>

### 0.0.25

- Updates to elastic ui to 31.0.0

### 0.0.24

🚀 Enhancements

- EuiModal

### 0.0.23

🚀 Enhancements

- EuiCallOut may now receive named blocks <:title> </:title> <:body> <:/body>

🏠 Internal

- Installed ember-named-blocks-polyfill

### 0.0.22

🐛 Bug / Fixes

- Renames EuiCallout to EuiCallOut

### 0.0.21

🐛 Bug / Fixes

- Fixes a few missing props for EuiPage, EuiPageBody, EuiPanel and EuiCard
- Fixes EuiHorizontalRule not receiving splattributes

### 0.0.20

🚀 Enhancements

- EuiHr

🐛 Bug / Fixes

- Fix EuiImage close Icon

### 0.0.19

🚀 Enhancements

- Performance for EuiText, EuiColor, EuiCallout, EuiPage, EuiFlexItem and more, reducing usage of element helper
- Text hack to avoid using element helper for simple text dom nodes
- EuiCard

🏠 Internal

- Update ember-svg-jar fork
- Update @elastic/eui to 30.3.0

### 0.0.18

🚀 Enhancements

- EuiFlexGroup
- EuiFlexGrid
- EuiFlexItem

### 0.0.17

🏠 Internal

- Fixes netlify redirects

### 0.0.16

🚀 Enhancements

- EuiBadge
- Use empty icon svg as placeholder while downloading the desired one
- Adds @victor-aguilars to contributors

🏠 Internal

- Update ember-svg-jar fork

🐛 Bug / Fixes

- Add accordion to demo

### 0.0.15

🚀 Enhancements

- EuiSideNav
- EuiAvatar

### 0.0.14

🚀 Enhancements

- EuiCallout

### 0.0.13

🚀 Enhancements

- Updates ember-svg-jar dependency and loads all svgs on demand.

### 0.0.12

🏠 Internal

- Let apps define svgPath in environment.js
  ```ts
    `@ember-eui/core`: {
      svgPath: 'svg/assets'
    }
  ```
  This assumes that you setup ember-svg-jar with the prefix `svg/` (which is the default one)

🐛 Bug / Fixes

- Fixed EuiIcon camelCase svgs

### 0.0.11

🚀 Enhancements

- EuiIcon
- EuiAccordion
- EuiPage
- EuiTitle
- EuiText
- EuiImage
- EuiSpinner
- EuiOverlayMask

🏠 Internal

- Update class-names helper to always concat

### 0.0.7

Update license and add a short description to the readme

### 0.0.6

Support importing only compiled css

```ts
  "@ember-eui/core": {
        "theme": "amsterdam_dark",
        "useCompiledCss": true
    }
```

### 0.0.5

Add ember-cli-sass and app.scss blueprint

### 0.0.4

Expose scss files so you can now use eui sass variables

### 0.0.3

Delete blueprint for now

### 0.0.2

Fix changelog location

### 0.0.1

Support importing custom themes

```ts
  "@ember-eui/core": {
        "theme": "light"
    }

```
