# ember-eui

This project aims to provide ember components implementing the css layer of https://elastic.github.io/eui

### Icons

For icons to work you will need to:

- install `ember-svg-jar`
- add the following `ember-svg-jar` options to your `ember-cli-build.js`:
- NOTICE: we are currently using a fork from ember-svg-jar, for the hbs strategy
  `"ember-svg-jar": "github:betocantu93/ember-svg-jar#a62c02509e5ea6953a51ded9b912c97ed0a43a48"`

```javascript
// ember-cli-build.js
var app = new EmberApp(defaults, {
  ...
    svgJar: {
      strategy: ['hbs'],
      hbs: {
        stripPath: false,
      },
      sourceDirs: [
        'public/assets',
        'node_modules/@elastic/eui/lib/components/icon',
      ],
    },
  ...
});

```

We use `ember-svg-jar` to create SVGs as TOC (Template only components) with the `hbs` strategy. `ember-svg-jar` uses [ember-cli-resolve-assset](https://github.com/buschtoens/ember-cli-resolve-asset) in order to support fingerprinting of the generated HBS TOC components, so you also have to install it in your host app.

`ember install ember-cli-resolve-asset`

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
