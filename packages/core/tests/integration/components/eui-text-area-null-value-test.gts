import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import Component from '@glimmer/component';

import EuiTextArea from '#src/components/eui-text-area.gts';

class Notes extends Component<{ Args: { notes: string | null } }> {
  get notes(): string | null {
    return this.args.notes;
  }

  <template><EuiTextArea @value={{this.notes}} /></template>
}

class State {
  @tracked notes: string | null = 'Some notes';
}

module(
  'Integration | Component | eui-text-area | null @value',
  function (hooks) {
    setupRenderingTest(hooks);

    test('a null @value renders an empty textarea, like an undefined one', async function (assert) {
      await render(<template><Notes @notes={{null}} /></template>);

      assert.dom('textarea').hasValue('');
    });

    test('changing @value to null empties the textarea', async function (assert) {
      const state = new State();

      await render(<template><Notes @notes={{state.notes}} /></template>);
      assert.dom('textarea').hasValue('Some notes');

      state.notes = null;
      await settled();

      assert.dom('textarea').hasValue('');
    });
  }
);
