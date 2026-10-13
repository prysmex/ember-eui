import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  blur,
  click,
  fillIn,
  focus,
  render,
  settled,
  triggerEvent,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';

import EuiComboBox from '#src/components/eui-combo-box.gts';
import EuiHighlight from '#src/components/eui-highlight.gts';
import EuiIcon from '#src/components/eui-icon.gts';

import type { TOC } from '@ember/component/template-only';

const INPUT =
  'input.euiComboBox__input:not(.fake-input-for-html-form-validity)';
const ROW = '.euiComboBoxOptionsList .euiComboBoxOption[role="option"]';
const panel = () => document.querySelector('.ember-basic-dropdown-content');
const rows = () => [...document.querySelectorAll<HTMLElement>(ROW)];
const texts = () => rows().map((row) => row.textContent!.trim());
const noop = () => {};

function q<T extends Element = HTMLElement>(
  selector: string,
  root: ParentNode = document
) {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

async function open(scope = '') {
  await click(scope ? `${scope} ${INPUT}` : INPUT);
  await waitUntil(() => document.querySelector(ROW));
  await settled();
}

async function search(text: string, scope = '') {
  await fillIn(scope ? `${scope} ${INPUT}` : INPUT, text);
}

const BellIcon: TOC<{ Args: { option?: { label: string } } }> = <template>
  <EuiIcon @type="bell" @size="s" data-option={{@option.label}} />
</template>;

class State {
  @tracked options: any[] = [];
  @tracked selected: any[] = [];
  created: string[] = [];
  changes: any[][] = [];

  constructor(options: any[] = [], selected: any[] = []) {
    this.options = options;
    this.selected = selected;
  }

  onChange = (selected: any[]) => {
    this.changes.push(selected);
    this.selected = selected;
  };

  onCreateOption = (value: string, flattened: any[]) => {
    this.created.push(value);
    const option = { label: value };
    if (!flattened.some((o) => o.label === value)) {
      this.options = [...this.options, option];
    }
    this.selected = [...this.selected, option];
  };
}

module('Integration | Component | eui-combo-box upstream props', function (hooks) {
  setupRenderingTest(hooks);

  test('option prepend/append render around the label in the list and the pills', async function (assert) {
    const options = [
      { label: 'Titan', prepend: BellIcon },
      { label: 'Iapetus', append: '(2)' },
      { label: 'Phoebe' }
    ];
    const state = new State(options, [options[0], options[1]]);

    await render(
      <template>
        <EuiComboBox
          @options={{state.options}}
          @selectedOptions={{state.selected}}
          @searchField="label"
          @onChange={{state.onChange}}
        />
      </template>
    );

    const [titan, iapetus] = [...document.querySelectorAll('.euiComboBoxPill')];
    assert.dom('.euiComboBoxPill__prepend [data-icon-type="bell"]', titan).exists('component prepend in the pill');
    assert.dom('.euiComboBoxPill__prepend [data-option="Titan"]', titan).exists('components get @option');
    assert.dom('.euiComboBoxPill__append', iapetus).hasText('(2)');
    assert.dom('.eui-textTruncate', iapetus).hasText('Iapetus');
    assert.strictEqual(getComputedStyle(q('.euiComboBoxPill__append', iapetus)).marginLeft, '4px', 'upstream xs margin');

    // upstream: selected options are not listed in multiple selection
    state.selected = [];
    await settled();
    await open();
    const [titanRow, iapetusRow, phoebeRow] = rows();
    assert.dom('.euiListItemLayout__prepend [data-icon-type="bell"]', titanRow).exists();
    assert.dom('.euiListItemLayout__append', iapetusRow).hasText('(2)');
    assert.dom('.euiListItemLayout__prepend', phoebeRow).doesNotExist();
    assert.dom('.euiListItemLayout__text', iapetusRow).hasText('Iapetus', 'append is not part of the label');

    await search('2');
    assert.deepEqual(texts(), [], 'append is not searchable');
  });

  test('plain text single selection and groups render prepend/append', async function (assert) {
    const options = [{ label: 'Titan', prepend: 'P', append: 'A' }];
    const grouped = [
      { groupName: 'Moons', prepend: '>', append: '<', options: ['Titan'] }
    ];

    await render(
      <template>
        <div data-c="plain">
          <EuiComboBox
            @options={{options}}
            @selectedOptions={{options}}
            @searchField="label"
            @singleSelection={{hash asPlainText=true}}
            @onChange={{noop}}
          />
        </div>
        <div data-c="groups">
          <EuiComboBox @options={{grouped}} @onChange={{noop}} />
        </div>
      </template>
    );

    // upstream: the option's prepend/append sit around the input, which
    // shows the selection as its value
    const plain = q('[data-c="plain"] .euiComboBox__inputWrap');
    const input = q<HTMLInputElement>(INPUT, plain);
    const prepend = q('.euiComboBoxPlainTextSelection__prepend', plain);
    const append = q('.euiComboBoxPlainTextSelection__append', plain);
    assert.dom(prepend).hasText('P');
    assert.dom(append).hasText('A');
    assert.dom(input).hasValue('Titan');
    assert.true(Boolean(prepend.compareDocumentPosition(input) & Node.DOCUMENT_POSITION_FOLLOWING), 'prepend before the input');
    assert.true(Boolean(append.compareDocumentPosition(input) & Node.DOCUMENT_POSITION_PRECEDING), 'append after the input');
    assert.strictEqual(getComputedStyle(plain).display, 'flex');

    await open('[data-c="groups"]');
    assert.dom('.euiComboBoxTitle', panel()!).hasText('>Moons<');
  });

  test('option toolTipContent/toolTipProps: described option, shown while highlighted', async function (assert) {
    const options = [
      { label: 'Titan', toolTipContent: 'The largest moon', toolTipProps: { position: 'bottom', title: 'Titan facts' } },
      { label: 'Pandora' },
      { label: 'Disabled', disabled: true, toolTipContent: 'never shown' }
    ];

    await render(
      <template>
        <EuiComboBox @options={{options}} @searchField="label" @onChange={{noop}} />
      </template>
    );
    await open();

    const [titan, pandora, disabled] = rows();
    const tooltipId = `${titan!.id}-tooltip`;
    assert.dom(titan).hasAttribute('aria-describedby', tooltipId);
    assert.dom(pandora).doesNotHaveAttribute('aria-describedby');
    assert.dom(disabled).doesNotHaveAttribute('aria-describedby', 'no tooltip on disabled options');
    assert.dom('.euiListItemLayout__text', titan).doesNotHaveAttribute('title', 'no title with a tooltip');

    // upstream: nothing is highlighted when the list opens, so no tooltip
    // until the arrow keys highlight the option
    assert.notOk(document.getElementById(tooltipId), 'no tooltip on open');
    await triggerKeyEvent(INPUT, 'keydown', 'ArrowDown');
    await waitUntil(() => document.getElementById(tooltipId), { timeout: 2000 });
    const tooltip = document.getElementById(tooltipId);
    assert.dom(tooltip).hasAttribute('role', 'tooltip').includesText('The largest moon').includesText('Titan facts');
    assert.dom(tooltip).hasClass('euiToolTip');

    await triggerKeyEvent(INPUT, 'keydown', 'ArrowDown');
    await waitUntil(() => !document.getElementById(tooltipId), { timeout: 2000 });
    assert.notOk(document.getElementById(tooltipId), 'hidden when another option is highlighted');
  });

  test('truncationProps: EuiTextTruncate per combo box, overridden per option, ignored by searches', async function (assert) {
    const long = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, lorem ipsum dolor sit amet';
    const options = [
      { label: long },
      { label: `Override ${long}`, truncationProps: { truncation: 'start' } },
      { label: 'Short' }
    ];

    await render(
      <template>
        <div style="width: 600px">
          <EuiComboBox
            @options={{options}}
            @searchField="label"
            @onChange={{noop}}
            @truncationProps={{hash truncation="middle"}}
          />
        </div>
      </template>
    );
    await open();

    const [first, second, short] = rows();
    const truncated = (row: Element) => q('[data-test-subj="truncatedText"]', row).textContent!.trim();
    assert.dom('.euiTextTruncate', first).exists();
    assert.ok(truncated(first!).includes('…') && !truncated(first!).startsWith('…') && !truncated(first!).endsWith('…'), `middle: ${truncated(first!)}`);
    assert.ok(truncated(second!).startsWith('…'), `option override: ${truncated(second!)}`);
    assert.dom('[data-test-subj="truncatedText"]', short).doesNotExist('short texts are not truncated');
    assert.dom('.euiListItemLayout__text', first).doesNotHaveAttribute('title');

    await search('consectetur');
    const match = rows()[0]!;
    const shown = truncated(match);
    assert.ok(shown.startsWith('…') && shown.endsWith('…') && shown.includes('consectetur'), `searching truncates around the match: ${shown}`);
    assert.dom('mark', match).hasText('consectetur');
  });

  test('rowHeight="auto": no virtualization, wrapping rows, highlighted search', async function (assert) {
    const options = Array.from({ length: 40 }, (_, i) => ({
      label: `Option ${i} with a long text that wraps onto several lines in a narrow combo box`
    }));

    await render(
      <template>
        <div style="width: 200px">
          <EuiComboBox @options={{options}} @searchField="label" @rowHeight="auto" @onChange={{noop}} />
        </div>
      </template>
    );
    await open();

    assert.strictEqual(rows().length, 40, 'every option is rendered');
    const row = rows()[0]!;
    assert.notOk(row.getAttribute('style'), 'no fixed row height');
    assert.ok(row.getBoundingClientRect().height > 29, 'rows grow with their text');
    assert.strictEqual(getComputedStyle(q('.euiListItemLayout__text', row)).whiteSpace, 'normal', 'text wraps');
    assert.dom('.euiListItemLayout__text', row).doesNotHaveAttribute('title');
    assert.strictEqual(getComputedStyle(q('[role="listbox"]', panel()!)).overflowY, 'auto', 'the list scrolls');

    await search('Option 3 ');
    assert.dom('mark', rows()[0]).hasText('Option 3');
    assert.dom('.euiTextTruncate', rows()[0]).doesNotExist('no truncation');
  });

  test('delimiter: typing it adds the value, Enter adds each pasted value', async function (assert) {
    const state = new State([{ label: 'Titan' }, { label: 'Mimas' }, { label: 'Off', disabled: true }]);

    await render(
      <template>
        <EuiComboBox
          @options={{state.options}}
          @selectedOptions={{state.selected}}
          @searchField="label"
          @onChange={{state.onChange}}
          @onCreateOption={{state.onCreateOption}}
          @delimiter=","
        />
      </template>
    );
    await open();

    await search('Kiwi,');
    assert.deepEqual(state.created, ['Kiwi'], 'typing the delimiter creates the value');
    assert.dom(INPUT).hasValue('', 'and clears the input');
    assert.dom('.euiComboBoxPill').hasText('Kiwi');

    await search('titan,');
    assert.deepEqual(state.created, ['Kiwi'], 'the only matching option is selected instead');
    assert.deepEqual(state.selected.map((o) => o.label), ['Kiwi', 'Titan']);

    await search('Rhea, Dione, Rhea, , Kiwi');
    assert.dom('.euiComboBoxOption__emptyStateText', panel()!).hasText('Add each item separated by ,');
    assert.dom('.euiComboBoxOption__emptyStateText strong', panel()!).hasText(',');
    await triggerKeyEvent(INPUT, 'keydown', 'Enter');
    assert.deepEqual(state.created, ['Kiwi', 'Rhea', 'Dione'], 'trimmed, without duplicates or selected values');
    assert.deepEqual(state.selected.map((o) => o.label), ['Kiwi', 'Titan', 'Rhea', 'Dione']);
    assert.dom(INPUT).hasValue('');
  });

  test('delimiter: leaving the combo box adds what was typed', async function (assert) {
    const state = new State([]);

    await render(
      <template>
        <EuiComboBox
          @options={{state.options}}
          @selectedOptions={{state.selected}}
          @searchField="label"
          @onChange={{state.onChange}}
          @onCreateOption={{state.onCreateOption}}
          @delimiter=","
        />
        <button type="button" id="elsewhere">elsewhere</button>
      </template>
    );
    await focus(INPUT);
    await search('a, b');
    await blur(INPUT);
    await focus('#elsewhere');
    assert.deepEqual(state.created, ['a', 'b']);
  });

  test('isCaseSensitive: matching and highlighting respect case', async function (assert) {
    const options = [{ label: 'Titan' }, { label: 'titanic' }, { label: 'Mimas' }];

    await render(
      <template>
        <div data-c="sensitive">
          <EuiComboBox @options={{options}} @searchField="label" @isCaseSensitive={{true}} @onChange={{noop}} />
        </div>
        <div data-c="default">
          <EuiComboBox @options={{options}} @searchField="label" @onChange={{noop}} />
        </div>
      </template>
    );

    await open('[data-c="sensitive"]');
    await search('Tit', '[data-c="sensitive"]');
    assert.deepEqual(texts(), ['Titan']);
    await search('tit', '[data-c="sensitive"]');
    assert.deepEqual(texts(), ['titanic']);
    assert.dom('mark', rows()[0]).hasText('tit');
    await search(' Mim ', '[data-c="sensitive"]');
    assert.deepEqual(texts(), ['Mimas'], 'the search is trimmed (upstream)');
    await triggerKeyEvent(`[data-c="sensitive"] ${INPUT}`, 'keydown', 'Escape');

    await open('[data-c="default"]');
    await search('tit', '[data-c="default"]');
    assert.deepEqual(texts(), ['Titan', 'titanic'], 'case-insensitive by default');
  });

  test('sortMatchesBy="startsWith" lists the matches starting with the search first', async function (assert) {
    const options = [{ label: 'Pandora' }, { label: 'Dione' }, { label: 'Rhea' }, { label: 'Andromeda' }];
    const grouped = [{ groupName: 'G', options: ['Pandora', 'Dione', 'Andromeda'] }];

    await render(
      <template>
        <div data-c="sorted">
          <EuiComboBox @options={{options}} @searchField="label" @sortMatchesBy="startsWith" @onChange={{noop}} />
        </div>
        <div data-c="none">
          <EuiComboBox @options={{options}} @searchField="label" @onChange={{noop}} />
        </div>
        <div data-c="groups">
          <EuiComboBox @options={{grouped}} @sortMatchesBy="startsWith" @onChange={{noop}} />
        </div>
      </template>
    );

    await open('[data-c="sorted"]');
    assert.deepEqual(texts(), ['Pandora', 'Dione', 'Rhea', 'Andromeda'], 'original order without a search');
    await search('d', '[data-c="sorted"]');
    assert.deepEqual(texts(), ['Dione', 'Pandora', 'Andromeda']);
    await triggerKeyEvent(`[data-c="sorted"] ${INPUT}`, 'keydown', 'Escape');

    await open('[data-c="none"]');
    await search('d', '[data-c="none"]');
    assert.deepEqual(texts(), ['Pandora', 'Dione', 'Andromeda']);
    await triggerKeyEvent(`[data-c="none"] ${INPUT}`, 'keydown', 'Escape');

    await open('[data-c="groups"]');
    await search('a', '[data-c="groups"]');
    assert.deepEqual(texts(), ['Andromeda', 'Pandora'], 'sorted within groups');
  });

  test('noSuggestions: no list and no dropdown icon; Enter and leaving add the text', async function (assert) {
    const state = new State([]);
    const reject = (value: string) => (value === 'bad' ? false : state.onCreateOption(value, []));

    await render(
      <template>
        <EuiComboBox
          @noSuggestions={{true}}
          @options={{state.options}}
          @selectedOptions={{state.selected}}
          @searchField="label"
          @onChange={{state.onChange}}
          @onCreateOption={{reject}}
        />
        <button type="button" id="elsewhere">elsewhere</button>
      </template>
    );

    assert.dom('[data-icon-type="chevronSingleDown"]').doesNotExist('no dropdown icon');
    await click(INPUT);
    await search('tag');
    assert.notOk(panel(), 'the list never opens');
    assert.dom('[data-test-subj="comboBoxCreateOption"]', document.body).doesNotExist('no "Add" row');

    await triggerKeyEvent(INPUT, 'keydown', 'Enter');
    assert.deepEqual(state.created, ['tag']);
    assert.dom('.euiComboBoxPill').hasText('tag');
    assert.dom(INPUT).hasValue('');

    await search('bad');
    await triggerKeyEvent(INPUT, 'keydown', 'Enter');
    assert.dom(INPUT).hasValue('bad', 'rejected text stays');

    await search('other');
    await blur(INPUT);
    await focus('#elsewhere');
    assert.deepEqual(state.created, ['tag', 'other'], 'leaving the combo box adds the text');
  });

  test('@prepend/@append: single selection only, text as form labels or components', async function (assert) {
    const options = ['Titan', 'Mimas'];
    const selected = ['Titan'];

    await render(
      <template>
        <div data-c="single">
          <EuiComboBox
            @options={{options}}
            @selectedOptions={{selected}}
            @singleSelection={{hash asPlainText=true}}
            @prepend="Prepend"
            @append={{BellIcon}}
            @onChange={{noop}}
          />
        </div>
        <div data-c="multi">
          <EuiComboBox @options={{options}} @prepend="Prepend" @onChange={{noop}} />
        </div>
      </template>
    );

    const single = q('[data-c="single"]');
    assert.dom('.euiFormControlLayout--group', single).exists();
    assert.dom('.euiFormControlLayout__prepend', single).hasText('Prepend');
    const label = q('.euiFormControlLayout__prepend label', single);
    assert.strictEqual(label.getAttribute('for'), q<HTMLInputElement>(INPUT, single).id, 'the label is for the input');
    assert.dom('.euiFormControlLayout__append [data-icon-type="bell"]', single).exists();
    assert.strictEqual(getComputedStyle(q('.euiComboBox__inputWrap', single)).boxShadow, 'none', 'upstream inGroup: no own border');

    const multi = q('[data-c="multi"]');
    assert.dom('.euiFormControlLayout__prepend', multi).doesNotExist('not with multiple selection');
    assert.dom('.euiFormControlLayout--group', multi).doesNotExist();
  });

  test('the block receives the search text (upstream renderOption)', async function (assert) {
    const options = [{ label: 'Titan' }, { label: 'Mimas' }];
    const selected = [options[1]];

    await render(
      <template>
        <EuiComboBox
          @options={{options}}
          @selectedOptions={{selected}}
          @searchField="label"
          @onChange={{noop}}
          as |option index searchValue|
        >
          <span class="custom" data-search={{searchValue}}>
            <EuiHighlight @text={{option.label}} @search={{searchValue}} />
          </span>
        </EuiComboBox>
      </template>
    );

    assert.dom('.euiComboBoxPill .custom').hasAttribute('data-search', '', 'pills get an empty search');
    await open();
    await search('ita');
    assert.dom('.custom', rows()[0]).hasAttribute('data-search', 'ita');
    assert.dom('mark', rows()[0]).hasText('ita');
  });

  test('customOptionText takes upstream {searchValue} (bold) and keeps {searchText}', async function (assert) {
    const state = new State([]);

    await render(
      <template>
        <div data-c="value">
          <EuiComboBox @options={{state.options}} @onChange={{noop}} @onCreateOption={{state.onCreateOption}} @customOptionText="Add {searchValue} as your occupation" />
        </div>
      </template>
    );
    await click(INPUT);
    await search('Pilot <b>');
    const text = q('.euiComboBoxOption__emptyStateText', panel()!);
    assert.dom(text).hasText('Add Pilot <b> as your occupation');
    assert.dom('strong', text).hasText('Pilot <b>');
    assert.dom('b', text).doesNotExist('typed text is escaped');
    await triggerEvent(q('[data-test-subj="comboBoxCreateOption"]', panel()!), 'pointerup');
    assert.deepEqual(state.created, ['Pilot <b>']);
  });
});
