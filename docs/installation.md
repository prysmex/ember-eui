# Installation

You can start by installing the core

1. `ember install @ember-eui/core`

### Icons

For icons to work you will need to:

- install `ember-svg-jar`
- add the following `ember-svg-jar` options to your `ember-cli-build.js`:
- NOTICE: we are currently using a fork from ember-svg-jar, for the hbs strategy
  `"ember-svg-jar": "https://github.com/betocantu93/ember-svg-jar.git#add-bundle-flag"`

```javascript
// ember-cli-build.js
var app = new EmberApp(defaults, {
  //...
    svgJar: {
      strategy: ['hbs'],
      hbs: {
        stripPath: false,
      },
      sourceDirs: [
        'public/assets',
        '../node_modules/@ember-eui/core/public',
        'node_modules/@elastic/eui/lib/components/icon',
      ],
    },
  //...
});

```

We use `ember-svg-jar` to create SVGs as TOC (Template only components) with the `hbs` strategy. For fingerprinting and such, `ember-svg-jar#add-bundle-flag` exposes an `asset-map` service, with a `resolve` callback/hook, so you can implement your own resolver, you could use for example [ember-cli-resolve-assset](https://github.com/buschtoens/ember-cli-resolve-asset).

```javascript
import EmberSvgJarService from 'ember-svg-jar/services/asset-map';
import resolveAsset from 'ember-cli-resolve-asset'

export default class SvgJarService extends EmberSvgJarService {
  resolve(path) {
    //Here you could implement, for instance ember-cli-ifa, instead of ember-cli-resolve-asset.
    return resolveAsset(path);
  }
}
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
By default, `@ember-eui/core` will only include the compiled css theme version. If by any means you need to extend or access to css variables you can opt in:

```javascript
// ember-cli-build.js
var app = new EmberApp(defaults, {
  //...
    '@ember-eui/core': {
      useCompiledCss: false
    },
  //...
});
```

And then import it inside your app/styles/app.sass, word of caution, the performance of recompiling elastic sass is really noticable, so try to avoid this.

```css
@import 'ember-eui-core';
```