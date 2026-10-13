---
order: 3
title: Theming your own components
---

<EuiPageHeader @pageTitle="Theming your own components" />

<EuiSpacer />

<EuiText>

Ember EUI components read their styles from the nearest
`EuiEmotionProvider`: the Borealis theme (EUI 123.1.0), its color mode,
its high contrast mode and your `@borealisOverrides`. This guide shows how
to make **your own** components and CSS follow the same theme, so they
switch to dark mode, high contrast and your brand colors together with
EUI's.

Everything below is exported from one public module:

```js
import {
  getEuiThemeContext,   // the nearest provider's theme context
  useEuiBorealisStyles, // run a style factory, memoized per theme
  euiClass,             // compose styles into a class in the provider's cache
  euiCssVar,            // 'colors.textSubdued' → 'var(--eui-color-text-subdued)'
} from '@ember-eui/core/theming';
import type { EuiCss, EuiThemeStyleContext } from '@ember-eui/core/theming';
```

### 1. Compose EUI components first

Before writing styles, check whether EUI already has the piece:
`EuiPanel` (surfaces, padding, borders, `@color="subdued"`), `EuiFlexGroup`
/ `EuiFlexItem` (layout and gaps), `EuiSpacer`, `EuiText` /
`EuiTextColor` / `EuiTitle` (typography and semantic text colors),
`EuiBadge`, `EuiCallOut`, `EuiHorizontalRule`… They are already themed,
accessible, tested in light, dark and high contrast, and get upstream's
fixes for free. Most "custom" components are a composition of these plus
a few lines of styles.

### 2. Style factories with semantic tokens

When you do need styles, write them the way EUI does: a **style
factory**, a pure function of the theme that returns style objects, run
through `useEuiBorealisStyles` (memoized per resolved theme, like
upstream's `useEuiMemoizedStyles`) and turned into a class with
`euiClass` inside a `@cached` getter. The class is regenerated only when
an argument or the provider's theme changes.

```gjs
import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import {
  euiClass,
  getEuiThemeContext,
  useEuiBorealisStyles
} from '@ember-eui/core/theming';

// Module scope: one function identity, so results are shared and cached.
const statCardStyles = ({ euiTheme }) => ({
  root: {
    padding: euiTheme.size.m,
    borderRadius: euiTheme.border.radius.medium,
    border: euiTheme.border.thin,
    backgroundColor: euiTheme.colors.backgroundBasePlain,
    color: euiTheme.colors.textParagraph
  },
  // semantic tokens: "danger text", not "red"
  danger: { borderColor: euiTheme.colors.borderBaseDanger },
  value: { fontWeight: euiTheme.font.weight.bold }
});

export default class StatCard extends Component {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, statCardStyles);
    return euiClass(
      context,
      styles.root,
      this.args.danger && styles.danger,
      this.args.css // let callers compose last, like EUI components
    );
  }

  <template>
    <div class={{this.classes}} ...attributes>{{yield}}</div>
  </template>
}
```

- Use **semantic tokens**: `colors.textSubdued`,
  `colors.backgroundBaseSubdued`, `colors.borderBasePlain`,
  `colors.textDanger`, `size.m`, `border.radius.medium`. They are what
  changes between light, dark and high contrast. Avoid the raw palette
  (`colors.primary` for text, shade names) unless you mean exactly that.
- Never call the factory directly in a getter: `useEuiBorealisStyles`
  runs it once per theme for every instance.
- The upstream factories EUI uses (`euiPanelStyles`, `euiFontSize`,
  `euiFocusRing`, …) are in `@ember-eui/core/utils/eui/styles.generated`
  if you want to build on them.

### 3. `@css`: style an EUI component from the outside

Every migrated component takes `@css` (and slot variants such as
`EuiPopover @panelCss`, `EuiButton @contentCss`,
`EuiFormControlLayout @iconCss`). It accepts:

- an **object**: `{ maxInlineSize: '40ch' }`;
- a **string**: `"text-decoration: underline;"`;
- a **theme function**, like upstream's `css` prop callback:
  `({ euiTheme, colorMode, highContrastMode }) => styles`;
- an **array** mixing them.

The value is composed **last into the component's own class**, so your
declarations win without `!important` or selector tricks. An extra
`class="my-panel"` creates a second Emotion class whose precedence depends
on rule insertion order, which changes as components mount; `@css` does
not. Theme functions are resolved centrally (in `euiClass`), memoized per
theme and function identity: define them at module scope (or as a stable
class field) so they run once per theme, not on every render.

```gjs
const subdued = ({ euiTheme }) => ({
  backgroundColor: euiTheme.colors.backgroundBaseSubdued,
  color: euiTheme.colors.textSubdued
});

<template>
  <EuiPanel @css={{subdued}}>Follows light, dark and high contrast</EuiPanel>
</template>
```

### 4. CSS variables for plain CSS

For stylesheets you don't want to move into JS (an app's `app.css`, a
third-party widget, a `<style>` in a template), the root provider
publishes the theme as **CSS custom properties** on `:root`:

