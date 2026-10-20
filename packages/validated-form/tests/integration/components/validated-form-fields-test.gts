import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { array, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { click, fillIn, render, triggerKeyEvent, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import pick from '@nullvoxpopuli/ember-composable-helpers/helpers/pick';

import ValidatedForm from '#src/components/validated-form.gts';

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

module('Integration | Component | validated-form fields', function (hooks) {
  setupRenderingTest(hooks);

  test('FieldNumber, FieldPassword, FieldTextArea and FieldSelect report their value', async function (assert) {
    const number = recorder();
    const password = recorder();
    const textArea = recorder();
    const select = recorder();

    await render(
      <template>
        <ValidatedForm as |Form|>
          <Form.FieldNumber @label="Age" @value={{1}} @onChange={{number.onChange}} class="number" />
          <Form.FieldPassword @label="Password" @onChange={{password.onChange}} class="password" />
          <Form.FieldTextArea @label="Bio" @onChange={{textArea.onChange}} class="bio" />
          <Form.FieldSelect @label="Country" @options={{OPTIONS}} @onChange={{select.onChange}} class="country" />
        </ValidatedForm>
      </template>
    );

    await fillIn('input.number', '42');
    await fillIn('input.password', 'secret');
    await fillIn('textarea.bio', 'Hello');
    await fillIn('select.country', 'pt');

    assert.deepEqual(number.values, ['42']);
    assert.deepEqual(password.values, ['secret']);
    assert.deepEqual(textArea.values, ['Hello']);
    assert.deepEqual(select.values, ['pt']);
    assert.dom('.euiFormRow__label').exists({ count: 4 });
  });

  test('FieldCheckboxGroup toggles ids in an array', async function (assert) {
    const checks = recorder();
    const selected = ['a'];

    await render(
      <template>
        <ValidatedForm as |Form|>
          <Form.FieldCheckboxGroup @label="Letters" @options={{CHOICES}} @value={{selected}} @onChange={{checks.onChange}} />
        </ValidatedForm>
      </template>
    );

    const inputs = [...(this.element as HTMLElement).querySelectorAll('input[type="checkbox"]:not(.fake-input-for-html-form-validity)')] as HTMLInputElement[];

    assert.true(inputs[0]!.checked);
    await click(inputs[1]!);
    assert.deepEqual(checks.values, [['a', 'b']]);
  });

  test('FieldRadioGroup selects a single id', async function (assert) {
    const radios = recorder();

    await render(
      <template>
        <ValidatedForm as |Form|>
          <Form.FieldRadioGroup @label="Letter" @options={{CHOICES}} @value="a" @onChange={{radios.onChange}} />
        </ValidatedForm>
      </template>
    );

    const inputs = [...(this.element as HTMLElement).querySelectorAll('input[type="radio"]')] as HTMLInputElement[];

    assert.true(inputs[0]!.checked, 'the @value option is checked');
    await click(inputs[1]!);
    assert.deepEqual(radios.values, ['b']);
  });

  test('FieldSwitch reports checked', async function (assert) {
    const switches = recorder();

    await render(
      <template>
        <ValidatedForm as |Form|>
          <Form.FieldSwitch @label="Notify" @value={{false}} @onChange={{switches.onChange}} />
        </ValidatedForm>
      </template>
    );

    await click('button.euiSwitch__button');
    assert.deepEqual(switches.values, [true]);
  });

  test('FieldComboBox reports the selected options', async function (assert) {
    const combo = recorder();
    const none: unknown[] = [];

    await render(
      <template>
        <ValidatedForm as |Form|>
          <Form.FieldComboBox @label="Countries" @options={{OPTIONS}} @selectedOptions={{none}} @searchField="text" @onChange={{combo.onChange}} as |option|>
            {{option.text}}
          </Form.FieldComboBox>
        </ValidatedForm>
      </template>
    );

    await click('input.euiComboBox__input:not(.fake-input-for-html-form-validity)');
    // upstream EuiListItemLayout option rows (were `button.euiFilterSelectItem`)
    const option = '.euiComboBoxOptionsList .euiComboBoxOption[role="option"]';
    await waitUntil(() => document.querySelector(option));
    const portugal = [...document.querySelectorAll(option)].find(
      (el) => el.textContent!.trim() === 'Portugal'
    )!;
    const { triggerEvent } = await import('@ember/test-helpers');

    await triggerEvent(portugal, 'mouseup');

    assert.deepEqual(combo.values, [[OPTIONS[1]]]);
  });

  test('FieldRangeSlider and FieldDualRangeSlider render ranges', async function (assert) {
    const range = recorder();
    const dual = recorder();

    await render(
      <template>
        <ValidatedForm as |Form|>
          <Form.FieldRangeSlider @label="Volume" @min={{0}} @max={{10}} @value={{5}} @onChange={{range.onChange}} class="single" />
          <Form.FieldDualRangeSlider @label="Between" @min={{0}} @max={{10}} @value={{array 2 8}} @onChange={{dual.onChange}} @showInput={{true}} />
        </ValidatedForm>
      </template>
    );

    assert.dom('input[type="range"].single, .single input[type="range"], input[type="range"]').exists();
    await fillIn('input[type="range"]', '7');
    assert.ok(range.values.length >= 1, 'range change reported');

    await fillIn('input.euiRangeInput', '3');
    assert.ok(dual.values.length >= 1, 'dual range change reported');
  });

  test('FieldMarkdownEditor reports text', async function (assert) {
    const md = recorder();

    await render(
      <template>
        <ValidatedForm as |Form|>
          <Form.FieldMarkdownEditor @label="Notes" @value="" @onChange={{md.onChange}} />
        </ValidatedForm>
      </template>
    );

    await fillIn('textarea', '**bold**');
    assert.deepEqual(md.values, ['**bold**']);
  });

  test('FieldMarkdownEditor renders @editorComponent instead of EuiMarkdownEditor', async function (assert) {
    const md = recorder();
    const Editor = <template>
      <textarea class="my-editor" value={{@value}} {{on "input" (pick "target.value" @onChange)}} ...attributes></textarea>
    </template>;

    await render(
      <template>
        <ValidatedForm as |Form|>
          <Form.FieldMarkdownEditor @label="Notes" @value="" @onChange={{md.onChange}} @editorComponent={{Editor}} />
        </ValidatedForm>
      </template>
    );

    assert.dom('.euiFormRow textarea.my-editor').exists();
    assert.dom('.euiMarkdownEditor').doesNotExist();

    await fillIn('textarea', 'plain');
    assert.deepEqual(md.values, ['plain']);
  });

  test('validation messages for select presence', async function (assert) {
    const noop = () => {};

    await render(
      <template>
        <ValidatedForm as |Form|>
          <Form.FieldSelect @label="Country" @options={{OPTIONS}} @hasNoInitialSelection={{true}} @onChange={{noop}} @validations={{hash presence=(hash presence=true)}} />
          <button type="submit">Save</button>
        </ValidatedForm>
      </template>
    );
    
    await click('button[type="submit"]');

    assert.dom('.euiFormErrorText').hasText("This field can't be blank");
  });
  test('FieldComboBox forwards the EuiComboBox args', async function (assert) {
    const state = new ComboState(['Banana', 'apple', 'Cherry']);
    const fruits = [
      { label: 'Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor', prepend: 'P', toolTipContent: 'Tip' }
    ];
    const none: unknown[] = [];
    const noop = () => {};

    await render(
      <template>
        <ValidatedForm as |Form|>
          <div data-c="multi">
            <Form.FieldComboBox @label="Tags" @ariaLabel="Tags" @options={{state.options}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} @onCreateOption={{state.onCreateOption}} @delimiter="," @isCaseSensitive={{true}} @sortMatchesBy="startsWith" @rowHeight="auto" @onFocusBadge={{true}} as |option index search|>
              <span class="row" data-search={{search}}>{{option}}</span>
            </Form.FieldComboBox>
          </div>
          <div data-c="single">
            <Form.FieldComboBox @label="Fruit" @options={{fruits}} @selectedOptions={{none}} @searchField="label" @singleSelection={{true}} @prepend="Fruit" @append="!" @truncationProps={{hash truncation="middle"}} @noMatchesMessage="Nothing" @onChange={{noop}} />
          </div>
          <div data-c="tags">
            <Form.FieldComboBox @label="Free" @options={{none}} @selectedOptions={{none}} @noSuggestions={{true}} @onChange={{noop}} />
          </div>
        </ValidatedForm>
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

  test('FieldComboBox: selected options leave the list, leaving adds the typed text, validity follows', async function (assert) {
    const state = new ComboState(['Mexico', 'Portugal'], []);

    await render(
      <template>
        <ValidatedForm as |Form|>
          <Form.FieldComboBox @label="Countries" @options={{state.options}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} @onCreateOption={{state.onCreateOption}} @validations={{hash presence=(hash presence=true)}} />
          <button type="button" id="elsewhere">elsewhere</button>
        </ValidatedForm>
      </template>
    );

    await click(INPUT);
    await click('#elsewhere');
    assert.dom('.euiFormErrorText').hasText("This field can't be blank", 'touched and empty');

    await click(INPUT);
    await triggerKeyEvent(INPUT, 'keydown', 'ArrowDown');
    await triggerKeyEvent(INPUT, 'keydown', 'Enter');
    assert.deepEqual(state.selected, ['Mexico']);
    assert.deepEqual(rowTexts(), ['Portugal'], 'the selected Mexico is not listed');
    assert.dom('.euiFormErrorText').doesNotExist('valid');

    await fillIn(INPUT, 'Spain');
    await click('#elsewhere');
    assert.deepEqual(state.created, ['Spain'], 'leaving adds the typed text');
    assert.deepEqual(state.selected, ['Mexico', 'Spain']);
    assert.dom(INPUT).hasValue('');
    assert.dom('.euiFormErrorText').doesNotExist();
  });
});
