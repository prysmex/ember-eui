# @ember-eui/core

This project aims to provide ember components implementing the css layer of https://elastic.github.io/eui
### Icons

For icons to work you will need to:

- install `ember-svg-jar`
- add the following `ember-svg-jar` options to your `ember-cli-build.js`:

```javascript
// ember-cli-build.js
var app = new EmberApp(defaults, {
  ...
    svgJar: {
      sourceDirs: [
        'public/assets',
        '../node_modules/@ember-eui/core/public',
        '../node_modules/@ember-eui/core/vendor/icon',
      ],
    },
  ...
});

```

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
