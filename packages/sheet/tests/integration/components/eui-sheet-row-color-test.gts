/**
 * Row colours (V03-DESIGN.md 10.2, RC1-RC4): a 4 px bar at the row's left
 * edge from `@rowColor`, named colours from the theme, a CSS colour as
 * given, frozen and scrolled, and `colorByOption`.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { render, settled, triggerEvent } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { colorByOption } from '#src/field-types.ts';
import { cell, el } from '../../helpers/sheet.ts';

import type { EuiSheetField } from '#src/core/index.ts';
import type { SheetRowColor } from '#src/types.ts';
import type EuiEmotionService from '@ember-eui/core/services/eui-emotion';

interface Row {
  id: string;
  name: string;
  status: string | null;
  [key: string]: unknown;
}

const getId = (row: Row) => row.id;
const noop = () => {};

const STATUS: EuiSheetField<Row> = {
  id: 'status',
  label: 'Status',
  type: 'singleSelect',
  options: [
    { value: 'late', label: 'Late', color: 'danger' },
    { value: 'ok', label: 'On time', color: 'success' },
    { value: 'hold', label: 'On hold', color: 'default' },
    { value: 'plain', label: 'Plain' },
    { value: 'custom', label: 'Custom', color: '#123456' }
  ]
};

function rows(count = 4): Row[] {
  return Array.from({ length: count }, (_, i) => {
    const row: Row = { id: `r${i}`, name: `N${i}`, status: null };
    for (let f = 0; f < 12; f++) row[`f${f}`] = `${i}-${f}`;
    return row;
  });
}

function rowNumberCell(row: number): HTMLElement {
  return el(
    `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-index="0"]`
  );
}

/** `#rrggbb` → `rgb(r, g, b)`, as computed styles report it. */
function rgb(hex: string): string {
  const parts = /^#([\da-f]{2})([\da-f]{2})([\da-f]{2})$/i.exec(hex.trim());
  if (!parts) return hex.trim();
  return `rgb(${parts
    .slice(1)
    .map((pair) => parseInt(pair, 16))
    .join(', ')})`;
}

function shadow(element: Element): string {
  return getComputedStyle(element).boxShadow;
}

function token(name: string): string {
  return getComputedStyle(el('[data-test-subj=euiSheet]'))
    .getPropertyValue(name)
    .trim();
}

class State {
  @tracked records: Row[] = rows();
  @tracked fields: EuiSheetField<Row>[] = [
    { id: 'name', label: 'Name', width: 150 },
    STATUS
  ];
  @tracked rowNumbers = true;
  @tracked frozenFields = 0;
  @tracked rowColor: ((record: Row) => SheetRowColor | undefined) | undefined =
    (record: Row) =>
      ({ r0: 'danger', r1: undefined, r2: 'rgb(1, 2, 3)', r3: 'success' })[
        record.id
      ];
}