```css
.my-sidebar {
  background: var(--eui-color-background-base-subdued);
  border-inline-end: var(--eui-border-thin);
  color: var(--eui-color-text-paragraph);
  padding: var(--eui-size-m);
  font-family: var(--eui-font-family);
}
```

- They follow `@colorMode`, high contrast and `@borealisOverrides`, and
  are re-published when any of them changes.
- A nested provider whose theme differs (another color mode, contrast
  mode or overrides) re-declares them on its wrapper span, so CSS inside
  it gets the nested values. A nested provider with `@wrapper={{false}}`
  has no element to scope them on; content rendered into a portal
  (popovers, flyouts) reads the root values.
- They live in the provider-owned `eui-vars` Emotion cache (one rule, no
  inline styles), are published even with `@globalStyles={{false}}`, and
  are removed with the root provider.
- Names are `--eui-` plus the token path in kebab case, with `colors`
  singular: `colors.textSubdued` → `--eui-color-text-subdued`,
  `border.radius.medium` → `--eui-border-radius-medium`,
  `font.weight.semiBold` → `--eui-font-weight-semi-bold`. Font sizes are
  computed like upstream `euiFontSize`: `--eui-font-size-s`,
  `--eui-line-height-s`. `euiCssVar('colors.textSubdued')` returns
  `var(--eui-color-text-subdued)`. Upstream EUI has no token variables
  (only per-component ones such as `--euiFixedHeadersOffset`), so these
  names are Ember EUI's. The full list is in the
  [reference](#reference-css-variables) below.

Prefer factories or `@css` for component code: they are typed, can use
upstream mixins, and are tested against the same tokens.

### 5. Brand overrides with `@borealisOverrides`

Customize the theme once, at the root provider, with upstream Borealis
modifications. Everything (EUI components, your factories, `@css` theme
functions and the CSS variables) picks them up:

```js
// e.g. on the application controller
themeOverrides = {
  colors: {
    LIGHT: { primary: '#5a2ca0', textPrimary: '#4b2386' },
    DARK: { primary: '#b79cf2', textPrimary: '#c9b5f5' }
  },
  border: { radius: { medium: '2px' } }
};
```

```hbs
<EuiEmotionProvider @borealisOverrides={{this.themeOverrides}}>
  {{outlet}}
</EuiEmotionProvider>
```

Override **mode-specific** colors (`colors.LIGHT` / `colors.DARK`): flat
color overrides lose to Borealis' per-mode values. Override the semantic
tokens you need (`textPrimary`, `backgroundFilledPrimary`, …) as well as
the base color: they are computed from the palette, not from `primary`.
Nested providers merge their own overrides on top, for a branded section.

### 6. High contrast

`@highContrastMode` is `true` (upstream's `"preferred"`), `false` or
`"forced"`. Left unset on the root provider it follows the OS:
`prefers-contrast: more` enables it, and Windows' forced colors mode
(`forced-colors: active`) yields `"forced"`, which supersedes every app
setting, including `@colorMode`. Like upstream, high contrast replaces the
**border** tokens: every `colors.border*` becomes the matching text color
(or plain dark/light) and `border.thin`/`thick` use it.

So, to support high contrast in your own components:

- use `border.thin` / `colors.borderBase*` for borders and outlines
  instead of hardcoded colors, and draw a border rather than relying on a
  background or shadow alone to separate surfaces;
- read `highContrastMode` in a theme function when you need more, as
  upstream components do:

```js
const card = ({ euiTheme, highContrastMode }) => ({
  border: highContrastMode ? euiTheme.border.thick : euiTheme.border.thin,
  boxShadow: highContrastMode ? 'none' : `0 1px 2px ${euiTheme.colors.shadow}`
});
```

- in `"forced"` mode the browser replaces colors itself: keep borders and
  outlines (with `transparent` colors if you hide them), never encode
  meaning in color alone.

The site header has a high contrast toggle next to the light/dark switch
to try it.

### 7. Checklist: migrating hardcoded colors

1. Find them: `grep -rnE '#[0-9a-fA-F]{3,8}\b|rgba?\(' app/` (and
   `color:`/`background` rules in your CSS).
2. For each, ask what it **means**: body text → `textParagraph`; muted
   text → `textSubdued`; headings → `textHeading`; links/primary actions →
   `textPrimary`; page/panel background → `backgroundBasePlain`; muted
   surface → `backgroundBaseSubdued`; dividers → `borderBasePlain`
   (`border.thin`); errors → `textDanger` / `backgroundBaseDanger` /
   `borderBaseDanger`; success/warning likewise.
3. Prefer an EUI component or argument (`EuiTextColor @color="subdued"`,
   `EuiPanel @color="subdued"`, `EuiCallOut @color="danger"`) over a style.
4. Otherwise move the rule to a style factory or `@css` theme function;
   for CSS that must stay CSS, use the `--eui-*` variable.
5. Replace hardcoded spacing, radii and font sizes with `size.*`,
   `border.radius.*` and `euiFontSize` / `--eui-font-size-*`.
6. Remove rules that target EUI's internal or legacy classes
   (`.euiButton--primary`, `.euiPanel .euiTitle`); pass `@css` to the
   component instead.
7. Check the result in light, dark and high contrast (header toggles),
   and in a nested `@colorMode="dark"` section.
8. Brand colors belong in `@borealisOverrides`, not in per-component CSS.

</EuiText>

## Reference: CSS variables

<EuiText>

190 variables, generated from the resolved Borealis theme (EUI 123.1.0,
Borealis 8.1.0) without overrides. "same" means the dark value equals the
light one. Every string color is published, plus `colors.severity`;
`colors.vis` is not. Size, border and font come from `size.*`, `border.*`
and `font.*`; `--eui-font-size-*` / `--eui-line-height-*` are upstream
`euiFontSize` results (rem, relative to the root provider's 14px root font
size).

#### Colors

| Variable | Light | Dark |
| --- | --- | --- |
| `--eui-color-plain-light` | `#FFFFFF` | same |
| `--eui-color-plain-dark` | `#07101F` | same |
| `--eui-color-primary` | `#0B64DD` | `#61A2FF` |
| `--eui-color-accent` | `#BC1E70` | `#EE72A6` |
| `--eui-color-accent-secondary` | `#008B87` | `#16C5C0` |
| `--eui-color-success` | `#008A5E` | `#24C292` |
| `--eui-color-warning` | `#FACB3D` | same |
| `--eui-color-danger` | `#C61E25` | `#F6726A` |
| `--eui-color-empty-shade` | `#FFFFFF` | `#111C2C` |
| `--eui-color-lightest-shade` | `#ECF1F9` | `#172336` |
| `--eui-color-light-shade` | `#CAD3E2` | `#243147` |
| `--eui-color-medium-shade` | `#8E9FBC` | `#516381` |
| `--eui-color-dark-shade` | `#5A6D8C` | `#7186A8` |
| `--eui-color-darkest-shade` | `#2B394F` | `#CAD3E2` |
| `--eui-color-full-shade` | `#07101F` | `#FFFFFF` |
| `--eui-color-body` | `#ECF1F9` | `#07101F` |
| `--eui-color-highlight` | `#F1F6FF` | `#1750BA` |
| `--eui-color-disabled` | `#E3E8F2` | `#1D2A3E` |
| `--eui-color-disabled-text` | `#6A7FA0` | same |
| `--eui-color-shadow` | `#000000` | same |
| `--eui-color-primary-text` | `#1750BA` | `#61A2FF` |
| `--eui-color-accent-text` | `#A11262` | `#EE72A6` |
| `--eui-color-success-text` | `#09724D` | `#24C292` |
| `--eui-color-warning-text` | `#825803` | `#FCD883` |
| `--eui-color-danger-text` | `#A71627` | `#F6726A` |
| `--eui-color-text-primary` | `#1750BA` | `#61A2FF` |
| `--eui-color-text-accent` | `#A11262` | `#EE72A6` |
| `--eui-color-text-accent-secondary` | `#047471` | `#16C5C0` |
| `--eui-color-text-neutral` | `#0F658A` | `#37B8DC` |
| `--eui-color-text-success` | `#09724D` | `#24C292` |
| `--eui-color-text-warning` | `#825803` | `#FCD883` |
| `--eui-color-text-risk` | `#9E3A16` | `#FF995E` |
| `--eui-color-text-danger` | `#A71627` | `#F6726A` |
| `--eui-color-text-assistance` | `#6B3C9F` | `#C5A5FA` |
| `--eui-color-text` | `#384861` | `#B4C1D5` |
| `--eui-color-title` | `#111C2C` | `#E3E8F2` |
| `--eui-color-subdued-text` | `#516381` | `#98A8C3` |
| `--eui-color-link` | `#1750BA` | `#61A2FF` |
| `--eui-color-text-paragraph` | `#384861` | `#B4C1D5` |
| `--eui-color-text-heading` | `#111C2C` | `#E3E8F2` |
| `--eui-color-text-subdued` | `#516381` | `#98A8C3` |
| `--eui-color-text-disabled` | `#798EAF` | `#6A7FA0` |
| `--eui-color-text-inverse` | `#FFFFFF` | `#07101F` |
| `--eui-color-text-ink` | `#07101F` | same |
| `--eui-color-text-ghost` | `#FFFFFF` | same |
| `--eui-color-background-base-primary` | `#F1F6FF` | `#0A2342` |
| `--eui-color-background-base-accent` | `#FFF0F8` | `#351725` |
| `--eui-color-background-base-accent-secondary` | `#EAFBFA` | `#03282B` |
| `--eui-color-background-base-neutral` | `#ECFBFF` | `#002938` |
| `--eui-color-background-base-success` | `#E9FFF7` | `#092A26` |
| `--eui-color-background-base-warning` | `#FFF7E2` | `#2C2721` |
| `--eui-color-background-base-risk` | `#FFF3E3` | `#361D18` |
| `--eui-color-background-base-danger` | `#FFF3F1` | `#351721` |
| `--eui-color-background-base-assistance` | `#F7F2FF` | `#2A1E3E` |
| `--eui-color-background-base-recessed` | `#F6F9FC` | `#07101F` |
| `--eui-color-background-base-subdued` | `#F6F9FC` | `#0B1628` |
| `--eui-color-background-base-plain` | `#FFFFFF` | `#111C2C` |
| `--eui-color-background-base-disabled` | `#ECF1F9` | `#1D2A3E` |
| `--eui-color-background-base-highlighted` | `#F6F9FC` | `#172336` |
| `--eui-color-background-base-forms-prepend` | `#ECF1F9` | `#243147` |
| `--eui-color-background-base-forms-control-disabled` | `#CAD3E2` | `#2B394F` |
| `--eui-color-background-base-interactive-hover` | `rgba(23,80,186, 0.04)` | `rgba(255,255,255, 0.08)` |
| `--eui-color-background-base-interactive-hover-assistance` | `#ECE2FE` | `#322452` |
| `--eui-color-background-base-interactive-select` | `#F1F6FF` | `#0D2F5E` |
| `--eui-color-background-base-interactive-select-hover` | `#D9E8FF` | `#123778` |
| `--eui-color-background-base-interactive-overlay` | `rgba(72,89,117, 0.7)` | `rgba(43,57,79, 0.7)` |
| `--eui-color-background-base-skeleton-edge` | `rgba(72,89,117, 0.16)` | `rgba(255,255,255, 0.16)` |
| `--eui-color-background-base-skeleton-middle` | `rgba(72,89,117, 0.04)` | `rgba(255,255,255, 0.08)` |
| `--eui-color-background-light-primary` | `#D9E8FF` | `#0D2F5E` |
| `--eui-color-background-light-accent` | `#FDDDE9` | `#481E32` |
| `--eui-color-background-light-accent-secondary` | `#C9F3F0` | `#023436` |
| `--eui-color-background-light-neutral` | `#CFEEF7` | `#003447` |
| `--eui-color-background-light-success` | `#C9F3E3` | `#0D362B` |
| `--eui-color-background-light-warning` | `#FDE9B5` | `#3D3014` |
| `--eui-color-background-light-risk` | `#FFDEBF` | `#4A221C` |
| `--eui-color-background-light-danger` | `#FDDDD8` | `#491D27` |
| `--eui-color-background-light-assistance` | `#ECE2FE` | `#3E2C63` |
| `--eui-color-background-light-text` | `#E3E8F2` | `#2B394F` |
| `--eui-color-background-filled-primary` | `#0B64DD` | `#61A2FF` |
| `--eui-color-background-filled-accent` | `#BC1E70` | `#EE72A6` |
| `--eui-color-background-filled-accent-secondary` | `#008B87` | `#16C5C0` |
| `--eui-color-background-filled-neutral` | `#1C8CB5` | `#63C8E3` |
| `--eui-color-background-filled-success` | `#008A5E` | `#24C292` |
| `--eui-color-background-filled-warning` | `#FACB3D` | same |
| `--eui-color-background-filled-risk` | `#ED6723` | `#FF995E` |
| `--eui-color-background-filled-danger` | `#C61E25` | `#F6726A` |
| `--eui-color-background-filled-assistance` | `#8144CC` | `#C5A5FA` |
| `--eui-color-background-filled-text` | `#5A6D8C` | `#8E9FBC` |
| `--eui-color-background-transparent` | `transparent` | same |
| `--eui-color-background-transparent-primary` | `#F1F6FF` | `#0A2342` |
| `--eui-color-background-transparent-accent` | `#FFF0F8` | `#351725` |
| `--eui-color-background-transparent-accent-secondary` | `#EAFBFA` | `#351725` |
| `--eui-color-background-transparent-neutral` | `#ECFBFF` | `#002938` |
| `--eui-color-background-transparent-success` | `#E9FFF7` | `#092A26` |
| `--eui-color-background-transparent-warning` | `#FFF7E2` | `#2C2721` |
| `--eui-color-background-transparent-risk` | `#FFF3E3` | `#361D18` |
| `--eui-color-background-transparent-danger` | `#FFF3F1` | `#351721` |
| `--eui-color-background-transparent-subdued` | `#ECF1F9` | `#0B1628` |
| `--eui-color-background-transparent-highlighted` | `#ECF1F9` | `#0B1628` |
| `--eui-color-background-transparent-plain` | `#ECF1F9` | `#111C2C` |
| `--eui-color-border-base-primary` | `#BFDBFF` | `#123778` |
| `--eui-color-border-base-accent` | `#FFC7DB` | `#5E2140` |
| `--eui-color-border-base-accent-secondary` | `#A6EDEA` | `#044949` |
| `--eui-color-border-base-neutral` | `#B5E5F2` | `#00425C` |
| `--eui-color-border-base-success` | `#AEE8D2` | `#094837` |
| `--eui-color-border-base-warning` | `#FCD883` | `#513910` |
| `--eui-color-border-base-risk` | `#FFCDA1` | `#5E281A` |
| `--eui-color-border-base-danger` | `#FFC9C2` | `#5E2129` |
| `--eui-color-border-base-assistance` | `#E2D3FE` | `#3E2C63` |
| `--eui-color-border-base-plain` | `#CAD3E2` | `#485975` |
| `--eui-color-border-base-subdued` | `#E3E8F2` | `#2B394F` |
| `--eui-color-border-base-prominent` | `#A2B1C9` | `#6A7FA0` |
| `--eui-color-border-base-disabled` | `#CAD3E2` | `#485975` |
| `--eui-color-border-base-floating` | `transparent` | `#2B394F` |
| `--eui-color-border-base-forms-color-swatch` | `rgba(72,89,117, 0.24)` | `rgba(255,255,255, 0.32)` |
| `--eui-color-border-interactive-forms-hover-plain` | `#B4C1D5` | `#5A6D8C` |
| `--eui-color-border-interactive-forms-hover-prominent` | `#798EAF` | `#8E9FBC` |
| `--eui-color-border-interactive-forms-hover-danger` | `#DA3737` | `#EE4C48` |
| `--eui-color-border-strong-primary` | `#0B64DD` | `#61A2FF` |
| `--eui-color-border-strong-accent` | `#BC1E70` | `#EE72A6` |
| `--eui-color-border-strong-accent-secondary` | `#008B87` | `#16C5C0` |
| `--eui-color-border-strong-neutral` | `#19799F` | `#37B8DC` |
| `--eui-color-border-strong-success` | `#008A5E` | `#24C292` |
| `--eui-color-border-strong-warning` | `#966B03` | `#FACB3D` |
| `--eui-color-border-strong-risk` | `#C24411` | `#FF995E` |
| `--eui-color-border-strong-danger` | `#C61E25` | `#F6726A` |
| `--eui-color-border-strong-assistance` | `#8144CC` | `#B386F9` |
| `--eui-color-border-strong-text` | `#5A6D8C` | `#8E9FBC` |
| `--eui-color-severity-unknown` | `#E3E8F2` | same |
| `--eui-color-severity-neutral` | `#B5E5F2` | same |
| `--eui-color-severity-success` | `#24C292` | same |
| `--eui-color-severity-warning` | `#FCD883` | same |
| `--eui-color-severity-risk` | `#FF995E` | same |
| `--eui-color-severity-danger` | `#EE4C48` | same |

#### Size

| Variable | Light | Dark |
| --- | --- | --- |
| `--eui-size-xxs` | `2px` | same |
| `--eui-size-xs` | `4px` | same |
| `--eui-size-s` | `8px` | same |
| `--eui-size-m` | `12px` | same |
| `--eui-size-base` | `16px` | same |
| `--eui-size-l` | `24px` | same |
| `--eui-size-xl` | `32px` | same |
| `--eui-size-xxl` | `40px` | same |
| `--eui-size-xxxl` | `48px` | same |
| `--eui-size-xxxxl` | `64px` | same |

#### Border

| Variable | Light | Dark |
| --- | --- | --- |
| `--eui-border-color` | `#E3E8F2` | `#2B394F` |
| `--eui-border-width-thin` | `1px` | same |
| `--eui-border-width-thick` | `2px` | same |
| `--eui-border-radius-medium` | `4px` | same |
| `--eui-border-radius-small` | `4px` | same |
| `--eui-border-radius-inline` | `4px` | same |
| `--eui-border-radius-control` | `8px` | same |
| `--eui-border-radius-panel` | `12px` | same |
| `--eui-border-radius-frame` | `16px` | same |
| `--eui-border-thin` | `1px solid #E3E8F2` | `1px solid #2B394F` |
| `--eui-border-thick` | `2px solid #E3E8F2` | `2px solid #2B394F` |
| `--eui-border-editable` | `2px dotted #E3E8F2` | `2px dotted #2B394F` |

#### Font

| Variable | Light | Dark |
| --- | --- | --- |
| `--eui-font-family` | `'Inter', BlinkMacSystemFont, Helvetica, Arial, sans-serif` | same |
| `--eui-font-family-code` | `'Roboto Mono', Menlo, Courier, monospace` | same |
| `--eui-font-family-serif` | `Georgia, Times, Times New Roman, serif` | same |
| `--eui-font-feature-settings` | `'calt' 1, 'kern' 1, 'liga' 1` | same |
| `--eui-font-weight-light` | `300` | same |
| `--eui-font-weight-regular` | `400` | same |
| `--eui-font-weight-medium` | `450` | same |
| `--eui-font-weight-semi-bold` | `500` | same |
| `--eui-font-weight-bold` | `600` | same |
| `--eui-font-size-xxxs` | `0.6429rem` | same |
| `--eui-font-size-xxs` | `0.7857rem` | same |
| `--eui-font-size-xs` | `0.8571rem` | same |
| `--eui-font-size-s` | `1.0000rem` | same |
| `--eui-font-size-m` | `1.1429rem` | same |
| `--eui-font-size-l` | `1.4286rem` | same |
| `--eui-font-size-xl` | `1.7143rem` | same |
| `--eui-font-size-xxl` | `2.1429rem` | same |

#### Line height

| Variable | Light | Dark |
| --- | --- | --- |
| `--eui-line-height-xxxs` | `0.8571rem` | same |
| `--eui-line-height-xxs` | `1.1429rem` | same |
| `--eui-line-height-xs` | `1.1429rem` | same |
| `--eui-line-height-s` | `1.4286rem` | same |
| `--eui-line-height-m` | `1.7143rem` | same |
| `--eui-line-height-l` | `1.7143rem` | same |
| `--eui-line-height-xl` | `2.0000rem` | same |
| `--eui-line-height-xxl` | `2.5714rem` | same |

#### Focus

| Variable | Light | Dark |
| --- | --- | --- |
| `--eui-focus-color` | `#1750BA` | `#61A2FF` |
| `--eui-focus-width` | `2px` | same |

#### Animation

| Variable | Light | Dark |
| --- | --- | --- |
| `--eui-animation-extra-fast` | `90ms` | same |
| `--eui-animation-fast` | `150ms` | same |
| `--eui-animation-normal` | `250ms` | same |
| `--eui-animation-slow` | `350ms` | same |
| `--eui-animation-extra-slow` | `500ms` | same |
| `--eui-animation-bounce` | `cubic-bezier(.34, 1.61, .7, 1)` | same |
| `--eui-animation-resistance` | `cubic-bezier(.32, .72, 0, 1)` | same |

</EuiText>
