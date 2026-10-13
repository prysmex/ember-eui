import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, fillIn, render, settled, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiComboBox from '#src/components/eui-combo-box.gts';

const USERS = [{ name: 'Jane Cooper' }, { name: 'Raj Patel' }];
const INPUT =
  'input.euiComboBox__input:not(.fake-input-for-html-form-validity)';
const OPTION = '.euiComboBoxOptionsList .euiComboBoxOption[role="option"]';

class State {
  @tracked selected: unknown[] = [];
  onChange = (selected: unknown[]) => (this.selected = selected);
  search = (term: string) =>
    new Promise((resolve) =>
      setTimeout(
        () =>
          resolve(
            USERS.filter((u) => u.name.toLowerCase().includes(term.toLowerCase()))
          ),
        10
      )
    );
}

// What a real browser does: mousedown on the option moves focus out of the
// input (unless prevented), then mouseup and click land on the option.
async function realClick(option: HTMLElement) {
  const input = document.querySelector<HTMLInputElement>(INPUT)!;
  const down = new MouseEvent('mousedown', { bubbles: true, cancelable: true });
  option.dispatchEvent(down);
  if (!down.defaultPrevented) input.blur();
  await settled();
  if (!option.isConnected) return 'option was removed before the click';
  option.dispatchEvent(new MouseEvent('mouseup', { bubbles: true, cancelable: true }));
  option.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
  await settled();
  return down.defaultPrevented ? 'prevented' : 'not prevented';
}

module('Integration | Component | eui-combo-box > clicking options keeps focus', function (hooks) {
  setupRenderingTest(hooks);

  test('with @search, a real click selects the option', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiComboBox
          @search={{state.search}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          as |user|
        >{{user.name}}</EuiComboBox>
      </template>
    );
    await click(INPUT);
    await fillIn(INPUT, 'ja');
    await waitUntil(() => document.querySelector(OPTION));

    // the list is replaced while each search loads; clicks must keep working
    const result = await realClick(document.querySelector<HTMLElement>(OPTION)!);

    assert.strictEqual(result, 'prevented', 'mousedown on the list keeps focus in the input');
    assert.deepEqual(state.selected, [USERS[0]]);

    await fillIn(INPUT, 'raj');
    await waitUntil(() => document.querySelector(OPTION)?.textContent?.includes('Raj'));
    await realClick(document.querySelector<HTMLElement>(OPTION)!);

    assert.deepEqual(state.selected, [USERS[0], USERS[1]], 'a second search still selects');
  });

  test('with @options, a real click selects the option', async function (assert) {
    const state = new State();
    await render(
      <template>
        <EuiComboBox
          @options={{USERS}}
          @searchField="name"
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          as |user|
        >{{user.name}}</EuiComboBox>
      </template>
    );
    await click(INPUT);
    await waitUntil(() => document.querySelector(OPTION));

    const result = await realClick(document.querySelectorAll<HTMLElement>(OPTION)[1]!);

    assert.strictEqual(result, 'prevented');
    assert.deepEqual(state.selected, [USERS[1]]);
  });
});
