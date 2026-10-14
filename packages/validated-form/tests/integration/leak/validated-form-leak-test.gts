/*
 * Memory-leak audit (leak-infra): fields register with their form on
 * construction and unregister on destruction, so a form never keeps
 * references to fields (or nested forms) that are gone. See
 * internal/memory-leak-audit/leak-infra.md.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { hash } from '@ember/helper';
import { render, settled } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import ValidatedForm from '#src/components/validated-form.gts';

const N = 10;

class State {
  @tracked show = false;
  @tracked text = '';
  setText = (v: string) => (this.text = v);
  form?: { childComponents: unknown[] };
  register = (form: { childComponents: unknown[] }) => (this.form = form);
  unregister = () => {};
}

module('Integration | leak-infra | validated-form', function (hooks) {
  setupRenderingTest(hooks);

  test('toggling fields and nested forms N times leaves only the rendered children registered', async function (assert) {
    const state = new State();
    await render(
      <template>
        <ValidatedForm @register={{state.register}} @unregister={{state.unregister}} as |Form|>
          <Form.FieldText @label="Always" @value={{state.text}} @onChange={{state.setText}} @validations={{hash presence=(hash presence=true)}} />
          {{#if state.show}}
            <Form.FieldText @label="Name" @value={{state.text}} @onChange={{state.setText}} @validations={{hash presence=(hash presence=true)}} />
            <Form.FieldNestedForm as |Nested|>
              <Nested.FieldText @label="Nested" @value={{state.text}} @onChange={{state.setText}} />
            </Form.FieldNestedForm>
          {{/if}}
        </ValidatedForm>
      </template>
    );
    for (let i = 0; i < N; i++) {
      state.show = true;
      await settled();
      state.show = false;
      await settled();
    }
    assert.strictEqual(state.form?.childComponents.length, 1, 'only the always-rendered field remains registered');
  });
});
