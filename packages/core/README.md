# @ember-eui/core

This project aims to provide ember components implementing the css layer of https://elastic.github.io/eui
### Icons

EUI icons work out of the box: they are bundled with the addon, no build
configuration is needed (this used to require `ember-svg-jar`).

```hbs
<EuiIcon @type="arrowDown" />
```

To use your own icons, add [`@svg-jar/plugin`](https://github.com/svg-jar/plugin)
to your app's `vite.config.mjs` (`svgJar({ target: 'ember' })`) so svg files
can be imported as components. Then either pass the component directly:

```js
import MyLogo from '../icons/my-logo.svg';
```

```hbs
<EuiIcon @type={{MyLogo}} />
<EuiBadge @iconType={{MyLogo}}>New</EuiBadge>
```

or register them by name, e.g. a whole folder at once with `iconsFromGlob`
(icons are named after their file, like ember-svg-jar did):

```js
// app/routes/application.js
import Route from '@ember/routing/route';
import { service } from '@ember/service';
import { iconsFromGlob } from '@ember-eui/core/utils/icons-from-glob';

export default class ApplicationRoute extends Route {
  @service euiConfig;

  beforeModel() {
    this.euiConfig.updateConfig({
      'euiIcon.icons': iconsFromGlob(
        import.meta.glob('../icons/**/*.svg', { eager: true })
      ),
    });
  }
}
```

```hbs
<EuiIcon @type="my-logo" />
<EuiButton @iconType="rocket">Launch</EuiButton>
```

Keep these svgs out of `public/`: Vite does not want files from the
public directory imported from JavaScript (it warns in development).
Moving e.g. `public/assets/*.svg` to `app/icons/` keeps the same names.

Any other string is rendered as an `<img>` with that URL.

## Compatibility

- Ember.js v5.8 or above
- Ember CLI v5.8 or above
- Node.js v18 or above

## Installation

```
ember install @ember-eui/core
```

## Contributing

See the [Contributing](CONTRIBUTING.md) guide for details.

### PR's are truly welcome

## License

This project is licensed under the [MIT License](LICENSE.md).
