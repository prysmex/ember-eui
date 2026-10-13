import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { fillIn, render, settled } from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';

import EuiSelectable from '#src/components/eui-selectable.gts';

import type { EuiSelectableOption } from '#src/-private/selectable-options.ts';

const options: EuiSelectableOption[] = [{ label: 'Titan' }, { label: 'Enceladus' }];
const noop = () => {};

function attr(selector: string, name: string): string | null {
  return document.querySelector(selector)!.getAttribute(name);
}

// Upstream selectable.tsx `getAccessibleName`: the root's `aria-label` /
// `aria-describedby` are taken out of the root's props and name the search
// and the listbox; `searchProps` / `listProps` keys of the same names win.
module('Integration | Component | EuiSelectable accessible name (upstream getAccessibleName)', function (hooks) {
  setupRenderingTest(hooks);

  test('the root aria-label names the search and the listbox, not the root', async function (assert) {
    await render(<template><EuiSelectable aria-label="Moons" @options={{options}} @onChange={{noop}} @searchable={{true}} data-test="root" /></template>);

    assert.dom('[data-test="root"]').doesNotHaveAttribute('aria-label');
    assert.dom('input.euiSelectableSearch').hasAttribute('aria-label', 'Moons');
    const instructions = attr('input.euiSelectableSearch', 'aria-describedby')!;
    assert.true(instructions.endsWith('_instructions'), 'a label keeps the instructions');
    assert.dom(`#${instructions}`).includesText('Use the Up and Down arrow keys');
    assert.dom('[role="listbox"]').hasAttribute('aria-label', 'Moons').doesNotHaveAttribute('aria-describedby');
  });

  test('without a search the listbox gets the root aria-label', async function (assert) {
    await render(<template><EuiSelectable aria-label="Moons" @options={{options}} @onChange={{noop}} data-test="root" /></template>);

    assert.dom('[data-test="root"]').doesNotHaveAttribute('aria-label');
    assert.dom('[role="listbox"]').hasAttribute('aria-label', 'Moons');
  });

  test('the root aria-describedby describes the search (+ message id) and the list (+ instructions id)', async function (assert) {
    await render(
      <template>
        <p id="help">Pick moons</p>
        <EuiSelectable aria-describedby="help" @options={{options}} @onChange={{noop}} @searchable={{true}} data-test="root" />
      </template>
    );

    assert.dom('[data-test="root"]').doesNotHaveAttribute('aria-describedby');
    const search = attr('input.euiSelectableSearch', 'aria-describedby')!.split(' ');
    assert.strictEqual(search[0], 'help');
    assert.true(search[1]!.endsWith('_messageContent'), 'message id appended, instructions replaced');
    assert.dom('input.euiSelectableSearch').doesNotHaveAttribute('aria-label', 'no placeholder name when described');
    const list = attr('[role="listbox"]', 'aria-describedby')!.split(' ');
    assert.strictEqual(list[0], 'help');
    assert.true(list[1]!.endsWith('_instructions'));
    assert.dom('[role="listbox"]').doesNotHaveAttribute('aria-label');

    await fillIn('input.euiSelectableSearch', 'zzz');
    const messageId = attr('input.euiSelectableSearch', 'aria-describedby')!.split(' ')[1]!;
    assert.dom(`#${messageId}`).includesText('zzz', 'the message is the described element');
  });

  test('searchProps / listProps aria keys win over the root', async function (assert) {
    const searchProps = { 'aria-label': 'Search moons' };
    const listProps = { 'aria-describedby': 'list-help' };
    await render(
      <template>
        <EuiSelectable aria-label="Moons" @options={{options}} @onChange={{noop}} @searchable={{true}} @searchProps={{searchProps}} @listProps={{listProps}} />
      </template>
    );

    assert.dom('input.euiSelectableSearch').hasAttribute('aria-label', 'Search moons');
    assert.true(attr('input.euiSelectableSearch', 'aria-describedby')!.endsWith('_instructions'));
    const list = attr('[role="listbox"]', 'aria-describedby')!.split(' ');
    assert.strictEqual(list[0], 'list-help');
    assert.dom('[role="listbox"]').doesNotHaveAttribute('aria-label');
  });

  test('listProps aria-label, and searchProps aria-describedby', async function (assert) {
    await render(
      <template>
        <EuiSelectable
          @options={{options}}
          @onChange={{noop}}
          @searchable={{true}}
          @searchProps={{hash aria-describedby="search-help"}}
          @listProps={{hash aria-label="Moon list"}}
        />
      </template>
    );

    const search = attr('input.euiSelectableSearch', 'aria-describedby')!.split(' ');
    assert.strictEqual(search[0], 'search-help');
    assert.true(search[1]!.endsWith('_messageContent'));
    assert.dom('input.euiSelectableSearch').doesNotHaveAttribute('aria-label');
    assert.dom('[role="listbox"]').hasAttribute('aria-label', 'Moon list');
  });

  test('without a name: placeholder name for a searchable selectable (not the custom placeholder), nothing otherwise', async function (assert) {
    class State {
      @tracked searchable = true;
    }
    const state = new State();
    await render(
      <template>
        <EuiSelectable @options={{options}} @onChange={{noop}} @searchable={{state.searchable}} @searchProps={{hash placeholder="Find a moon"}} />
      </template>
    );

    assert.dom('input.euiSelectableSearch').hasAttribute('placeholder', 'Find a moon').hasAttribute('aria-label', 'Filter options');
    assert.dom('[role="listbox"]').hasAttribute('aria-label', 'Filter options');
    state.searchable = false;
    await settled();
    assert.dom('[role="listbox"]').doesNotHaveAttribute('aria-label');
  });

  test('a changed root aria-label is moved again', async function (assert) {
    class State {
      @tracked label = 'Moons';
    }
    const state = new State();
    await render(<template><EuiSelectable aria-label={{state.label}} @options={{options}} @onChange={{noop}} data-test="root" /></template>);

    assert.dom('[role="listbox"]').hasAttribute('aria-label', 'Moons');
    state.label = 'Satellites';
    await settled();
    assert.dom('[data-test="root"]').doesNotHaveAttribute('aria-label');
    assert.dom('[role="listbox"]').hasAttribute('aria-label', 'Satellites');
  });
});
