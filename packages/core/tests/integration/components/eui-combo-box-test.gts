import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  fillIn,
  render,
  rerender,
  triggerEvent,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { array, hash } from '@ember/helper';

import EuiComboBox from '#src/components/eui-combo-box.gts';
import EuiText from '#src/components/eui-text.gts';

import type EuiConfigService from '#src/services/eui-config.ts';
// what apps load with `import '@ember-eui/core/styles/ember-eui.css'`
import emberEuiCss from '#src/styles/ember-eui.css?raw';

import type { TOC } from '@ember/component/template-only';

const OPTIONS = ['Apple', 'Banana', 'Cherry'];

const MySelectedItem: TOC<{ Args: { option: string } }> = <template>
  <span class="my-selected-item">{{@option}}</span>
</template>;

class State {
  @tracked selected: unknown[] = [];
  changes: unknown[][] = [];
  created: string[] = [];

  onChange = (selected: unknown[]) => {
    this.changes.push(selected);
    this.selected = selected;
  };

  onCreateOption = (search: string) => {
    this.created.push(search);
    this.selected = [...this.selected, search];
  };
}

const TRIGGER = '.ember-power-select-trigger';
const INPUT = 'input.euiComboBox__input:not(.fake-input-for-html-form-validity)';
// upstream EuiListItemLayout rows (were `button.euiFilterSelectItem`)
const OPTION = '.euiComboBoxOptionsList .euiComboBoxOption[role="option"]';

// the dropdown renders into #ember-basic-dropdown-wormhole, outside of the
// test root element, so query the whole document
const inDocument = (selector: string) => () => document.querySelector(selector);

async function open() {
  await click(INPUT);
  await waitUntil(inDocument(OPTION));
}

function optionTexts() {
  return [...document.querySelectorAll(OPTION)].map((el) =>
    el.textContent!.trim()
  );
}

async function choose(text: string) {
  const option = [...document.querySelectorAll(OPTION)].find(
    (el) => el.textContent!.trim() === text
  );

  if (!option) throw new Error(`option "${text}" not found`);

  await triggerEvent(option, 'mouseup');
}

