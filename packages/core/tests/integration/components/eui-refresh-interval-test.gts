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

    await click('.euiRefreshInterval__startButton');
    assert.deepEqual(state.changes.at(-1), { refreshInterval: 5000, isPaused: true });
    assert.dom('.euiRefreshInterval__startButton').hasText('Start');

    await click('.euiRefreshInterval__startButton');

    await fillIn('input', '2');
    await select('select', 'm');
    assert.deepEqual(state.changes.at(-1), { refreshInterval: 120000, isPaused: false });

    await fillIn('input', '120');
    assert.dom('input').hasValue('120');
    assert.dom('select').hasValue('m', 'accepting an edit preserves the units chosen by the user');
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

  test('external interval updates synchronize the fields, description and next callback', async function (assert) {
    const state = new State();

    await render(<template><EuiRefreshInterval @isPaused={{state.isPaused}} @refreshInterval={{state.refreshInterval}} @applyRefreshInterval={{state.apply}} /></template>);

    state.refreshInterval = 120000;
    await rerender();
    assert.dom('input').hasValue('2');
    assert.dom('select').hasValue('m');
    assert.dom('.euiScreenReaderOnly').hasText('Refresh interval currently set to 2 Minutes.');
    assert.deepEqual(state.changes, [], 'synchronization does not emit a user change');

    await click('.euiRefreshInterval__startButton');
    assert.deepEqual(state.changes.at(-1), { refreshInterval: 120000, isPaused: false });

    state.refreshInterval = 0;
    await rerender();
    assert.dom('input').hasValue('0');
    assert.dom('.euiRefreshInterval__startButton').isDisabled();
    const count = state.changes.length;
    await triggerKeyEvent('input', 'keydown', 'Enter');
    assert.strictEqual(state.changes.length, count, 'invalid intervals cannot start through Enter');
  });

  test('local edits survive ignored callbacks and rerenders until the interval changes externally', async function (assert) {
    const state = new State();
    const changes: number[] = [];
    const record = ({ refreshInterval }: { refreshInterval: number }) => changes.push(refreshInterval);

    await render(<template><EuiRefreshInterval @refreshInterval={{state.refreshInterval}} @applyRefreshInterval={{record}} /></template>);

    await fillIn('input', '2');
    await select('select', 'm');
    await rerender();
    assert.deepEqual(changes, [2000, 120000]);
    assert.dom('input').hasValue('2');
    assert.dom('select').hasValue('m');

    await fillIn('input', '');
    await rerender();
    assert.dom('input').hasValue('', 'an empty draft survives rerenders');

    state.refreshInterval = 120000;
    await rerender();
    assert.dom('input').hasValue('2', 'external arguments replace an empty draft even if they match an earlier ignored edit');
    assert.dom('select').hasValue('m');
  });
});
