import { click, render, settled } from '@ember/test-helpers';
import { hbs } from 'ember-cli-htmlbars';
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';

module('Integration | Component | combo box groups', function (hooks) {
  setupRenderingTest(hooks);

  test('group headings cannot be selected and grouped options retain their labels', async function (assert) {
    const alpha = { label: 'Alpha' };
    const beta = { label: 'Beta' };
    const gamma = { label: 'Gamma' };

    this.setProperties({
      options: [
        { label: 'Ungrouped' },
        { groupName: 'First group', options: [alpha, beta] },
        { groupName: 'Second group', options: [gamma] }
      ],
      selected: [],
      onChange: (selected) => this.set('selected', selected)
    });

    await render(hbs`
      <EuiComboBox @options={{this.options}} @selectedOptions={{this.selected}}
        @onChange={{this.onChange}} @searchField="label"
        @renderInPlace={{true}} @closeOnSelect={{false}} as |option|>
        {{option.label}}
      </EuiComboBox>
    `);

    await click('.euiComboBox__inputWrap');
    assert.dom('.euiComboBoxTitle').exists({ count: 2 });
    await click('.euiComboBoxTitle');
    assert.deepEqual(this.selected, [], 'Clicking a heading does not select a group object');
    assert.dom('.ember-power-select-multiple-option').doesNotExist();

    await click('[role="option"][data-option-index="2"]');
    assert.deepEqual(this.selected, [alpha]);
    assert.dom('.ember-power-select-multiple-option').hasText('Alpha');

    await click('[role="option"][data-option-index="3"]');
    assert.deepEqual(this.selected, [alpha, beta], 'Repeated reads keep the same flattened index mapping');

    const pills = this.element.querySelectorAll('.ember-power-select-multiple-option');

    assert.strictEqual(pills[0].textContent.trim(), 'Alpha');
    assert.strictEqual(pills[1].textContent.trim(), 'Beta');

    this.set('options', [{ groupName: 'Updated group', options: [gamma] }]);
    await settled();
    await click('[role="option"][data-option-index="1"]');
    assert.deepEqual(this.selected, [alpha, beta, gamma], 'Replacing options invalidates the flattened cache');
    assert.strictEqual(this.element.querySelectorAll('.ember-power-select-multiple-option')[2].textContent.trim(), 'Gamma');
  });
});
