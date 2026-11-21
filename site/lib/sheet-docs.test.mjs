import assert from 'node:assert/strict';
import { readdirSync, readFileSync } from 'node:fs';
import { test } from 'node:test';
import { basename, dirname, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const docs = resolve(
  dirname(fileURLToPath(import.meta.url)),
  '../../packages/sheet/docs/sheet',
);
const read = (path) => readFileSync(resolve(docs, path), 'utf8');
const site = (path) =>
  readFileSync(
    resolve(dirname(fileURLToPath(import.meta.url)), '..', path),
    'utf8',
  );

/** The body of the first fence whose info string is `info`. */
function fence(markdown, info) {
  const start = markdown.indexOf('```' + info + '\n');

  assert.notEqual(start, -1, `a \`\`\`${info} fence`);

  const body = start + info.length + 4;

  return markdown.slice(body, markdown.indexOf('\n```', body));
}

test('the getting-started demo runs exactly the code the page shows', () => {
  assert.equal(
    fence(read('demo/d01-getting-started.md'), 'gts component'),
    fence(read('index.md'), 'gts'),
  );
});

test('the example app page shows its data module as it is', () => {
  assert.equal(
    fence(read('example-app/index.md'), 'js'),
    site('app/utils/sheet-example-products.js').trimEnd(),
  );
});

/* ---------------------------------------------------------------------- */
/* the sheet's pages and their demos                                       */
/* ---------------------------------------------------------------------- */

const SHEET_URL = '/docs/sheet/docs/sheet';

/** Every markdown file under the sheet's docs, relative to it. */
function sheetFiles(dir = docs) {
  return readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = join(dir, entry.name);

    return entry.isDirectory()
      ? sheetFiles(path)
      : entry.name.endsWith('.md')
        ? [relative(docs, path)]
        : [];
  });
}

const frontMatter = (markdown) =>
  Object.fromEntries(
    (/^---\n([\s\S]*?)\n---\n/.exec(markdown)?.[1] ?? '')
      .split('\n')
      .map((line) => line.split(/:\s*/, 2)),
  );

const files = sheetFiles();
const pageFiles = files.filter(
  (file) => basename(file) === 'index.md' && !file.split(sep).includes('demo'),
);
const demoFiles = files.filter((file) => basename(dirname(file)) === 'demo');
/** A page's folder ('' for Getting started), as in its URL. */
const pageOf = (demo) => dirname(dirname(demo)).replace(/^\.$/, '');
const folderOf = (page) => dirname(page).replace(/^\.$/, '');
/** Old URLs kept as short pages of links (`nav: false`), with no demos. */
const isStub = (page) => frontMatter(read(page)).nav === 'false';

/**
 * Pages with no example of their own. Only the API reference (and the old
 * URLs' pages) should stay here.
 */
const WITHOUT_EXAMPLES = new Set([
  'more/api-reference',
  // their examples come with the next commits
  'validation/field-rules',
  'validation/record-checks',
  'validation/blocking-and-warnings',
  'validation/paste-and-import',
  'editing/keyboard',
  'editing/undo-redo',
  'editing/read-only',
  'field-types/text-fields',
  'field-types/numbers',
  'field-types/dates',
  'field-types/selects',
  'field-types/checkbox-and-rating',
  'field-types/email-url-phone',
  'field-types/users',
  'field-types/barcode',
  'field-types/buttons',
  'fields/field-actions',
  'selection',
  'selection/touch',
  'rows/row-height',
  'data/sorting',
  'import-export/csv-import',
  'more/theme',
]);

test('the sheet docs: every file is a page or a demo of a page', () => {
  assert.deepEqual(
    files.filter(
      (file) => !pageFiles.includes(file) && !demoFiles.includes(file),
    ),
    [],
    'no markdown outside a page or its demo/ folder',
  );
  const folders = new Set(pageFiles.map(folderOf));

  for (const demo of demoFiles) {
    assert.ok(
      folders.has(pageOf(demo)),
      `${demo}: its page exists (not an orphan)`,
    );
  }
});

test('the sheet docs: no page folder has the name of another docs page', async () => {
  // docfy gives a demo to the first page named like its folder's parent,
  // across every source (core's display/text would take field-types/text's)
  const { default: config } = await import('../docfy.config.mjs');
  const names = config.sources.flatMap(({ root, pattern }) => {
    const walk = (dir) =>
      readdirSync(dir, { withFileTypes: true }).flatMap((entry) =>
        entry.isDirectory()
          ? entry.name === 'node_modules'
            ? []
            : walk(join(dir, entry.name))
          : entry.name.endsWith('.md')
            ? [join(dir, entry.name)]
            : [],
      );

    return walk(join(root, pattern.split('**')[0]))
      .filter((file) => !/[/\\](demo|[\w-]+-demo)[/\\]/.test(file))
      .map((file) =>
        basename(file) === 'index.md'
          ? basename(dirname(file))
          : basename(file, '.md'),
      );
  });

  for (const page of pageFiles.filter((page) => page !== 'index.md')) {
    const name = basename(dirname(page));

    assert.equal(
      names.filter((other) => other === name).length,
      1,
      `${page}: "${name}" names one page`,
    );
  }
});

