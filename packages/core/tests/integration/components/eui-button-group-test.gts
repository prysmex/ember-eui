import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiButtonGroup from '#src/components/eui-button-group.gts';

const OPTIONS = [
  { id: 'left', label: 'Left', value: 'l' },
  { id: 'center', label: 'Center', value: 'c' },
  { id: 'right', label: 'Right', value: 'r', isDisabled: true }
];

class State {
  @tracked idSelected = 'left';
  @tracked idToSelectedMap: Record<string, boolean> = { left: true };
  calls: unknown[][] = [];

  onChangeSingle = (id: string, value: string) => {
    this.calls.push([id, value]);
    this.idSelected = id;
  };

  onChangeMulti = (id: string) => {
    this.calls.push([id]);
    this.idToSelectedMap = { ...this.idToSelectedMap, [id]: !this.idToSelectedMap[id] };
  };
}

module('Integration | Component | eui-button-group', function (hooks) {
  setupRenderingTest(hooks);

  test('single selection uses radio inputs', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiButtonGroup @legend="Alignment" @options={{OPTIONS}} @idSelected={{state.idSelected}} @onChange={{state.onChangeSingle}} />
      </template>
    );

    assert.dom('fieldset.euiButtonGroup').hasClass('euiButtonGroup--small').hasClass('euiButtonGroup--text');
    assert.dom('fieldset legend').hasText('Alignment');
    assert.dom('input[type="radio"]').exists({ count: 2 }, 'disabled options render as buttons');
    assert.dom('.euiButtonGroupButton-isSelected').hasText('Left');

    await click('label.euiButtonGroupButton:nth-child(2) input');

    assert.deepEqual(state.calls, [['center', 'c']]);
    assert.dom('.euiButtonGroupButton-isSelected').hasText('Center');
  });

  test('multi selection uses buttons with aria-pressed', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiButtonGroup @legend="Styles" @type="multi" @options={{OPTIONS}} @idToSelectedMap={{state.idToSelectedMap}} @onChange={{state.onChangeMulti}} />
      </template>
    );

    assert.dom('button.euiButtonGroupButton').exists({ count: 3 });
    assert.dom('button.euiButtonGroupButton:nth-child(1)').hasAttribute('aria-pressed', 'true');

    await click('button.euiButtonGroupButton:nth-child(2)');

    assert.deepEqual(state.calls, [['center']]);
    assert.dom('button.euiButtonGroupButton:nth-child(2)').hasAttribute('aria-pressed', 'true');
    assert.dom('button.euiButtonGroupButton:nth-child(3)').isDisabled();
  });

  test('size, color, full width and icon only', async function (assert) {
    const icons = [{ id: 'bold', label: 'Bold', iconType: 'editorBold' }];

    await render(
      <template>
        <EuiButtonGroup @legend="Text" @options={{icons}} @buttonSize="m" @color="primary" @isFullWidth={{true}} @isIconOnly={{true}} />
      </template>
    );

    assert.dom('.euiButtonGroup').hasClass('euiButtonGroup--medium').hasClass('euiButtonGroup--primary').hasClass('euiButtonGroup--fullWidth');
    assert.dom('.euiButtonGroupButton').hasClass('euiButtonGroupButton-isIconOnly');
    assert.dom('.euiButtonGroupButton svg.euiIcon').exists();
  });

  // Bug: a disabled group gets the full width class (see eui-button-group.gts)
  test.todo('@isDisabled disables the group without making it full width', async function (assert) {
    await render(<template><EuiButtonGroup @legend="Off" @options={{OPTIONS}} @isDisabled={{true}} /></template>);

    assert.dom('fieldset').isDisabled();
    assert.dom('fieldset').doesNotHaveClass('euiButtonGroup--fullWidth');
  });
});
