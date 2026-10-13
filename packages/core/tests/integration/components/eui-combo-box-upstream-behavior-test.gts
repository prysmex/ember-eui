/**
 * EuiComboBox behavior ported from upstream EUI 123.1.0's
 * `combo_box.test.tsx`, `combo_box.spec.tsx` and `matching_options.test.ts`.
 */
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
import { on } from '@ember/modifier';

import EuiComboBox from '#src/components/eui-combo-box.gts';
import {
  flattenOptionGroups,
  getMatchingEntries,
  createPartialStringEqualityOptionMatcher
} from '#src/utils/eui/combo-box.ts';

const INPUT =
  'input.euiComboBox__input:not(.fake-input-for-html-form-validity)';
const ROW = '.euiComboBoxOptionsList .euiComboBoxOption[role="option"]';
const panel = () => document.querySelector('.ember-basic-dropdown-content');
const rows = () => [...document.querySelectorAll<HTMLElement>(ROW)];
const texts = () => rows().map((row) => row.textContent!.trim());
const labels = (options: unknown[]) =>
  options.map((o) => (typeof o === 'string' ? o : (o as { label: string }).label));
const noop = () => {};

// upstream's test options (Saturn's moons)
const MOONS = [
  { label: 'Titan' },
  { label: 'Enceladus' },
  { label: 'Mimas' },
  { label: 'Dione' },
  { label: 'Iapetus' },
  { label: 'Phoebe' },
  { label: 'Rhea' },
  { label: 'Tethys' },
  { label: 'Hyperion' }
];

async function open(scope = '') {
  await click(scope ? `${scope} ${INPUT}` : INPUT);
  await waitUntil(() => panel());
  await settled();
}

const isOpen = () => Boolean(panel());

class State {
  @tracked options: any[];
  @tracked selected: any[];
  changes: any[][] = [];
  created: [string, any[]][] = [];
  searches: [string, boolean | undefined][] = [];

  constructor(options: any[] = MOONS, selected: any[] = []) {
    this.options = options;
    this.selected = selected;
  }

  onChange = (selected: any[]) => {
    this.changes.push(selected);
    this.selected = selected;
  };

  onCreateOption = (value: string, flattened: any[]) => {
    this.created.push([value, flattened]);
    const option = { label: value };
    this.options = [...this.options, option];
    this.selected = [...this.selected, option];
  };

  onSearchChange = (value: string, hasMatches?: boolean) => {
    this.searches.push([value, hasMatches]);
  };
}

