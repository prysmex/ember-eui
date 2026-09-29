import { readdirSync } from 'node:fs';
import { basename, dirname, join, parse, relative, sep } from 'node:path';

import config from '../docfy.config.mjs';

function markdownFiles(dir) {
  return readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = join(dir, entry.name);

    if (entry.isDirectory()) {
      return entry.name === 'node_modules' ? [] : markdownFiles(path);
    }

    return entry.name.endsWith('.md') ? [path] : [];
  });
}

/**
 * Whether docfy renders the file as a demo inside a page: it is in `demo/`
 * or `<page>-demo/` and that page exists (docfy's combine-demos rule).
 */
function isDemo(file, files) {
  const folder = basename(dirname(file));
  const owner =
    folder === 'demo'
      ? basename(dirname(dirname(file)))
      : folder.endsWith('-demo')
        ? folder.slice(0, -'-demo'.length)
        : undefined;

  return (
    owner !== undefined &&
    files.some((other) => {
      const { name } = parse(other);

      return (
        name === owner ||
        (name === 'index' && basename(dirname(other)) === owner)
      );
    })
  );
}

/**
 * The route of every docs page, as docfy names them: the page's URL
 * (`urlPrefix` + its path) with dots.
 * Computed from the sources, since the pages are generated during the build.
 */
export default function docsPageRoutes() {
  return config.sources.flatMap(({ root, pattern, urlPrefix }) => {
    // the sources are `**/*.md` or `docs/**/*.md`
    const files = markdownFiles(join(root, pattern.split('**')[0]));

    const pages = files.filter((file) => !isDemo(file, files));

    return pages.map((file) => {
      const path = relative(root, file).replace(/\.md$/, '').split(sep);
      const folder = dirname(file);
      // an index page keeps its `index` route when its folder has other
      // pages (docfy's removeUnnecessaryIndex), e.g. `form-layouts.index`
      const hasSubPages = pages.some(
        (other) => other !== file && other.startsWith(folder + sep),
      );

      if (path.at(-1) === 'index' && !hasSubPages) path.pop();

      return [...urlPrefix.split('/'), ...path].join('.');
    });
  });
}
