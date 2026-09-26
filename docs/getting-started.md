---
order: 2
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

### Load a theme

Import one of the two themes and EUI's extensions once, e.g. in
`app/app.js`:

```js
// app/app.js
import '@ember-eui/core/themes/light.css'; // or '@ember-eui/core/themes/dark.css'
import '@ember-eui/core/styles/ember-eui.css';
```

To let users switch themes at runtime, load the theme through a single
`<link>` whose `href` you swap (importing both CSS files would stack them).
With Vite, `?url` gives the built file's URL; this site does exactly this:

```js
// app/utils/change-theme.js
import darkTheme from '@ember-eui/core/themes/dark.css?url';
import lightTheme from '@ember-eui/core/themes/light.css?url';

export function changeTheme(name) {
  let link = document.getElementById('eui-theme');

  if (!link) {
    link = document.createElement('link');
    link.id = 'eui-theme';
    link.rel = 'stylesheet';
    // before the app's styles, so your overrides still win
    document.head.prepend(link);
  }

  link.href = name === 'dark' ? darkTheme : lightTheme;
}
```

Keep `import '@ember-eui/core/styles/ember-eui.css'` static; it works with
both themes.

Classic apps that do not use Vite or Embroider can add the files with
`app.import('node_modules/@ember-eui/core/vendor/eui_theme_light.min.css')`
and `app.import('node_modules/@ember-eui/core/dist/styles/ember-eui.css')`
in `ember-cli-build.js`.

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

For Glint (typed templates) in loose mode, add the registry to your types:

```ts
// types/glint.d.ts
import type EmberEuiRegistry from '@ember-eui/core/template-registry';

declare module '@glint/environment-ember-loose/registry' {
  export default interface Registry extends EmberEuiRegistry {}
}
```

Arguments start with `@` (`@iconType="check"`); plain HTML attributes and
modifiers (`class`, `aria-label`, `{{on "click" …}}`) are applied to the
component's main element. Every docs page ends with an *API reference*
listing each argument, its default and which element gets the attributes.

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
      // height in px of EuiComboBox options (defaults to 33)
      euiComboBoxOptionsHeight: 33,
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
