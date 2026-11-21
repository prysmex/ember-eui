/**
 * The import screen's count messages for one (READINESS.md item 5,
 * IPL1-IPL3), and its value map listing the texts it is applied to,
 * after the column's trim and transform (IVM1-IVM2).
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { click, render, select, settled } from '@ember/test-helpers';

import EuiSheetImport from '#src/components/eui-sheet-import.gts';

import type {
  EuiSheetField,
  SheetImportTransform,
  SheetMessages
} from '#src/core/index.ts';
import type { SheetImportResult } from '#src/types.ts';
import type EuiI18n from '@ember-eui/core/services/eui-i18n';

interface Row {
  id: string;
  [key: string]: unknown;
}

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Nombre' },
  { id: 'price', label: 'Precio', type: 'number' },
  { id: 'active', label: 'Activo', type: 'checkbox' }
];

const SEL = (subj: string) => `[data-test-subj="${subj}"]`;

function q(subj: string, root: ParentNode = document): HTMLElement {
  const found = root.querySelector<HTMLElement>(SEL(subj));
  if (!found) throw new Error(`no ${subj}`);
  return found;
}

const all = (subj: string, root: ParentNode = document) => [
  ...root.querySelectorAll<HTMLElement>(SEL(subj))
];

const row = (index: number) =>
  q(`euiSheetImportColumn"][data-column="${index}`);

const textOf = (element: Element | null | undefined) =>
  (element?.textContent ?? '').replace(/\s+/g, ' ').trim();

/** The texts a screen shows that count something. */
function counts() {
  return {
    lines: textOf(q('euiSheetImportLineCount')),
    caption: textOf(
      document.querySelector(`${SEL('euiSheetImportPreviewTable')} caption`)
    ),
    totals: textOf(q('euiSheetImportTotalsText')),
    submit: textOf(q('euiSheetImportSubmit')),
    status: all('euiSheetImportColumn').map((tr) =>
      textOf(
        tr.querySelector(
          `${SEL('euiSheetImportRead')}, ${SEL('euiSheetImportCantRead')}`
        )
      )
    ),
    values: textOf(
      document.querySelector(
        `${SEL('euiSheetImportColumn')}[data-column="2"] ${SEL('euiSheetImportValuesToggle')}`
      )
    )
  };
}

class Screen {
  @tracked text = 'Nombre,Precio,Activo\r\nAna,1.5,Sí';
  @tracked messages: Partial<SheetMessages> | undefined = undefined;
  @tracked transforms: SheetImportTransform[] | undefined = undefined;
  results: SheetImportResult<Row>[] = [];
  onImport = (result: SheetImportResult<Row>) => {
    this.results.push(result);
  };
  onCancel = () => {};
}

async function renderScreen(screen: Screen): Promise<void> {
  await render(
    <template>
      <EuiSheetImport
        @fields={{FIELDS}}
        @text={{screen.text}}
        @messages={{screen.messages}}
        @transforms={{screen.transforms}}
        @onImport={{screen.onImport}}
        @onCancel={{screen.onCancel}}
      />
    </template>
  );
}

/** `Sí` → `Y`, `No` → `N`: texts no yes/no word matches. */
const YN: SheetImportTransform = {
  id: 'yn',
  label: 'Y/N',
  apply: (text) => (text === 'Sí' ? 'Y' : text === 'No' ? 'N' : text)
};

const LOWER: SheetImportTransform = {
  id: 'lower',
  label: 'Lower case',
  apply: (text) => text.toLowerCase()
};

