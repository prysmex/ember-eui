import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiHighlight from '#src/components/eui-highlight.gts';
import EuiMark from '#src/components/eui-mark.gts';

module('Integration | Component | eui-highlight and eui-mark', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiMark renders a <mark>', async function (assert) {
    await render(<template><EuiMark>match</EuiMark></template>);

    assert.dom('mark.euiMark').hasText('match');
  });

  test('EuiHighlight marks the first match, ignoring case', async function (assert) {
    await render(<template><EuiHighlight @text="Apple and apple pie" @search="APPLE" /></template>);

    assert.dom('mark').exists({ count: 1 });
    assert.dom('mark').hasText('Apple');
    assert.dom('span').hasText('Apple and apple pie');
  });

  test('@highlightAll and @strict', async function (assert) {
    await render(
      <template>
        <EuiHighlight class="all" @text="Apple and apple pie" @search="apple" @highlightAll={{true}} />
        <EuiHighlight class="strict" @text="Apple and apple pie" @search="apple" @strict={{true}} />
      </template>
    );

    assert.dom('.all mark').exists({ count: 2 });
    assert.dom('.strict mark').exists({ count: 1 });
    assert.dom('.strict mark').hasText('apple');
  });

  test('search text is not a regular expression', async function (assert) {
    await render(<template><EuiHighlight @text="1+1 (two)" @search="(two)" /></template>);

    assert.dom('mark').hasText('(two)');
  });
});
