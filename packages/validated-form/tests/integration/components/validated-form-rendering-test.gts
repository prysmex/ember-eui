import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { hash } from '@ember/helper';
import { run } from '@ember/runloop';
import { click, fillIn, render } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import ValidatedForm from '#src/components/validated-form.gts';
import ValidatedFormFieldText from '#src/components/validated-form/field-text.gts';

import type { ValidatedFormChild } from '#src/components/validated-form.gts';

class Data {
  @tracked text = '';
  setText = (v: string) => (this.text = v);
}

/**
 * FieldText, recording what the first render saw: the messages used to be
 * stored after it (in `did-insert`), which rendered every field again.
 */
let firstHasErrorMessages: boolean | undefined;
class RecordingFieldText extends ValidatedFormFieldText {
  get hasErrorMessages() {
    const value = super.hasErrorMessages;
    firstHasErrorMessages ??= value;
    return value;
  }
}

/** A registered child that is not a field: counts reads of its validity. */
class Probe {
  reads = 0;
  isTouched = false;
  get isValid() {
    this.reads++;
    return true;
  }
}

module(
  'Integration | Component | validated-form | rendering',
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      firstHasErrorMessages = undefined;
    });

    test('the first render has the messages', async function (assert) {
      const data = new Data();
      const theme = { FieldText: RecordingFieldText };

      await render(
        <template>
          <ValidatedForm @theme={{theme}} as |Form|>
            <Form.FieldText
              @label="Name"
              @value={{data.text}}
              @onChange={{data.setText}}
              @validations={{hash presence=(hash presence=true)}}
            />
          </ValidatedForm>
        </template>
      );

      assert.true(
        firstHasErrorMessages,
        'the empty value is invalid from the start'
      );
    });

    // they used to be computed in a timer after each render
    test('the messages follow the value in the same render', async function (assert) {
      const data = new Data();

      await render(
        <template>
          <ValidatedForm as |Form|>
            <Form.FieldText
              @label="Name"
              @value={{data.text}}
              @onChange={{data.setText}}
              @validations={{hash presence=(hash presence=true)}}
            />
            <button type="submit">Save</button>
          </ValidatedForm>
        </template>
      );
      await click('button[type="submit"]');
      assert.dom('.euiFormErrorText').exists();

      run(() => (data.text = 'Jane'));
      assert.dom('.euiFormErrorText').doesNotExist('no timer to wait for');

      run(() => (data.text = ''));
      assert.dom('.euiFormErrorText').exists();
    });

    test('@onValidityChange is called in the run loop of the change', async function (assert) {
      const data = new Data();
      const calls: boolean[] = [];
      const onValidityChange = (isValid: boolean) => calls.push(isValid);

      await render(
        <template>
          <ValidatedForm @onValidityChange={{onValidityChange}} as |Form|>
            <Form.FieldText
              @label="Name"
              @value={{data.text}}
              @onChange={{data.setText}}
              @validations={{hash presence=(hash presence=true)}}
            />
          </ValidatedForm>
        </template>
      );
      assert.deepEqual(calls, [false], 'once on insert');

      run(() => (data.text = 'Jane'));
      assert.deepEqual(calls, [false, true], 'before the run loop ends');

      run(() => (data.text = 'Janet'));
      assert.deepEqual(
        calls,
        [false, true],
        'not again while the validity holds'
      );

      run(() => (data.text = ''));
      assert.deepEqual(calls, [false, true, false]);
    });

    test("a field's change does not read the other children again", async function (assert) {
      const data = new Data();
      const probe = new Probe();
      const registerProbe = (register: (child: ValidatedFormChild) => void) => {
        register(probe as unknown as ValidatedFormChild);
      };

      await render(
        <template>
          <ValidatedForm as |Form|>
            {{registerProbe Form.register}}
            <Form.FieldText
              @label="Name"
              @value={{data.text}}
              @onChange={{data.setText}}
              @validations={{hash presence=(hash presence=true)}}
            />
            <Form.FieldText
              @label="Other"
              @value="x"
              @onChange={{data.setText}}
            />
          </ValidatedForm>
        </template>
      );
      const reads = probe.reads;

      await fillIn('.euiFormRow:nth-of-type(1) input', 'Jane');
      await fillIn('.euiFormRow:nth-of-type(1) input', '');

      assert.dom('.euiFormRow:nth-of-type(1) input').hasValue('');
      assert.strictEqual(probe.reads, reads, 'the probe was not asked');
    });
  }
);
