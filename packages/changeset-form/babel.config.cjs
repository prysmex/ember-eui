'use strict';

'use strict';

module.exports = {
  presets: ['@babel/preset-typescript'],
  plugins: [
    ['@babel/plugin-transform-typescript', { allowDeclareFields: true }],
    'ember-cached-decorator-polyfill/babel-plugin',
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
