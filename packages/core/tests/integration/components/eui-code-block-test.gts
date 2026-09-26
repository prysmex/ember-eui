import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, waitFor } from '@ember/test-helpers';

import EuiCodeBlock from '#src/components/eui-code-block.gts';

const LINES = 500;
const longCode = Array.from(
  { length: LINES },
  (_, i) => `const line${i} = ${i};`
).join('\n');

module('Integration | Component | eui-code-block', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders highlighted code', async function (assert) {
    await render(
      <template>
        <EuiCodeBlock @language="js">const a = 1;</EuiCodeBlock>
      </template>
    );

    await waitFor('pre.euiCodeBlock__pre code .token');
    assert.dom('pre.euiCodeBlock__pre code').hasText('const a = 1;');
  });

  test('isVirtualized only renders a window of the lines', async function (assert) {
    // uses @html-next/vertical-collection as the <code> element
    await render(
      <template>
        <EuiCodeBlock
          @language="js"
          @isVirtualized={{true}}
          @overflowHeight={{200}}
        >{{longCode}}</EuiCodeBlock>
      </template>
    );

    await waitFor('code.euiCodeBlock__code[data-code-language="js"] > span');

    const rendered = document.querySelectorAll(
      'code.euiCodeBlock__code > span'
    ).length;

    assert.true(rendered > 0, `renders some lines (${rendered})`);
    assert.true(rendered < LINES, `does not render all ${LINES} lines`);
  });
});
