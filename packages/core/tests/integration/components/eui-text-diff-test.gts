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
});
