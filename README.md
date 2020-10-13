# ember-eui

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
    strategy: 'hbs',
    sourceDirs: [
      'node_modules/@elastic/eui/lib/components/icon',
    ],
  },
  ...
});

//And import the ember-template-compiler... currently ember-eui depends on a fork of ember-svg-jar
app.import('node_modules/ember-source/dist/ember-template-compiler.js');

```

## Compatibility

- Ember.js v3.12 or above
- Ember CLI v2.13 or above
- Node.js v10 or above

## Installation

```
ember install ember-eui
```

## Contributing

See the [Contributing](CONTRIBUTING.md) guide for details.

### PR's are truly welcome
