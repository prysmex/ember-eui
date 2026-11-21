import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const docs = resolve(
  dirname(fileURLToPath(import.meta.url)),
  '../../packages/sheet/docs/sheet',
);
const read = (path) => readFileSync(resolve(docs, path), 'utf8');

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