module('Integration | Component | eui-combo-box upstream behavior', function (hooks) {
  setupRenderingTest(hooks);

  module('matching (matching_options.ts)', function () {
    test('getMatchingEntries: upstream getMatchingOptions cases', function (assert) {
      const matcher = createPartialStringEqualityOptionMatcher();
      const options = [{ label: 'Titan' }, { label: 'Mimas' }, { label: 'Iapetus' }];
      const match = (args: Partial<Parameters<typeof getMatchingEntries>[0]>) =>
        labels(
          getMatchingEntries({
            options,
            selectedOptions: [],
            searchValue: '',
            optionMatcher: matcher,
            ...args
          })
        );

      assert.deepEqual(match({}), ['Titan', 'Mimas', 'Iapetus'], 'no search: everything');
      assert.deepEqual(match({ searchValue: 'ta' }), ['Titan'], 'substring');
      assert.deepEqual(match({ searchValue: 'TI' }), ['Titan'], 'ignores case');
      assert.deepEqual(match({ searchValue: 'TI', isCaseSensitive: true }), [], 'case-sensitive');
      assert.deepEqual(match({ searchValue: '  mim  ' }), ['Mimas'], 'trimmed');
      assert.deepEqual(match({ selectedOptions: [{ label: 'Mimas' }] }), ['Titan', 'Iapetus'], 'selected (by label) left out');
      assert.deepEqual(match({ selectedOptions: [{ label: 'mimas' }] }), ['Titan', 'Iapetus'], 'label match ignores case');
      assert.deepEqual(match({ selectedOptions: [{ label: 'Mimas' }], showPrevSelected: true }), ['Titan', 'Mimas', 'Iapetus'], 'showPrevSelected');
      assert.deepEqual(match({ searchValue: 'zzz', isPreFiltered: true }), ['Titan', 'Mimas', 'Iapetus'], 'pre-filtered');

      const keyed = [
        { label: 'Titan', key: 'a' },
        { label: 'Titan', key: 'b' }
      ];
      assert.deepEqual(
        getMatchingEntries({ options: keyed, selectedOptions: [keyed[0]], searchValue: '', optionMatcher: matcher }),
        [keyed[1]],
        'keys tell duplicate labels apart'
      );

      const grouped = [{ label: 'Group', options: [{ label: 'Blue' }, { label: 'Red' }] }];
      assert.deepEqual(flattenOptionGroups(grouped), grouped[0]!.options, 'flattenOptionGroups');
    });

    test('default matching ignores case but not accents (upstream)', async function (assert) {
      const options = [{ label: 'México' }, { label: 'Mexico City' }, { label: 'Oaxaca' }];

      await render(<template><EuiComboBox @options={{options}} @onChange={{noop}} /></template>);
      await open();
      await fillIn(INPUT, 'mexico');
      assert.deepEqual(texts(), ['Mexico City']);
      await fillIn(INPUT, 'MÉX');
      assert.deepEqual(texts(), ['México']);
    });

    test('isCaseSensitive (upstream)', async function (assert) {
      const options = [{ label: 'Case sensitivity' }];

      await render(
        <template>
          <div data-c="off"><EuiComboBox @options={{options}} @isCaseSensitive={{false}} @onChange={{noop}} /></div>
          <div data-c="on"><EuiComboBox @options={{options}} @isCaseSensitive={{true}} @onChange={{noop}} /></div>
        </template>
      );
      await open('[data-c="off"]');
      await fillIn(`[data-c="off"] ${INPUT}`, 'case');
      assert.strictEqual(rows().length, 1);
      await triggerKeyEvent(`[data-c="off"] ${INPUT}`, 'keydown', 'Escape');

      await open('[data-c="on"]');
      await fillIn(`[data-c="on"] ${INPUT}`, 'case');
      assert.strictEqual(rows().length, 0);
      await fillIn(`[data-c="on"] ${INPUT}`, 'Case');
      assert.strictEqual(rows().length, 1);
    });

    test('@matcher and @optionMatcher still customize matching', async function (assert) {
      const startsWith = (option: { label: string }, text: string) =>
        option.label.toLowerCase().startsWith(text.toLowerCase()) ? 0 : -1;
      const exact = ({ option, searchValue }: { option: { label: string }; searchValue: string }) =>
        option.label === searchValue;

      await render(
        <template>
          <div data-c="matcher"><EuiComboBox @options={{MOONS}} @matcher={{startsWith}} @onChange={{noop}} /></div>
          <div data-c="option"><EuiComboBox @options={{MOONS}} @optionMatcher={{exact}} @onChange={{noop}} /></div>
        </template>
      );
      await open('[data-c="matcher"]');
      await fillIn(`[data-c="matcher"] ${INPUT}`, 'e');
      assert.deepEqual(texts(), ['Enceladus']);
      await triggerKeyEvent(`[data-c="matcher"] ${INPUT}`, 'keydown', 'Escape');

      await open('[data-c="option"]');
      await fillIn(`[data-c="option"] ${INPUT}`, 'Rhea');
      assert.deepEqual(texts(), ['Rhea']);
      await fillIn(`[data-c="option"] ${INPUT}`, 'rhea');
      assert.deepEqual(texts(), []);
    });

    test('sortMatchesBy "none" and "startsWith" (upstream)', async function (assert) {
      const options = [{ label: 'Something is Disabled' }, ...MOONS];

      await render(
        <template>
          <div data-c="none"><EuiComboBox @options={{options}} @sortMatchesBy="none" @onChange={{noop}} /></div>
          <div data-c="sw"><EuiComboBox @options={{options}} @sortMatchesBy="startsWith" @onChange={{noop}} /></div>
        </template>
      );
      await open('[data-c="none"]');
      await fillIn(`[data-c="none"] ${INPUT}`, 'di');
      assert.deepEqual(texts(), ['Something is Disabled', 'Dione']);
      await triggerKeyEvent(`[data-c="none"] ${INPUT}`, 'keydown', 'Escape');

      await open('[data-c="sw"]');
      await fillIn(`[data-c="sw"] ${INPUT}`, 'di');
      assert.deepEqual(texts(), ['Dione', 'Something is Disabled']);
    });

    test('sortMatchesBy="startsWith" sorts the flat list, group titles included (upstream)', async function (assert) {
      const grouped = [
        { groupName: 'Moons', options: ['Pandora', 'Andromeda', 'Dione'] },
        { groupName: 'Asteroids', options: ['Vesta', 'Ceres'] }
      ];

      await render(
        <template><EuiComboBox @options={{grouped}} @sortMatchesBy="startsWith" @onChange={{noop}} /></template>
      );
      await open();
      await fillIn(INPUT, 'a');

      const order = [
        ...panel()!.querySelectorAll('.euiComboBoxTitle, .euiComboBoxOption')
      ].map((el) => `${el.classList.contains('euiComboBoxTitle') ? '#' : ''}${el.textContent!.trim()}`);

      // upstream: [Andromeda, Asteroids title, Moons title, Pandora, Vesta]
      // (titles are entries of the sorted list; options follow the title
      // before them). The Asteroids title is left without options, which
      // ember-power-select does not render.
      assert.deepEqual(order, ['Andromeda', '#Moons', 'Pandora', 'Vesta']);
    });
  });

  module('selection', function () {
    test('renders selectedOptions as pills; multiple selection does not list them', async function (assert) {
      const state = new State(MOONS, [MOONS[2], MOONS[4]]);

      await render(
        <template><EuiComboBox @options={{state.options}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} /></template>
      );
      assert.deepEqual([...document.querySelectorAll('[data-test-subj="euiComboBoxPill"]')].map((p) => p.textContent!.trim()), ['Mimas', 'Iapetus']);

      await open();
      assert.notOk(texts().includes('Mimas'));
      assert.notOk(texts().includes('Iapetus'));
      assert.strictEqual(rows().length, MOONS.length - 2);
      assert.dom(q('[role="listbox"]')).hasAttribute('aria-multiselectable', 'true');
    });

    test('choosing keeps the list open in multiple selection and highlights the next option', async function (assert) {
      const state = new State(MOONS.slice(0, 4));

      await render(
        <template><EuiComboBox @options={{state.options}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} /></template>
      );
      await open();
      await triggerKeyEvent(INPUT, 'keydown', 'ArrowDown');
      await triggerKeyEvent(INPUT, 'keydown', 'ArrowDown');
      await triggerKeyEvent(INPUT, 'keydown', 'Enter');
      

      assert.deepEqual(labels(state.selected), ['Enceladus']);
      assert.true(isOpen(), 'the list stays open');
      assert.deepEqual(texts(), ['Titan', 'Mimas', 'Dione']);
      const active = q(INPUT).getAttribute('aria-activedescendant');
      assert.strictEqual(document.getElementById(active!)?.textContent!.trim(), 'Mimas', 'the next option is active');

      await triggerEvent(rows()[0]!, 'mouseup');
      assert.deepEqual(labels(state.selected), ['Enceladus', 'Titan'], 'clicking adds too');
      assert.true(isOpen());
    });

    test('single selection lists the selected option with a check and closes after a choice', async function (assert) {
      const state = new State(MOONS, [MOONS[0]]);

      await render(
        <template><EuiComboBox @singleSelection={{true}} @options={{state.options}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} /></template>
      );
      assert.dom('[data-test-subj="euiComboBoxPill"]').exists({ count: 1 }).hasText('Titan');
      await open();

      assert.strictEqual(rows().length, MOONS.length, 'the selection stays listed');
      assert.dom('[data-icon-type="check"]', panel()!).exists({ count: 1 });
      assert.dom('[data-icon-type="check"]', rows()[0]).exists('on the selected option');
      assert.dom(q('[role="listbox"]')).doesNotHaveAttribute('aria-multiselectable');
      assert.strictEqual(q(INPUT).getAttribute('aria-activedescendant'), rows()[0]!.id, 'clicking highlights the selection');

      await triggerEvent(rows()[0]!, 'mouseup');
      assert.deepEqual(labels(state.selected), ['Titan'], 'choosing the selected option keeps it');

      await open();
      await triggerEvent(rows()[2]!, 'mouseup');
      
      assert.deepEqual(labels(state.selected), ['Mimas']);
      assert.false(isOpen(), 'closes');
      assert.strictEqual(document.activeElement, q(INPUT), 'focus stays in the input');
    });

    test('duplicate labels get one check in single selection (upstream)', async function (assert) {
      const dupes = [
        { label: 'Titan', key: 'titan1' },
        { label: 'Titan', key: 'titan2' },
        { label: 'Tethys' }
      ];

      await render(
        <template>
          <div data-c="dupes"><EuiComboBox @singleSelection={{hash asPlainText=true}} @options={{dupes}} @selectedOptions={{array1 dupes}} @onChange={{noop}} /></div>
        </template>
      );
      await open('[data-c="dupes"]');
      const [first, second] = rows();
      assert.dom('[data-icon-type="check"]', first).doesNotExist();
      assert.dom('[data-icon-type="check"]', second).exists();
    });
  });

  module('the arguments are never copied or changed', function () {
    test('replacing @options while open and after a selection', async function (assert) {
      const state = new State([{ label: 'Titan' }, { label: 'Mimas' }]);

      await render(
        <template><EuiComboBox @options={{state.options}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} /></template>
      );
      await open();
      assert.deepEqual(texts(), ['Titan', 'Mimas']);

      state.options = [{ label: 'Rhea' }, { label: 'Dione' }, { label: 'Tethys' }];
      await settled();
      assert.deepEqual(texts(), ['Rhea', 'Dione', 'Tethys'], 'new options while open');

      await triggerEvent(rows()[1]!, 'mouseup');
      assert.deepEqual(labels(state.selected), ['Dione']);
      assert.deepEqual(texts(), ['Rhea', 'Tethys']);

      // e.g. options loaded from a server again: new, equal objects
      state.options = [{ label: 'Rhea' }, { label: 'Dione' }, { label: 'Tethys' }, { label: 'Iapetus' }];
      await settled();
      assert.deepEqual(texts(), ['Rhea', 'Tethys', 'Iapetus'], 'equal options to the selection are not listed');

      await fillIn(INPUT, 'e');
      state.options = [{ label: 'Enceladus' }, { label: 'Dione' }, { label: 'Mimas' }];
      await settled();
      assert.deepEqual(texts(), ['Enceladus'], 'new options while searching are filtered');
    });

    test('promised @options, then an array; @search results without the selection', async function (assert) {
      let resolve!: (value: unknown[]) => void;
      const state = new State(new Promise((r) => (resolve = r)) as unknown as unknown[], [{ label: 'Titan' }]);
      const search = (term: string) =>
        Promise.resolve(MOONS.filter((m) => m.label.toLowerCase().includes(term)));
      const searched = new State(MOONS, [MOONS[0]]);

      await render(
        <template>
          <div data-c="promise"><EuiComboBox @options={{state.options}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} /></div>
          <div data-c="search"><EuiComboBox @search={{search}} @selectedOptions={{searched.selected}} @onChange={{searched.onChange}} /></div>
        </template>
      );
      await click(`[data-c="promise"] ${INPUT}`);
      assert.dom('.euiComboBoxOptionsList', panel()!).includesText('Loading options...');
      resolve([{ label: 'Titan' }, { label: 'Rhea' }]);
      await settled();
      assert.deepEqual(texts(), ['Rhea'], 'resolved, without the (equal) selection');

      state.options = [{ label: 'Titan' }, { label: 'Dione' }];
      await settled();
      assert.deepEqual(texts(), ['Dione'], 'an array replaces the promise');
      await triggerKeyEvent(`[data-c="promise"] ${INPUT}`, 'keydown', 'Escape');

      await click(`[data-c="search"] ${INPUT}`);
      await fillIn(`[data-c="search"] ${INPUT}`, 't');
      
      assert.deepEqual(texts(), ['Iapetus', 'Tethys'], 'the selected Titan is not in the results');
    });

    test('frozen @options and @selectedOptions are never mutated', async function (assert) {
      const options = Object.freeze(MOONS.slice(0, 4).map((o) => Object.freeze({ ...o })));
      const grouped = Object.freeze([
        Object.freeze({ groupName: 'Inner', options: Object.freeze([options[0], options[1]]) }),
        Object.freeze({ groupName: 'Outer', options: Object.freeze([options[2], options[3]]) })
      ]);
      const state = new (class {
        @tracked selected: readonly unknown[] = Object.freeze([options[0]]);
        @tracked groupSelected: readonly unknown[] = Object.freeze([]);
        onChange = (selected: unknown[]) => {
          this.selected = Object.freeze(selected);
        };
        onGroupChange = (selected: unknown[]) => {
          this.groupSelected = Object.freeze(selected);
        };
      })();

      await render(
        <template>
          <div data-c="flat"><EuiComboBox @options={{options}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} @sortMatchesBy="startsWith" /></div>
          <div data-c="groups"><EuiComboBox @options={{grouped}} @selectedOptions={{state.groupSelected}} @onChange={{state.onGroupChange}} @sortMatchesBy="startsWith" /></div>
        </template>
      );
      await open('[data-c="flat"]');
      await fillIn(`[data-c="flat"] ${INPUT}`, 'm');
      await triggerKeyEvent(`[data-c="flat"] ${INPUT}`, 'keydown', 'ArrowDown');
      await triggerKeyEvent(`[data-c="flat"] ${INPUT}`, 'keydown', 'Enter');
      await triggerKeyEvent(`[data-c="flat"] ${INPUT}`, 'keydown', 'Backspace');
      await click('[data-c="flat"] .euiFormControlLayoutClearButton');
      await triggerKeyEvent(`[data-c="flat"] ${INPUT}`, 'keydown', 'Escape');

      await open('[data-c="groups"]');
      await fillIn(`[data-c="groups"] ${INPUT}`, 'e');
      await triggerKeyEvent(`[data-c="groups"] ${INPUT}`, 'keydown', 'ArrowDown');
      await triggerKeyEvent(`[data-c="groups"] ${INPUT}`, 'keydown', 'Enter');
      assert.strictEqual(state.groupSelected.length, 1, 'chose from a group');
      assert.deepEqual(grouped.map((g) => labels([...g.options])), [['Titan', 'Enceladus'], ['Mimas', 'Dione']], 'groups unchanged');
      assert.deepEqual(labels([...options]), ['Titan', 'Enceladus', 'Mimas', 'Dione'], 'options unchanged');
      assert.deepEqual(state.selected, [], 'no errors from frozen arrays');
    });
  });

  module('keyboard', function () {
    test('nothing is highlighted on open; arrows start at either end and wrap', async function (assert) {
      const options = [{ label: 'A' }, { label: 'B', disabled: true }, { label: 'C' }];

      await render(<template><EuiComboBox @options={{options}} @onChange={{noop}} /></template>);
      await open();
      const input = q(INPUT);
      const active = () => document.getElementById(input.getAttribute('aria-activedescendant') ?? '')?.textContent!.trim();

      assert.false(input.hasAttribute('aria-activedescendant'));
      await triggerKeyEvent(input, 'keydown', 'ArrowUp');
      assert.strictEqual(active(), 'C', 'ArrowUp starts at the end');
      await triggerKeyEvent(input, 'keydown', 'ArrowDown');
      assert.strictEqual(active(), 'A', 'wraps around');
      await triggerKeyEvent(input, 'keydown', 'ArrowDown');
      assert.strictEqual(active(), 'C', 'skips disabled options');
      await triggerKeyEvent(input, 'keydown', 'ArrowUp');
      assert.strictEqual(active(), 'A');
    });

    test('Tab: bubbles unless an option is highlighted (upstream)', async function (assert) {
      const bubbled: string[] = [];
      const record = (e: KeyboardEvent) => bubbled.push(e.key);

      await render(
        <template>
          {{! template-lint-disable no-invalid-interactive }}
          <div {{on "keydown" record}}><EuiComboBox @options={{MOONS}} @onChange={{noop}} /></div>
        </template>
      );
      await open();
      await triggerKeyEvent(INPUT, 'keydown', 'Tab', { shiftKey: true });
      assert.deepEqual(bubbled, ['Tab'], 'tabbing away works');

      await open();
      await triggerKeyEvent(INPUT, 'keydown', 'ArrowDown');
      bubbled.length = 0;
      await triggerKeyEvent(INPUT, 'keydown', 'Tab');
      assert.deepEqual(bubbled, [], 'held while navigating the options');
    });

    test('Escape closes the list and keeps the text; leftover text marks it invalid', async function (assert) {
      await render(<template><EuiComboBox @options={{MOONS}} @onChange={{noop}} /></template>);
      await open();
      await fillIn(INPUT, 'zzz');
      assert.dom('.euiComboBox').doesNotHaveClass('euiComboBox-isInvalid', 'not while typing');

      await triggerKeyEvent(INPUT, 'keydown', 'Escape');
      assert.false(isOpen());
      assert.dom(INPUT).hasValue('zzz');
      assert.dom('.euiComboBox').hasClass('euiComboBox-isInvalid');
      assert.dom(INPUT).hasAttribute('aria-invalid', 'true');
    });

    test('Enter selects the option the text matches, also in groups (upstream)', async function (assert) {
      const state = new State([{ label: 'Red' }]);
      const grouped = new State([{ label: 'Group', options: [{ label: 'Blue' }] }]);

      await render(
        <template>
          <div data-c="flat"><EuiComboBox @options={{state.options}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} /></div>
          <div data-c="group"><EuiComboBox @options={{grouped.options}} @selectedOptions={{grouped.selected}} @onChange={{grouped.onChange}} /></div>
        </template>
      );
      await focus(`[data-c="flat"] ${INPUT}`);
      await fillIn(`[data-c="flat"] ${INPUT}`, 'red');
      await triggerKeyEvent(`[data-c="flat"] ${INPUT}`, 'keydown', 'Enter');
      assert.deepEqual(state.changes, [[{ label: 'Red' }]]);

      await focus(`[data-c="group"] ${INPUT}`);
      await fillIn(`[data-c="group"] ${INPUT}`, 'blue');
      await triggerKeyEvent(`[data-c="group"] ${INPUT}`, 'keydown', 'Enter');
      assert.deepEqual(grouped.changes, [[{ label: 'Blue' }]]);
    });

    test('Enter with @onCreateOption: fires with input, not without, once per duplicated value', async function (assert) {
      const plain = new State(MOONS, [MOONS[2]]);
      const delimited = new State(MOONS, [MOONS[2]]);

      await render(
        <template>
          <div data-c="plain"><EuiComboBox @options={{plain.options}} @selectedOptions={{plain.selected}} @onChange={{plain.onChange}} @onCreateOption={{plain.onCreateOption}} /></div>
          <div data-c="delim"><EuiComboBox @delimiter="," @options={{delimited.options}} @selectedOptions={{delimited.selected}} @onChange={{delimited.onChange}} @onCreateOption={{delimited.onCreateOption}} /></div>
        </template>
      );
      await focus(`[data-c="plain"] ${INPUT}`);
      await triggerKeyEvent(`[data-c="plain"] ${INPUT}`, 'keydown', 'Enter');
      assert.strictEqual(plain.created.length, 0, 'not without input');

      // upstream adds custom text even when it partially matches an option
      await fillIn(`[data-c="plain"] ${INPUT}`, 'Tit');
      await triggerKeyEvent(`[data-c="plain"] ${INPUT}`, 'keydown', 'Enter');
      assert.deepEqual(plain.created.map(([v]) => v), ['Tit']);
      assert.deepEqual(plain.created[0]![1], MOONS, 'with the flattened options');
      assert.true(isOpen(), 'multiple selection keeps the list open');
      assert.dom(`[data-c="plain"] ${INPUT}`).hasValue('');

      await focus(`[data-c="delim"] ${INPUT}`);
      await fillIn(`[data-c="delim"] ${INPUT}`, 'a, a,  a,   a');
      await triggerKeyEvent(`[data-c="delim"] ${INPUT}`, 'keydown', 'Enter');
      assert.deepEqual(delimited.created.map(([v]) => v), ['a']);
    });

    test('a custom single selection closes the list', async function (assert) {
      const state = new State(MOONS);

      await render(
        <template><EuiComboBox @singleSelection={{true}} @options={{state.options}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} @onCreateOption={{state.onCreateOption}} /></template>
      );
      await open();
      await fillIn(INPUT, 'Pan');
      await triggerKeyEvent(INPUT, 'keydown', 'Enter');
      
      assert.deepEqual(state.created.map(([v]) => v), ['Pan']);
      assert.false(isOpen());
    });

    test('Backspace removes the last pill only from an empty input (upstream spec)', async function (assert) {
      const multi = new State(MOONS, [MOONS[0], MOONS[1]]);
      const single = new State(MOONS, [MOONS[0]]);
      const plain = new State(MOONS, [MOONS[0]]);

      await render(
        <template>
          <div data-c="multi"><EuiComboBox @options={{multi.options}} @selectedOptions={{multi.selected}} @onChange={{multi.onChange}} /></div>
          <div data-c="single"><EuiComboBox @singleSelection={{true}} @options={{single.options}} @selectedOptions={{single.selected}} @onChange={{single.onChange}} /></div>
          <div data-c="plain"><EuiComboBox @singleSelection={{hash asPlainText=true}} @options={{plain.options}} @selectedOptions={{plain.selected}} @onChange={{plain.onChange}} /></div>
        </template>
      );
      await fillIn(`[data-c="multi"] ${INPUT}`, 'tes');
      await triggerKeyEvent(`[data-c="multi"] ${INPUT}`, 'keydown', 'Backspace');
      assert.strictEqual(multi.selected.length, 2, 'not with search text');
      await fillIn(`[data-c="multi"] ${INPUT}`, '');
      await triggerKeyEvent(`[data-c="multi"] ${INPUT}`, 'keydown', 'Escape');
      await triggerKeyEvent(`[data-c="multi"] ${INPUT}`, 'keydown', 'Backspace');
      assert.deepEqual(labels(multi.selected), ['Titan'], 'removes the last pill');
      assert.false(isOpen(), 'does not open the list');

      await focus(`[data-c="single"] ${INPUT}`);
      await triggerKeyEvent(`[data-c="single"] ${INPUT}`, 'keydown', 'Escape');
      await triggerKeyEvent(`[data-c="single"] ${INPUT}`, 'keydown', 'Backspace');
      
      assert.deepEqual(single.selected, []);
      assert.true(isOpen(), 'single selection opens the list again');
      await triggerKeyEvent(`[data-c="single"] ${INPUT}`, 'keydown', 'Escape');

      await focus(`[data-c="plain"] ${INPUT}`);
      assert.dom(`[data-c="plain"] ${INPUT}`).hasValue('Titan', 'asPlainText: the selection is the value');
      await triggerKeyEvent(`[data-c="plain"] ${INPUT}`, 'keydown', 'Backspace');

      assert.deepEqual(plain.selected, [], 'asPlainText: removes the selection');
      assert.dom(`[data-c="plain"] ${INPUT}`).hasValue('Titan', 'the text stays (it is the search now)');
      assert.dom('[data-c="plain"] [data-test-subj="comboBoxClearButton"]').doesNotExist('selection removed');
      // the key's own deletion (synthetic key events don't edit the text)
      await fillIn(`[data-c="plain"] ${INPUT}`, 'Tita');
      assert.dom(`[data-c="plain"] ${INPUT}`).hasValue('Tita', 'and deletes one character');
    });
  });

  module('leaving the combo box', function () {
    test('calls onCreateOption with the text (upstream)', async function (assert) {
      const state = new State(MOONS, [MOONS[2]]);

      await render(
        <template><EuiComboBox @options={{state.options}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} @onCreateOption={{state.onCreateOption}} /></template>
      );
      await focus(INPUT);
      await fillIn(INPUT, 'foo');
      await blur(INPUT);

      assert.deepEqual(state.created.map(([v]) => v), ['foo']);
      assert.deepEqual(state.created[0]![1], MOONS);
      assert.dom(INPUT).hasValue('');
      assert.dom('.euiComboBox').doesNotHaveClass('euiComboBox-isInvalid');
    });

    test('selects the option the text names; other text stays and is invalid', async function (assert) {
      const state = new State(MOONS);

      await render(
        <template><EuiComboBox @options={{state.options}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} /></template>
      );
      await focus(INPUT);
      await fillIn(INPUT, 'rhea');
      await blur(INPUT);
      assert.deepEqual(labels(state.selected), ['Rhea'], 'no @onCreateOption needed');

      await focus(INPUT);
      await fillIn(INPUT, 'nope');
      await blur(INPUT);
      assert.deepEqual(labels(state.selected), ['Rhea']);
      assert.dom(INPUT).hasValue('nope', 'the text stays');
      assert.dom('.euiComboBox').hasClass('euiComboBox-isInvalid');
    });

    test('does nothing while an option is highlighted', async function (assert) {
      const state = new State(MOONS);

      await render(
        <template><EuiComboBox @options={{state.options}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} @onCreateOption={{state.onCreateOption}} /></template>
      );
      await open();
      await fillIn(INPUT, 'ti');
      await triggerKeyEvent(INPUT, 'keydown', 'ArrowDown');
      await blur(INPUT);
      assert.deepEqual(state.created, []);
      assert.deepEqual(state.changes, []);
    });
  });

  module('messages and states', function () {
    test('empty states: no options, all selected, already added (upstream)', async function (assert) {
      const none: unknown[] = [];
      const all = new State([{ label: 'Titan' }], [{ label: 'Titan' }]);
      const added = new State(MOONS, [{ label: 'Pan' }]);

      await render(
        <template>
          <div data-c="none"><EuiComboBox @options={{none}} @onChange={{noop}} /></div>
          <div data-c="all"><EuiComboBox @options={{all.options}} @selectedOptions={{all.selected}} @onChange={{noop}} /></div>
          <div data-c="added"><EuiComboBox @options={{added.options}} @selectedOptions={{added.selected}} @onChange={{noop}} @onCreateOption={{added.onCreateOption}} /></div>
        </template>
      );
      await open('[data-c="none"]');
      assert.dom('.euiComboBoxOptionsList__empty', panel()!).hasText("There aren't any options available");
      await triggerKeyEvent(`[data-c="none"] ${INPUT}`, 'keydown', 'Escape');

      await open('[data-c="all"]');
      assert.dom('.euiComboBoxOptionsList__empty', panel()!).hasText("You've selected all available options");
      await triggerKeyEvent(`[data-c="all"] ${INPUT}`, 'keydown', 'Escape');

      await open('[data-c="added"]');
      await fillIn(`[data-c="added"] ${INPUT}`, 'pan');
      assert.dom('.euiComboBoxOptionsList__empty', panel()!).hasText('Pan has already been added');
      assert.dom('[data-test-subj="comboBoxCreateOption"]', panel()!).doesNotExist();
      await triggerKeyEvent(`[data-c="added"] ${INPUT}`, 'keydown', 'Enter');
      assert.deepEqual(added.created, [], 'not added again');
    });

    test('a custom @noMatchesMessage still wins', async function (assert) {
      await render(<template><EuiComboBox @options={{MOONS}} @noMatchesMessage="Nothing" @onChange={{noop}} /></template>);
      await open();
      await fillIn(INPUT, 'zzz');
      assert.dom('.euiComboBoxOptionsList__empty', panel()!).hasText('Nothing');
    });

    test('isLoading swaps the options for a spinner', async function (assert) {
      await render(<template><EuiComboBox @options={{MOONS}} @isLoading={{true}} @onChange={{noop}} /></template>);
      await open();
      assert.strictEqual(rows().length, 0);
      assert.dom('.euiComboBoxOptionsList .euiFlexGroup', panel()!).exists('the spinner empty state');
      assert.dom('.euiComboBoxOptionsList', panel()!).includesText('Loading options...');
    });

    test('@async options are listed as given, without the selected ones', async function (assert) {
      const state = new State(MOONS.slice(0, 3), [MOONS[0]]);

      await render(
        <template><EuiComboBox @async={{true}} @options={{state.options}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} @onSearchChange={{state.onSearchChange}} /></template>
      );
      await open();
      await fillIn(INPUT, 'zzz');
      assert.deepEqual(texts(), ['Enceladus', 'Mimas'], 'not filtered again');
      assert.deepEqual(state.searches.at(-1), ['zzz', true]);
    });

    test('onSearchChange (upstream)', async function (assert) {
      const state = new State(MOONS);

      await render(
        <template><EuiComboBox @options={{state.options}} @onSearchChange={{state.onSearchChange}} @onChange={{noop}} /></template>
      );
      await open();
      await fillIn(INPUT, 'no results');
      assert.deepEqual(state.searches.at(-1), ['no results', false]);
      assert.strictEqual(rows().length, 0);
      await fillIn(INPUT, 'titan');
      assert.deepEqual(state.searches.at(-1), ['titan', true]);
      assert.strictEqual(rows().length, 1);
    });

    test('clear button: only with a selection and isClearable; empties, focuses, opens', async function (assert) {
      const state = new State(MOONS, [MOONS[2]]);

      await render(
        <template>
          <div data-c="clear"><EuiComboBox @options={{state.options}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} /></div>
          <div data-c="none"><EuiComboBox @options={{MOONS}} @onChange={{noop}} /></div>
          <div data-c="off"><EuiComboBox @options={{MOONS}} @selectedOptions={{state.selected}} @isClearable={{false}} @onChange={{noop}} /></div>
        </template>
      );
      assert.dom('[data-c="none"] .euiFormControlLayoutClearButton').doesNotExist();
      assert.dom('[data-c="off"] .euiFormControlLayoutClearButton').doesNotExist();

      await click('[data-c="clear"] .euiFormControlLayoutClearButton');
      assert.deepEqual(state.changes, [[]]);
      assert.strictEqual(document.activeElement, q(`[data-c="clear"] ${INPUT}`));
      assert.true(isOpen());
    });

    test('placeholder: not with a selection or a search', async function (assert) {
      const selected = [MOONS[0]];

      await render(
        <template>
          <div data-c="empty"><EuiComboBox @options={{MOONS}} @placeholder="Select something" @onChange={{noop}} /></div>
          <div data-c="selected"><EuiComboBox @options={{MOONS}} @selectedOptions={{selected}} @placeholder="Select something" @onChange={{noop}} /></div>
        </template>
      );
      assert.dom(`[data-c="empty"] ${INPUT}`).hasAttribute('placeholder', 'Select something');
      assert.notOk(q(`[data-c="selected"] ${INPUT}`).getAttribute('placeholder'));
      await fillIn(`[data-c="empty"] ${INPUT}`, 'some search');
      assert.notOk(q(`[data-c="empty"] ${INPUT}`).getAttribute('placeholder'));
    });

    test('isDisabled: no clear button, no toggle, no remove buttons', async function (assert) {
      const selected = [MOONS[0]];

      await render(
        <template><EuiComboBox @options={{MOONS}} @selectedOptions={{selected}} @isDisabled={{true}} @onChange={{noop}} /></template>
      );
      assert.dom('.euiComboBox').hasClass('euiComboBox-isDisabled');
      assert.dom(INPUT).isDisabled();
      assert.dom('.euiFormControlLayoutClearButton').doesNotExist();
      assert.dom('[data-icon-type="chevronSingleDown"]').doesNotExist();
      assert.dom('[aria-label="Remove Titan from selection in this group"]').doesNotExist();
    });

    test('onFocusBadge shows the return badge on the highlighted option', async function (assert) {
      await render(<template><EuiComboBox @options={{MOONS}} @onFocusBadge={{true}} @onChange={{noop}} /></template>);
      await open();
      assert.dom('.euiComboBoxOption__enterBadge', panel()!).doesNotExist();
      await triggerKeyEvent(INPUT, 'keydown', 'ArrowDown');
      assert.dom('.euiComboBoxOption__enterBadge', rows()[0]).exists().hasAttribute('aria-hidden', 'true');
    });
  });

  module('accessibility', function () {
    test('the input is the combobox; the listbox is labelled', async function (assert) {
      await render(
        <template><EuiComboBox @options={{MOONS}} @ariaLabel="Test label" @ariaLabelledBy="test-heading-id" @onChange={{noop}} /></template>
      );
      const input = q(INPUT);
      assert.dom(input).hasAttribute('role', 'combobox').hasAttribute('aria-autocomplete', 'list').hasAttribute('aria-haspopup', 'listbox');
      assert.dom(input).hasAttribute('aria-expanded', 'false').doesNotHaveAttribute('aria-controls');
      assert.dom(input).hasAttribute('aria-label', 'Test label').hasAttribute('aria-labelledby', 'test-heading-id');
      const root = q('.euiComboBox');
      assert.notStrictEqual(root.getAttribute('role'), 'combobox', 'not the wrapper');
      assert.dom(root).doesNotHaveAttribute('aria-label');
      assert.dom(root).hasAttribute('tabindex', '-1', 'the wrapper is not a tab stop');

      await open();
      const listbox = q('[role="listbox"]');
      assert.dom(input).hasAttribute('aria-expanded', 'true').hasAttribute('aria-controls', listbox.id);
      assert.dom(listbox).hasAttribute('aria-label', 'Choose from the following options');
    });

    test('screen reader instructions while the input has focus (upstream)', async function (assert) {
      const selected = [MOONS[0], MOONS[1]];

      await render(
        <template><EuiComboBox @options={{MOONS}} @selectedOptions={{selected}} @placeholder="Pick" @onChange={{noop}} /></template>
      );
      assert.dom('[aria-live="polite"][id$="_removeOptionMessage"]').doesNotExist();
      await focus(INPUT);
      assert.dom('[aria-live="polite"][id$="_removeOptionMessage"]').includesText('Titan, Enceladus. Press Backspace to delete Enceladus.');
      await blur(INPUT);
      assert.dom('[aria-live="polite"][id$="_removeOptionMessage"]').doesNotExist();
    });

    test('focusing the input opens the list (upstream)', async function (assert) {
      await render(<template><EuiComboBox @options={{MOONS}} @onChange={{noop}} /></template>);
      await focus(INPUT);
      
      assert.true(isOpen());
      assert.false(q(INPUT).hasAttribute('aria-activedescendant'));
    });
  });
});

function q<T extends Element = HTMLElement>(selector: string, root: ParentNode = document) {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function array1<T>(list: readonly T[]): T[] {
  return [list[1]!];
}
