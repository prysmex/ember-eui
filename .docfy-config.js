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
    ],
    highlight
  ],
  sources: [
		{
      root: path.resolve(__dirname, 'docs'),
      pattern: '**/*.md',
      urlPrefix: 'docs'
    },
  ],
  // labels: {
  //   components: 'Components',
  //   helpers: 'Helpers',
  //   core: '@docfy/core',
  //   ember: '@docfy/ember',
  //   docs: 'Documentation'
  // }
};