import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, focus, render, rerender } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiCheckbox from '#src/components/eui-checkbox.gts';
import EuiCheckboxGroup from '#src/components/eui-checkbox-group.gts';
import EuiComboBox from '#src/components/eui-combo-box.gts';
import EuiDescribedFormGroup from '#src/components/eui-described-form-group.gts';
import EuiFieldText from '#src/components/eui-field-text.gts';
import EuiForm from '#src/components/eui-form.gts';
import EuiFormErrorText from '#src/components/eui-form-error-text.gts';
import EuiFormFieldset from '#src/components/eui-form-fieldset.gts';
import EuiFormHelpText from '#src/components/eui-form-help-text.gts';
import EuiFormLabel from '#src/components/eui-form-label.gts';
import EuiFormLegend from '#src/components/eui-form-legend.gts';
import EuiFormRow from '#src/components/eui-form-row.gts';
import EuiSelect from '#src/components/eui-select.gts';
import EuiTextArea from '#src/components/eui-text-area.gts';

const ERRORS = ['Name is required', 'Email is invalid'];
const SELECT_OPTIONS = [{ value: 'a', text: 'A' }];
const CHECKBOX_OPTIONS = [{ id: 'apple', label: 'Apple' }, { id: 'pear', label: 'Pear' }];
const NO_CHECKS = {};
const COMBO_OPTIONS = ['One', 'Two'];
const NO_SELECTION: string[] = [];
const noop = () => {};

/** label[for] must point to the control, and clicking it must focus the control */
async function assertLabelled(assert: Assert, row: Element, control: HTMLElement) {
  const label = row.querySelector('label.euiFormRow__label') as HTMLLabelElement;

  assert.strictEqual(label.htmlFor, control.id, `label for="${label.htmlFor}" matches the control id`);
  assert.ok(control.id, 'the control has an id');

  await click(label);
  assert.strictEqual(document.activeElement, control, 'clicking the label focuses the control');
}

