# Installation

You can start by installing the core

1. `ember install @ember-eui/core`

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