test('the sheet docs: every demo has its code, a title and an order, and is on one page', () => {
  const names = new Map();
  const codes = new Map();

  for (const demo of demoFiles) {
    const markdown = read(demo);
    const fences = [
      ...markdown.matchAll(/^```(\w+) component\n([\s\S]*?)\n```$/gm),
    ];

    assert.equal(
      fences.length,
      1,
      `${demo}: one \`\`\`gjs component (or gts) fence`,
    );
    assert.ok(
      fences[0][2].includes('<template>'),
      `${demo}: its code renders something`,
    );
    assert.match(markdown, /^# \S/m, `${demo}: a # title`);
    assert.ok(
      Number.isFinite(Number(frontMatter(markdown).order)),
      `${demo}: an order`,
    );

    // a demo is on one page: no other demo has its file name or its code
    const name = basename(demo);
    assert.equal(
      names.get(name),
      undefined,
      `${demo}: its file name is on one page only`,
    );
    names.set(name, demo);
    assert.equal(
      codes.get(fences[0][2]),
      undefined,
      `${demo}: its code is on one page only`,
    );
    codes.set(fences[0][2], demo);

    // what the StackBlitz playground copies (lib/demo-playgrounds.mjs)
    for (const [, module] of fences[0][2].matchAll(
      /from\s*['"]site\/utils\/([\w-]+)['"]/g,
    )) {
      assert.doesNotThrow(
        () => site(`app/utils/${module}.js`),
        `${demo}: site/utils/${module} exists`,
      );
    }
  }
});

test('the sheet docs: every page has a title and an order, and examples unless listed', () => {
  const orders = new Map();

  for (const page of pageFiles) {
    const front = frontMatter(read(page));
    const folder = folderOf(page);
    const demos = demoFiles.filter((demo) => pageOf(demo) === folder);

    assert.ok(front.title, `${page}: a title`);
    assert.ok(Number.isFinite(Number(front.order)), `${page}: an order`);
    if (isStub(page)) {
      assert.equal(demos.length, 0, `${page}: an old URL's page has no demos`);
      continue;
    }
    assert.equal(
      orders.get(front.order),
      undefined,
      `${page}: its order is its own (${front.order})`,
    );
    orders.set(front.order, page);
    if (WITHOUT_EXAMPLES.has(folder)) {
      assert.equal(
        demos.length,
        0,
        `${page}: listed without examples, has none`,
      );
    } else {
      assert.ok(demos.length > 0, `${page}: has examples`);
    }
  }
});

test('the sheet docs build: each page with its demos, and every docs link resolves', async () => {
  const { default: Docfy } = await import('@docfy/core/lib/index.js');
  const { loadDocfyConfig } = await import(
    new URL('./config.js', import.meta.resolve('@docfy/ember-vite')).href
  );
  const config = await loadDocfyConfig(
    resolve(dirname(fileURLToPath(import.meta.url)), '..'),
  );
  const { content } = await new Docfy(config).run(config.sources);
  const ids = (headings) =>
    headings.flatMap((heading) => [heading.id, ...ids(heading.headings ?? [])]);
  const byUrl = new Map(content.map((page) => [page.meta.url, page]));
  const find = (url) => byUrl.get(url) ?? byUrl.get(`${url}/`);
  const sheetPages = content.filter((page) =>
    page.meta.url.startsWith(`${SHEET_URL}/`),
  );

  assert.equal(
    sheetPages.length,
    pageFiles.length,
    'every page file is a page',
  );
  let links = 0;

  for (const page of sheetPages) {
    const url = page.meta.url;
    const folder = url.slice(SHEET_URL.length + 1).replace(/\/$/, '');
    const demos = demoFiles.filter((demo) => pageOf(demo) === folder);

    assert.equal(
      page.demos?.length ?? 0,
      demos.length,
      `${url}: its ${demos.length} demos`,
    );
    assert.equal(
      [...page.rendered.matchAll(/<DocfyDemo[\s>]/g)].length,
      demos.length,
      `${url}: each demo is rendered`,
    );
    assert.doesNotMatch(
      page.rendered,
      /\[\[demos?-/,
      `${url}: no demo marker left as text`,
    );

    for (const [, href] of page.markdown.matchAll(/\]\((\/docs\/[^)\s]*)\)/g)) {
      const [path, hash] = href.split('#');
      const target = find(path);

      assert.ok(target, `${url}: the link ${href} has a page`);
      if (hash) {
        assert.ok(
          ids(target.meta.headings).includes(hash),
          `${url}: ${href} has its #${hash}`,
        );
      }
      links++;
    }
  }
  assert.ok(links > 100, `the pages link to each other (${links} links)`);
});
