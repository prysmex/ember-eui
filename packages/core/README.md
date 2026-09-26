# @ember-eui/core

This project aims to provide ember components implementing the css layer of https://elastic.github.io/eui
### Icons

EUI icons work out of the box: they are bundled with the addon, no build
configuration is needed (this used to require `ember-svg-jar`).

```hbs
<EuiIcon @type="arrowDown" />
```

To use your own icons by name (for example in `@iconType` arguments),
register them as components rendering an `<svg ...attributes>`. With
[`@svg-jar/plugin`](https://github.com/svg-jar/plugin) in your app's
`vite.config.mjs` (`svgJar({ target: 'ember' })`), svg files can be
imported directly:

```js
// app/routes/application.js
import Route from '@ember/routing/route';
import { service } from '@ember/service';
import MyLogo from '../icons/my-logo.svg';

export default class ApplicationRoute extends Route {
  @service euiConfig;

  beforeModel() {
    this.euiConfig.updateConfig({ 'euiIcon.icons': { myLogo: MyLogo } });
  }
}
```

```hbs
<EuiIcon @type="myLogo" />
```

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
