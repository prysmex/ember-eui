import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { click, render, settled } from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';

import EuiFlexItem from '#src/components/eui-flex-item.gts';

module('Integration | Component | eui-flex-item', function (hooks) {
  setupRenderingTest(hooks);

  test('dynamic tags preserve attributes, content and modifiers when updated', async function (assert) {
    class State {
      @tracked tagName = 'section';
    }

    const state = new State();
    let clicks = 0;
    const onClick = () => clicks++;

    await render(
      <template>
        <EuiFlexItem
          @tagName={{state.tagName}}
          class="custom"
          data-test-item
          {{on "click" onClick}}
        >
          Content
        </EuiFlexItem>
      </template>
    );

    assert.dom('section[data-test-item]').hasClass('euiFlexItem').hasClass('custom').hasText('Content');
    assert.dom('[data-test-item]').doesNotHaveClass('ember-view').doesNotHaveAttribute('id');
    await click('[data-test-item]');
    assert.strictEqual(clicks, 1);

    state.tagName = 'article';
    await settled();

    assert.dom('section[data-test-item]').doesNotExist();
    assert.dom('article[data-test-item]').hasClass('euiFlexItem').hasClass('custom').hasText('Content');
    await click('[data-test-item]');
    assert.strictEqual(clicks, 2);
  });
});