module(
  'Integration | Component | EuiSheetImport counts and value map',
  function (hooks) {
    setupRenderingTest(hooks);

    test('IPL1 one line: every count message in its form for one', async function (assert) {
      const screen = new Screen();
      await renderScreen(screen);
      assert.deepEqual(counts(), {
        lines: '1 line',
        caption: 'The only line',
        totals: '1 line ready, 0 with errors',
        submit: 'Import 1 line',
        status: ['1 of 1 read', '1 of 1 read', '1 of 1 read'],
        values: 'Values (1 mapped)'
      });
      screen.text = 'Nombre,Precio,Activo\r\nAna,abc,Sí';
      await settled();
      assert.deepEqual(
        [counts().totals, counts().status[1]],
        ['0 lines ready, 1 with errors', '1 can’t be read'],
        'one error'
      );
    });

    test('IPL2 two lines: the plural forms (one of them ready)', async function (assert) {
      const screen = new Screen();
      screen.text = 'Nombre,Precio,Activo\r\nAna,1.5,Sí\r\nBo,x,No';
      await renderScreen(screen);
      assert.deepEqual(counts(), {
        lines: '2 lines',
        caption: 'The first 2 of 2 lines',
        totals: '1 line ready, 1 with errors',
        submit: 'Import 2 lines',
        status: ['2 of 2 read', '1 can’t be read', '2 of 2 read'],
        values: 'Values (2 mapped)'
      });
    });

    test('IPL3 an owner who gave only the plural keeps it for one; both: the singular', async function (assert) {
      const screen = new Screen();
      screen.messages = {
        importLines: (n) => `Importar ${n} líneas`,
        importLineCount: (n) => `${n} líneas`
      };
      await renderScreen(screen);
      assert.strictEqual(counts().submit, 'Importar 1 líneas', '@messages');
      assert.strictEqual(counts().lines, '1 líneas');
      screen.messages = {
        importLines: (n) => `Importar ${n} líneas`,
        importLinesOne: (n) => `Importar ${n} línea`
      };
      await settled();
      assert.strictEqual(counts().submit, 'Importar 1 línea');
      assert.strictEqual(counts().lines, '1 line', 'the default singular');
      // eui-i18n: translations are set before the screen renders
      const i18n = this.owner.lookup('service:eui-i18n') as EuiI18n;
      i18n.addTranslations({
        euiSheet: { importLinesReady: '{n} líneas listas' }
      });
      const plain = new Screen();
      await renderScreen(plain);
      assert.strictEqual(
        counts().totals,
        '1 líneas listas, 0 with errors',
        'a translation of the plural only'
      );
      i18n.addTranslations({
        euiSheet: { importLinesReadyOne: '{n} línea lista' }
      });
      await renderScreen(new Screen());
      assert.strictEqual(
        counts().totals,
        '1 línea lista, 0 with errors',
        'and of both'
      );
    });

    test('IVM1 the value map lists the texts after the transform, and applies to them', async function (assert) {
      const screen = new Screen();
      screen.text = 'Nombre,Precio,Activo\r\nAna,1,Sí\r\nBo,2,No\r\nCaro,3,Sí';
      screen.transforms = [YN, LOWER];
      await renderScreen(screen);
      await click(q('euiSheetImportValuesToggle', row(2)));
      const listed = () =>
        all('euiSheetImportValueRow').map((tr) =>
          textOf(tr.querySelector('th'))
        );
      assert.deepEqual(
        listed(),
        ['Sí', 'No'],
        'no transform: the file’s texts'
      );
      await select(q('euiSheetImportTransform', row(2)), 'yn');
      assert.deepEqual(listed(), ['Y', 'N'], 'the transformed texts');
      const choices = all('euiSheetImportValue');
      await select(choices[0]!, 'true');
      await select(choices[1]!, 'false');
      await settled();
      assert.strictEqual(
        textOf(q('euiSheetImportTotalsText')),
        '3 lines ready, 0 with errors',
        'every line reads'
      );
      await click(q('euiSheetImportSubmit'));
      const [result] = screen.results;
      assert.deepEqual(
        result!.values.map((values) => values[2]),
        [true, false, true],
        'Y and N became checked and unchecked'
      );
    });

    test('IVM2 a transform change keeps the choices and prefills the new texts', async function (assert) {
      const screen = new Screen();
      screen.text = 'Nombre,Precio,Activo\r\nAna,1,SÍ\r\nBo,2,NO';
      screen.transforms = [LOWER];
      await renderScreen(screen);
      await click(q('euiSheetImportValuesToggle', row(2)));
      const listed = () =>
        all('euiSheetImportValueRow').map((tr) =>
          textOf(tr.querySelector('th'))
        );
      const chosen = () =>
        all('euiSheetImportValue').map(
          (element) => (element as HTMLSelectElement).value
        );
      assert.deepEqual(listed(), ['SÍ', 'NO']);
      assert.deepEqual(chosen(), ['true', 'false'], 'prefilled (case ignored)');
      // the user turns SÍ into unchecked
      await select(all('euiSheetImportValue')[0]!, 'false');
      await select(q('euiSheetImportTransform', row(2)), 'lower');
      assert.deepEqual(listed(), ['sí', 'no'], 'the lower-case texts');
      assert.deepEqual(chosen(), ['true', 'false'], 'the new texts prefilled');
      await select(q('euiSheetImportTransform', row(2)), '');
      assert.deepEqual(listed(), ['SÍ', 'NO']);
      assert.deepEqual(
        chosen(),
        ['false', 'false'],
        'back to the file’s texts: the user’s choice is still there'
      );
    });
  }
);
