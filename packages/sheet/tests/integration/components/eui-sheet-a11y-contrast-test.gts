/**
 * Contrast (READINESS.md item 3, WCAG 1.4.3 and 1.4.11), measured on the
 * rendered sheet in light and dark: an invalid cell's text on the range
 * tint, a rating's empty stars on a plain and a selected cell, and one
 * hover tint on a hovered row (not the grid's row tint under the cells').
 * The colours are the computed ones, composited over `--euiSheet-plain`.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import { cell, el, focusCell, press } from '../../helpers/sheet.ts';

import type { EuiSheetField } from '#src/core/index.ts';
import type EuiEmotionService from '@ember-eui/core/services/eui-emotion';
import type Owner from '@ember/owner';

interface Row {
  id: string;
  code: string;
  stars: number | null;
}

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'code', label: 'Code', pattern: /^A-\d$/ },
  { id: 'stars', label: 'Stars', type: 'rating' }
];
const rows = (): Row[] => [
  { id: 'r0', code: 'bad', stars: 1 },
  { id: 'r1', code: 'A-1', stars: 2 }
];
const getId = (row: Row) => row.id;

type Rgba = [number, number, number, number];

function parse(color: string): Rgba {
  const parts = /rgba?\(([^)]+)\)/.exec(color)?.[1]?.split(/[\s,/]+/);
  if (!parts) throw new Error(`not a colour: ${color}`);
  const [r, g, b, a] = parts.filter(Boolean).map(Number);
  return [r!, g!, b!, a ?? 1];
}

/** `top` over an opaque `bottom`. */
function over(top: Rgba, bottom: Rgba): Rgba {
  const a = top[3];
  return [0, 1, 2]
    .map((i) => top[i]! * a + bottom[i]! * (1 - a))
    .concat(1) as Rgba;
}

function luminance([r, g, b]: Rgba): number {
  const f = (v: number) => {
    v /= 255;
    return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
  };
  return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b);
}

function ratio(a: Rgba, b: Rgba): number {
  const [x, y] = [luminance(a), luminance(b)];
  return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05);
}

/** A colour as the browser computes it (a custom property resolved by a probe). */
function resolve(value: string, root: Element): Rgba {
  const probe = document.createElement('span');
  probe.style.color = value;
  root.appendChild(probe);
  const color = getComputedStyle(probe).color;
  probe.remove();
  return parse(color);
}

module(
  'Integration | Component | EuiSheet accessibility: contrast',
  function (hooks) {
    setupRenderingTest(hooks);

    async function renderSheet(owner: Owner, mode: 'light' | 'dark') {
      const emotion = owner.lookup('service:eui-emotion') as EuiEmotionService;
      emotion.colorMode = mode;
      const store = localRecords(rows(), { getRecordId: getId });
      await render(
        <template>
          <div style="width:500px">
            <EuiSheet
              @records={{store.records}}
              @fields={{FIELDS}}
              @getRecordId={{getId}}
              @onChange={{store.apply}}
            />
          </div>
        </template>
      );
      const wrapper = el('[data-test-subj=euiSheet]');
      const plain = resolve('var(--euiSheet-plain)', wrapper);
      return { wrapper, plain };
    }

    hooks.afterEach(function () {
      (
        this.owner.lookup('service:eui-emotion') as EuiEmotionService
      ).colorMode = 'light';
    });

    for (const mode of ['light', 'dark'] as const) {
      test(`C1 ${mode}: an invalid cell's text on the range tint is 4.5:1 or more`, async function (assert) {
        const { plain } = await renderSheet(this.owner, mode);
        // the range from the valid cell below: the invalid one is tinted, not the active cell
        await focusCell(1, 0);
        await press('ArrowUp', { shiftKey: true });
        const invalid = cell(0, 0);
        assert.dom(invalid).hasClass('euiSheet__cell--invalid');
        assert.dom(invalid).hasClass('euiSheet__cell--selected');
        const bg = over(
          parse(getComputedStyle(invalid).backgroundColor),
          plain
        );
        const fg = over(parse(getComputedStyle(invalid).color), bg);
        const value = ratio(fg, bg);
        assert.true(value >= 4.5, `${value.toFixed(2)}:1`);
      });

      test(`C2 ${mode}: a rating's empty stars are 3:1 or more, on a plain and a selected cell`, async function (assert) {
        const { plain } = await renderSheet(this.owner, mode);
        const off = (row: number) =>
          el('.euiSheet__star:not(.euiSheet__star--on)', cell(row, 1));
        const starOn = (star: HTMLElement, bg: Rgba) => {
          const style = getComputedStyle(star);
          const color = parse(style.color);
          color[3] *= Number(style.opacity);
          return ratio(over(color, bg), bg);
        };
        const onPlain = starOn(off(1), plain);
        assert.true(onPlain >= 3, `plain: ${onPlain.toFixed(2)}:1`);
        await focusCell(1, 1);
        await press('ArrowUp', { shiftKey: true });
        const selectedBg = over(
          parse(getComputedStyle(cell(1, 1)).backgroundColor),
          plain
        );
        assert.dom(cell(1, 1)).hasClass('euiSheet__cell--selected');
        const onSelected = starOn(off(1), selectedBg);
        assert.true(onSelected >= 3, `selected: ${onSelected.toFixed(2)}:1`);
      });
    }

    test('C3 a hovered row keeps its plain background: the cells draw the one hover tint', async function (assert) {
      await renderSheet(this.owner, 'dark');
      const rules = [...document.styleSheets].flatMap((sheet) => {
        try {
          return [...sheet.cssRules];
        } catch {
          return [];
        }
      }) as CSSStyleRule[];
      const rule = rules.find(
        (r) => r.selectorText === '.euiSheet .euiDataGridRow:hover'
      );
      assert.ok(rule, 'the sheet sets the hovered row');
      assert.strictEqual(
        rule?.style.backgroundColor,
        'var(--euiSheet-plain, #FFF)',
        'to the plain background'
      );
    });
  }
);
