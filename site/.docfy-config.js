const path = require('path');
const autolinkHeadings = require('remark-autolink-headings');
const highlight = require('remark-highlight.js');

module.exports = {
  remarkPlugins: [
    [
      autolinkHeadings,
      {
        behavior: 'wrap'
      }
    ]
    // highlight
  ],
  sources: [
    {
      root: path.resolve(__dirname, '../docs'),
      pattern: '**/*.md',
      urlPrefix: 'docs'
    },
    ...['core', 'pikaday', 'validated-form', 'flatpickr'].map((pkgName) => {
      return {
        root: path.resolve(__dirname, `../packages/${pkgName}`),
        pattern: '(docs|addon)/**/**/*.md',
        urlPrefix: `docs/${pkgName}`
      };
    })
  ],
  labels: {
    docs: 'Documentation',
    editors: 'Editors & syntax',
    tabular: 'Tabular content',
    charts: 'Elastic chards',
    'changeset-form': 'Changeset form',
    'validated-form': 'Validated form'
  }
};
