import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { blur, click, fillIn, focus, render, triggerEvent, triggerKeyEvent, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';

import { Changeset } from 'ember-changeset';
import lookupValidator from 'ember-changeset-validations';
import { validatePresence } from 'ember-changeset-validations/validators';

import EuiChangesetForm from '#src/components/eui-changeset-form.gts';
import FieldRadio from '#src/components/eui-changeset-form/fields/field-radio.gts';

const OPTIONS = [
  { value: 'mx', text: 'Mexico' },
  { value: 'pt', text: 'Portugal' }
];
const CHOICES = [
  { id: 'a', label: 'A' },
  { id: 'b', label: 'B' }
];

function recorder() {
  const values: unknown[] = [];

  return { values, onChange: (value: unknown) => values.push(value) };
}

const INPUT = 'input.euiComboBox__input:not(.fake-input-for-html-form-validity)';
const ROW = '.euiComboBoxOptionsList .euiComboBoxOption[role="option"]';
const rowTexts = () =>
  [...document.querySelectorAll(ROW)].map((el) => el.textContent!.trim());

function q(selector: string): HTMLElement {
  const element = document.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

class ComboState {
  @tracked options: string[];
  @tracked selected: string[];
  created: string[] = [];

  constructor(options: string[], selected: string[] = []) {
    this.options = options;
    this.selected = selected;
  }

  onChange = (selected: string[]) => {
    this.selected = selected;
  };

  onCreateOption = (value: string) => {
    this.created.push(value);
    this.options = [...this.options, value];
    this.selected = [...this.selected, value];
  };
}

module('Integration | Component | eui-changeset-form fields', function (hooks) {
  setupRenderingTest(hooks);

  test('FieldNumber, FieldPassword, FieldTextArea and FieldSelect set the changeset', async function (assert) {
    const changeset = Changeset({ age: 1, password: '', bio: '', country: 'mx' });

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <Form.FieldNumber @fieldName="age" @label="Age" class="age" />
          <Form.FieldPassword @fieldName="password" @label="Password" class="password" />
          <Form.FieldTextArea @fieldName="bio" @label="Bio" class="bio" />
          <Form.FieldSelect @fieldName="country" @label="Country" @options={{OPTIONS}} class="country" />
        </EuiChangesetForm>
      </template>
    );

    assert.dom('input.age').hasValue('1');
    assert.dom('select.country').hasValue('mx');

    await fillIn('input.age', '42');
    await fillIn('input.password', 'secret');
    await fillIn('textarea.bio', 'Hello');
    await fillIn('select.country', 'pt');

    assert.strictEqual(String(changeset.get('age')), '42');
    assert.strictEqual(changeset.get('password'), 'secret');
    assert.strictEqual(changeset.get('bio'), 'Hello');
    assert.strictEqual(changeset.get('country'), 'pt');
  });

  test('fields validate on blur and show the changeset errors', async function (assert) {
    const Validations = { bio: validatePresence(true), country: validatePresence(true) };
    const changeset = Changeset({ bio: '', country: '' }, lookupValidator(Validations), Validations);
    const empty = [{ value: '', text: 'Pick one' }, ...OPTIONS];

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <Form.FieldTextArea @fieldName="bio" @label="Bio" class="bio" />
          <Form.FieldSelect @fieldName="country" @label="Country" @options={{empty}} class="country" />
        </EuiChangesetForm>
      </template>
    );

    await focus('textarea.bio');
    await blur('textarea.bio');
    await focus('select.country');
    await blur('select.country');
    

    const errors = [...document.querySelectorAll('.euiFormErrorText')].map((e) => e.textContent!.trim());

    assert.deepEqual(errors, ["Bio can't be blank", "Country can't be blank"]);
  });

  test('FieldSwitch sets a boolean', async function (assert) {
    const changeset = Changeset({ notify: false });
    const changes = recorder();

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <Form.FieldSwitch @fieldName="notify" @label="Notify" @onChange={{changes.onChange}} />
        </EuiChangesetForm>
      </template>
    );

    assert.dom('button.euiSwitch__button').hasAttribute('aria-checked', 'false');
    await click('button.euiSwitch__button');
    assert.true(changeset.get('notify'));
    assert.deepEqual(changes.values, [true]);
    assert.dom('button.euiSwitch__button').hasAttribute('aria-checked', 'true');
  });

  test('FieldRadioGroup selects a single id', async function (assert) {
    const changeset = Changeset({ letter: 'a' });
    const changes = recorder();

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <Form.FieldRadioGroup @fieldName="letter" @label="Letter" @options={{CHOICES}} @onChange={{changes.onChange}} />
        </EuiChangesetForm>
      </template>
    );

    const inputs = () => [...(this.element as HTMLElement).querySelectorAll('input[type="radio"]')] as HTMLInputElement[];

    assert.true(inputs()[0]!.checked);
    await click(inputs()[1]!);
    assert.strictEqual(changeset.get('letter'), 'b');
    assert.deepEqual(changes.values, ['b']);
    assert.true(inputs()[1]!.checked);
  });

  test('FieldCheckboxGroup toggles ids in an array', async function (assert) {
    const changeset = Changeset({ letters: ['a'] });

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <Form.FieldCheckboxGroup @fieldName="letters" @label="Letters" @options={{CHOICES}} />
        </EuiChangesetForm>
      </template>
    );

    const inputs = () => [...(this.element as HTMLElement).querySelectorAll('input[type="checkbox"]')] as HTMLInputElement[];

    assert.true(inputs()[0]!.checked);
    await click(inputs()[1]!);
    assert.deepEqual(changeset.get('letters'), ['a', 'b']);
    await click(inputs()[0]!);
    assert.deepEqual(changeset.get('letters'), ['b']);
    assert.false(inputs()[0]!.checked);
  });

  test('FieldComboBox reports the selected options', async function (assert) {
    const changeset = Changeset({ countries: [] });
    const combo = recorder();
    const none: unknown[] = [];

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <Form.FieldComboBox @fieldName="countries" @label="Countries" @options={{OPTIONS}} @selectedOptions={{none}} @searchField="text" @onChange={{combo.onChange}} as |option|>
            {{option.text}}
          </Form.FieldComboBox>
        </EuiChangesetForm>
      </template>
    );

    await click('input.euiComboBox__input:not(.fake-input-for-html-form-validity)');
    // upstream EuiListItemLayout option rows (were `button.euiFilterSelectItem`)
    const option = '.euiComboBoxOptionsList .euiComboBoxOption[role="option"]';
    await waitUntil(() => document.querySelector(option));
    const portugal = [...document.querySelectorAll(option)].find(
      (el) => el.textContent!.trim() === 'Portugal'
    )!;

    await triggerEvent(portugal, 'mouseup');

    assert.deepEqual(combo.values, [[OPTIONS[1]]]);
  });

  test('FieldRangeSlider and FieldDualRangeSlider set the changeset', async function (assert) {
    const changeset = Changeset({ volume: 5, between: [2, 8] });

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <Form.FieldRangeSlider @fieldName="volume" @label="Volume" @min={{0}} @max={{10}} />
          <Form.FieldDualRangeSlider @fieldName="between" @label="Between" @min={{0}} @max={{10}} @showInput={{true}} />
        </EuiChangesetForm>
      </template>
    );

    await fillIn('input[type="range"]', '7');
    assert.strictEqual(String(changeset.get('volume')), '7');

    await fillIn('input.euiRangeInput', '3');
    assert.deepEqual((changeset.get('between') as unknown[]).map(String), ['3', '8']);
  });

  test('Form.FieldCheckbox renders a checkbox that sets a boolean', async function (assert) {
    const changeset = Changeset({ agree: false });

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <Form.FieldCheckbox @fieldName="agree" @label="I agree" />
        </EuiChangesetForm>
      </template>
    );

    assert.dom('input[type="checkbox"]').exists();
    await click('input[type="checkbox"]');
    assert.true(changeset.get('agree'));
    assert.dom('input[type="checkbox"]').isChecked();
  });

  test('Form.FieldRadio renders a radio that sets a boolean', async function (assert) {
    const changeset = Changeset({ yes: false });

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <Form.FieldRadio @fieldName="yes" @label="Answer" @radioLabel="Yes" />
        </EuiChangesetForm>
      </template>
    );

    assert.dom('input[type="radio"]').exists();
    await click('input[type="radio"]');
    assert.true(changeset.get('yes'));
  });

  test('FieldRadio reflects the changeset value', async function (assert) {
    const changeset = Changeset({ yes: true });

    await render(
      <template>
        <FieldRadio @changeset={{changeset}} @fieldName="yes" @label="Answer" @radioLabel="Yes" />
      </template>
    );

    assert.dom('input[type="radio"]').isChecked();
  });
  test('FieldComboBox forwards the EuiComboBox args', async function (assert) {
    const state = new ComboState(['Banana', 'apple', 'Cherry']);
    const changeset = Changeset({ tags: [], fruit: [], free: [] });
    const fruits = [
      { label: 'Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor', prepend: 'P', toolTipContent: 'Tip' }
    ];
    const none: unknown[] = [];
    const noop = () => {};

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <div data-c="multi">
            <Form.FieldComboBox @fieldName="tags" @label="Tags" @ariaLabel="Tags" @options={{state.options}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} @onCreateOption={{state.onCreateOption}} @delimiter="," @isCaseSensitive={{true}} @sortMatchesBy="startsWith" @rowHeight="auto" @onFocusBadge={{true}} as |option index search|>
              <span class="row" data-search={{search}}>{{option}}</span>
            </Form.FieldComboBox>
          </div>
          <div data-c="single">
            <Form.FieldComboBox @fieldName="fruit" @label="Fruit" @options={{fruits}} @selectedOptions={{none}} @searchField="label" @singleSelection={{true}} @prepend="Fruit" @append="!" @truncationProps={{hash truncation="middle"}} @noMatchesMessage="Nothing" @onChange={{noop}} />
          </div>
          <div data-c="tags">
            <Form.FieldComboBox @fieldName="free" @label="Free" @options={{none}} @selectedOptions={{none}} @noSuggestions={{true}} @onChange={{noop}} />
          </div>
        </EuiChangesetForm>
      </template>
    );

    const input = (c: string) => `[data-c="${c}"] ${INPUT}`;

    assert.dom(input('multi')).hasAttribute('aria-label', 'Tags', '@ariaLabel');
    await click(input('multi'));
    await fillIn(input('multi'), 'a');
    assert.deepEqual(rowTexts(), ['apple', 'Banana'], '@isCaseSensitive and @sortMatchesBy');
    assert.dom(q(ROW)).doesNotHaveAttribute('style', '@rowHeight="auto"');
    assert.dom('.row', q(ROW)).hasAttribute('data-search', 'a', 'the search value in the block');
    await triggerKeyEvent(input('multi'), 'keydown', 'ArrowDown');
    assert.dom('.euiComboBoxOption__enterBadge', q(ROW)).exists('@onFocusBadge');
    await fillIn(input('multi'), 'kiwi,');
    assert.deepEqual(state.created, ['kiwi'], '@delimiter');
    await triggerKeyEvent(input('multi'), 'keydown', 'Escape');

    assert.dom('[data-c="single"] .euiFormControlLayout__prepend').hasText('Fruit', '@prepend');
    assert.dom('[data-c="single"] .euiFormControlLayout__append').hasText('!', '@append');
    await click(input('single'));
    assert.dom('.euiTextTruncate', q(ROW)).exists('@truncationProps');
    assert.dom('.euiListItemLayout__prepend', q(ROW)).hasText('P', 'option prepend');
    assert.dom(q(ROW)).hasAttribute('aria-describedby', /tooltip/, 'option tooltip');
    await fillIn(input('single'), 'zzz');
    assert.dom('.euiComboBoxOptionsList__empty', document.body).hasText('Nothing', '@noMatchesMessage');
    await triggerKeyEvent(input('single'), 'keydown', 'Escape');

    assert.dom('[data-c="tags"] [data-icon-type="chevronSingleDown"]').doesNotExist('@noSuggestions');
  });

  test('FieldComboBox: leaving with typed text adds it, and validates after it is added', async function (assert) {
    const Validations = { countries: validatePresence(true) };
    const changeset = Changeset({ countries: [] as string[] }, lookupValidator(Validations), Validations);
    const state = new ComboState(['Mexico', 'Portugal'], []);
    const onChange = (selected: string[]) => {
      state.onChange(selected);
      changeset.set('countries', selected);
    };
    const onCreateOption = (value: string) => {
      state.onCreateOption(value);
      changeset.set('countries', state.selected);
    };

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <Form.FieldComboBox @fieldName="countries" @label="Countries" @options={{state.options}} @selectedOptions={{state.selected}} @onChange={{onChange}} @onCreateOption={{onCreateOption}} />
          <button type="button" id="elsewhere">elsewhere</button>
        </EuiChangesetForm>
      </template>
    );

    await click(INPUT);
    await click('#elsewhere');
    assert.dom('.euiFormErrorText').hasText("Countries can't be blank");

    await click(INPUT);
    assert.deepEqual(rowTexts(), ['Mexico', 'Portugal']);
    await fillIn(INPUT, 'Spain');
    await click('#elsewhere');
    assert.deepEqual(state.created, ['Spain'], 'leaving adds the typed text');
    assert.deepEqual(changeset.get('countries'), ['Spain']);
    assert.dom('.euiFormErrorText').doesNotExist('validated after the option was added');

    await click(INPUT);
    assert.deepEqual(rowTexts(), ['Mexico', 'Portugal'], 'the created Spain is selected, so not listed');
    await triggerKeyEvent(INPUT, 'keydown', 'ArrowDown');
    await triggerKeyEvent(INPUT, 'keydown', 'Enter');
    assert.deepEqual(changeset.get('countries'), ['Spain', 'Mexico']);
    assert.deepEqual(rowTexts(), ['Portugal']);
  });
});
