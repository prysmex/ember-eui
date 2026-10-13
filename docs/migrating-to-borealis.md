---
order: 3
title: Migrating to Borealis
---

<EuiPageHeader @pageTitle="Migrating to Borealis" />

<EuiSpacer />

<EuiText>

Ember EUI used to ship EUI 41.4's prebuilt Amsterdam CSS. It now renders
every component with the styles of the current Elastic UI: **EUI 123.1.0**
with the **Borealis 8.1.0** theme (`@elastic/eui-theme-borealis`,
`@elastic/eui-theme-common` 10.1.0). This page explains what changed, how
to upgrade an app, and which defaults and behaviors are different.

Component APIs (arguments, blocks, attributes and modifiers) are kept. Most
of the upgrade is visual: components look like current Kibana/EUI, some
defaults follow upstream, and EUI's legacy modifier classes are gone.

### What changed

**Styles come from upstream.** Each component builds its styles from
upstream EUI's own style factories (extracted from `@elastic/eui@123.1.0`,
pinned and checked against upstream by a parity test) and injects them
with Emotion at runtime, as hashed classes. There is no prebuilt
stylesheet, and the Amsterdam theme CSS is no longer needed: no component
reads it.

**`EuiEmotionProvider` is the root.** Components read the theme from the
nearest `EuiEmotionProvider`:

- The **outermost** provider injects upstream's global styles while it is
  rendered, exactly as upstream `EuiProvider` does by default: the reset,
  a **root font size of 14px** (Borealis' body scale, which upstream `rem`
  sizes are relative to), body colors, focus ring, selection and link
  color. They are removed when it is torn down. `@globalStyles={{false}}`
  opts out. Nested providers (or ones given `@parent`) never inject.
- Every provider wraps its content in `<span class="euiThemeProvider">`
  carrying the mode's paragraph color, so inherited text follows its
  mode, like upstream's nested provider. `@wrapper={{false}}` skips the
  span where an extra element would break a flex or grid layout
  (attributes are forwarded to the span).
- **Light/dark** is the provider's `@colorMode` (`"light"` or `"dark"`).
  Like upstream `EuiProvider`, a root provider left without one follows
  the OS (`prefers-color-scheme`); components rendered without any
  provider use light. Nested providers inherit it, or fix a section to
  the other mode; siblings are isolated.
- **Theme overrides** are `@borealisOverrides`: upstream Borealis token
  modifications, merged into nested providers.
- **High contrast** is `@highContrastMode`: `true` (= `"preferred"`),
  `false` (overrides the OS preference) or `"forced"`, inherited by
  nested providers. Left unset, a root provider follows the OS
  (`prefers-contrast: more`; Windows `forced-colors: active` gives
  `"forced"`, which supersedes app settings, including `@colorMode`).
  High contrast applies upstream's border token modifications.
- **CSS variables.** The root provider publishes the theme's tokens as
  `--eui-*` custom properties (`--eui-color-text-subdued`,
  `--eui-size-s`, …) for plain app CSS. See
  [Theming your own components](/docs/theming).

**`@css` on components.** Migrated components take an `@css` argument
(type `EuiCss`: Emotion's CSS interpolation, an object or a string, or a
theme function `({ euiTheme, colorMode, highContrastMode }) => styles`
like upstream's `css` prop callback; arrays mix them). It is
composed **last into the component's own class**, like upstream's `css`
prop, so your declarations win regardless of stylesheet order. Some
components have slot variants: `EuiPopover` `@panelCss`, `EuiToolTip`
`@anchorCss`, `EuiButton`/`EuiButtonEmpty` `@contentCss`,
`EuiFormControlLayout` `@iconCss`. Use `@css` instead of adding a second
class or a specificity hack to a component: with two Emotion classes, which
one wins depends on insertion order.

**Upstream icon set.** The bundled icons are EUI 123.1.0's (Borealis
artwork, so every glyph looks different from EUI 41): 698 names, 228 of
them new. All 470 previous names still resolve: 111 legacy names are
aliases that render their upstream successor (e.g. `arrowDown` renders
`chevronSingleDown`, `popout` renders `external`, `iInCircle` renders
`info`), and 18 legacy-only assets keep their EUI 41 svg. The 84 names
upstream deprecated still work; `deprecatedIconTypes`, `legacyIconAliases`
and `legacyIconTypes` are exported from
`@ember-eui/core/utils/css-mappings/eui-icon`. The Icons page gallery
hides legacy and deprecated names.

**Performance.**

- Factory output is memoized per resolved theme (like upstream's
  `useEuiMemoizedStyles`), and components cache their class getters, so
  styles are serialized only when an argument or the provider's theme
  changes. Measured: `euiTextStyles` went from 194µs to 0.07µs per call,
  `euiFormControlStyles` from 94µs to 0.04µs.
- The Borealis theme and chroma-js are imported, not inlined, so the
  theme is not bundled twice.
- Icons stay lazy: 698 loaders point at 550 chunks, aliases share their
  target's chunk, and only rendered icons are downloaded.
- Only the outermost provider injects global styles.

### Upgrade step by step

