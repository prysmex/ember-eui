import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, fillIn, render, rerender, select, triggerKeyEvent } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiRefreshInterval from '#src/components/eui-refresh-interval.gts';

class State {
  @tracked isPaused = true;
  @tracked refreshInterval = 5000;
  changes: { refreshInterval: number; isPaused: boolean }[] = [];

  apply = (change: { refreshInterval: number; isPaused: boolean }) => {
    this.changes.push(change);
    this.isPaused = change.isPaused;
    this.refreshInterval = change.refreshInterval;
  };
}

module('Integration | Component | eui-refresh-interval', function (hooks) {
  setupRenderingTest(hooks);

  test('it shows the interval and starts and stops refreshing', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiRefreshInterval @isPaused={{state.isPaused}} @refreshInterval={{state.refreshInterval}} @applyRefreshInterval={{state.apply}} />
      </template>
    );

    assert.dom('legend').hasText('Refresh every');
    assert.dom('input').hasValue('5');
    assert.dom('select').hasValue('s');
    assert.dom('.euiRefreshInterval__startButton').hasText('Start');

    await click('.euiRefreshInterval__startButton');
    await rerender();
    assert.deepEqual(state.changes.at(-1), { refreshInterval: 5000, isPaused: false });
    assert.dom('.euiRefreshInterval__startButton').hasText('Stop');

    await fillIn('input', '2');
    await select('select', 'm');
    assert.deepEqual(state.changes.at(-1), { refreshInterval: 120000, isPaused: false });
  });

  test('an empty value disables the button; Enter starts', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiRefreshInterval @isPaused={{state.isPaused}} @refreshInterval={{state.refreshInterval}} @applyRefreshInterval={{state.apply}} />
      </template>
    );

    await fillIn('input', '');
    assert.dom('.euiRefreshInterval__startButton').isDisabled();

    await fillIn('input', '10');
    await triggerKeyEvent('input', 'keydown', 'Enter');
    assert.deepEqual(state.changes.at(-1), { refreshInterval: 10000, isPaused: false });
  });
});
