import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiTextDiff from '#src/components/eui-text-diff.gts';

module('Integration | Component | eui-text-diff', function (hooks) {
  setupRenderingTest(hooks);

  test('it marks removed and added words', async function (assert) {
    await render(<template><EuiTextDiff @beforeText="The quick brown fox" @afterText="The slow brown dog" /></template>);

    assert.dom('.euiTextDiff del').exists({ count: 2 });
    assert.dom('.euiTextDiff ins').exists({ count: 2 });
    assert.deepEqual(
      [...this.element.querySelectorAll('del')].map((el) => el.textContent),
      ['quick', 'fox']
    );
    assert.deepEqual(
      [...this.element.querySelectorAll('ins')].map((el) => el.textContent),
      ['slow', 'dog']
    );
    assert.dom('.euiTextDiff').hasText('The quickslow brown foxdog');
  });

  test('character granularity', async function (assert) {
    await render(<template><EuiTextDiff @beforeText="kitten" @afterText="sitting" @granularity="characters" /></template>);

    assert.deepEqual(
      [...this.element.querySelectorAll('ins')].map((el) => el.textContent),
      ['s', 'i', 'g']
    );
  });

  test('the block renders the chunks yourself', async function (assert) {
    await render(
      <template>
        <EuiTextDiff @beforeText="a b" @afterText="a c" as |chunks|>
          {{#each chunks as |chunk|}}<i>{{chunk}}</i>{{/each}}
        </EuiTextDiff>
      </template>
    );

    assert.dom('.euiTextDiff').doesNotExist();
    assert.dom('i').exists({ count: 3 });
  });

  test('@insertComponent and @deleteComponent take a tag name or a component, @sameComponent wraps unchanged text', async function (assert) {
    const Added = <template><b class="added">{{yield}}</b></template>;
    await render(
      <template>
        <EuiTextDiff
          @beforeText="The quick fox"
          @afterText="The slow fox"
          @insertComponent={{Added}}
          @deleteComponent="mark"
          @sameComponent="span"
        />
      </template>
    );

    assert.dom('.euiTextDiff ins').doesNotExist();
    assert.dom('.euiTextDiff del').doesNotExist();
    assert.dom('.euiTextDiff mark').hasText('quick');
    assert.dom('.euiTextDiff b.added').hasText('slow');
    assert.dom('.euiTextDiff > span').exists('unchanged text is wrapped');
    assert.dom('.euiTextDiff').hasText('The quickslow fox');
  });

  test('without wrapper args the tags stay ins/del and unchanged text is bare', async function (assert) {
    await render(<template><EuiTextDiff @beforeText="a b" @afterText="a c" /></template>);

    assert.dom('.euiTextDiff ins').hasText('c');
    assert.dom('.euiTextDiff del').hasText('b');
    assert.dom('.euiTextDiff > span').doesNotExist();
  });

  test('@timeout bounds the comparison: past it, the differing part is one removal and one insertion', async function (assert) {
    const tokens = Array.from({ length: 1500 }, (_, i) => `w${i}`);
    const before = tokens.join(' ');
    const after = tokens.map((token, i) => (i % 2 ? `x${i}` : token)).join(' ');

    await render(<template><EuiTextDiff @beforeText={{before}} @afterText={{after}} @timeout={{0}} /></template>);
    const exact = this.element.querySelectorAll('ins').length;
    assert.ok(exact > 100, `@timeout={{0}} diffs fully (${exact} insertions)`);

    await render(<template><EuiTextDiff @beforeText={{before}} @afterText={{after}} @timeout={{0.0005}} /></template>);
    assert.dom('ins').exists({ count: 1 }, 'one coarse insertion');
    assert.dom('del').exists({ count: 1 }, 'one coarse removal');
  });
});
