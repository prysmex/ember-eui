---
order: 2
title: Getting started
---

<EuiPageHeader @pageTitle="Getting started" />

<EuiSpacer />

<EuiText>

Ember EUI is Elastic's [EUI](https://eui.elastic.co) design system for
Ember: over a hundred components (buttons, forms, layout, popovers, a
markdown editor, a date picker, …) that share EUI's look, accessibility and
theming. It is a set of v2 addons:

| Package | Contents |
| --- | --- |
| `@ember-eui/core` | Every component, the themes and the services (config, toasts, i18n) |
| `@ember-eui/changeset-form` | Forms bound to an [ember-changeset](https://github.com/adopted-ember-addons/ember-changeset) |
| `@ember-eui/validated-form` | Forms validated with [ember-validators](https://github.com/rwjblue/ember-validators) |
| `@ember-eui/flatpickr` | A date picker built on flatpickr |
| `@ember-eui/pikaday` | A date picker built on Pikaday |

### Install

Install the addon and its peer dependencies:

```bash
pnpm add @ember-eui/core @ember/string ember-basic-dropdown ember-concurrency ember-focus-trap ember-power-select moment
```

`npm info @ember-eui/core peerDependencies` lists the supported versions.
The app needs `ember-source` 4.12 or later.

### Set up the theme

The components are styled with Elastic UI's Borealis theme (EUI 123.1.0):
each component injects its own styles at runtime, built from upstream
EUI's style factories. There is no theme stylesheet to load. Instead,
render one `EuiEmotionProvider` around the whole app, e.g. in
`app/templates/application.hbs`:

```hbs
{{! app/templates/application.hbs }}
<EuiEmotionProvider @colorMode="light">
  {{outlet}}
</EuiEmotionProvider>
```

In `.gjs` / `.gts` files import it from
`@ember-eui/core/components/eui-emotion-provider` (default export).

The outermost provider injects EUI's global styles (reset, a 14px root font
size, body colors, focus ring, selection and link colors) while it is
rendered. Components read their theme from the nearest provider, so:

- **Light/dark**: pass `@colorMode="light"` or `"dark"` (default light) and
  change it at runtime to switch themes; nested providers can fix a section
  to the other mode.
- **Theme overrides**: `@borealisOverrides` takes Borealis token
  overrides (e.g. colors or border radius), inherited by nested providers.
- **Opt-outs**: `@globalStyles={{false}}` if your app owns its global
  styles; `@wrapper={{false}}` to skip the provider's
  `<span class="euiThemeProvider">` where an extra element would break a
  flex or grid layout.

Keep importing EUI's small extensions stylesheet once, e.g. in
`app/app.js`:

```js
// app/app.js
import '@ember-eui/core/styles/ember-eui.css';
```

Upgrading from 14.1 or earlier, which loaded
`@ember-eui/core/themes/light.css` / `dark.css`? See
[Migrating to Borealis](/docs/migrating-to-borealis) for the steps and the
list of changed defaults.

### Use components

In `.gjs` / `.gts` files, import the components you use:

```gjs
import { EuiButton, EuiFieldText, EuiFormRow } from '@ember-eui/core/components';

<template>
  <EuiFormRow @label="Name">
    <EuiFieldText @value={{@name}} />
  </EuiFormRow>
  <EuiButton @fill={{true}} @iconType="check">Save</EuiButton>
</template>
```

Each component can also be imported on its own, e.g.
`import EuiButton from '@ember-eui/core/components/eui-button';`. In
classic `.hbs` templates the components are available by name without
imports.

With [Glint](https://typed-ember.gitbook.io/glint) 2 (`ember-tsc`), templates
in `.gjs` / `.gts` files are type-checked through their imports: the
components' arguments, blocks and the attributes their element accepts. No
registry is needed. Apps still on Glint 1 with loose-mode `.hbs` templates can
register the components by name:

```ts
// types/glint.d.ts (Glint 1, loose mode)
import type EmberEuiRegistry from '@ember-eui/core/template-registry';

declare module '@glint/environment-ember-loose/registry' {
  export default interface Registry extends EmberEuiRegistry {}
}
```

Arguments start with `@` (`@iconType="check"`); plain HTML attributes and
modifiers (`class`, `aria-label`, `{{on "click" …}}`) are applied to the
component's main element. Every docs page ends with an *API reference*
listing each argument, its default and which element gets the attributes.

Working with an AI assistant? Point it at [`/llms.txt`](/llms.txt) (an
index with the rules for using Ember EUI) or
[`/llms-full.txt`](/llms-full.txt) (every page, example and API reference
in one file).

### Icons

EUI's icons ship with the addon and load lazily, one small chunk per icon;
nothing needs configuring. Your own svgs work too: see the
[Icons page](/docs/core/docs/display/icons) for
`@svg-jar/plugin`, registering icons by name and preloading.

### Runtime configuration

The `euiConfig` service holds settings that apply to every instance of a
component. Set them early, e.g. in the application route:

```js
// app/routes/application.js
import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class ApplicationRoute extends Route {
  @service euiConfig;

  beforeModel() {
    this.euiConfig.updateConfig({
      // default size of every EuiButtonIcon: 'xs', 's' or 'm'
      'euiButtonIcon.size': 's',
      // height in px of EuiComboBox options (defaults to 29)
      euiComboBoxOptionsHeight: 29,
      // icons usable by name, see the Icons page
      'euiIcon.icons': {},
    });
  }
}
```

`updateConfig` merges into the current settings; `setConfig` replaces
them.

### Toasts

Render `EuiGlobalToastList` once, e.g. in `app/templates/application.hbs`,
then show toasts from anywhere through the `euiToaster` service:

```hbs
<EuiGlobalToastList @toastLifeTimeMs={{6000}} />
```

```js
this.euiToaster.show({ title: 'Saved', color: 'success', iconType: 'check' });
```

### Combo box

`EuiComboBox` is built on ember-power-select and ember-basic-dropdown. Its
options list renders into a wormhole element, so add one to
`index.html` (or pass `@renderInPlace={{true}}` to each combo box):

```html
<div id="ember-basic-dropdown-wormhole"></div>
```

</EuiText>
