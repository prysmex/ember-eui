---
order: 2
---

<EuiPageHeader @pageTitle="Getting started" />

<EuiSpacer />

<EuiText>

This addon requires some peer dependencies. Install the correct versions of each package, which are listed by the command

1. `npm info @ember-eui/core peerDependencies`

Once you've installed it, you can now install the addon itself:

2. `ember install @ember-eui/core`

You _might_ get babel errors for a dependency mistmatch between embroider packages, here's a [link](https://github.com/embroider-build/embroider/issues/1077) for more info,
if so, you can force that all packages use the same dependency with npm `overrides` or yarn `resolutions`, here's a the sample for yarn that you could add to your package.json

```text
"resolutions": {
    "@embroider/macros": "^1.5.0",
    "@embroider/shared-internals": "^1.5.0",
    "@embroider/util": "^1.5.0"
  }
```

<EuiTitle>
  <h3>
    Icons
  </h3>
</EuiTitle>

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
      'node_modules/@elastic/eui/lib/components/icon'
    ]
  }
  //...
});
```

<EuiTitle>
  <h3>
    Styles and Theming
  </h3>
</EuiTitle>

`theme`: You can specify the theme you want

```javascript
// ember-cli-build.js
var app = new EmberApp(defaults, {
  //...
  '@ember-eui/core': {
    theme: 'amsterdam_light' //light, dark, amsterdam_dark, amsterdam_light , defaults to amsterdam_light
  }
  //...
});
```

</EuiText>