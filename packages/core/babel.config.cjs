'use strict';

module.exports = {
  presets: ['@babel/preset-typescript'],
  plugins: [
    [
      '@babel/plugin-transform-typescript',
      {
        allExtensions: true,
        onlyRemoveTypeImports: true,
        allowDeclareFields: true
      }
    ],
    '@embroider/addon-dev/template-colocation-plugin',
    [
      'babel-plugin-ember-template-compilation',
      {
        targetFormat: 'hbs',
        transforms: []
      }
    ],
    [
      'module:decorator-transforms',
      { runtime: { import: 'decorator-transforms/runtime' } }
    ]
  ]
};
