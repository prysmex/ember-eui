/**
 * The import screen opens before its first dry run (READINESS.md item 5:
 * 377-446 ms on 10,000 lines x 20 columns, 300 ms wanted), IDR1-IDR2:
 * the preview and the columns come first; the totals, each column's
 * status and the share in its badge after the frame that shows them.
 * `requestAnimationFrame` is held here, so "after the frame" is when the
 * test lets it run.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { click, render, rerender, settled } from '@ember/test-helpers';

import EuiSheetImport from '#src/components/eui-sheet-import.gts';

import type { EuiSheetField } from '#src/core/index.ts';
import type { SheetImportResult } from '#src/types.ts';

interface Row {
  id: string;
  [key: string]: unknown;
}

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Nombre' },
  { id: 'price', label: 'Precio', type: 'number' }
];

const SEL = (subj: string) => `[data-test-subj="${subj}"]`;

const textOf = (element: Element | null | undefined) =>
  (element?.textContent ?? '').replace(/\s+/g, ' ').trim();

const all = (subj: string) => [
  ...document.querySelectorAll<HTMLElement>(SEL(subj))
];

const csv = (lines: number, bad = 0) =>
  [
    'Nombre,Precio',
    ...Array.from(
      { length: lines },
      (_, i) => `P${i},${i < bad ? 'x' : String(i)}`
    )
  ].join('\r\n');

class Screen {
  @tracked text = csv(5, 2);
  results: SheetImportResult<Row>[] = [];
  onImport = (result: SheetImportResult<Row>) => {
    this.results.push(result);
  };
  onCancel = () => {};
}

/** Holds `requestAnimationFrame`'s callbacks until `release`. */
function holdFrames() {
  const original = window.requestAnimationFrame;
  const held: FrameRequestCallback[] = [];
  window.requestAnimationFrame = (callback) => {
    held.push(callback);
    return held.length;
  };
  return {
    get count() {
      return held.length;
    },
    release() {
      window.requestAnimationFrame = original;
      for (const callback of held.splice(0)) callback(performance.now());
    },
    restore() {
      window.requestAnimationFrame = original;
    }
  };
}

const view = () => ({
  totals: textOf(document.querySelector(SEL('euiSheetImportTotalsText'))),
  statuses: all('euiSheetImportColumn').map((tr) =>
    textOf(
      tr.querySelector(
        `${SEL('euiSheetImportRead')}, ${SEL('euiSheetImportCantRead')}`
      )
    )
  ),
  badges: all('euiSheetImportColumn').map((tr) =>
    textOf(tr.querySelector(SEL('euiSheetImportGuess')))
  ),
  previewRows: all('euiSheetImportPreviewRow').length,
  submit: textOf(document.querySelector(SEL('euiSheetImportSubmit')))
});

module(
  'Integration | Component | EuiSheetImport first dry run',
  function (hooks) {
    setupRenderingTest(hooks);

    test('IDR1 the preview and the columns first; the counts after the frame', async function (assert) {
      const screen = new Screen();
      const frames = holdFrames();
      try {
        const rendered = render(
          <template>
            <EuiSheetImport
              @fields={{FIELDS}}
              @text={{screen.text}}
              @onImport={{screen.onImport}}
              @onCancel={{screen.onCancel}}
            />
          </template>
        );
        await rerender();
        assert.deepEqual(
          view(),
          {
            totals: 'Checking the lines…',
            statuses: ['', ''],
            badges: ['Single line text', 'Number'],
            previewRows: 5,
            submit: 'Import 5 lines'
          },
          'the first render: no dry run yet'
        );
        assert.true(frames.count > 0, 'it waits for a frame');
        frames.release();
        await rendered;
        await settled();
        assert.deepEqual(view(), {
          totals: '3 lines ready, 2 with errors',
          statuses: ['5 of 5 read', '2 can’t be read'],
          badges: ['Single line text · 100%', 'Number · 60%'],
          previewRows: 5,
          submit: 'Import 5 lines'
        });
      } finally {
        frames.restore();
      }
    });

    test('IDR2 a new source waits for its own run; the last one’s counts are not shown', async function (assert) {
      const screen = new Screen();
      await render(
        <template>
          <EuiSheetImport
            @fields={{FIELDS}}
            @text={{screen.text}}
            @onImport={{screen.onImport}}
            @onCancel={{screen.onCancel}}
          />
        </template>
      );
      assert.strictEqual(view().totals, '3 lines ready, 2 with errors');
      const frames = holdFrames();
      try {
        screen.text = csv(3);
        await rerender();
        assert.strictEqual(view().totals, 'Checking the lines…');
        assert.strictEqual(view().submit, 'Import 3 lines');
        frames.release();
        await settled();
        assert.strictEqual(view().totals, '3 lines ready, 0 with errors');
        assert.deepEqual(view().statuses, ['3 of 3 read', '3 of 3 read']);
      } finally {
        frames.restore();
      }
    });

    test('IDR3 Import while the first run waits: the import reads every line itself', async function (assert) {
      const screen = new Screen();
      const frames = holdFrames();
      try {
        const rendered = render(
          <template>
            <EuiSheetImport
              @fields={{FIELDS}}
              @text={{screen.text}}
              @onImport={{screen.onImport}}
              @onCancel={{screen.onCancel}}
            />
          </template>
        );
        await rerender();
        assert.strictEqual(view().totals, 'Checking the lines…');
        const clicked = click(SEL('euiSheetImportSubmit'));
        frames.release();
        await clicked;
        await rendered;
        await settled();
        assert.strictEqual(screen.results.length, 1, '@onImport called once');
        const [result] = screen.results;
        assert.deepEqual(result!.lines, [1, 2, 3, 4, 5], 'every line');
        assert.deepEqual(result!.fieldIds, ['name', 'price']);
        assert.deepEqual(
          result!.values.map((values) => values[1]),
          [undefined, undefined, 2, 3, 4],
          'the two unreadable prices, as without the wait'
        );
      } finally {
        frames.restore();
      }
    });

    test('IDR4 removed while the first run waits: no run, no error, the test waiter ends', async function (assert) {
      const screen = new Screen();
      class Shown {
        @tracked on = true;
      }
      const shown = new Shown();
      const frames = holdFrames();
      try {
        const rendered = render(
          <template>
            {{#if shown.on}}
              <EuiSheetImport
                @fields={{FIELDS}}
                @text={{screen.text}}
                @onImport={{screen.onImport}}
                @onCancel={{screen.onCancel}}
              />
            {{/if}}
          </template>
        );
        await rerender();
        assert.strictEqual(view().totals, 'Checking the lines…');
        shown.on = false;
        await rerender();
        assert.dom(SEL('euiSheetImport')).doesNotExist();
        // the frame it asked for comes after it is gone
        frames.release();
        await rendered;
        await settled();
        assert.dom(SEL('euiSheetImportTotalsText')).doesNotExist();
        assert.strictEqual(screen.results.length, 0);
      } finally {
        frames.restore();
      }
    });
  }
);