module('Integration | Component | EuiSheet row colours', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    // elementFromPoint needs the container on screen
    document.getElementById('ember-testing-container')?.scrollIntoView();
  });

  async function renderSheet(state: State): Promise<void> {
    await render(
      <template>
        <div style="width:500px">
          <EuiSheet
            @fields={{state.fields}}
            @records={{state.records}}
            @getRecordId={{getId}}
            @onChange={{noop}}
            @rowColor={{state.rowColor}}
            @rowNumbers={{state.rowNumbers}}
            @frozenFields={{state.frozenFields}}
            @height={{300}}
          />
        </div>
      </template>
    );
  }

  test('RC1 a named colour is the theme’s token; undefined draws none; a CSS colour as given', async function (assert) {
    const state = new State();
    await renderSheet(state);
    const danger = token('--euiSheet-rowDanger');
    assert.ok(danger, `--euiSheet-rowDanger is defined (${danger})`);
    assert.dom(rowNumberCell(0)).hasClass('euiSheet__rowColor');
    assert.ok(
      shadow(rowNumberCell(0)).includes(rgb(danger)) &&
        shadow(rowNumberCell(0)).includes('4px 0px 0px 0px inset'),
      `a 4 px inset bar in ${rgb(danger)}: ${shadow(rowNumberCell(0))}`
    );
    assert.dom(rowNumberCell(1)).doesNotHaveClass('euiSheet__rowColor');
    assert.strictEqual(shadow(rowNumberCell(1)), 'none', 'undefined: no bar');
    assert.ok(
      shadow(rowNumberCell(2)).includes('rgb(1, 2, 3)'),
      `a CSS colour as given: ${shadow(rowNumberCell(2))}`
    );
    assert.ok(
      shadow(rowNumberCell(3)).includes(rgb(token('--euiSheet-rowSuccess'))),
      'success'
    );
    assert.strictEqual(shadow(cell(0, 0)), 'none', 'not on the data cells');
    assert
      .dom(rowNumberCell(0))
      .hasAttribute('aria-label', 'Row 1', 'the label is unchanged');
    // a selected row keeps its bar next to the selection's edge
    await triggerEvent(rowNumberCell(0), 'mousedown', { button: 0 });
    await triggerEvent(document, 'mouseup');
    assert.dom(rowNumberCell(0)).hasClass('euiSheet__rowCell--selected');
    assert.ok(
      shadow(rowNumberCell(0)).includes(rgb(danger)),
      `selected: ${shadow(rowNumberCell(0))}`
    );
    // without row numbers: the first field's cell
    state.rowNumbers = false;
    await settled();
    const first = el(
      '[role=gridcell][data-gridcell-visible-row-index="0"][data-gridcell-column-index="0"]'
    );
    assert.dom(first).hasClass('euiSheet__rowColor');
    assert.ok(shadow(first).includes(rgb(danger)), 'on the first field');
    // no @rowColor: nothing
    state.rowNumbers = true;
    state.rowColor = undefined;
    await settled();
    assert.strictEqual(
      document.querySelectorAll('.euiSheet__rowColor').length,
      0,
      'none without @rowColor'
    );
  });

  test('RC2 dark theme: the named colour’s computed value changes with the theme', async function (assert) {
    const state = new State();
    await renderSheet(state);
    const light = shadow(rowNumberCell(0));
    const lightToken = token('--euiSheet-rowDanger');
    const emotion = this.owner.lookup(
      'service:eui-emotion'
    ) as EuiEmotionService;
    emotion.colorMode = 'dark';
    await settled();
    try {
      const darkToken = token('--euiSheet-rowDanger');
      assert.notStrictEqual(
        darkToken,
        lightToken,
        `the token follows the theme: ${lightToken} (light), ${darkToken} (dark)`
      );
      const dark = shadow(rowNumberCell(0));
      assert.notStrictEqual(dark, light, `the bar: ${light} → ${dark}`);
      assert.ok(dark.includes(rgb(darkToken)), 'in the dark token');
      assert.ok(
        shadow(rowNumberCell(2)).includes('rgb(1, 2, 3)'),
        'a CSS colour stays as given'
      );
    } finally {
      emotion.colorMode = 'light';
      await settled();
    }
  });

  test('RC3 frozen and scrolled: the bar is visible on the frozen row-number cell', async function (assert) {
    const state = new State();
    state.fields = [
      { id: 'name', label: 'Name', width: 150 },
      ...Array.from({ length: 12 }, (_, f) => ({
        id: `f${f}`,
        label: `F${f}`,
        width: 150
      }))
    ];
    state.frozenFields = 1;
    await renderSheet(state);
    const outer = el('.euiDataGrid__virtualized');
    outer.scrollLeft = 700;
    await triggerEvent(outer, 'scroll');
    assert.strictEqual(outer.scrollLeft, 700, 'scrolled');
    const number = rowNumberCell(0);
    assert.strictEqual(number.style.position, 'sticky', 'still sticky');
    assert.ok(
      shadow(number).includes(rgb(token('--euiSheet-rowDanger'))),
      `the bar: ${shadow(number)}`
    );
    const box = number.getBoundingClientRect();
    const hit = document.elementFromPoint(
      box.left + 1,
      box.top + box.height / 2
    );
    assert.true(
      !!hit && number.contains(hit),
      'the bar’s pixels are the row-number cell’s, not a scrolled cell’s'
    );
  });

  test('RC4 colorByOption returns the option’s colour, undefined for no value', function (assert) {
    const color = colorByOption(STATUS);
    const row = (status: string | null): Row => ({
      id: 'x',
      name: 'x',
      status
    });
    assert.strictEqual(color(row('late')), 'danger');
    assert.strictEqual(color(row('ok')), 'success');
    assert.strictEqual(color(row('custom')), '#123456', 'a CSS colour');
    assert.strictEqual(color(row('hold')), 'neutral', "EuiBadge's default");
    assert.strictEqual(color(row('plain')), undefined, 'no colour');
    assert.strictEqual(color(row(null)), undefined, 'no value');
    assert.strictEqual(color(row('gone')), undefined, 'not an option');
    const tags = colorByOption<Row>({
      id: 'tags',
      type: 'multiSelect',
      options: (record: Row) =>
        record.id === 'x' ? [{ value: 'a', label: 'A', color: 'warning' }] : []
    });
    assert.strictEqual(
      tags({ id: 'x', name: '', status: null, tags: ['a', 'b'] }),
      'warning',
      'a multi-select: its first value; options from the record'
    );
  });
});
