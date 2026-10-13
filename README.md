
<img src="site/public/assets/euivector.svg" alt="logo" height="200">

# @ember-eui monorepo

This is the @ember-eui monorepo.

This addon requires some peer dependencies. Install the correct versions of each package, which are listed by the command

1. `npm info @ember-eui/core peerDependencies`


Once you've installed it, you can now install the addon itself:

1. `ember install @ember-eui/core`

## Demo

### [Live demo and documentation](https://ember-eui.vercel.app)

## Packages
- [@ember-eui/core](./packages/core/README.md)
- [@ember-eui/changeset-form](./packages/changeset-form/README.md)
- [@ember-eui/pikaday](./packages/pikaday/README.md)
- [@ember-eui/flatpickr](./packages/flatpickr/README.md)
- [@ember-eui/validated-form](./packages/validated-form/README.md)

## License and attribution

Ember EUI implements [Elastic UI (EUI)](https://github.com/elastic/eui), created
by Elasticsearch B.V. (Copyright 2012-2024 Elasticsearch B.V.). The packages'
own code is licensed as stated in each package's `LICENSE.md`; the parts
derived from EUI (component styles generated from its sources, icons, ported
component logic and the documentation examples) remain under Elastic's
license for EUI: at your election, the Elastic License 2.0 or the Server Side
Public License, v 1. See [packages/core/NOTICE.md](./packages/core/NOTICE.md)
and the license texts in
[packages/core/vendor/eui-latest](./packages/core/vendor/eui-latest).

This is a community project, not affiliated with or endorsed by Elastic.
Elastic and EUI are trademarks of Elasticsearch B.V.
