<EuiPageHeader>
  <EuiPageHeaderSection>
    <EuiTitle @size="l">
      <h1>
        Installation
      </h1>
    </EuiTitle>
  </EuiPageHeaderSection>
</EuiPageHeader>

This addon requires some peer dependencies. Install the correct versions of each package, which are listed by the command

1. `npm info @ember-eui/core peerDependencies`


Once you've installed it, you can now install the addon itself:

1. `ember install @ember-eui/core`


You _might_ get babel errors for a dependency mistmatch between embroider packages, here's a [link](https://github.com/embroider-build/embroider/issues/1077) for more info,
if so, you can force that all packages use the same dependency with npm `overrides` or yarn `resolutions`, here's a the sample for yarn that you could add to your package.json

```
"resolutions": {
    "@embroider/macros": "^1.3.0",
    "@embroider/shared-internals": "^1.3.0",
    "@embroider/util": "^1.3.0"
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
        'node_modules/@elastic/eui/lib/components/icon',
      ],
    },
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
      theme: 'dark', //light, dark, amsterdam_dark, amsterdam_light 
    },
  //...
});
```