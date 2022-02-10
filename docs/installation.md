# Installation

You can start by installing the core

1. `ember install @ember-eui/core`


You _might_ get babel errors for a dependency mistmatch between embroider packages, here's a [link](https://github.com/embroider-build/embroider/issues/1077) for more info,
if so, you can force that all packages use the same dependency with npm `overrides` or yarn `resolutions`, here's a the sample for yarn that you could add to your package.json

```
"resolutions": {
    "@embroider/macros": "^1.0.0",
    "@embroider/shared-internals": "^1.0.0",
    "@embroider/util": "^1.0.0"
  }
```


### Icons

For icons to work you will need to:

- install `ember-svg-jar`
- add the following `ember-svg-jar` options to your `ember-cli-build.js`:

```javascript
// ember-cli-build.js
var app = new EmberApp(defaults, {
  //...
    svgJar: {
      sourceDirs: [
        'public/assets',
        'node_modules/@elastic/eui/lib/components/icon',
      ],
    },
  //...
});

```


### Styles and Theming

`theme`: You can specify the theme you want  

```javascript
// ember-cli-build.js
var app = new EmberApp(defaults, {
  //...
    '@ember-eui/core': {
      theme: 'dark', //light, dark, amsterdam_dark, amsterdam_light 
    },
  //...
});
```