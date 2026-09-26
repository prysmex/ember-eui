import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';

import EuiCard from '#src/components/eui-card.gts';

module('Integration | Component | eui-card', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders title and description', async function (assert) {
    await render(
      <template>
        <EuiCard @title="Hello" @description="World" />
      </template>
    );

    assert.dom('.euiCard').exists();
    assert.dom('.euiCard__title').hasText('Hello');
    assert.dom('.euiCard__description').hasText('World');
  });

  test('clicking the card forwards the click to the title button', async function (assert) {
    // relies on `didInsert (set this "link")` registering the title button
    let calls = 0;
    const onClick = () => calls++;

    await render(
      <template><EuiCard @title="Clickable" @onClick={{onClick}} /></template>
    );

    assert.dom('button.euiCard__titleButton').exists();

    await click('.euiCard');
    assert.strictEqual(calls, 1, 'outer click is forwarded once');

    await click('button.euiCard__titleButton');
    assert.strictEqual(calls, 2, 'direct click is not forwarded twice');
  });
});
