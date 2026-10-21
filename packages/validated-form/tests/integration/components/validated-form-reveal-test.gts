import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, triggerEvent } from '@ember/test-helpers';

import ValidatedForm from '#src/components/validated-form.gts';

import type { ValidatedFormChild } from '#src/components/validated-form.gts';

const presence = { presence: true };

/** Records the elements scrolled into view, without scrolling. */
function stubScrollIntoView(hooks: NestedHooks): Element[] {
  const scrolled: Element[] = [];
  let original: Element['scrollIntoView'];

  hooks.beforeEach(function () {
    scrolled.length = 0;
    original = Element.prototype.scrollIntoView;
    Element.prototype.scrollIntoView = function (this: Element) {
      scrolled.push(this);
    };
  });
  hooks.afterEach(function () {
    Element.prototype.scrollIntoView = original;
  });

  return scrolled;
}

/** An app field that is always invalid and has no control of its own. */
class CustomChild {
  isValid = false;
  isTouched = false;
  setIsTouched(isTouched: boolean) {
    this.isTouched = isTouched;
  }
}

module('Integration | Component | validated-form | reveal first invalid', function (hooks) {
  setupRenderingTest(hooks);
  const scrolled = stubScrollIntoView(hooks);

  test('the first submit focuses the first invalid field', async function (assert) {
    let submits = 0;
    let invalids = 0;
    const onSubmit = () => void submits++;
    const onInvalid = () => {
      invalids++;
      assert.strictEqual(scrolled.length, 0, '@onInvalid runs first');
    };
    const noop = () => {};
    const validations = { presence };

    await render(
      <template>
        <ValidatedForm @onSubmit={{onSubmit}} @onInvalid={{onInvalid}} as |Form|>
          <Form.FieldText @label="Name" @value="Ada" @onChange={{noop}} @validations={{validations}} />
          <Form.FieldText @label="Email" @value="" @onChange={{noop}} @validations={{validations}} />
          <Form.FieldText @label="Phone" @value="" @onChange={{noop}} @validations={{validations}} />
          <button type="submit">Save</button>
        </ValidatedForm>
      </template>
    );

    await click('button[type="submit"]');

    const [, email] = this.element.querySelectorAll('input');
    assert.dom(email).isFocused();
    assert.dom(email).hasAttribute('aria-invalid', 'true');
    assert.strictEqual(scrolled[0], email!.closest('.euiFormRow'), 'its row is scrolled to');
    assert.strictEqual(submits, 0);
    assert.strictEqual(invalids, 1);
  });

  test('a custom field with a hidden validity input gets its row scrolled to', async function (assert) {
    const child = new CustomChild();
    const registerChild = (register: (child: ValidatedFormChild) => void) => {
      register(child as unknown as ValidatedFormChild);
    };

    await render(
      <template>
        <ValidatedForm as |Form|>
          {{registerChild Form.register}}
          <div class="euiFormRow" data-test-custom>
            <input required style="display: none" />
            <button type="button" data-test-pick>Pick</button>
          </div>
        </ValidatedForm>
      </template>
    );

    await triggerEvent('form', 'submit');

    assert.strictEqual(scrolled[0], this.element.querySelector('[data-test-custom]'));
    assert.dom('[data-test-pick]').isFocused('its visible control, not the stand-in');
  });

  test('@revealFirstInvalid={{false}} leaves focus and scroll alone', async function (assert) {
    const noop = () => {};
    const validations = { presence };

    await render(
      <template>
        <ValidatedForm @revealFirstInvalid={{false}} as |Form|>
          <Form.FieldText @label="Email" @value="" @onChange={{noop}} @validations={{validations}} />
          <button type="submit">Save</button>
        </ValidatedForm>
      </template>
    );

    await click('button[type="submit"]');

    assert.dom('input').isNotFocused();
    assert.strictEqual(scrolled.length, 0);
  });

  test('a valid form focuses nothing', async function (assert) {
    let submits = 0;
    const onSubmit = () => void submits++;
    const noop = () => {};
    const validations = { presence };

    await render(
      <template>
        <ValidatedForm @onSubmit={{onSubmit}} as |Form|>
          <Form.FieldText @label="Name" @value="Ada" @onChange={{noop}} @validations={{validations}} />
          <button type="submit">Save</button>
        </ValidatedForm>
      </template>
    );

    await click('button[type="submit"]');

    assert.strictEqual(submits, 1);
    assert.strictEqual(scrolled.length, 0);
    assert.dom('input').isNotFocused();
  });
});
