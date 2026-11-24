import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  fillIn,
  focus,
  render,
  settled,
  triggerEvent,
  triggerKeyEvent
} from '@ember/test-helpers';
import { array } from '@ember/helper';
import { tracked } from '@glimmer/tracking';

import moment from 'moment';

import EuiDatePicker from '#src/components/eui-date-picker.gts';
import EuiDatePickerRange from '#src/components/eui-date-picker-range.gts';
import EuiFieldText from '#src/components/eui-field-text.gts';

function el<T extends Element = HTMLElement>(
  selector: string,
  root: ParentNode = document
) {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

const startInput = () => el<HTMLInputElement>('input[aria-label="Start date"]');
const endInput = () => el<HTMLInputElement>('input[aria-label="End date"]');
const panelDay = (date: string) =>
  el<HTMLElement>(`[data-popover-panel] td[data-date="${date}"]`);
const dayIn = (root: ParentNode, date: string) =>
  el<HTMLElement>(`td[data-date="${date}"]`, root);
const classesOf = (root: ParentNode, from: string, to: string, name: string) =>
  [...root.querySelectorAll<HTMLElement>('td[data-date]')]
    .filter((cell) => cell.classList.contains(`react-datepicker__day--${name}`))
    .map((cell) => cell.dataset['date']!)
    .filter((date) => date >= from && date <= to);

const realMatchMedia = window.matchMedia;
function stubPointer(coarse: boolean) {
  window.matchMedia = (query: string) => {
    if (query.replace(/\s/g, '') !== '(pointer:coarse)') {
      return realMatchMedia.call(window, query);
    }
    return {
      matches: coarse,
      media: query,
      onchange: null,
      addListener() {},
      removeListener() {},
      addEventListener() {},
      removeEventListener() {},
      dispatchEvent: () => false
    } as MediaQueryList;
  };
}

class Range {
  @tracked start: string | null = '2026-11-10';
  @tracked end: string | null = '2026-11-14';
  @tracked compressed = false;
  @tracked disabled = false;
  @tracked invalid = false;
  @tracked timeSelect = false;
  setStart = (value: string | null) => {
    this.start = value;
  };
  setEnd = (value: string | null) => {
    this.end = value;
  };
}

module(
  'Integration | Component | eui-date-picker-range | with EuiDatePicker (DESIGN 4.5)',
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.afterEach(function () {
      window.matchMedia = realMatchMedia;
    });

    test("a picker in a block takes the range's place: no frame, no icon of its own, the yielded class", async function (assert) {
      const state = new Range();
      await render(
        <template>
          <EuiDatePickerRange>
            <:start as |className|>
              <EuiDatePicker
                class={{className}}
                aria-label="Start date"
                @value={{state.start}}
                @onChange={{state.setStart}}
              />
            </:start>
            <:end as |className|>
              <EuiDatePicker
                class={{className}}
                aria-label="End date"
                @value={{state.end}}
                @onChange={{state.setEnd}}
              />
            </:end>
          </EuiDatePickerRange>
        </template>
      );

      // controlOnly: the inputs sit in the delimited layout, no layout of their own
      assert
        .dom('.euiDatePickerRange .euiFormControlLayout')
        .exists({ count: 1 }, "only the range's layout");
      assert
        .dom('.euiDatePickerRange div.euiDatePicker')
        .doesNotExist('no picker wrapper');
      // showIcon false: the range's calendar icon only
      assert
        .dom('.euiDatePickerRange [data-icon-type="calendar"]')
        .exists({ count: 1 });
      assert
        .dom(startInput())
        .hasClass('euiDatePickerRange__start')
        .hasClass('euiFormControlLayoutDelimited__input')
        .hasValue('11/10/2026');
      assert
        .dom(endInput())
        .hasClass('euiDatePickerRange__end')
        .hasValue('11/14/2026');
    });

    test("compressed, fullWidth, readOnly, disabled and isInvalid come from the range; the picker's own disabled and isInvalid add to them", async function (assert) {
      const state = new Range();
      await render(
        <template>
          <div data-p="range">
            <EuiDatePickerRange
              @compressed={{state.compressed}}
              @disabled={{state.disabled}}
              @isInvalid={{state.invalid}}
              @fullWidth={{true}}
            >
              <:start as |className|>
                <EuiDatePicker
                  class={{className}}
                  aria-label="Start date"
                  @value={{state.start}}
                />
              </:start>
              <:end as |className|>
                <EuiDatePicker
                  class={{className}}
                  aria-label="End date"
                  @value={{state.end}}
                  @isInvalid={{true}}
                />
              </:end>
            </EuiDatePickerRange>
          </div>
          <div data-p="reference">
            <EuiFieldText
              @controlOnly={{true}}
              @compressed={{true}}
              aria-label="compressed"
            />
            <EuiFieldText @controlOnly={{true}} aria-label="uncompressed" />
          </div>
        </template>
      );

      // the classes EuiFieldText adds for @compressed
      const classList = (label: string) => [
        ...el(`input[aria-label="${label}"]`).classList
      ];
      // emotion composes one class per input, its labels in the name
      const isCompressed = (input: HTMLInputElement) =>
        /-compressed(-|$)/.test([...input.classList].join(' '));
      assert.true(
        classList('compressed').some((name) => /-compressed(-|$)/.test(name)),
        'the label shows'
      );
      assert.false(
        classList('uncompressed').some((name) => /-compressed(-|$)/.test(name))
      );
      assert.false(isCompressed(startInput()), 'not compressed yet');
      assert.notOk(startInput().disabled);
      assert.dom(startInput()).doesNotHaveAria('invalid');
      assert.dom(endInput()).hasAria('invalid', 'true', 'its own @isInvalid');

      state.compressed = true;
      state.disabled = true;
      state.invalid = true;
      await settled();
      assert.true(startInput().disabled, 'the range disables both');
      assert.true(endInput().disabled);
      assert
        .dom(startInput())
        .hasAria('invalid', 'true', 'the range makes both invalid');
      assert.true(isCompressed(startInput()), 'compressed as the range');
      assert.true(isCompressed(endInput()));

      state.disabled = false;
      await settled();
      await click(startInput());
      assert
        .dom('[data-popover-panel]', document.body)
        .exists('enabled again, it opens');
    });

    test('a read-only range: the pickers are read-only, nothing opens', async function (assert) {
      const state = new Range();
      await render(
        <template>
          <EuiDatePickerRange @readOnly={{true}}>
            <:start as |className|><EuiDatePicker
                class={{className}}
                aria-label="Start date"
                @value={{state.start}}
              /></:start>
            <:end as |className|><EuiDatePicker
                class={{className}}
                aria-label="End date"
                @value={{state.end}}
              /></:end>
          </EuiDatePickerRange>
        </template>
      );
      assert.true(startInput().readOnly);
      assert.true(endInput().readOnly);
      await click(endInput());
      assert.dom('[data-popover-panel]', document.body).doesNotExist();
    });

    test("the end opens downRight, the start downLeft (upstream popoverPlacement); the picker's own wins", async function (assert) {
      const state = new Range();
      await render(
        <template>
          <div style="padding: 0 400px; width: 900px">
            <EuiDatePickerRange @fullWidth={{true}}>
              <:start as |className|><EuiDatePicker
                  class={{className}}
                  aria-label="Start date"
                  @value={{state.start}}
                /></:start>
              <:end as |className|><EuiDatePicker
                  class={{className}}
                  aria-label="End date"
                  @value={{state.end}}
                /></:end>
            </EuiDatePickerRange>
            <EuiDatePickerRange @fullWidth={{true}}>
              <:start as |className|><EuiDatePicker
                  class={{className}}
                  aria-label="Own"
                  @popoverPlacement="downRight"
                /></:start>
              <:end as |className|><EuiDatePicker
                  class={{className}}
                  aria-label="Other end"
                /></:end>
            </EuiDatePickerRange>
          </div>
        </template>
      );

      const panelBox = () => el('[data-popover-panel]').getBoundingClientRect();
      await click(endInput());

      const end = endInput().getBoundingClientRect();
      assert.true(
        Math.abs(panelBox().right - end.right) < 2,
        `end: right edges meet (${panelBox().right} / ${end.right})`
      );
      await triggerKeyEvent(endInput(), 'keydown', 'Escape');

      await click(startInput());

      const start = startInput().getBoundingClientRect();
      assert.true(
        Math.abs(panelBox().left - start.left) < 2,
        `start: left edges meet (${panelBox().left} / ${start.left})`
      );
      await triggerKeyEvent(startInput(), 'keydown', 'Escape');

      const own = el<HTMLInputElement>('input[aria-label="Own"]');
      await click(own);

      assert.true(
        Math.abs(panelBox().right - own.getBoundingClientRect().right) < 2,
        'its own @popoverPlacement wins'
      );
    });

    test('the range highlight: in-range, range-start and range-end from @startDate and @endDate; it follows them (9 #50)', async function (assert) {
      const state = new Range();
      await render(
        <template>
          <EuiDatePickerRange>
            <:start as |className|>
              <EuiDatePicker
                class={{className}}
                aria-label="Start date"
                @value={{state.start}}
                @onChange={{state.setStart}}
                @selectsStart={{true}}
                @startDate={{state.start}}
                @endDate={{state.end}}
                @maxDate={{state.end}}
              />
            </:start>
            <:end as |className|>
              <EuiDatePicker
                class={{className}}
                aria-label="End date"
                @value={{state.end}}
                @onChange={{state.setEnd}}
                @selectsEnd={{true}}
                @startDate={{state.start}}
                @endDate={{state.end}}
                @minDate={{state.start}}
              />
            </:end>
          </EuiDatePickerRange>
        </template>
      );

      await click(startInput());
      const panel = el('[data-popover-panel]');
      assert.deepEqual(
        classesOf(panel, '2026-11-01', '2026-11-30', 'in-range'),
        ['2026-11-10', '2026-11-11', '2026-11-12', '2026-11-13', '2026-11-14']
      );
      assert
        .dom(panelDay('2026-11-10'))
        .hasClass('react-datepicker__day--range-start')
        .hasClass('react-datepicker__day--selected');
      assert
        .dom(panelDay('2026-11-14'))
        .hasClass('react-datepicker__day--range-end')
        .doesNotHaveClass('react-datepicker__day--selected');
      assert
        .dom(panelDay('2026-11-15'))
        .hasClass('react-datepicker__day--disabled', 'after @maxDate, the end');

      // pick a new start: the highlight follows
      await click(el('button', panelDay('2026-11-12')));
      assert.strictEqual(state.start, '2026-11-12');
      await click(endInput());
      const endPanel = el('[data-popover-panel]');
      assert.deepEqual(
        classesOf(endPanel, '2026-11-01', '2026-11-30', 'in-range'),
        ['2026-11-12', '2026-11-13', '2026-11-14']
      );
      assert
        .dom(panelDay('2026-11-11'))
        .hasClass(
          'react-datepicker__day--disabled',
          'before @minDate, the start'
        );
      assert
        .dom(panelDay('2026-11-14'))
        .hasClass('react-datepicker__day--selected')
        .hasClass('react-datepicker__day--range-end');

      // one end missing: no highlight (upstream)
      state.end = null;
      await settled();
      assert
        .dom('[data-popover-panel] .react-datepicker__day--in-range')
        .doesNotExist();
    });

    test('the end before the start: nothing in range, the pickers do not change the other value (9 #49)', async function (assert) {
      const state = new Range();
      state.start = '2026-11-20';
      await render(
        <template>
          <EuiDatePickerRange @isInvalid={{true}}>
            <:start as |className|><EuiDatePicker
                class={{className}}
                aria-label="Start date"
                @value={{state.start}}
                @onChange={{state.setStart}}
                @selectsStart={{true}}
                @startDate={{state.start}}
                @endDate={{state.end}}
              /></:start>
            <:end as |className|><EuiDatePicker
                class={{className}}
                aria-label="End date"
                @value={{state.end}}
                @onChange={{state.setEnd}}
                @selectsEnd={{true}}
                @startDate={{state.start}}
                @endDate={{state.end}}
              /></:end>
          </EuiDatePickerRange>
        </template>
      );
      await click(startInput());
      assert
        .dom('[data-popover-panel] .react-datepicker__day--in-range')
        .doesNotExist();
      assert.strictEqual(state.end, '2026-11-14');
      assert.dom(startInput()).hasAria('invalid', 'true');
    });

    test('the hover preview: from the hovered day to the end, or from the start to it; never reversed, never a disabled day', async function (assert) {
      const state = new Range();
      await render(
        <template>
          <EuiDatePickerRange>
            <:start as |className|><EuiDatePicker
                class={{className}}
                aria-label="Start date"
                @value={{state.start}}
                @onChange={{state.setStart}}
                @selectsStart={{true}}
                @startDate={{state.start}}
                @endDate={{state.end}}
              /></:start>
            <:end as |className|><EuiDatePicker
                class={{className}}
                aria-label="End date"
                @value={{state.end}}
                @onChange={{state.setEnd}}
                @selectsEnd={{true}}
                @startDate={{state.start}}
                @endDate={{state.end}}
                @excludeDates={{array "2026-11-18"}}
              /></:end>
          </EuiDatePickerRange>
        </template>
      );

      await click(startInput());
      let panel = el('[data-popover-panel]');
      assert
        .dom('.react-datepicker__day--in-selecting-range', panel)
        .doesNotExist('nothing before a hover');
      await triggerEvent(panelDay('2026-11-07'), 'mouseenter');
      assert.deepEqual(
        classesOf(panel, '2026-11-01', '2026-11-30', 'in-selecting-range'),
        [
          '2026-11-07',
          '2026-11-08',
          '2026-11-09',
          '2026-11-10',
          '2026-11-11',
          '2026-11-12',
          '2026-11-13',
          '2026-11-14'
        ]
      );
      assert
        .dom(panelDay('2026-11-07'))
        .hasClass('react-datepicker__day--selecting-range-start');
      assert
        .dom(panelDay('2026-11-14'))
        .hasClass('react-datepicker__day--selecting-range-end');
      assert
        .dom('.react-datepicker__month', panel)
        .hasClass('react-datepicker__month--selecting-range');
      await triggerEvent(panelDay('2026-11-20'), 'mouseenter');
      assert
        .dom('.react-datepicker__day--in-selecting-range', panel)
        .doesNotExist('after the end: no preview');
      await triggerEvent(el('.react-datepicker__month', panel), 'mouseleave');
      assert
        .dom('.react-datepicker__month', panel)
        .doesNotHaveClass('react-datepicker__month--selecting-range');
      await triggerKeyEvent(startInput(), 'keydown', 'Escape');

      await click(endInput());
      panel = el('[data-popover-panel]');
      await triggerEvent(panelDay('2026-11-20'), 'mouseenter');
      const preview = classesOf(
        panel,
        '2026-11-01',
        '2026-11-30',
        'in-selecting-range'
      );
      assert.strictEqual(preview[0], '2026-11-10');
      assert.strictEqual(preview[preview.length - 1], '2026-11-20');
      assert.notOk(
        preview.includes('2026-11-18'),
        'a disabled day is not previewed'
      );
      await triggerEvent(panelDay('2026-11-05'), 'mouseenter');
      assert
        .dom('.react-datepicker__day--in-selecting-range', panel)
        .doesNotExist('before the start: no preview');
    });

    test('the keyboard previews too: the focused day while focus is in the grid', async function (assert) {
      const state = new Range();
      await render(
        <template>
          <EuiDatePickerRange>
            <:start as |className|><EuiDatePicker
                class={{className}}
                aria-label="Start date"
                @value={{state.start}}
                @onChange={{state.setStart}}
                @selectsStart={{true}}
                @startDate={{state.start}}
                @endDate={{state.end}}
              /></:start>
            <:end as |className|><EuiDatePicker
                class={{className}}
                aria-label="End date"
                @value={{state.end}}
                @onChange={{state.setEnd}}
                @selectsEnd={{true}}
                @startDate={{state.start}}
                @endDate={{state.end}}
              /></:end>
          </EuiDatePickerRange>
        </template>
      );
      await focus(endInput());
      await triggerKeyEvent(endInput(), 'keydown', 'ArrowDown');

      const focused = document.activeElement as HTMLElement;
      assert.strictEqual(
        focused.closest<HTMLElement>('td')?.dataset['date'],
        '2026-11-14'
      );
      await triggerKeyEvent(focused, 'keydown', 'ArrowRight');
      await triggerKeyEvent(document.activeElement!, 'keydown', 'ArrowRight');
      const panel = el('[data-popover-panel]');
      assert.deepEqual(
        classesOf(panel, '2026-11-01', '2026-11-30', 'selecting-range-end'),
        ['2026-11-16']
      );
      // Enter: the button's native activation
      await click(document.activeElement!);
      assert.strictEqual(state.end, '2026-11-16');
    });

    test('@startDate and @endDate as instants, Dates and moments: highlighted by their day in the zone', async function (assert) {
      const instants = {
        start: '2026-11-10T15:00:00.000Z',
        end: '2026-11-13T03:30:00.000Z' // 12 November in New York
      };
      const dates = {
        start: new Date(2026, 10, 3, 12),
        end: moment([2026, 10, 5, 12])
      };
      await render(
        <template>
          <div data-p="instants">
            <EuiDatePicker
              @inline={{true}}
              @showTimeSelect={{true}}
              @timeZone="America/New_York"
              @value={{instants.start}}
              @selectsStart={{true}}
              @startDate={{instants.start}}
              @endDate={{instants.end}}
            />
          </div>
          <div data-p="objects">
            <EuiDatePicker
              @inline={{true}}
              @value="2026-11-03"
              @selectsEnd={{true}}
              @startDate={{dates.start}}
              @endDate={{dates.end}}
            />
          </div>
        </template>
      );
      const instantsRoot = el('[data-p="instants"]');
      assert.deepEqual(
        classesOf(instantsRoot, '2026-11-01', '2026-11-30', 'in-range'),
        ['2026-11-10', '2026-11-11', '2026-11-12']
      );
      assert
        .dom(dayIn(instantsRoot, '2026-11-12'))
        .hasClass('react-datepicker__day--range-end');
      const objectsRoot = el('[data-p="objects"]');
      assert.deepEqual(
        classesOf(objectsRoot, '2026-11-01', '2026-11-30', 'in-range'),
        ['2026-11-03', '2026-11-04', '2026-11-05']
      );
      assert.strictEqual(
        dates.end.format('YYYY-MM-DD HH:mm'),
        '2026-11-05 12:00',
        'the moment is not changed'
      );
    });

    test('an inline range: two bare calendars, no frame of their own; a time list widens the stacking point', async function (assert) {
      const state = new Range();
      await render(
        <template>
          <div data-p="pickers">
            <EuiDatePickerRange @inline={{true}}>
              <:start as |className|><EuiDatePicker
                  class={{className}}
                  aria-label="Start date"
                  @value={{state.start}}
                  @onChange={{state.setStart}}
                  @showTimeSelect={{state.timeSelect}}
                /></:start>
              <:end as |className|><EuiDatePicker
                  class={{className}}
                  aria-label="End date"
                  @value={{state.end}}
                  @onChange={{state.setEnd}}
                /></:end>
            </EuiDatePickerRange>
          </div>
          <div data-p="with-arg"><EuiDatePickerRange
              @inline={{true}}
              @showTimeSelect={{true}}
            ><:start>x</:start><:end>y</:end></EuiDatePickerRange></div>
          <div data-p="without-arg"><EuiDatePickerRange @inline={{true}}><:start
              >x</:start><:end>y</:end></EuiDatePickerRange></div>
        </template>
      );

      const pickers = el('[data-p="pickers"]');
      assert.dom('.react-datepicker', pickers).exists({ count: 2 });
      // the yielded class has `euiDatePicker`; the frame would be a layout around the calendar
      for (const calendar of pickers.querySelectorAll('.react-datepicker')) {
        assert
          .dom(calendar.parentElement!.closest('.euiFormControlLayout'))
          .hasClass(
            'euiFormControlLayoutDelimited',
            "no frame of the picker's own: the range's layout holds the calendar"
          );
      }
      assert.dom('.react-datepicker', pickers).hasClass('euiDatePicker');
      assert
        .dom('.react-datepicker[aria-label="Start date"]', pickers)
        .hasClass('euiDatePickerRange__start');
      assert.dom('[data-popover-panel]', document.body).doesNotExist();

      const rangeClass = (selector: string) =>
        el(`${selector} .euiDatePickerRange`).className;
      assert.strictEqual(
        rangeClass('[data-p="pickers"]'),
        rangeClass('[data-p="without-arg"]')
      );
      state.timeSelect = true;
      await settled();
      assert.strictEqual(
        rangeClass('[data-p="pickers"]'),
        rangeClass('[data-p="with-arg"]'),
        'a picker with a time list tells the range'
      );
      state.timeSelect = false;
      await settled();
      assert.strictEqual(
        rangeClass('[data-p="pickers"]'),
        rangeClass('[data-p="without-arg"]')
      );

      await click(el('button', dayIn(pickers, '2026-11-20')));
      assert.strictEqual(state.start, '2026-11-20', 'the start calendar picks');
    });

    test('@isCustom: the picker takes nothing from the range', async function (assert) {
      await render(
        <template>
          <EuiDatePickerRange @isCustom={{true}} @disabled={{true}}>
            <:start as |className|><EuiDatePicker
                class={{className}}
                aria-label="Start date"
                @value="2026-11-10"
              /></:start>
            <:end as |className|><EuiDatePicker
                class={{className}}
                aria-label="End date"
                @value="2026-11-14"
              /></:end>
          </EuiDatePickerRange>
        </template>
      );
      assert.false(startInput().disabled);
      assert
        .dom('.euiDatePickerRange div.euiDatePicker')
        .exists({ count: 2 }, 'each picker keeps its layout');
    });

    test('mixed blocks: EuiFieldText ignores the context; a picker next to it still takes it', async function (assert) {
      await render(
        <template>
          <EuiDatePickerRange @disabled={{true}}>
            <:start as |className|><EuiFieldText
                @controlOnly={{true}}
                type="date"
                class={{className}}
                aria-label="Start date"
              /></:start>
            <:end as |className|><EuiDatePicker
                class={{className}}
                aria-label="End date"
                @value="2026-11-14"
              /></:end>
          </EuiDatePickerRange>
        </template>
      );
      assert
        .dom(startInput())
        .hasAttribute('type', 'date')
        .hasClass('euiDatePickerRange__start');
      assert.false(
        startInput().disabled,
        'not a picker: the range does not disable it'
      );
      assert.true(endInput().disabled);
    });

    test('on a phone (coarse pointer): two native inputs in the range; an inline range keeps the calendars; a read-only one, text inputs', async function (assert) {
      stubPointer(true);
      const state = new Range();
      await render(
        <template>
          <div data-p="plain">
            <EuiDatePickerRange>
              <:start as |className|><EuiDatePicker
                  class={{className}}
                  aria-label="Start date"
                  @value={{state.start}}
                  @onChange={{state.setStart}}
                  @maxDate={{state.end}}
                /></:start>
              <:end as |className|><EuiDatePicker
                  class={{className}}
                  aria-label="End date"
                  @value={{state.end}}
                  @onChange={{state.setEnd}}
                  @minDate={{state.start}}
                /></:end>
            </EuiDatePickerRange>
          </div>
          <div data-p="inline">
            <EuiDatePickerRange @inline={{true}}>
              <:start as |className|><EuiDatePicker
                  class={{className}}
                  aria-label="Inline start"
                /></:start>
              <:end as |className|><EuiDatePicker
                  class={{className}}
                  aria-label="Inline end"
                /></:end>
            </EuiDatePickerRange>
          </div>
          <div data-p="readonly">
            <EuiDatePickerRange @readOnly={{true}}>
              <:start as |className|><EuiDatePicker
                  class={{className}}
                  aria-label="Read-only start"
                  @value="2026-11-10"
                /></:start>
              <:end as |className|><EuiDatePicker
                  class={{className}}
                  aria-label="Read-only end"
                  @value="2026-11-14"
                /></:end>
            </EuiDatePickerRange>
          </div>
        </template>
      );
      assert
        .dom(startInput())
        .hasAttribute('type', 'date')
        .hasClass('euiDatePicker--native')
        .hasClass('euiDatePickerRange__start')
        .hasAttribute('max', '2026-11-14');
      assert
        .dom(endInput())
        .hasAttribute('type', 'date')
        .hasAttribute('min', '2026-11-10');
      await fillIn(endInput(), '2026-11-20');
      await triggerEvent(endInput(), 'change');
      assert.strictEqual(state.end, '2026-11-20');
      assert.dom('[data-p="inline"] .react-datepicker').exists({ count: 2 });
      assert
        .dom('[data-p="readonly"] input[aria-label="Read-only start"]')
        .hasAttribute('type', 'text')
        .hasValue('11/10/2026');
    });

    test('no preview on the selected day: after a pick the mouse (or a tap) and focus stay there, the range shows at rest', async function (assert) {
      const state = new Range();
      await render(
        <template>
          <EuiDatePicker
            @inline={{true}}
            @value={{state.start}}
            @onChange={{state.setStart}}
            @selectsStart={{true}}
            @startDate={{state.start}}
            @endDate={{state.end}}
          />
        </template>
      );
      const root = el('.react-datepicker');
      await triggerEvent(dayIn(root, '2026-11-08'), 'mouseenter');
      assert
        .dom('.react-datepicker__day--in-selecting-range', root)
        .exists('a preview before the pick');
      await click(el('button', dayIn(root, '2026-11-08')));
      assert.strictEqual(state.start, '2026-11-08');
      assert
        .dom('.react-datepicker__day--in-selecting-range', root)
        .doesNotExist('the picked day under the mouse previews nothing');
      assert.deepEqual(
        classesOf(root, '2026-11-01', '2026-11-30', 'in-range').length,
        7,
        'the range at rest'
      );
      await triggerEvent(dayIn(root, '2026-11-09'), 'mouseenter');
      assert
        .dom('.react-datepicker__day--in-selecting-range', root)
        .exists('another day previews again');
    });

    test('a picker with a time list that leaves an inline range stops widening it', async function (assert) {
      const state = new Range();
      state.timeSelect = true;
      await render(
        <template>
          <div data-p="pickers">
            <EuiDatePickerRange @inline={{true}}>
              <:start as |className|>
                {{#if state.timeSelect}}
                  <EuiDatePicker class={{className}} @showTimeSelect={{true}} />
                {{/if}}
              </:start>
              <:end as |className|><EuiDatePicker class={{className}} /></:end>
            </EuiDatePickerRange>
          </div>
          <div data-p="with-arg"><EuiDatePickerRange
              @inline={{true}}
              @showTimeSelect={{true}}
            ><:start>x</:start><:end>y</:end></EuiDatePickerRange></div>
          <div data-p="without-arg"><EuiDatePickerRange @inline={{true}}><:start
              >x</:start><:end>y</:end></EuiDatePickerRange></div>
        </template>
      );
      const rangeClass = (selector: string) =>
        el(`${selector} .euiDatePickerRange`).className;
      assert.strictEqual(
        rangeClass('[data-p="pickers"]'),
        rangeClass('[data-p="with-arg"]')
      );
      state.timeSelect = false;
      await settled();
      assert.strictEqual(
        rangeClass('[data-p="pickers"]'),
        rangeClass('[data-p="without-arg"]')
      );
    });
  }
);
