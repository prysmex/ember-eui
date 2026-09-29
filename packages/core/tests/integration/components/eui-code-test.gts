import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import { SUPPORTED_LANGUAGES } from '#src/-private/language-loader.ts';
import EuiCode from '#src/components/eui-code.gts';
import EuiCodeBlock from '#src/components/eui-code-block.gts';
import EuiMarkdownFormat from '#src/components/eui-markdown-format.gts';

const fenced = '```yaml\nkey: value\n```';

module('Integration | Component | eui-code (languages)', function (hooks) {
  setupRenderingTest(hooks);

  test('a language loads on first use and then highlights', async function (assert) {
    // bash is not built into refractor/core: rendering loads it, and
    // settled() waits for it
    await render(<template><EuiCode @language="bash">echo "hi"</EuiCode></template>);

    assert.dom('code.euiCode .token.string').hasText('"hi"');
    assert.dom('code.euiCode').hasText('echo "hi"');
  });

  test('a language loads with the languages it builds on', async function (assert) {
    await render(
      <template>
        <EuiCodeBlock @language="tsx">const a: number = 1;</EuiCodeBlock>
      </template>
    );

    assert.dom('pre.euiCodeBlock__pre code .token.builtin').hasText('number');
  });

  test('aliases load their language', async function (assert) {
    await render(<template><EuiCode @language="sh-session">$ ls</EuiCode></template>);

    assert.dom('code.euiCode .token').exists();
  });

  test('built-in languages and unknown ones need no loading', async function (assert) {
    await render(
      <template>
        <EuiCode @language="js" class="js">const a = 1;</EuiCode>
        <EuiCode @language="not-a-language" class="unknown">const a = 1;</EuiCode>
      </template>
    );

    assert.dom('code.js .token.keyword').hasText('const');
    assert.dom('code.unknown .token').doesNotExist('unknown languages stay plain text');
    assert.dom('code.unknown').hasText('const a = 1;');
  });

  test('markdown code blocks load their language', async function (assert) {
    await render(<template><EuiMarkdownFormat @value={{fenced}} /></template>);

    assert.dom('pre code .token.key').hasText('key');
  });

  test('every refractor language and alias is supported', function (assert) {
    for (const name of ['markup', 'html', 'css', 'js', 'ts', 'hbs', 'json', 'yml', 'vb']) {
      assert.true(SUPPORTED_LANGUAGES.includes(name), name);
    }
  });
});