**1. Wrap the app in one root provider**, e.g. in
`app/templates/application.hbs`, and drive `@colorMode` from your theme
state (this site passes the header switcher's choice):

```hbs
{{! app/templates/application.hbs }}
<EuiEmotionProvider @colorMode={{this.colorMode}}>
  {{outlet}}
</EuiEmotionProvider>
```

In `.gjs` / `.gts` files, import it from its module:

```gjs
import EuiEmotionProvider from '@ember-eui/core/components/eui-emotion-provider';
```

Without a provider, components fall back to the default light theme but
no global styles are injected: the page keeps the browser's 16px root, so
every `rem`-based size renders larger than designed. In integration
tests, render inside a provider or assert sizes relative to the root font
size.

**2. Remove the legacy theme stylesheet.** Delete
`import '@ember-eui/core/themes/light.css'` / `dark.css`, any `<link>`
that swaps them at runtime (switch `@colorMode` instead), and classic
`app.import('…/vendor/eui_theme_light.min.css')` lines. The files are
still in the package, but no component needs them, and loading them
fights the new styles: Amsterdam selectors that are more specific
override migrated components (e.g. `.euiFlexGroup .euiFlexItem` beats
`EuiFlexItem @grow={{false}}`). Keep the small extensions stylesheet:

```js
// app/app.js
import '@ember-eui/core/styles/ember-eui.css';
```

**3. Move theme customization to `@borealisOverrides`.** Pass a JS object
of Borealis token modifications; nested providers merge their own on top:

```js
// e.g. on the application controller
get themeOverrides() {
  return {
    border: { radius: { control: '4px', panel: '4px' } },
    colors: { LIGHT: { primary: '#0b64dd' }, DARK: { primary: '#61a2ff' } },
  };
}
```

```hbs
<EuiEmotionProvider
  @colorMode={{this.colorMode}}
  @borealisOverrides={{this.themeOverrides}}
>
  {{outlet}}
</EuiEmotionProvider>
```

Use mode-specific color overrides (`colors.LIGHT` / `colors.DARK`): a flat
color override loses to Borealis' mode-specific values. Overriding
`size.base` does not re-derive the other sizes; override each size you
need.

**4. Replace CSS that targeted legacy classes.** Rules on Amsterdam
modifier classes (`euiButton--primary`, `euiFlexGroup--gutterLarge`,
`euiPanel--paddingMedium`, …) no longer match anything. Pass an argument
or `@css` instead (see [Legacy classes](#legacy-classes)).

**5. Dark sections.** Nest a provider rather than relying on `ghost`
colors, which now map to the themed `text` tokens:

```hbs
<EuiEmotionProvider @colorMode="dark" @wrapper={{false}}>
  <EuiButton @color="text">On a dark surface</EuiButton>
</EuiEmotionProvider>
```

`EuiBottomBar` and `EuiControlBar` already render in a nested dark
provider; `EuiHeader @theme="dark"` styles its own links and buttons but
does not nest one, so other children (an `EuiButton`, an `EuiBadge`) keep
the surrounding mode.

**6. Review the changed defaults below**, and pass the old value
explicitly where your layout depends on it (e.g. `@gutterSize="l"`,
`@size="m"`, `@hasShadow={{true}}`).

**7. Icons.** Legacy names keep working, so nothing breaks; prefer the
upstream names in new code. An icon registered by name in the
`euiIcon.icons` config now **wins** over an EUI icon of the same name (EUI
123 added common names such as `rocket`, `copy`, `return` and `send`; before,
EUI's icon silently shadowed yours).

**8. Deprecations.** Components that upstream removed log a deprecation
in development (see [Deprecations](#deprecations)). Plan their
replacement before 16.0.0.

### Changed defaults and behaviors

Collected from the migration of every component family. "Not stated"
means the previous value was not recorded.

#### Foundation and typography

| Component | Change | Before | Now |
| --- | --- | --- | --- |
| Global styles | Reset, root font size, body colors, focus ring, selection, link color | Not stated | Injected by the outermost `EuiEmotionProvider`; root font size 14px |
| `EuiEmotionProvider` | Root provider without `@colorMode` / `@highContrastMode` | `light` / `false` | Follows the OS (`prefers-color-scheme`, `prefers-contrast`, `forced-colors`), as upstream `EuiProvider`; pass the value to pin it |
| `EuiEmotionProvider` | High contrast border tokens | Unchanged | Upstream's high contrast modifications: borders use the text colors / plain dark (light) or plain light (dark) |
| `EuiText` | Default `@size` | `m` | `s` |
| `EuiText` | DOM with `@color` / `@textAlign` | Nested `EuiTextColor` / `EuiTextAlign` wrappers | A single `.euiText` element; without `@color` the color is inherited |
| `EuiTextAlign` | Alignment | Physical | Logical: `left` / `right` serialize to `start` / `end` and flip in RTL |
| `EuiTextColor` | `primary` | Upstream color | Kept as an Ember extension mapped to `textPrimary`; custom colors use a class, never your `style` |
| `EuiHealth` | Default `@textSize` | `m` | `s` |

#### Color palettes

| Component | Change | Before | Now |
| --- | --- | --- | --- |
| `euiPaletteColorBlind` | Colors | Amsterdam set (`#54B399`, `#6092C0`, …) | Borealis vis colors (`#16C5C0`, `#A6EDEA`, `#61A2FF`, …); `useEuiPaletteColorBlind(context)` follows high contrast |
| `euiPaletteColorBlindBehindText` | Colors | Base palette brightened by 0.5 | Same as `euiPaletteColorBlind` (upstream) |
| `euiPaletteForStatus`, `euiPaletteForTemperature`, `euiPaletteCool`, `euiPaletteWarm`, `euiPaletteGray` | Colors | Amsterdam gradients | Gradients between the Borealis vis colors (success, warning, danger, cool, warm, grey); 1 step returns a vis color |
| `euiPaletteComplementary` | New name and colors | `euiPaletteComplimentary`: blue to orange | Borealis complementary vis colors through the base color; `euiPaletteComplimentary` is a deprecated alias (until 16.0.0) |
| `euiPaletteNegative`, `euiPalettePositive`, `euiPaletteForLightBackground`, `euiPaletteForDarkBackground` | Removed upstream | Available | Deprecated until 16.0.0 with unchanged values; use `euiPaletteRed`, `euiPaletteGreen`, `euiPaletteColorBlind` |
| `euiPalette*` | `@colors` option and theme-aware functions | Not available | `euiPaletteX(steps, { colors })`; `useEuiPaletteX(context, …)` with `getEuiThemeContext(this).upstream` |
| `EuiColorPicker` | Default `@swatches` | Amsterdam color-blind palette | Theme's vis colors (`useEuiPaletteColorBlind`) |

#### Layout

| Component | Change | Before | Now |
| --- | --- | --- | --- |
| `EuiPanel` | `@hasShadow` / `@hasBorder` | `true` / unspecified | `false` / `true` (border drawn on `::after`; only plain/transparent colors in normal contrast) |
| `EuiPageContent` | Panel defaults | Shadow | Inherits Panel's: no shadow, border |
| `EuiHorizontalRule` | Default `@margin` | Not stated | `m` (16px) |
| `EuiFlexGroup` | Default `@gutterSize` | `l` | `m` (16px) |
| `EuiFlexGroup` | `xl` gutter | 32px | 40px |
| `EuiFlexGroup` | Gutters | Negative margins and item padding | CSS `gap` |
| `EuiFlexGroup` | Responsive | Not stated | Below 768px the group wraps and items become 100% wide (never for column directions) |
| `EuiFlexGrid` | Default `@columns` | `0` | `1` (`0` still accepted) |
| `EuiPage` | Default `@paddingSize` | `m` | `none` |
| `EuiPage` | Minimum height | Inline `min-height: 460px` | None (`EuiPageTemplate` still sets `@minHeight`) |
| `EuiPageBody` | `@paddingSize` when `@panelled` | `l` | `none` |
| `EuiPageBody` | Unrestricted `max-width` | `none` | `100%` |
| `EuiPageHeader` | Default `@alignItems` | `top` / `center` | `stretch` (`center` with only a default block) |
| `EuiPageHeader` | `@restrictWidth` | Limits the `<header>` | Limits and centers `.euiPageHeaderContent` |
| `EuiPageSideBar` | Default `@paddingSize` | `l` | `none` |
| `EuiBottomBar` | Default `@top` | `0` | None, so sticky bars stick to the bottom |
| Page components | `@restrictWidth={{true}}` | A class | Inline `max-width: 1200px` with `margin-inline: auto` |
| `EuiResizablePanel` | `@hasBorder` | No such argument | `false` (not Panel's new `true`) |
| `EuiPageTemplate` | `T.BottomBar` position | Rendered where it is placed in the default block | At the end of the main element wherever it is placed (upstream portals it there) |

#### Display

| Component | Change | Before | Now |
| --- | --- | --- | --- |
| `EuiBadge` | Named colors | Solid vis colors | Light base fill, as upstream; `@fill={{true}}` for solid |
| `EuiBadge` | `default` color | `#d3dae6` | Upstream light badge (`backgroundLightText`) |
| `EuiBadge` | Icon size | `m` for icon-only badges | Always `s` (12px) |
| `EuiBadge` | Clickable badge with `@iconType` | Inner `euiBadge__childButton` | The whole badge is the `<button>` / `<a>` (child button only with `@iconOnClick`) |
| `EuiBadge`, `EuiBetaBadge` | Links | Not stated | `rel` always has `noreferrer` (plus `noopener` for `_blank`) |
| `EuiBadge` | Attributes with `@iconOnClick` and `@onClick` / `@href` | On the outer `<span>` | On the text `<button>` / `<a>`; `class` and `style` stay on the `<span>` (upstream `...rest`) |
| `EuiBetaBadge` | Clickable badge with `@tooltipContent` | Rendered twice | Rendered once, inside the tooltip |
| `EuiIcon` | Unlabelled icon | `aria-hidden="true"` and `role="image"` | `role="presentation"`, no `aria-hidden` |
| `EuiIcon` | Labelled icon | `role="image"` | `role="img"` (pass the label as `@aria-label`, not as an attribute) |
| `EuiIcon` | Custom color | Inline `fill` | `color` + `fill: currentColor` through a class; no `color` attribute on the svg |
| `EuiToken` | Presets | Amsterdam vis colors | Borealis' even vis colors (49 presets differ); `tokenRepo` / `tokenSymbol` / `tokenFile` are light squares |
| `EuiAvatar` | Default background | Amsterdam palette | `colors.vis[name.length % 10]`; initials uppercase for users |
| `EuiImage` | `@hasShadow` | `true` | `false` |
| `EuiImage` | Attributes (`class`, `style`, `data-test-subj`…) | On the `<figure>` | On the `<img>` and the full screen `<img>`, as upstream's rest props; the figure takes `@wrapperProps` (other keys become attributes) |
| `EuiProgress` | `@valueText={{true}}` | `{value}` | `{value}%` |
| `EuiCallOut` | Title element | `<span>` | `<p>` (an `EuiTitle`) |
| `EuiCallOut` | `@iconSize` | `m` | `l` (`m` for size `s`) |
| `EuiCallOut` | Default icon | Only with a title and `@iconType` | Always a color icon (`infoFill`, `checkCircleFill`, `warningStatic`, `errorFill`) |
| `EuiEmptyPrompt` | `@hasBorder` | Panel's `true` | Only for `@color="plain"` |
| `EuiEmptyPrompt` | Grow | `true` | `false` |
| `EuiEmptyPrompt` | Title to body spacing | `m` (16px) | `s` (8px) |
| `EuiEmptyPrompt` | `@actions` | Group only for two or more | Always `.euiEmptyPrompt__actions`, even for one |
| `EuiCard` | `@titleElement` | `span` / `h2` | `p` (or `span`); it is the title element itself |
| `EuiCard` | Border | Added by `@display` | None; any `@display` removes the shadow |
| `EuiCard` | Interaction | The card is `role="button"`, `tabindex=0` | A surface click clicks the title link/button, the only focusable control; clicks on nested interactive content are not forwarded |
| `EuiCard` | Image `alt` | `"card-top"` | `""` |
| `EuiCardSelect` | Button | `xs` `EuiButtonEmpty` | Full-width `m` `EuiButton` |
| `EuiCodeBlock` | `<pre>` `tabindex` | `1` | `-1`, or `0` when it overflows |
| `EuiCodeBlock` | Copy | Rendered `innerText`, blank lines collapsed; `copyClipboard` icon | The trimmed source with blank lines (rich content: the rendered `innerText`, blank lines collapsed); `copy` icon; button only when there is text |
| `EuiCodeBlock` | Markup in the block | Flattened to its text and highlighted | Rendered as-is, without highlighting, line numbers or virtualization; only text, or one `<pre>`/`<code>` wrapper around text, is highlighted |
| `EuiTreeView` | `aria-expanded` | On every node | Only on nodes with children |
| `EuiTabbedContent` | Unknown keys of a tab object | Ignored | Set as attributes of the tab (e.g. `data-test-subj`, `aria-label`) |
| `EuiExpression` | `@isInvalid` | Whole expression danger | Only the description turns danger |

#### Buttons and links

| Component | Change | Before | Now |
| --- | --- | --- | --- |
| `EuiLink` | Default `@color` | `primary` | `text` (paragraph color, primary on hover/focus, dotted underline) |
| `EuiLink` | `rel` | Not stated | Always `noreferrer` (plus `noopener` for `_blank`): same-origin links send no `Referer`; `@rel` merges, a `rel` attribute replaces |
| `EuiLink` | External icon | Labelled "External link" | Decorative; screen-reader text "(external, opens in a new tab or window)" or "(external)" |
| `EuiLink` | `@target="_blank" @external={{false}}` | New-tab note read | No icon and no screen-reader text |
| `EuiButton`, `EuiButtonEmpty`, `EuiButtonIcon` | `ghost` color | White | Themed `text` tokens; use a dark provider on dark surfaces |
| `EuiButton` | `@isSelected={{false}}` | No attribute | `aria-pressed="false"` |
| `EuiButtonIcon` | `aria-pressed` | Always `"false"` | Omitted unless `@isSelected` is set; never on links |
| `EuiButtonEmpty`, `EuiButtonIcon` | `@disabled` with `@href` | Ignored | Renders a disabled `<button>` (no `href` / `target`) |
| `EuiButtonIcon` | Missing label | Silent | `console.warn` without `aria-label` / `aria-labelledby` |
| Buttons | Unknown `@color` | Unstyled | Primary |
| `EuiButtonGroup` | Markup | Rendered through `EuiButton` | Own `euiButtonGroupButton` markup; default color `text` |
| `EuiFilterButton` | Markup | A `<button>` | Wrapped in `div.euiFilterButton__wrapper`; `__textShift` renamed `__text` |
| `EuiFilterSelectItem` | `aria-selected` | From `@isFocused` | From `@checked === 'on'` |
| `EuiFacetGroup` | Root | An `EuiFlexGroup` | A plain `div.euiFacetGroup` |

#### Forms

| Component | Change | Before | Now |
| --- | --- | --- | --- |
| `EuiFormRow` | Width | Not stated | Capped at 400px unless `@fullWidth` (which now defaults from `EuiForm @fullWidth`) |
| `EuiDescribedFormGroup` | Width | Not stated | Capped at 800px unless `@fullWidth` |
| `EuiDescribedFormGroup` | Default `@titleSize` | `m` | `xs` |
| `EuiFormRow` | `@display="rowCompressed"` | Compressed row | Same as `row` (upstream deprecated it) |
| Text controls, `EuiSelect`, `EuiTextArea` | Width | Not stated | `max-width: 400px`, `width: 100%` (`@fullWidth` 100%); 40px tall, 32px compressed |
| Form controls | Icon size in compressed controls | `s` | Always `m` |
| Form controls | `@isInvalid` | Not stated | Sets `aria-invalid="true"` and shows a warning icon |
| `EuiForm` | Error callout | Never focused | `tabindex="-1"`, focused when the form becomes invalid with errors (including the first render) and `@invalidCallout="above"`; not on re-renders or when valid |
| `EuiFieldNumber` | Default `@step` | Browser default `1` | `'any'` |
| `EuiFieldSearch` | `type` | `"text"` | `"search"` |
| `EuiFieldPassword` | Toggle | `tabindex=-1` | Focusable, labelled, disabled with `@disabled`; `@readOnly` sets `readonly` |
| `EuiCheckbox`, `EuiRadio` | `@compressed` | Compressed control | No effect (deprecated); `EuiCheckbox @icon` too |
| `EuiCheckboxGroup`, `EuiRadioGroup` | `@compressed` | Row gap 4px, forwarded to items | Row gap 0, not forwarded |
| `EuiCheckboxGroup`, `EuiRadioGroup` | With `@legend` | Attributes dropped | Class and attributes on the `EuiFormFieldset` |
| `EuiSwitch` | `.euiSwitch__track` / `__icon` | Present | Replaced by `.euiSwitch__body` / `__icons` / `__thumb` |
| `EuiComboBox` | Width | Stretched to its container | Form width (400px) unless `@fullWidth` |
| `EuiComboBox` | `euiComboBoxOptionsHeight` config | 33 | 29 |
| `EuiComboBox` | Pills | `default` badge | `hollow` badge |
| `EuiComboBox` | Options | `button.euiFilterSelectItem`, tab stops | `div.euiComboBoxOption[role=option]`; focus stays in the input |
| `EuiComboBox` | Placeholder | `p.euiComboBoxPlaceholder` | The input's native `placeholder` |
| `EuiComboBox` | Dropdown z-index | Global `:root` variable in `ember-eui.css` | Set on the combo box's own content element; app-owned ember-basic-dropdowns no longer get 99999 |
| `EuiComboBox` | Default matching | Ignores case and accents (ember-power-select) | Upstream: ignores case only (`@isCaseSensitive`, `@matcher`, `@optionMatcher` customize it) |
| `EuiComboBox` | Selected options, multiple selection | Listed, marked selected; choosing one again removed it | Not listed (matched by label and `key`, like upstream) |
| `EuiComboBox` | After a choice, multiple selection | List closed | List stays open, next option highlighted (`@closeOnSelect` defaults to single selection only) |
| `EuiComboBox` | Typed text on blur | Kept only with `@noSuggestions` / `@delimiter`, else cleared | Added (`@onCreateOption`, or the option it names); otherwise kept and marked invalid |
| `EuiComboBox` | Enter without a highlighted option | Closed the list (created only without matches) | Adds the typed text (`@onCreateOption`, or the only exact match); the list stays open in multiple selection |
| `EuiComboBox` | Highlight when the list opens | First option (its tooltip shown) | None, except single selection's option on click; the arrows wrap and start at either end; hover no longer highlights |
| `EuiComboBox` | Keys | Escape cleared the text; Tab chose nothing and left; Backspace opened the list | Escape keeps the text; Tab is held while an option is highlighted; Backspace only reopens single selection's list (plain text: also deletes one character) |
| `EuiComboBox` | `@sortMatchesBy="startsWith"` with groups | Sorted within each group | Sorts the whole list, group titles included (upstream) |
| `EuiComboBox` | Empty list messages | "No results found" | Upstream: "{searchValue} doesn't match any options", "There aren't any options available", "You've selected all available options", "{label} has already been added" (`@noMatchesMessage` still wins) |
| `EuiComboBox` | Focus | Opened on click or typing | Focusing the input opens the list |
| `EuiComboBox` | Accessibility | Wrapper `role="combobox"`, a tab stop with the label | The input is the combobox (`aria-expanded`, `aria-controls` while open, `aria-haspopup`); the listbox is labelled; screen reader instructions on focus |
| `EuiComboBox` | Enter badge on the highlighted option | Always | Only with `@onFocusBadge` |
| `EuiComboBox` | Pressing the chevron | Decorative icon; focus stayed in the input | `comboBoxToggleListButton` takes focus, as upstream: closing the list leaves focus on it (arrows reopen and move, Escape closes), opening focuses the input; leaving from it closes the list and adds the typed text |
| `EuiComboBox` | `@onBlur`, focus moving inside the combo box (chevron, clear or pill button) | Called on every input blur | Called only when focus leaves the combo box; moving inside clears the highlighted option (upstream `onContainerBlur`) |
| `EuiComboBox` | Pills | Only the option's `color` | The option's other keys become attributes of the pill (`data-test-subj`, `id`, `aria-*`, `className`; plain objects without `@searchField`), `title` is the label, and an `onClick` makes a "Change" button pill without the remove button (upstream `renderPills`) |
| `EuiSuperSelect` | Options | `EuiContextMenuItem` buttons | `button.euiSuperSelect__item[role=option]`; arrows no longer wrap; Tab chooses |
| `EuiSelectable` | Focusing the search field | The first checked (or first) option became current | Nothing is current until a key: arrows start at the top/bottom, other keys and searches pick the first checked option (upstream `onFocus`) |
| `EuiSelectable` | Unknown `@searchProps` keys | Ignored | Set as attributes of the search `<input>` (upstream spreads them onto EuiFieldSearch) |
| `EuiSelectable` | `aria-label` / `aria-describedby` attributes | On the root `<div>`; the search and list were labelled with the placeholder | Moved to the search and the listbox (upstream `getAccessibleName`; `@searchProps` / `@listProps` keys win); the fallback label is "Filter options", not a custom placeholder |
| `EuiRange` | Slider with `@showInput` | `aria-hidden` only for `true` | `aria-hidden`, `tabindex=-1` for any `@showInput`, including `"inputWithPopover"` |
| `EuiDualRange` | Popover class | `euiRange__popover` | `euiDualRange__popover` |
| `EuiFilePicker` | Default `@display` | `''` | `default` (clear button or spinner); `"none"` is a deprecated alias |
| `EuiFilePicker` | Clear button label | "Clear selected files" | "Remove selected files" |
| `EuiFilePicker` | Prompt icon | `importAction` | `upload` |
| `EuiFormControlLayoutDelimited` (`EuiDatePickerRange`, `EuiDualRange`, `EuiSuperDatePicker`) | Default delimiter | `→` text | `sortRight` icon labelled "to" (`euiFormControlLayoutDelimited.delimiterLabel`); `@delimiter` still wins |
| `EuiColorPalettePicker` | Option dividers | Shown | None |
| `EuiHue` | `@hue={{0}}` | Replaced by 1 | Kept as 0 |
| `EuiColorStops` | `@stopType="fixed"` | Blended | Holds each color until the next stop; area before the first stop is transparent |
| `EuiDatePickerRange` | Default `@iconType` | No icon | `true` (calendar icon first; `@iconType={{false}}` for the old look) |
| `EuiSuperDatePicker` | Root | `EuiFlexGroup .euiSuperDatePicker__flexWrapper` | `div.euiSuperDatePicker`; restricted width 600px (480px without the update button) |
| `EuiSuperDatePicker` | Start/end date button title | `title` attribute | An `EuiToolTip` (hover/focus); screen readers get it only when invalid or needing an update |
| `EuiSuperDatePicker` | Time zone display | `div` label; inputs described only while a zone shows | `span` label (`EuiText @component`); the date inputs always point `aria-describedby` at the display id |
| `EuiSuperUpdateButton` | `@fill` / pending icon | Not stated / `kqlFunction` | `true` / `push` |
| `EuiRefreshInterval` | Toggle | Start/Stop `EuiButton` | Compressed `EuiSwitch` ("Refresh every"); fields disabled while paused |

#### Overlays

| Component | Change | Before | Now |
| --- | --- | --- | --- |
| `EuiPopover` | Default `@anchorPosition` | `downCenter` | `downLeft` |
| `EuiPopover` | Default `@hasArrow` | `true` | `false` |
| `EuiPopover` | Arrow | 24px | 16px wide; bordered in dark and high contrast |
| `EuiPopover` | Panel | An `EuiPanel` | A `div.euiPanel.euiPopover__panel`; anchor gets `aria-expanded` / `aria-controls` |
| `EuiPopoverTitle`, `EuiPopoverFooter` | Padding | Not stated | The popover's `@panelPaddingSize` (`l` outside a popover) |
| `EuiToolTip` | Effective delay | 250ms | About 400ms (JS delay plus upstream's 150ms CSS delay) |
| `EuiToolTip` | Anchor | `role="tooltip"` | No role; the anchored element gets `aria-describedby` while visible; one tooltip at a time |
| `EuiContextMenu` | Separator margin | `none` | `xs` |
| `EuiContextMenuItem` | Default `@color` | Not stated | `text` |
| `EuiContextMenuPanel` | Title | A whole `button` | `div` with a back `EuiButtonIcon` and an `h2` |
| `EuiModal` | Default `@maxWidth` | Not stated | `true`: capped at 768px, minimum 400px |
| `EuiModal` | Focus trap / Escape | Escape: global ember-keyboard handler | `allowOutsideClick: true`, `escapeDeactivates: false`; Escape only from inside the modal |
| `EuiConfirmModal` | Role | Not stated | `alertdialog`; `@title` in an `<h1>` |
| `EuiFlyout` | `tabindex` | `-1` | `0` (with `data-autofocus`) when not pushed |
| `EuiFlyout` | Mask click | Always closes | Closes unless `@outsideClickCloses={{false}}` |
| `EuiFlyout` | Mask | Parent of the flyout | Sibling of the portalled flyout |
| `EuiFlyout` | Pushed flyout | Closes on Escape | Ignores Escape; no dialog role unless `@role` |
| `EuiFlyout` | Pushed standard flyout nested in a managed (session) flyout | n/a (new in 15) | Does not pad the page: only the active session's flyouts push (upstream `shouldPush`) |
| `EuiSelectable` | Multiple selection | Check marks, `aria-selected` | Checkbox indicators, `aria-checked` |
| `EuiSelectable` | `listProps.onFocusBadge` | `true` | `false` |
| `EuiSelectableTemplateSitewide` | Row height / popover padding | 68 / `none` | 52 / `s` |

#### Navigation

| Component | Change | Before | Now |
| --- | --- | --- | --- |
| `EuiBreadcrumbs` | Default `@responsive` | Off | `{ xs: 1, s: 2, m: 4 }` (`@responsive={{false}}` for the old behavior) |
| `EuiBreadcrumbs` | Link color | Last clickable crumb `text` | Every crumb `subdued` |
| `EuiPagination` | `@responsive` | None | `['xs', 's']`: compressed below `m` (`false` disables) |
| `EuiPagination` | Arrow labels | "Previous page, {n}" / "Next page, {n}" | "First / Previous / Next / Last page" |
| `EuiPagination`, `EuiTablePagination` | Active page | `aria-current="true"` | `aria-current="page"` |
| `EuiTabs` | Keyboard | No arrow-key navigation | Roving tabindex; ArrowLeft/Right move focus; `xl` is an alias of `l` |
| `EuiStep` | `@step` | Required | Optional, default 1 |
| `EuiHeaderLinks` | Default `@gutterSize` / `@panelPaddingSize` | `xs` / `none` | `s` / `s` |
| `EuiHeaderLink` | Size | `m` (not forwarded) | `s` |
| `EuiHeaderSectionItemButton` | Badge becomes a dot | Below `xs` | Below `m` (CSS) |
| `EuiHeaderSectionItem` | Dividers / `@border` | Shown | Gone (deprecated, no effect) |
| `EuiHeader` | `@position="fixed"` | Not stated | Stacks fixed headers; sets `--euiFixedHeadersOffset` and pads the body |
| `EuiSideNav` | Section items with children | Not toggleable | Accordion buttons with `aria-expanded` |
| `EuiListGroup` | Default `@maxWidth` | Not stated | `true` (400px); `@maxWidth={{false}}` to fill wide containers |
| `EuiListGroupItem` | Default color | `inherit` | `text` |
| `EuiListGroup` | `@wrapText` | n/a (new in 15) | Applies to `@listItems` only; items in the block set their own `@wrapText` (upstream) |
| `EuiListGroupItem` | Block label (`{{yield}}`) | No `title`, no tooltip content | Its text is the `title` when truncated (no wrap, no tooltip) and its content is the tooltip without `@toolTipText` (upstream node `label`) |
| `EuiKeyPadMenuItem` | `aria-pressed` | Always `"false"` | Omitted unless `@isSelected` is set |

#### Tables

| Component | Change | Before | Now |
| --- | --- | --- | --- |
| `EuiTablePagination` | Default `@itemsPerPage` | 50 | 10 |
| `EuiTablePagination` | Default `@itemsPerPageOptions` | `[10, 20, 50, 100]` | `[10, 25, 50]`; `0` means all rows |
| `EuiTableRowCell` | Long words | Not stated | Break unless `@truncateText` |
| `EuiTable` | Markup | `<table>` | Wrapped in `div.euiTable__wrapper` (attributes stay on the table) |
| `EuiTable` | Mobile cards | Both layouts rendered, hidden with classes | JS-driven below the theme's `m` breakpoint; mobile headers render only in cards |
| `EuiTableRow` | `@onClick` | Toggling replaced the element | Always one `<tr>` |
| `EuiTableHeaderCell` | `aria-sort` | Not stated | `none` on sortable unsorted columns |

#### Feedback

| Component | Change | Before | Now |
| --- | --- | --- | --- |
| `EuiToast` | Default `@color` | `none` | `primary`; a default icon is always shown |
| `EuiGlobalToastList` | Role | `region` | `log` |
| `EuiGlobalToastList` | Clear all | None | "Clear all" from 3 toasts (`@showClearAllButtonAt`) |
| `EuiAccordion` | Content role | `region` | `group` |
| `EuiAccordion` | Opening | Focuses the content region | Focus stays on the button |
| `EuiAccordion` | Loading message | "Loading..." | "Loading" |
| `EuiCommentList` | Element | `div` | `<ol>`; comments are `<li>` |

#### Editors

| Component | Change | Before | Now |
| --- | --- | --- | --- |
| `EuiMarkdownFormat` | Links | Raw `euiLink--primary` anchors | `EuiLink` (`text` color, `rel="noreferrer"`) |
| `EuiMarkdownEditor` | Height | Footer-height taller than `@height` | Footer height subtracted |
| `EuiMarkdownEditor` | Toolbar tooltip delay | `long` | Default |
| `EuiMarkdownEditor` | Help button | Unlabelled | "Show markdown help" |

#### Utilities and icons

| Component | Change | Before | Now |
| --- | --- | --- | --- |
| `EuiScreenReaderOnly` | Show on focus class | `euiScreenReaderOnly--showOnFocus` | `euiScreenReaderOnly-showOnFocus` |
| `EuiLoadingChart`, `EuiLoadingElastic`, `EuiLoadingLogo`, `EuiLoadingContent` | Semantics | Not stated | `role="progressbar"`, `aria-label="Loading"` |
| `EuiOverlayMask` | Header position | `--aboveHeader` / `--belowHeader` classes | `data-relative-to-header` |
| `EuiResizableContainer` | Collapse button | `euiResizableToggleButton`, filled while open | `euiResizableCollapseButton`, an empty `EuiButtonIcon` |
| `EuiIconTip` | Default icon | `questionInCircle` | `question` |
| `EuiCallOut`, `EuiToast` | Default icons | `iInCircle`, `checkInCircleFilled`, `warning`, `error` | `infoFill`, `checkCircleFill`, `warningStatic` (own two tones), `errorFill` |
| `EuiFieldSearch`, `EuiFieldPassword` | Icons | `search`, `eyeClosed` | `magnify`, `eyeSlash` |
| Dropdown arrows, pagination, accordion, side nav, tree view | Icons | `arrowDown`, `arrowLeft`, `arrowRight`, … | `chevronSingle*` / `chevronLimit*` |
| `EuiMarkdownEditor` toolbar | Icons | `editorBold`, `editorItalic`, … | `textBold`, `textItalic`, `listBullet`, `listNumber`, `listCheck`, `code`, `link` |
| `euiIcon.icons` config | Name clash with an EUI icon | EUI's icon wins | Your icon wins |

### Legacy classes

Migrated components keep their stable root and element classes
(`euiButton`, `euiFlexItem`, `euiCard__title`, `euiPopover__panel`, …),
but **every Amsterdam modifier class is gone**: color, size, padding,
gutter, state and layout variants such as `euiButton--primary`,
`euiFlexGroup--gutterLarge`, `euiPanel--paddingMedium`,
`euiLink--subdued` or `euiTab-isDisabled`. Components are styled by
hashed Emotion classes instead. If your CSS, tests or scripts select on
those classes:

- **Style** with the component's arguments or `@css` (and `@panelCss`,
  `@anchorCss`, `@contentCss`, `@iconCss`).
- **Select state** through ARIA and data attributes: `aria-current`,
  `aria-pressed`, `aria-checked`, `aria-expanded`, `data-step-status`,
  `data-position`, `data-collapsed`, `data-type`,
  `data-relative-to-header`, `data-test-subj`.
- **Assert visuals** in tests with computed styles (`flex-grow`,
  `max-width`, `position`, colors) rather than class names.

Renamed or replaced hooks worth knowing:

| Old | Use instead |
| --- | --- |
| `euiPanel` variant classes | Root `euiPanelBorealis` / `[data-eui-panel]` |
| `euiFilePicker--hasFiles` | `euiFilePicker-hasFiles` |
| `euiCallOut--small` | `[data-size="s"]` |
| `.euiCallOut .euiText` | `.euiCallOut__additionalContent` |
| `.euiComboBoxOptionsList button.euiFilterSelectItem` | `.euiComboBoxOptionsList .euiComboBoxOption[role="option"]` |
| `euiAccordion__iconButton` | `euiAccordion__arrow` |
| `.euiToast__closeButton` | `[data-test-subj="toastCloseButton"]` |
| `euiMarkdownEditor--isPreviewing` | `euiMarkdownEditor-isPreviewing` |
| `euiResizablePanel--first` / `--last`, `-isCollapsed` | `[data-position]`, `[data-collapsed="true"]` |
| `euiDraggable__item--isDisabled` | `euiDraggable__item-isDisabled` |
| `euiDatePickerRange__delimeter`, `euiFormControlLayoutDelimited__delimeter` | `euiFormControlLayoutDelimited__delimiter` |
| `euiFormControlLayoutIcons--right` | Select icon groups by order |
| `euiSideNavItemButton--hasChildItems` | `-hasChildItems` |
| `euiFilterButton__textShift` | `euiFilterButton__text` |
| `euiStepNumber--<status>` | `[data-step-status]` |
| `euiCommentEvent--*`, `euiCommentTimeline*` | `.euiCommentEvent[data-type]`, `.euiCommentAvatar svg[data-icon-type]` |

Some wrapper elements are gone too: `euiModal__flex` (header, body and
footer are direct children of the modal), the modal and flyout close
button wrappers, `euiFilePicker__wrap`, the `EuiCallOut` header wrapper,
the toast header wrapper and the `EuiTreeView` text wrapper. A hard-coded
`class="euiScreenReaderOnly"` gets no styles any more: use
`EuiScreenReaderOnly` or the `euiScreenReaderOnlyClass(context, showOnFocus)`
export of `eui-screen-reader-only`.

### Deprecations

Components that Elastic UI removed upstream keep working, but log an
Ember deprecation in development (once per rendered instance, stripped in
production) and will be removed in **16.0.0**. Ids have the form
`ember-eui.<file>.removed-upstream` (since 15.0.0); add them to your
deprecation workflow while you migrate.

| Component | Deprecation id | Use instead |
| --- | --- | --- |
| `EuiNotificationEvent` (and its messages, meta, read button and read icon) | `ember-eui.eui-notification-event.removed-upstream` (one id per part) | Compose `EuiPanel`, `EuiTitle`, `EuiText` and `EuiContextMenu` |
| `EuiSuggest` (and `EuiSuggestInput`, `EuiSuggestItem`) | `ember-eui.eui-suggest.removed-upstream` (one id per part) | `EuiSelectable` or `EuiComboBox` |
| `EuiColorStops` (and its thumbs) | `ember-eui.eui-color-stops.removed-upstream` (thumbs: `eui-color-stops-thumb`) | No direct replacement; `EuiColorPalettePicker` for predefined gradients |
| `EuiControlBar` | `ember-eui.eui-control-bar.removed-upstream` | `EuiBottomBar`, or a bar composed with `EuiFlexGroup` and `EuiTabs` |
| `EuiPageTemplate` legacy API (`@template`, `@pageHeader`, `@page…Props`, `@bottomBarProps`, `@fullHeight`, the `<:pageSideBar>`, `<:pageHeader…>` and `<:bottomBar>` blocks) | `ember-eui.eui-page-template-legacy.removed-upstream` | The composable API: `<EuiPageTemplate as \|T\|>` with `T.Header`, `T.Section`, `T.EmptyPrompt`, `T.BottomBar`, and `T.Sidebar` in a `<:sidebar as \|T\|>` block |

Arguments that no longer do anything are marked deprecated in the
signatures and API reference (no runtime warning), e.g. `EuiCheckbox` /
`EuiRadio` `@compressed`, `EuiCheckbox @icon`, `EuiCardSelect @flush`,
`EuiStat @screenReader` / `@isColorClass`, `EuiComment @type`,
`EuiHeaderSectionItem @border`, `@size` / `@flush` / `@gutterSize` on list
groups, `@size` on context menus, `EuiPaginationButton @paddingSize` /
`@hideOnMobile`, `EuiSuperSelect @screenReaderId`,
`EuiFormControlLayoutDelimited @useGroup`, `EuiLoadingChart @mono` and
`EuiTablePagination @hidePerPageOptions` (alias of `@showPerPageOptions`).

### Known gaps

Upstream features that are not ported yet (the Ember API keeps working
as before):

- **Popover**: initial focus on the panel itself, `panelProps`,
  `focusTrapProps` and `onPositionChange`.
- **Combo box**: `inputPopoverProps` and `inputRef`. It keeps
  ember-power-select; its input sizes with `field-sizing: content`, which
  Firefox does not support yet, so there the input may wrap below the pills
  earlier.
- **Tooltips** on pagination arrows, color picker swatches and the
  hue/saturation controls; the avatar uses a native `title`.
- **Forms**: `EuiTextArea` icons, loading state and clear button; the error
  callout shows only when there are errors.
- **Header**: `EuiHeaderLogo` `logoType="horizontal"` and
  `EuiCollapsibleNavBeta`.

Other things to know:

- `EuiPortal` content (modals, flyouts, popovers) does not carry the
  nearest provider's color class; modals and flyouts set their own text
  color.
- A provider with a custom Emotion cache container (e.g. a shadow root)
  does not receive the screen-reader-only modifier's styles.
- The removed-upstream deprecations fire per instance, so pages with many
  notification events or suggest items log many lines in development.
- Server-side rendering (FastBoot) style extraction and hydration were a
  release gate of the migration and are not covered by this guide.

</EuiText>
