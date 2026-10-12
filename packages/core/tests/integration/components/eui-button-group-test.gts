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

    // Latest-only: no size/color modifier classes (sizes and colors are
    // measured in eui-buttons-misc-test.gts).
    assert.dom('fieldset.euiButtonGroup').doesNotHaveClass('euiButtonGroup--small');
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

    // Latest-only: full width is measured instead of a modifier class.
    assert.strictEqual(getComputedStyle(document.querySelector('.euiButtonGroup')!).display, 'block');
    assert.strictEqual(
      document.querySelector('.euiButtonGroup__buttons')!.getBoundingClientRect().width,
      document.querySelector('.euiButtonGroup')!.getBoundingClientRect().width
    );
    assert.dom('.euiButtonGroupButton').hasClass('euiButtonGroupButton-isIconOnly');
    assert.dom('.euiButtonGroupButton svg.euiIcon').exists();
  });

  test('@isDisabled disables the group without making it full width', async function (assert) {
    await render(<template><EuiButtonGroup @legend="Off" @options={{OPTIONS}} @isDisabled={{true}} /></template>);

    assert.dom('fieldset').isDisabled();
    assert.strictEqual(getComputedStyle(document.querySelector('fieldset')!).display, 'inline-block', 'not full width');
    // Upstream's state class is `euiButtonGroup-isDisabled`.
    assert.dom('fieldset').hasClass('euiButtonGroup-isDisabled');
  });
});
