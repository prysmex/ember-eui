import assert from 'node:assert/strict';
import { test } from 'node:test';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import Docfy from '@docfy/core/lib/index.js';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');

test('all generated demo snippets contain source without nested code-block controls', async () => {
  // Use the same config loader as the Vite plugin, including its built-in plugins.
  const { loadDocfyConfig } = await import(
    new URL('./config.js', import.meta.resolve('@docfy/ember-vite')).href
  );
  const config = await loadDocfyConfig(root, {});
  const { content } = await new Docfy(config).run(config.sources);
  let snippets = 0;
  let proseBlocks = 0;
  let templates = 0;
  let components = 0;

  for (const page of content) {
    proseBlocks += [...page.rendered.matchAll(/<DocfyCodeBlock[\s>]/g)].length;
    for (const [snippet] of page.rendered.matchAll(
      /<(?:demo\.)?Snippet[\s>][\s\S]*?<\/(?:demo\.)?Snippet>/g,
    )) {
      snippets++;
      if (snippet.includes('@name="template"')) templates++;
      if (snippet.includes('@name="component"')) components++;
      assert.ok(
        !snippet.includes('<DocfyCodeBlock'),
        `${page.meta.url}: no nested Copy button or layout whitespace`,
      );
      assert.match(
        snippet,
        /<pre><code[\s>]/,
        `${page.meta.url}: the original source is preserved`,
      );
    }
  }
  assert.ok(snippets > 300, 'checked the complete docs corpus');
  assert.ok(templates > 0 && components > 0, 'checked both source tabs');
  assert.ok(proseBlocks > 0, 'prose code blocks retain their controls');
});
