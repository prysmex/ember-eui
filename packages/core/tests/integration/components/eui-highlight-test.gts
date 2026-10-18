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

  test('accents are ignored by default, both ways; @ignoreAccents={{false}} turns it off', async function (assert) {
    await render(
      <template>
        <EuiHighlight class="off" @text="Médico" @search="medico" @ignoreAccents={{false}} />
        <EuiHighlight class="on" @text="Médico general" @search="medico" />
        <EuiHighlight class="reverse" @text="Medicina" @search="MÉDIC" />
        <EuiHighlight class="all" @text="Médico y médica" @search="medic" @highlightAll={{true}} />
      </template>
    );

    assert.dom('.off mark').doesNotExist('off with false');
    assert.dom('.on mark').hasText('Médico');
    assert.dom('.on').hasText('Médico general');
    assert.dom('.reverse mark').hasText('Medic');
    assert.deepEqual(
      [...document.querySelectorAll('.all mark')].map((mark) => mark.textContent),
      ['Médic', 'médic']
    );
  });

  test('ignoring accents keeps a decomposed accent with its letter', async function (assert) {
    const text = 'Me\u0301dico'; // "e" + combining acute accent

    await render(<template><EuiHighlight @text={{text}} @search="me" /></template>);

    assert.strictEqual(document.querySelector('mark')?.textContent, 'Me\u0301');
  });

  test('values that are not strings do not throw, and highlight nothing', async function (assert) {
    const notText = 42 as unknown as string;
    const nothing = null as unknown as string;
    const notSearch = { term: 'app' } as unknown as string;
    const mixed = [null, 7, 'pie'] as unknown as string[];

    await render(
      <template>
        <EuiHighlight class="number" @text={{notText}} @search="4" />
        <EuiHighlight class="null" @text={{nothing}} @search="a" />
        <EuiHighlight class="search" @text="Apple pie" @search={{notSearch}} />
        <EuiHighlight class="mixed" @text="Apple pie" @search={{mixed}} @highlightAll={{true}} />
      </template>
    );

    assert.dom('.number').hasText('42');
    assert.dom('.number mark').doesNotExist();
    assert.dom('.null').hasText('');
    assert.dom('.search').hasText('Apple pie');
    assert.dom('.search mark').doesNotExist();
    assert.dom('.mixed mark').hasText('pie', 'the strings still match');
  });
});
