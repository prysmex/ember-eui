import assert from 'node:assert/strict';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';
import Docfy from '@docfy/core/lib/index.js';

import tableCode, { tokenize } from './docfy-table-code.mjs';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');

/** The site's docfy config (with @docfy/ember-vite's own plugins). */
async function loadConfig(config) {
  const { loadDocfyConfig } = await import(
    new URL('./config.js', import.meta.resolve('@docfy/ember-vite')).href
  );

  return loadDocfyConfig(root, config ? { config } : {});
}

async function render(config) {
  const { content } = await new Docfy(config).run(config.sources);

  return new Map(content.map((page) => [page.meta.url, page.rendered]));
}

const TOKEN = /<span class="docsTok docsTok--([a-z]+)">([^<]*)<\/span>/g;
const kinds = (html) =>
  [...html.matchAll(TOKEN)].map(([, kind, value]) => `${kind}:${value}`);

test('tokenize: a type splits into its kinds, and the tokens join to the input', () => {
  const cases = {
    "'primary' | 'accent'": ['string', 'text', 'punctuation', 'text', 'string'],
    '(id: string, value?: string | Event) => void': [
      'punctuation',
      'text',
      'punctuation',
      'text',
      'keyword',
      'punctuation',
      'text',
      'punctuation',
      'punctuation',
      'text',
      'keyword',
      'text',
      'punctuation',
      'text',
      'type',
      'punctuation',
      'text',
      'punctuation',
      'text',
      'keyword',
    ],
    'Array<EuiBasicTableColumn<T>>': [
      'type',
      'punctuation',
      'type',
      'punctuation',
      'type',
      'punctuation',
      'punctuation',
    ],
    false: ['boolean'],
    1.5: ['number'],
    'readonly string[]': [
      'keyword',
      'text',
      'keyword',
      'punctuation',
      'punctuation',
    ],
    'keyof typeof x': ['keyword', 'text', 'keyword', 'text'],
  };

  for (const [source, expected] of Object.entries(cases)) {
    const tokens = tokenize(source);

    assert.deepEqual(
      tokens.map((token) => token.type),
      expected,
      source,
    );
    assert.equal(tokens.map((token) => token.value).join(''), source);
  }
});

test('tokenize: names (a property, a parameter, a member) and lower-case identifiers stay text', () => {
  assert.deepEqual(
    tokenize('{ t: (key: string) => string; }')
      .filter((t) => t.type === 'text' && t.value.trim())
      .map((t) => t.value.trim()),
    ['t', 'key'],
  );
  assert.deepEqual(
    tokenize('row.Parent ?? row.parent').map((t) => t.type),
    [
      'text',
      'punctuation',
      'text',
      'punctuation',
      'text',
      'punctuation',
      'text',
    ],
    'a member is text, also a capitalised one',
  );
  assert.deepEqual(
    tokenize('{ Name: string }').map((t) => t.type),
    [
      'punctuation',
      'text',
      'punctuation',
      'text',
      'keyword',
      'text',
      'punctuation',
    ],
  );
});

test('tokenize: `{{` and `}}` stay one token, strings and odd characters too', () => {
  assert.deepEqual(tokenize('{{a}}'), [
    { type: 'punctuation', value: '{{' },
    { type: 'text', value: 'a' },
    { type: 'punctuation', value: '}}' },
  ]);
  assert.deepEqual(tokenize("'it\\'s'"), [
    { type: 'string', value: "'it\\'s'" },
  ]);
  assert.deepEqual(tokenize("'open"), [{ type: 'string', value: "'open" }]);
  assert.deepEqual(tokenize('…'), [{ type: 'text', value: '…' }]);
  assert.deepEqual(tokenize(''), []);
});

test('a page: the Type and Default columns and the first column’s names are coloured; nothing else', async () => {
  const dir = mkdtempSync(join(tmpdir(), 'docfy-table-code-'));

  try {
    writeFileSync(
      join(dir, 'page.md'),
      [
        '# Page',
        '',
        'Prose `string` and `@arg` stay plain.',
        '',
        '| Argument | Type | Default | Description |',
        '| --- | --- | --- | --- |',
        "| `@size` | `'s' \\| 'm'` | `'m'` | Not `string` here. |",
        '| `@count` | `number` | `1` | |',
        '| `<:append>` | `{{x}}` | `false` | |',
        '| `EuiButton @fill={{true}}` | | | |',
        '',
        '| Variable | Light |',
        '| --- | --- |',
        '| `--eui-x` | `#fff` |',
        '',
      ].join('\n'),
    );

    const config = await loadConfig({
      plugins: [tableCode],
      sources: [{ root: dir, pattern: '*.md', urlPrefix: 'docs' }],
    });
    const [html] = (await render(config)).values();

    assert.deepEqual(kinds(html), [
      'arg:@size',
      "string:'s'",
      'punctuation:|',
      "string:'m'",
      "string:'m'",
      'arg:@count',
      'keyword:number',
      'number:1',
      'block:&#x3C;:append>',
      'punctuation:\\{{',
      'punctuation:}}',
      'boolean:false',
    ]);
    assert.match(html, /Prose <code>string<\/code> and <code>@arg<\/code>/);
    assert.match(
      html,
      /Not <code>string<\/code> here/,
      'the Description column is plain',
    );
    assert.match(
      html,
      /<code>EuiButton @fill=\\\{\{true}}<\/code>/,
      'other first-column code is plain, and escaped',
    );
    assert.match(html, /<code>--eui-x<\/code>/);
    assert.match(
      html,
      /<code>#fff<\/code>/,
      'a table without Type or Default columns: only names',
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('the docs corpus: the spans are the only change, inside table cells only', async () => {
  const config = await loadConfig();
  const without = await loadConfig();

  without.plugins = without.plugins.filter((plugin) => plugin !== tableCode);
  assert.equal(
    without.plugins.length,
    config.plugins.length - 1,
    'the plugin is in the site config',
  );

  const coloured = await render(config);
  const plain = await render(without);
  let spans = 0;
  let pages = 0;

  for (const [url, html] of coloured) {
    const count = [...html.matchAll(TOKEN)].length;
    const inCells = [...html.matchAll(/<td>[\s\S]*?<\/td>/g)].reduce(
      (sum, [cell]) => sum + [...cell.matchAll(TOKEN)].length,
      0,
    );

    assert.equal(inCells, count, `${url}: every span is in a table cell`);
    assert.equal(
      html.replace(TOKEN, '$2'),
      plain.get(url),
      `${url}: the same page without the spans`,
    );
    spans += count;
    if (count) pages++;
  }
  assert.ok(pages > 100, `the API pages are coloured (${pages})`);
  assert.ok(spans > 5000, `many tokens (${spans})`);
});