module('Integration | Component | eui-form', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiForm shows an error callout above the content when invalid', async function (assert) {
    await render(
      <template>
        <EuiForm @tagName="form" @isInvalid={{true}} @error={{ERRORS}}>
          <p class="content">Fields</p>
        </EuiForm>
      </template>
    );

    assert.dom('form.euiForm').exists();
    assert.dom('.euiForm__errors').hasAttribute('role', 'alert').hasClass('euiCallOut--danger');
    assert.dom('.euiForm__errors .euiCallOutHeader__title').hasText('Please correct the fields');
    assert.dom('.euiForm__error').exists({ count: 2 });
    assert.dom('.euiForm .content').hasText('Fields');
  });

  test('EuiForm hides the callout when valid or with invalidCallout="none"', async function (assert) {
    await render(
      <template>
        <EuiForm @isInvalid={{false}} @error={{ERRORS}} class="valid" />
        <EuiForm @isInvalid={{true}} @error={{ERRORS}} @invalidCallout="none" class="none" />
      </template>
    );

    assert.dom('div.euiForm.valid .euiForm__errors').doesNotExist();
    assert.dom('div.euiForm.none .euiForm__errors').doesNotExist();
  });

  test('EuiFormRow renders label, field, help text and errors', async function (assert) {
    await render(
      <template>
        <EuiFormRow @id="name" @label="Name" @helpText="Your full name" @isInvalid={{true}} @error={{ERRORS}}>
          <EuiFieldText @id="name" />
        </EuiFormRow>
      </template>
    );

    assert.dom('.euiFormRow label.euiFormRow__label').hasAttribute('for', 'name').hasText('Name').hasClass('euiFormLabel-isInvalid').hasAttribute('aria-invalid', 'true');
    assert.dom('.euiFormRow__fieldWrapper input#name').exists();
    assert.dom('.euiFormHelpText').hasText('Your full name');
    assert.dom('.euiFormErrorText').exists({ count: 2 });
    assert.dom('.euiFormErrorText').hasText('Name is required').hasAttribute('aria-live', 'polite');
  });

  test('EuiFormRow renders @labelAppend and the <:labelAppend> block', async function (assert) {
    await render(
      <template>
        <EuiFormRow @label="Nickname" @labelAppend="Optional" class="text">
          <EuiFieldText />
        </EuiFormRow>
        <EuiFormRow @label="Password" class="block">
          <:labelAppend><a href="#help" class="help">Help</a></:labelAppend>
          <:field><EuiFieldText /></:field>
        </EuiFormRow>
      </template>
    );

    assert.dom('.text .euiFormRow__labelWrapper').includesText('Optional');
    assert.dom('.text .euiFormRow__label').hasText('Nickname');
    assert.dom('.block .euiFormRow__labelWrapper a.help').hasText('Help');
  });

  test('EuiFormRow: focus highlights the label; errors only show when invalid', async function (assert) {
    await render(
      <template>
        <EuiFormRow @id="email" @label="Email" @error={{ERRORS}} @fullWidth={{true}} @display="rowCompressed">
          <EuiFieldText @id="email" />
        </EuiFormRow>
      </template>
    );

    assert.dom('.euiFormRow').hasClass('euiFormRow--fullWidth');
    assert.dom('.euiFormErrorText').doesNotExist();

    await focus('input#email');
    assert.dom('label.euiFormRow__label').hasClass('euiFormLabel-isFocused');
  });

  test('EuiFormLabel, EuiFormHelpText, EuiFormErrorText and EuiFormFieldset', async function (assert) {
    await render(
      <template>
        <EuiFormLabel @for="x" @isInvalid={{true}} class="label">Label</EuiFormLabel>
        <EuiFormLabel @type="legend" class="legend-label">Legend</EuiFormLabel>
        <EuiFormHelpText @id="help">Help</EuiFormHelpText>
        <EuiFormErrorText>Error</EuiFormErrorText>
        <EuiFormFieldset @legend="Group"><span class="inside">inside</span></EuiFormFieldset>
      </template>
    );

    assert.dom('label.label').hasAttribute('for', 'x').hasClass('euiFormLabel-isInvalid');
    assert.dom('legend.legend-label').hasClass('euiFormLabel');
    assert.dom('#help.euiFormHelpText').hasText('Help');
    assert.dom('.euiFormErrorText').hasText('Error');
    assert.dom('fieldset legend.euiFormLegend').hasText('Group');
    assert.dom('fieldset .inside').exists();
  });

  test('EuiFormLegend hidden and compressed classes', async function (assert) {
    await render(
      <template>
        <EuiFormLegend @display="hidden" class="hidden">Hidden</EuiFormLegend>
        <EuiFormLegend @compressed={{true}} class="compressed">Small</EuiFormLegend>
      </template>
    );

    assert.dom('legend.hidden').hasClass('euiFormLegend-isHidden');
    assert.dom('legend.hidden .euiScreenReaderOnly').hasText('Hidden');
    assert.dom('legend.compressed').hasClass('euiFormLegend--compressed');
  });

  test('EuiDescribedFormGroup renders title, description and fields', async function (assert) {
    await render(
      <template>
        <EuiDescribedFormGroup @fullWidth={{true}} @titleSize="s">
          <:title><h3>Settings</h3></:title>
          <:description>Configure things</:description>
          <:default><span class="fields">fields</span></:default>
        </EuiDescribedFormGroup>
      </template>
    );

    assert.dom('[role="group"].euiDescribedFormGroup').hasClass('euiDescribedFormGroup--fullWidth');
    assert.dom('.euiDescribedFormGroup__title h3').hasText('Settings');
    assert.dom('.euiDescribedFormGroup__description').hasText('Configure things');
    assert.dom('.euiDescribedFormGroup__fields .fields').exists();
  });

  module('label association', function () {
    test('a field without ids is labelled by the row label', async function (assert) {
      await render(<template><EuiFormRow @label="Name"><EuiFieldText /></EuiFormRow></template>);

      await assertLabelled(assert, this.element.querySelector('.euiFormRow')!, this.element.querySelector('input')!);
    });

    test('@id on the row but not on the field', async function (assert) {
      await render(<template><EuiFormRow @id="name-row" @label="Name"><EuiFieldText /></EuiFormRow></template>);

      await assertLabelled(assert, this.element.querySelector('.euiFormRow')!, this.element.querySelector('input')!);
      assert.dom('.euiFormRow').hasAttribute('id', 'name-row-row', 'the row id itself is unchanged');
    });

    test('the same @id on row and field keeps working unchanged', async function (assert) {
      await render(<template><EuiFormRow @id="email" @label="Email"><EuiFieldText @id="email" /></EuiFormRow></template>);

      const input = this.element.querySelector('input')!;

      assert.strictEqual(input.id, 'email');
      await assertLabelled(assert, this.element.querySelector('.euiFormRow')!, input);
    });

    test('a plain input without an id gets the row id', async function (assert) {
      await render(<template><EuiFormRow @id="plain" @label="Plain"><input class="plain" /></EuiFormRow></template>);

      // (not named `input`: that would shadow the <input> element in the template)
      const field = this.element.querySelector('input.plain') as HTMLInputElement;

      assert.strictEqual(field.id, 'plain');
      await assertLabelled(assert, this.element.querySelector('.euiFormRow')!, field);
    });

    test('select and text area', async function (assert) {
      await render(
        <template>
          <EuiFormRow @label="Pick" class="select-row"><EuiSelect @options={{SELECT_OPTIONS}} /></EuiFormRow>
          <EuiFormRow @label="Notes" class="textarea-row"><EuiTextArea /></EuiFormRow>
        </template>
      );

      await assertLabelled(assert, this.element.querySelector('.select-row')!, this.element.querySelector('.select-row select')!);
      await assertLabelled(assert, this.element.querySelector('.textarea-row')!, this.element.querySelector('.textarea-row textarea')!);
    });

    test('a combo box is labelled by its search input, not the hidden validity input', async function (assert) {
      await render(
        <template>
          <EuiFormRow @label="Fruits">
            <EuiComboBox @options={{COMBO_OPTIONS}} @selectedOptions={{NO_SELECTION}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox>
          </EuiFormRow>
        </template>
      );

      const input = this.element.querySelector('input.euiComboBox__input:not(.fake-input-for-html-form-validity)') as HTMLInputElement;
      const label = this.element.querySelector('label.euiFormRow__label') as HTMLLabelElement;

      assert.strictEqual(label.htmlFor, input.id);
    });

    test('a control rendered later is picked up', async function (assert) {
      class State {
        @tracked show = false;
      }
      const state = new State();

      await render(
        <template><EuiFormRow @label="Later">{{#if state.show}}<EuiFieldText @id="later-input" />{{/if}}</EuiFormRow></template>
      );

      state.show = true;
      await rerender();

      await assertLabelled(assert, this.element.querySelector('.euiFormRow')!, this.element.querySelector('#later-input')!);
    });

    test('@hasChildLabel={{false}} renders the label without for', async function (assert) {
      await render(
        <template><EuiFormRow @label="Group" @hasChildLabel={{false}}><EuiFieldText @id="x" /></EuiFormRow></template>
      );

      assert.dom('label.euiFormRow__label').doesNotHaveAttribute('for');
      assert.dom('input#x').exists('the field id is untouched');
    });
    test('an existing association is never overridden', async function (assert) {
      // the let pattern: the row id matches the second control, not the first
      await render(
        <template>
          <EuiFormRow @id="second" @label="Second">
            <div><EuiFieldText @id="first" /><EuiFieldText @id="second" /></div>
          </EuiFormRow>
        </template>
      );

      assert.dom('label.euiFormRow__label').hasAttribute('for', 'second');
      assert.dom('input#first').exists();
      assert.dom('input#second').exists();
    });

    test('the control is described by the help text', async function (assert) {
      await render(
        <template><EuiFormRow @id="nick" @label="Nickname" @helpText="Shown to others"><EuiFieldText /></EuiFormRow></template>
      );

      assert.dom('input').hasAria('describedby', 'nick-help');
    });

    test('errors are added while invalid, and ids the app set are kept', async function (assert) {
      class State {
        @tracked isInvalid = false;
      }
      const state = new State();
      const errors = ['Too short', 'Taken'];

      await render(
        <template>
          <span id="mine">Hint</span>
          <EuiFormRow @id="user" @label="User" @helpText="Help" @isInvalid={{state.isInvalid}} @error={{errors}}>
            <EuiFieldText aria-describedby="mine" />
          </EuiFormRow>
        </template>
      );

      assert.dom('input').hasAria('describedby', 'mine user-help');

      state.isInvalid = true;
      await rerender();
      assert.dom('input').hasAria('describedby', 'mine user-error-0 user-error-1 user-help');

      state.isInvalid = false;
      await rerender();
      assert.dom('input').hasAria('describedby', 'mine user-help');
    });

    test('a replaced control is described too', async function (assert) {
      class State {
        @tracked long = false;
      }
      const state = new State();

      await render(
        <template>
          <EuiFormRow @id="bio" @label="Bio" @helpText="Markdown works">
            {{#if state.long}}<EuiTextArea />{{else}}<EuiFieldText />{{/if}}
          </EuiFormRow>
        </template>
      );

      assert.dom('input').hasAria('describedby', 'bio-help');

      state.long = true;
      await rerender();
      assert.dom('textarea').hasAria('describedby', 'bio-help');
    });

    test('a fieldset row is described itself', async function (assert) {
      await render(
        <template>
          <EuiFormRow @id="fruit" @label="Fruits" @labelType="legend" @legendType="legend" @helpText="Pick any">
            <EuiCheckboxGroup @options={{CHECKBOX_OPTIONS}} @idToSelectedMap={{NO_CHECKS}} @onChange={{noop}} />
          </EuiFormRow>
        </template>
      );

      assert.dom('fieldset.euiFormRow').hasAria('describedby', 'fruit-help');
      assert.dom('input[type="checkbox"][aria-describedby]').doesNotExist();
    });

    test('a row whose label already points to its field observes nothing', async function (assert) {
      const Original = window.MutationObserver;
      const observed: Node[] = [];

      window.MutationObserver = class extends Original {
        observe(target: Node, options?: MutationObserverInit) {
          observed.push(target);
          super.observe(target, options);
        }
      };

      try {
        await render(
          <template>
            <EuiFormRow @id="linked" @label="Linked"><EuiFieldText @id="linked" /></EuiFormRow>
            <EuiFormRow @label="Unlinked" class="unlinked"><EuiFieldText /></EuiFormRow>
          </template>
        );
      } finally {
        window.MutationObserver = Original;
      }

      const wrappers = observed.filter((node) => (node as Element).classList?.contains('euiFormRow__fieldWrapper'));

      assert.strictEqual(wrappers.length, 1, 'only the row that had to link its field is observed');
      assert.true(this.element.querySelector('.unlinked')!.contains(wrappers[0]!));
    });

    test('checkbox groups and checkboxes are not associated with the row label', async function (assert) {
      const changes: string[] = [];
      const onChange = (id: string) => changes.push(id);

      await render(
        <template>
          <EuiFormRow @label="Fruits" class="group-row">
            <EuiCheckboxGroup @options={{CHECKBOX_OPTIONS}} @idToSelectedMap={{NO_CHECKS}} @onChange={{onChange}} />
          </EuiFormRow>
          <EuiFormRow @label="Terms" class="single-row">
            <EuiCheckbox @id="terms" @label="I agree" />
          </EuiFormRow>
        </template>
      );

      const groupLabel = this.element.querySelector('.group-row label.euiFormRow__label') as HTMLLabelElement;
      const checkboxIds = [...this.element.querySelectorAll('.group-row input[type="checkbox"]')].map((el) => el.id);

      assert.false(checkboxIds.includes(groupLabel.htmlFor), 'the group label does not point to a checkbox');

      await click(groupLabel);
      assert.deepEqual(changes, [], 'clicking the row label does not toggle a checkbox');

      assert.notStrictEqual((this.element.querySelector('.single-row label.euiFormRow__label') as HTMLLabelElement).htmlFor, 'terms');
    });
  });
});