module('Integration | Component | eui-combo-box', function (hooks) {
  setupRenderingTest(hooks);

  test('external options and selection replacements update pills and available choices', async function (assert) {
    const state = new (class {
      @tracked options = ['Apple', 'Banana'];
      @tracked selected = ['Apple'];
      changes: string[][] = [];
      change = (selected: string[]) => this.changes.push(selected);
    })();

    await render(<template><EuiComboBox @options={{state.options}} @selectedOptions={{state.selected}} @onChange={{state.change}} as |option|>{{option}}</EuiComboBox></template>);

    state.options = ['Cherry', 'Date'];
    state.selected = ['Cherry'];
    await rerender();
    assert.dom('.euiComboBoxPill').exists({ count: 1 }).hasText('Cherry');

    await open();
    // upstream: selected options are not listed in multiple selection
    assert.deepEqual(optionTexts(), ['Date']);
    await choose('Date');
    assert.deepEqual(state.changes, [['Cherry', 'Date']]);
    assert.dom('.euiComboBoxPill').exists({ count: 1 }).hasText('Cherry', 'ignored callback does not change the pills');

    state.selected = [];
    state.options = [];
    await rerender();
    assert.dom('.euiComboBoxPill').doesNotExist();
    assert.deepEqual(state.changes, [['Cherry', 'Date']], 'external replacements do not emit changes');
  });

  test('it renders selected options as pills by default', async function (assert) {
    const state = new State();
    state.selected = ['Apple', 'Cherry'];

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    assert.dom(TRIGGER).hasClass('euiComboBox');
    assert.dom('.euiComboBoxPill').exists({ count: 2 });
    assert.dom('.euiComboBoxPill').hasText('Apple');
  });

  test('it renders a custom @selectedItemComponent', async function (assert) {
    const state = new State();
    state.selected = ['Apple', 'Cherry'];

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          @selectedItemComponent={{MySelectedItem}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    assert.dom('.euiComboBoxPill').doesNotExist();
    assert.dom('.my-selected-item').exists({ count: 2 });
    assert.dom('.my-selected-item').hasText('Apple');
  });

  test('it opens the options list and selects an option', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    await open();

    assert.deepEqual(optionTexts(), OPTIONS);

    await choose('Banana');

    assert.deepEqual(state.changes, [['Banana']]);
    assert.dom('.euiComboBoxPill').hasText('Banana');
  });

  test('typing filters the options', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    await open();
    await fillIn(INPUT, 'an');

    assert.deepEqual(optionTexts(), ['Banana']);
  });

  test('selected options are not listed, so they cannot be chosen again', async function (assert) {
    const state = new State();
    state.selected = ['Apple', 'Banana'];

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    await open();

    // upstream: selected options are not listed in multiple selection
    assert.deepEqual(optionTexts(), ['Cherry']);
    assert.deepEqual(state.changes, []);
  });

  test('the pill close button removes that option', async function (assert) {
    const state = new State();
    state.selected = ['Apple', 'Banana'];

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    await triggerEvent('[data-selected-index="0"]', 'mousedown');

    assert.deepEqual(state.changes, [['Banana']]);
    assert.dom('.euiComboBoxPill').exists({ count: 1 });
  });

  test('backspace in an empty search removes the last selected option', async function (assert) {
    const state = new State();
    state.selected = ['Apple', 'Banana'];

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    await click(INPUT);
    await triggerKeyEvent(INPUT, 'keydown', 'Backspace');

    assert.deepEqual(state.changes, [['Apple']]);
  });

  test('the clear button empties the selection', async function (assert) {
    const state = new State();
    state.selected = ['Apple', 'Banana'];

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    await click('.euiFormControlLayoutClearButton');

    assert.deepEqual(state.changes, [[]]);
  });

  test('with @onCreateOption, a search without matches can be created', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          @onCreateOption={{state.onCreateOption}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    await open();
    await fillIn(INPUT, 'Durian');
    await waitUntil(inDocument('.euiComboBoxOption__emptyStateText'));
    await triggerKeyEvent(INPUT, 'keydown', 'Enter');

    assert.deepEqual(state.created, ['Durian']);
    await rerender();
    assert.dom('.euiComboBoxPill').hasText('Durian');
  });

  test('the create option shows the typed text as text, not HTML', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          @onCreateOption={{state.onCreateOption}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    await open();
    await fillIn(INPUT, '<img src=x>');
    await waitUntil(inDocument('.euiComboBoxOption__emptyStateText'));

    // the options list renders in the dropdown's wormhole, outside the test container
    assert.dom('.euiComboBoxOption__emptyStateText img', document.body).doesNotExist();
    assert.dom('.euiComboBoxOption__emptyStateText', document.body).includesText('<img src=x>');
  });

  test('@singleSelection keeps only the last chosen option', async function (assert) {
    const state = new State();
    state.selected = ['Apple'];

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          @singleSelection={{true}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    await open();
    await choose('Cherry');

    assert.deepEqual(state.changes, [['Cherry']]);
    assert.deepEqual(state.selected, ['Cherry']);
  });

  test('it renders groups', async function (assert) {
    const state = new State();
    const grouped = [
      { groupName: 'Fruits', options: ['Apple', 'Banana'] },
      { groupName: 'Veggies', options: ['Carrot'] }
    ];

    await render(
      <template>
        <EuiComboBox
          @options={{grouped}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    await open();

    // the list is virtualized: only the first rows fit in the test viewport
    const rows = [
      ...document.querySelectorAll(
        '.euiComboBoxOptionsList__rowWrap > .ember-power-select-group, ' + OPTION
      )
    ].map((el) => el.textContent!.trim());

    assert.deepEqual(rows.slice(0, 3), ['Fruits', 'Apple', 'Banana']);
    assert.dom('.euiComboBoxTitle', document.body).hasText('Fruits');
  });

  test('choosing an option in a group selects that option', async function (assert) {
    const state = new State();
    const grouped = [
      'Loose',
      { groupName: 'Fruits', options: [{ label: 'Apple' }, { label: 'Banana' }] },
      { groupName: 'Veggies', options: [{ label: 'Carrot' }] }
    ];

    await render(
      <template>
        <EuiComboBox
          @options={{grouped}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          as |option|
        >
          {{option.label}}
        </EuiComboBox>
      </template>
    );

    await open();
    await choose('Apple');

    assert.deepEqual(state.changes, [[{ label: 'Apple' }]], 'the option, not its group');
    // the old cache lost the flattening, so this chose the "Veggies" group
    assert.dom('.euiComboBoxPill').hasText('Apple');
  });

  test('@isDisabled disables the input and hides the clear button', async function (assert) {
    const state = new State();
    state.selected = ['Apple'];

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          @isDisabled={{true}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    assert.dom(TRIGGER).hasClass('euiComboBox-isDisabled');
    assert.dom(INPUT).isDisabled();
    assert.dom('.euiFormControlLayoutClearButton').doesNotExist();
  });

  module('styles', function (hooks) {
    let style: HTMLStyleElement;

    hooks.beforeEach(function () {
      style = document.createElement('style');
      // EUI's prose styles, which also reach lists inside components. The
      // input wrap carries its own (upstream) box and font now, and is a
      // <div> like upstream's, so no theme CSS is injected for it.
      style.textContent = `${emberEuiCss}
        .euiText ul { list-style: disc; margin-left: 24px; }`;
      document.head.append(style);
    });

    hooks.afterEach(function () {
      style.remove();
    });

    test('prose list styles leave the input alone', async function (assert) {
      const selected = ['Apple', 'Banana'];

      await render(
        <template>
          <div id="plain">
            <EuiComboBox @options={{OPTIONS}} @selectedOptions={{selected}} as |o|>{{o}}</EuiComboBox>
          </div>
          <EuiText id="prose">
            <EuiComboBox @options={{OPTIONS}} @selectedOptions={{selected}} as |o|>{{o}}</EuiComboBox>
          </EuiText>
        </template>
      );

      // ember-power-select renders the input wrap as a <ul>
      const offsets = (id: string) => {
        const combo = document.querySelector(`#${id} .euiComboBox`)!.getBoundingClientRect();
        const wrap = document.querySelector(`#${id} .euiComboBox__inputWrap`)!;

        return {
          wrap: wrap.getBoundingClientRect().left - combo.left,
          listStyle: getComputedStyle(wrap).listStyleType,
          pills: [...wrap.querySelectorAll('.euiComboBoxPill')].map(
            (pill) => pill.getBoundingClientRect().left - combo.left
          )
        };
      };

      assert.deepEqual(offsets('prose'), offsets('plain'));
      assert.strictEqual(offsets('prose').listStyle, 'none');
    });

    test('the options list stays above modals, whatever loads first', async function (assert) {
      // ember-basic-dropdown's own styles set the same property on the same
      // selector; they may load after ember-eui.css (e.g. with a lazy route)
      document.head.prepend(style);

      await render(<template><EuiComboBox @options={{OPTIONS}} as |o|>{{o}}</EuiComboBox></template>);
      await open();

      const content = document.querySelector('.ember-basic-dropdown-content')!;

      // our z-index (upstream EuiInputPopover: anchor + levels.menu, above
      // the modal or flyout the combo box is in) wins over the stylesheet
      assert.true(Number(getComputedStyle(content).zIndex) >= 2000);
    });

    test('the announcement of the results is for screen readers only', async function (assert) {
      await render(<template><EuiComboBox @options={{OPTIONS}} as |o|>{{o}}</EuiComboBox></template>);
      await open();

      const status = document.querySelector('.ember-power-select-visually-hidden[role="status"]')!;
      const rect = status.getBoundingClientRect();

      assert.dom(status).hasText('3 results');
      assert.true(rect.width <= 1 && rect.height <= 1, 'takes no space');
    });
  });

  test('a group heading cannot be selected', async function (assert) {
    const state = new State();
    const grouped = [
      { groupName: 'Fruits', options: [{ label: 'Apple' }, { label: 'Banana' }] }
    ];

    await render(
      <template>
        <EuiComboBox
          @options={{grouped}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          as |option|
        >
          {{option.label}}
        </EuiComboBox>
      </template>
    );

    await open();
    await triggerEvent(
      document.querySelector('.euiComboBoxTitle')!,
      'mouseup'
    );

    assert.deepEqual(state.changes, [], 'the group is not chosen');
    assert.dom('.euiComboBoxPill').doesNotExist();
  });

  module('plain text selection with a block (not upstream)', function () {
    const ENUMS = ['complete_ppe', 'partial_ppe'];
    const BLOCK = '.euiComboBoxPlainTextSelection__block';
    const isUniqueId = (select: { uniqueId?: string }) => Boolean(select?.uniqueId);
    const noop = () => {};

    test('the block renders the selection while nothing is typed', async function (assert) {
      await render(
        <template>
          <EuiComboBox
            @options={{ENUMS}}
            @selectedOptions={{array "complete_ppe"}}
            @singleSelection={{hash asPlainText=true}}
            @onChange={{noop}}
            as |option select|
          >
            <span class="enum-option" data-select={{if (isUniqueId select) "true"}}>Enum
              {{option}}</span>
          </EuiComboBox>
        </template>
      );

      assert.dom(BLOCK).exists({ count: 1 });
      assert.dom(BLOCK).hasAttribute('aria-hidden', 'true');
      assert.dom(`${BLOCK} .enum-option`).hasText('Enum complete_ppe');
      assert.dom(`${BLOCK} .enum-option`).hasAttribute('data-select', 'true', 'the block receives the option, then the select');
      // the input keeps the label (screen readers, typing over it), unseen
      assert.dom(INPUT).hasValue('complete_ppe');
      assert.strictEqual(getComputedStyle(document.querySelector(INPUT)!).color, 'rgba(0, 0, 0, 0)');
      assert.notStrictEqual(getComputedStyle(document.querySelector(INPUT)!).caretColor, 'rgba(0, 0, 0, 0)', 'the caret shows');
      assert.strictEqual(getComputedStyle(document.querySelector(BLOCK)!).pointerEvents, 'none');
      assert.strictEqual(getComputedStyle(document.querySelector('.euiComboBox__inputWrap')!).position, 'relative');
    });

    test('typing hides the block and shows the typed text', async function (assert) {
      await render(
        <template>
          <EuiComboBox
            @options={{ENUMS}}
            @selectedOptions={{array "complete_ppe"}}
            @singleSelection={{hash asPlainText=true}}
            @onChange={{noop}}
            as |option|
          >
            <span class="enum-option">Enum {{option}}</span>
          </EuiComboBox>
        </template>
      );

      await open();
      assert.dom(BLOCK).exists('still shown while the list is open');
      await fillIn(INPUT, 'part');

      assert.dom(BLOCK).doesNotExist();
      assert.dom(INPUT).hasValue('part');
      assert.notStrictEqual(getComputedStyle(document.querySelector(INPUT)!).color, 'rgba(0, 0, 0, 0)');
      assert.deepEqual(optionTexts(), ['Enum partial_ppe'], 'search still filters');
    });

    test('focusing or clicking the input selects the hidden label, so typing replaces it', async function (assert) {
      await render(
        <template>
          <EuiComboBox
            @options={{ENUMS}}
            @selectedOptions={{array "complete_ppe"}}
            @singleSelection={{hash asPlainText=true}}
            @onChange={{noop}}
            as |option|
          >
            <span class="enum-option">Enum {{option}}</span>
          </EuiComboBox>
        </template>
      );

      await click(INPUT);

      const input = document.querySelector<HTMLInputElement>(INPUT)!;
      assert.strictEqual(input.selectionStart, 0);
      assert.strictEqual(input.selectionEnd, 'complete_ppe'.length);
    });

    test('without a block the input shows the label text (upstream)', async function (assert) {
      await render(
        <template>
          <EuiComboBox
            @options={{ENUMS}}
            @selectedOptions={{array "complete_ppe"}}
            @singleSelection={{hash asPlainText=true}}
            @onChange={{noop}}
          />
        </template>
      );

      assert.dom(BLOCK).doesNotExist();
      assert.dom(INPUT).hasValue('complete_ppe');
      assert.notStrictEqual(getComputedStyle(document.querySelector(INPUT)!).color, 'rgba(0, 0, 0, 0)');
    });

    test('multiple selection keeps rendering the block in pills', async function (assert) {
      await render(
        <template>
          <EuiComboBox
            @options={{ENUMS}}
            @selectedOptions={{array "complete_ppe" "partial_ppe"}}
            @onChange={{noop}}
            as |option|
          >
            <span class="enum-option">Enum {{option}}</span>
          </EuiComboBox>
        </template>
      );

      assert.dom(BLOCK).doesNotExist();
      assert.dom('.euiComboBoxPill .enum-option').exists({ count: 2 });
      assert.dom(INPUT).hasValue('');
    });
  });

  module('ignoreAccents (not upstream)', function () {
    const PROFESSIONS = [{ label: 'Médico' }, { label: 'Enfermero' }];
    const noop = () => {};

    test('off by default (upstream)', async function (assert) {
      await render(<template><EuiComboBox @options={{PROFESSIONS}} @onChange={{noop}} /></template>);
      await open();
      await fillIn(INPUT, 'medico');

      assert.deepEqual(optionTexts().filter((text) => text.includes('dico')), []);
    });

    test('@ignoreAccents matches options ignoring accents, both ways', async function (assert) {
      const options = [...PROFESSIONS, { label: 'Medicina' }];

      await render(
        <template><EuiComboBox @options={{options}} @ignoreAccents={{true}} @onChange={{noop}} /></template>
      );
      await open();
      await fillIn(INPUT, 'medic');
      assert.deepEqual(optionTexts(), ['Médico', 'Medicina']);
      await fillIn(INPUT, 'MÉDICI');
      assert.deepEqual(optionTexts(), ['Medicina']);
    });

    test('@ignoreAccents highlights what it matched', async function (assert) {
      await render(
        <template><EuiComboBox @options={{PROFESSIONS}} @ignoreAccents={{true}} @onChange={{noop}} /></template>
      );
      await open();
      await fillIn(INPUT, 'medico');

      assert.dom(`${OPTION} mark`, document.body).hasText('Médico');
    });

    test('the euiComboBox.ignoreAccents config sets the default; the argument wins', async function (assert) {
      const config = this.owner.lookup('service:eui-config') as EuiConfigService;

      config.updateConfig({ 'euiComboBox.ignoreAccents': true });

      await render(
        <template>
          <div data-c="config"><EuiComboBox @options={{PROFESSIONS}} @onChange={{noop}} /></div>
          <div data-c="off"><EuiComboBox @options={{PROFESSIONS}} @ignoreAccents={{false}} @onChange={{noop}} /></div>
        </template>
      );

      await click(`[data-c="config"] ${INPUT}`);
      await waitUntil(inDocument(OPTION));
      await fillIn(`[data-c="config"] ${INPUT}`, 'medico');
      assert.deepEqual(optionTexts(), ['Médico'], 'from the config');

      await click(`[data-c="off"] ${INPUT}`);
      await fillIn(`[data-c="off"] ${INPUT}`, 'medico');
      assert.deepEqual(optionTexts().filter((text) => text.includes('dico')), [], 'the argument wins');
    });
  });

  module('array-like options and selections', function () {
    const noop = () => {};

    // Ember array-likes (`objectAt`) without `slice`, e.g. ember-data's
    // PromiseManyArray: iterable, or only with `content`
    class Iterable {
      constructor(private items: unknown[]) {}
      get length() {
        return this.items.length;
      }
      objectAt(index: number) {
        return this.items[index];
      }
      [Symbol.iterator]() {
        return this.items[Symbol.iterator]();
      }
    }

    class WithContent {
      constructor(public content: unknown[]) {}
      get length() {
        return this.content.length;
      }
      objectAt(index: number) {
        return this.content[index];
      }
    }

    test('array-likes without slice() are read as lists', async function (assert) {
      const iterable = new Iterable(['Apple', 'Banana', 'Cherry']);
      const selected = new WithContent(['Banana']);

      await render(
        <template>
          <EuiComboBox @options={{iterable}} @selectedOptions={{selected}} @onChange={{noop}} />
        </template>
      );

      assert.dom('.euiComboBoxPill').hasText('Banana');
      await open();
      assert.deepEqual(optionTexts(), ['Apple', 'Cherry']);
    });
  });
});
