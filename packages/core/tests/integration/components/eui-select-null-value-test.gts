import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import Component from '@glimmer/component';

import EuiSelect from '#src/components/eui-select.gts';

const OPTIONS = [
  { value: '1', text: 'One' },
  { value: '2', text: 'Two' }
];

// a form editing a record's `belongsTo` id, which is `null` until picked
class RecordSelect extends Component<{ Args: { recordId: string | null } }> {
  get recordId(): string | null {
    return this.args.recordId;
  }

  <template>
    <EuiSelect
      @options={{OPTIONS}}
      @value={{this.recordId}}
      @hasNoInitialSelection={{true}}
    />
  </template>
}

module('Integration | Component | eui-select | null @value', function (hooks) {
  setupRenderingTest(hooks);

  test('a null @value selects the empty option, like an undefined one', async function (assert) {
    await render(<template><RecordSelect @recordId={{null}} /></template>);

    assert.dom('select').hasValue('');
  });

  test('a string @value selects its option', async function (assert) {
    await render(<template><RecordSelect @recordId="2" /></template>);

    assert.dom('select').hasValue('2');
  });
});
