import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import autoImportComponents from './lib/docfy-auto-imports.mjs';
import remarkKeepHeadingDepth from './lib/remark-keep-heading-depth.mjs';

const root = dirname(fileURLToPath(import.meta.url));

export default {
  plugins: [autoImportComponents],
  remarkPlugins: [remarkKeepHeadingDepth],
  sources: [
    {
      root: resolve(root, '../docs'),
      pattern: '**/*.md',
      urlPrefix: 'docs',
    },
    ...['core', 'pikaday', 'validated-form', 'flatpickr', 'changeset-form'].map(
      (pkgName) => ({
        root: resolve(root, `../packages/${pkgName}`),
        pattern: 'docs/**/*.md',
        urlPrefix: `docs/${pkgName}`,
      }),
    ),
  ],
  labels: {
    docs: 'Documentation',
    editors: 'Editors & syntax',
    tabular: 'Tabular content',
    charts: 'Elastic charts',
    'changeset-form': 'Changeset form',
    'validated-form': 'Validated form',
  },
};
