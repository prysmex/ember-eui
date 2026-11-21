/**
 * The import screen `<EuiSheetImport>` (v0.4 10, stage 2), IW1-IW13: the
 * columns proposed and guessed, the preview and the dry run, new fields,
 * errors, saved mappings, rejections, the end-to-end path with a sheet,
 * keyboard reachability, per-column field copies (decision 14), and a
 * windows-1252 file, a blank column and a change of `@transforms`
 * (IW12). The prefix IW was unused (`grep -rnoE '\bIW[0-9]+'`).
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import {
  click,
  fillIn,
  render,
  rerender,
  select,
  settled,
  triggerKeyEvent
} from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import EuiSheetImport from '#src/components/eui-sheet-import.gts';
import {
  applyChangeSet,
  defaultMessages,
  importSignature
} from '#src/core/index.ts';
import { focusCell, pressed } from '../../helpers/sheet.ts';

import type {
  ChangeSet,
  EuiSheetField,
  SheetImportFieldDraft,
  SheetImportMapping,
  SheetImportTransform
} from '#src/core/index.ts';
import type { SheetApi, SheetImportResult } from '#src/types.ts';

/* -------------------------------------------------------------------- */
/* Data                                                                  */
/* -------------------------------------------------------------------- */

interface Row {
  id: string;
  [key: string]: unknown;
}

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name of product', importAliases: ['nombre'] },
  { id: 'price', label: 'Precio', type: 'number' },
  { id: 'due', label: 'Fecha', type: 'date' },
  { id: 'active', label: 'Active', type: 'checkbox' },
  { id: 'notes', label: 'Notes' }
];

const pad = (n: number) => String(n).padStart(2, '0');

/** `Nombre,Precio,Fecha,Activo`, 25 lines: day `i` of November, `Sí` on odd lines. */
function csv(lines = 25, extra?: (i: number) => string[]): string {
  const out = ['Nombre,Precio,Fecha,Activo'];
  for (let i = 1; i <= lines; i++) {
    out.push(
      [
        `Producto ${i}`,
        `${i}.5`,
        `${pad(i)}/11/2026`,
        i % 2 ? 'Sí' : 'No',
        ...(extra?.(i) ?? [])
      ].join(',')
    );
  }
  return out.join('\r\n');
}

const CENTS: SheetImportTransform = {
  id: 'cents',
  label: 'Cents to amount',
  apply: (text) => (text === '' ? null : String(Number(text) / 100))
};

const UPPER: SheetImportTransform = {
  id: 'upper',
  label: 'Upper case',
  apply: (text) => text.toUpperCase()
};

const BOOM: SheetImportTransform = {
  id: 'boom',
  label: 'Throws',
  apply: () => {
    throw new Error('no way');
  }
};

/* -------------------------------------------------------------------- */
/* Helpers                                                               */
/* -------------------------------------------------------------------- */

const SEL = (subj: string) => `[data-test-subj="${subj}"]`;

function q<E extends Element = HTMLElement>(
  subj: string,
  root: ParentNode = document
): E {
  const found = root.querySelector<E>(SEL(subj));
  if (!found) throw new Error(`no ${subj}`);
  return found;
}

function all(subj: string, root: ParentNode = document): HTMLElement[] {
  return [...root.querySelectorAll<HTMLElement>(SEL(subj))];
}

function row(index: number): HTMLElement {
  return q(`euiSheetImportColumn"][data-column="${index}`);
}

const textOf = (element: Element | null | undefined) =>
  (element?.textContent ?? '').replace(/\s+/g, ' ').trim();

const targets = () =>
  all('euiSheetImportColumn').map((tr) => tr.dataset['target']);

const badges = () =>
  all('euiSheetImportColumn').map((tr) =>
    textOf(tr.querySelector(SEL('euiSheetImportGuess')))
  );

const previewHeaders = () =>
  all('euiSheetImportPreviewHeader').map((th) => textOf(th));

const previewRows = () =>
  all('euiSheetImportPreviewRow').map((tr) =>
    [...tr.querySelectorAll('td')].slice(1).map((td) => textOf(td))
  );

const totals = () => textOf(q('euiSheetImportTotalsText'));

const submitText = () => textOf(q('euiSheetImportSubmit'));

async function setTarget(index: number, value: string): Promise<void> {
  await select(q('euiSheetImportTarget', row(index)), value);
}

function optionValues(selectEl: HTMLElement): string[] {
  return [...(selectEl as HTMLSelectElement).options].map((o) => o.value);
}

/** The screen's arguments, tracked so a test can change them. */
class Screen {
  @tracked fields: EuiSheetField<Row>[] = FIELDS;
  @tracked text: string | null = csv();
  @tracked file: File | null = null;
  @tracked transforms: SheetImportTransform[] | undefined = undefined;
  @tracked savedMapping: SheetImportMapping | null = null;
  @tracked creates = false;
  results: SheetImportResult<Row>[] = [];
  drafts: SheetImportFieldDraft[][] = [];
  /** What `@onCreateFields` does with the drafts. */
  create: (drafts: SheetImportFieldDraft[]) => Promise<EuiSheetField<Row>[]> = (
    drafts
  ) =>
    Promise.resolve(
      drafts.map((draft) => ({
        ...draft,
        id: draft.label.toLowerCase().replace(/\W+/g, '-')
      }))
    );
  onImportImpl: (result: SheetImportResult<Row>) => unknown = () => undefined;

  onCreateFields = (drafts: SheetImportFieldDraft[]) => {
    this.drafts.push(drafts);
    return this.create(drafts);
  };

  cancels = 0;
  onCancel = () => {
    this.cancels++;
  };

  onImport = (result: SheetImportResult<Row>) => {
    this.results.push(result);
    return this.onImportImpl(result) as Promise<unknown> | undefined;
  };

  get createFields() {
    return this.creates ? this.onCreateFields : undefined;
  }
}

async function renderScreen(screen: Screen): Promise<void> {
  await render(
    <template>
      <EuiSheetImport
        @fields={{screen.fields}}
        @text={{screen.text}}
        @file={{screen.file}}
        @transforms={{screen.transforms}}
        @savedMapping={{screen.savedMapping}}
        @onCreateFields={{screen.createFields}}
        @onImport={{screen.onImport}}
        @onCancel={{screen.onCancel}}
      />
    </template>
  );
}

/** An owner for a sheet next to the screen: `applyChangeSet` in `@onChange`. */
class SheetOwner {
  @tracked fields: EuiSheetField<Row>[] = FIELDS;
  @tracked records: Row[] = [{ id: 'r0', name: 'Ana' }];
  log: ChangeSet[] = [];
  api: SheetApi | null = null;
  register = (api: SheetApi) => (this.api = api);
  onChange = (changeSet: ChangeSet): void => {
    this.log.push(changeSet);
    this.records = applyChangeSet(this.records, changeSet, {
      getRecordId: (r: Row) => r.id,
      createRecord: (values, tempId) => ({ id: tempId, ...values }) as Row
    });
  };
}

const getId = (record: Row) => record.id;

module('Integration | Component | EuiSheetImport', function (hooks) {
  setupRenderingTest(hooks);

  test('IW1 the columns are mapped by alias and label, the guesses shown, the preview has 20 lines', async function (assert) {
    const screen = new Screen();
    await renderScreen(screen);
    assert.deepEqual(
      all('euiSheetImportHeader').map(textOf),
      ['Nombre', 'Precio', 'Fecha', 'Activo'],
      'one row per file column'
    );
    assert.deepEqual(
      targets(),
      ['f:name', 'f:price', 'f:due', 'skip'],
      'Nombre by its alias, Precio and Fecha by label; Activo matches none (no @onCreateFields: skipped)'
    );
    assert.deepEqual(
      badges(),
      [
        'Single line text · 100%',
        'Number · 100%',
        'Date, D/M/Y · 100%',
        'Checkbox · 100%'
      ],
      'what each target reads; the guess for the skipped column'
    );
    assert.deepEqual(
      all('euiSheetImportSample', row(2)).map(textOf),
      ['01/11/2026', '02/11/2026', '03/11/2026'],
      'three sample texts'
    );
    assert.deepEqual(
      all('euiSheetImportRead').map(textOf),
      ['25 of 25 read', '25 of 25 read', '25 of 25 read'],
      'the status of each mapped column'
    );
    assert.strictEqual(textOf(q('euiSheetImportLineCount')), '25 lines');
    assert.deepEqual(previewHeaders(), ['Name of product', 'Precio', 'Fecha']);
    const lines = previewRows();
    assert.strictEqual(lines.length, 20, 'the preview has @sampleSize lines');
    assert.deepEqual(lines[0], ['Producto 1', '1.5', '01/11/2026']);
    assert.deepEqual(lines[19], ['Producto 20', '20.5', '20/11/2026']);
    assert.strictEqual(totals(), '25 lines ready, 0 with errors');
    assert.strictEqual(submitText(), 'Import 25 lines');
    assert.dom(SEL('euiSheetImportDownloadErrors')).doesNotExist();
    assert.dom(SEL('euiSheetImportDelimiter')).hasValue(',');
    assert.dom(SEL('euiSheetImportTransform')).doesNotExist();
    await click(SEL('euiSheetImportCancel'));
    assert.strictEqual(screen.cancels, 1, 'Cancel calls @onCancel');
    assert.strictEqual(screen.results.length, 0);
  });

  test('IW2 a target, a transform and the date order update the preview at once and the totals after the debounce', async function (assert) {
    const screen = new Screen();
    screen.transforms = [CENTS, UPPER];
    await renderScreen(screen);

    await setTarget(3, 'f:active');
    assert.deepEqual(previewHeaders(), [
      'Name of product',
      'Precio',
      'Fecha',
      'Active'
    ]);
    assert.deepEqual(previewRows()[0], [
      'Producto 1',
      '1.5',
      '01/11/2026',
      'true'
    ]);
    assert.deepEqual(previewRows()[1]!.slice(3), ['false']);
    assert.strictEqual(
      textOf(q('euiSheetImportValuesToggle', row(3))),
      'Values (2 mapped)',
      'the value map was prefilled (Sí, No)'
    );

    await select(q('euiSheetImportTransform', row(0)), 'upper');
    await select(q('euiSheetImportTransform', row(1)), 'cents');
    assert.deepEqual(previewRows()[0]!.slice(0, 2), ['PRODUCTO 1', '0.015']);

    // the date order: the preview at once, the totals 250 ms later
    const order = q<HTMLSelectElement>('euiSheetImportDateOrder', row(2));
    order.value = 'mdy';
    order.dispatchEvent(new Event('change', { bubbles: true }));
    await rerender();
    assert.deepEqual(
      previewRows()[0]!.slice(2, 3),
      ['11/01/2026'],
      '01/11/2026 reads as January 11, shown as the D/M/Y field shows it'
    );
    assert.strictEqual(
      all('euiSheetImportPreviewCell', all('euiSheetImportPreviewRow')[12])[2]!
        .dataset['state'],
      'error',
      '13/11/2026 is not M/D/Y'
    );
    assert.strictEqual(
      totals(),
      '25 lines ready, 0 with errors',
      'the dry run waits (debounced)'
    );
    await settled();
    assert.strictEqual(totals(), '12 lines ready, 13 with errors');
    assert.strictEqual(
      textOf(q('euiSheetImportCantRead', row(2))),
      '13 can’t be read'
    );
    assert.strictEqual(
      textOf(q('euiSheetImportGuess', row(2))),
      'Date, M/D/Y · 48%',
      'the badge: how much the M/D/Y copy reads'
    );
    assert.strictEqual(submitText(), 'Import 25 lines');

    // "can't be read" filters the preview to those lines
    await click(q('euiSheetImportCantRead', row(2)));
    assert.strictEqual(previewRows().length, 13);
    assert.deepEqual(
      all('euiSheetImportPreviewRow').map((tr) =>
        textOf(tr.querySelector('td'))
      ),
      Array.from({ length: 13 }, (_, k) => String(k + 14)),
      'the lines of days 13-25 (file lines 14-26)'
    );
    await click(q('euiSheetImportShowFirst'));
    assert.strictEqual(previewRows().length, 20);

    // a field takes one column: shown taken and disabled in the others
    const taken = [
      ...q<HTMLSelectElement>('euiSheetImportTarget', row(3)).options
    ].find((o) => o.value === 'f:name')!;
    assert.strictEqual(
      taken.text.trim(),
      'Name of product (in use by "Nombre")'
    );
    assert.true(taken.disabled, 'disabled for the other columns');
    const own = [
      ...q<HTMLSelectElement>('euiSheetImportTarget', row(0)).options
    ].find((o) => o.value === 'f:name')!;
    assert.false(own.disabled, 'not for its own column');
    await setTarget(0, 'skip');
    await setTarget(3, 'f:name');
    assert.deepEqual(
      targets(),
      ['skip', 'f:price', 'f:due', 'f:name'],
      'freed, then taken'
    );
    assert.true(
      [...q<HTMLSelectElement>('euiSheetImportTarget', row(0)).options].find(
        (o) => o.value === 'f:name'
      )!.disabled,
      'now taken by Activo'
    );
  });

  test('IW3 a new field: nothing is created before Import; then @onCreateFields once, and @onImport with its id', async function (assert) {
    const screen = new Screen();
    screen.creates = true;
    await renderScreen(screen);
    assert.deepEqual(
      targets(),
      ['f:name', 'f:price', 'f:due', 'new'],
      'an unmatched column goes to a new field'
    );
    assert.strictEqual(
      textOf(q('euiSheetImportNewFieldText', row(3))),
      'New field: Activo (Checkbox)'
    );
    assert.deepEqual(previewHeaders(), [
      'Name of product',
      'Precio',
      'Fecha',
      'Activo new'
    ]);
    assert.true(
      optionValues(q('euiSheetImportTarget', row(0))).includes('new'),
      '"New field…" is offered'
    );

    // the form: the field editor's content
    await click(q('euiSheetImportEditNewField', row(3)));
    assert.dom(SEL('euiSheetImportNewFieldForm')).exists();
    assert.dom(SEL('euiSheetFieldName')).hasValue('Activo');
    assert.dom(SEL('euiSheetFieldType')).hasValue('checkbox');
    assert.strictEqual(
      document.activeElement,
      q('euiSheetFieldName'),
      'its name has focus'
    );
    await fillIn(SEL('euiSheetFieldName'), 'Activo sí/no');
    await click(SEL('euiSheetFieldSave'));
    assert.dom(SEL('euiSheetImportNewFieldForm')).doesNotExist();
    assert.strictEqual(
      textOf(q('euiSheetImportNewFieldText', row(3))),
      'New field: Activo sí/no (Checkbox)'
    );
    assert.strictEqual(
      document.activeElement,
      q('euiSheetImportEditNewField', row(3)),
      'focus back on its button'
    );
    assert.strictEqual(screen.drafts.length, 0, 'nothing created yet');

    await click(SEL('euiSheetImportSubmit'));
    assert.deepEqual(screen.drafts, [
      [{ label: 'Activo sí/no', type: 'checkbox' }]
    ]);
    assert.strictEqual(screen.results.length, 1);
    const result = screen.results[0]!;
    assert.deepEqual(result.fieldIds, ['name', 'price', 'due', 'activo-s-no']);
    assert.deepEqual(result.createdFields, [
      { label: 'Activo sí/no', type: 'checkbox', id: 'activo-s-no' }
    ]);
    assert.deepEqual(result.rows[0], [
      'Producto 1',
      '1.5',
      '01/11/2026',
      'true'
    ]);
    assert.deepEqual(result.rows[1]![3], 'false');
    assert.deepEqual(result.fields[3], result.createdFields[0]);
    assert.deepEqual(result.values[0], ['Producto 1', 1.5, '2026-11-01', true]);
    assert.strictEqual(result.rows.length, 25);
    assert.deepEqual(
      result.lines.slice(0, 3),
      [1, 2, 3],
      "each row's line in the file"
    );
    assert.deepEqual(
      targets()[3],
      'f:activo-s-no',
      'the column now goes to it'
    );
  });

  test('IW4 without @onCreateFields "New field…" is not offered', async function (assert) {
    const screen = new Screen();
    await renderScreen(screen);
    for (const selectEl of all('euiSheetImportTarget')) {
      assert.deepEqual(
        optionValues(selectEl),
        ['f:name', 'f:price', 'f:due', 'f:active', 'f:notes', 'skip'],
        'fields and Skip only'
      );
    }
    assert.dom(SEL('euiSheetImportEditNewField')).doesNotExist();
    // a saved mapping's new field becomes Skip without the handler
    screen.savedMapping = {
      signature: importSignature(['Nombre', 'Precio', 'Fecha', 'Activo']),
      columns: [
        {
          index: 3,
          header: 'Activo',
          target: { newField: { label: 'Activo', type: 'checkbox' } }
        }
      ]
    };
    await settled();
    assert.strictEqual(targets()[3], 'skip');
  });

  test('IW5 "Skip lines with errors" leaves them out and lists them; "Import all" keeps them; the error lines download', async function (assert) {
    const screen = new Screen();
    screen.text = csv(25).replace('3.5', 'abc').replace('7.5', 'xyz');
    await renderScreen(screen);
    assert.strictEqual(totals(), '23 lines ready, 2 with errors');
    assert.strictEqual(
      textOf(q('euiSheetImportCantRead', row(1))),
      '2 can’t be read'
    );
    const cell = all(
      'euiSheetImportPreviewCell',
      all('euiSheetImportPreviewRow')[2]
    )[1]!;
    assert.strictEqual(cell.dataset['state'], 'error');
    assert.strictEqual(
      textOf(cell),
      `abc ${defaultMessages.notANumber('abc')}`,
      'the text and the type message'
    );

    // the download: a Blob with the header line and the two lines
    const blobs: Blob[] = [];
    const names: string[] = [];
    const create = URL.createObjectURL.bind(URL);
    const clickLink = HTMLAnchorElement.prototype.click;
    URL.createObjectURL = (blob: Blob) => {
      blobs.push(blob);
      return create(blob);
    };
    HTMLAnchorElement.prototype.click = function (this: HTMLAnchorElement) {
      names.push(this.download);
    };
    try {
      await click(SEL('euiSheetImportDownloadErrors'));
    } finally {
      URL.createObjectURL = create;
      HTMLAnchorElement.prototype.click = clickLink;
    }
    assert.strictEqual(blobs.length, 1);
    assert.deepEqual(names, ['import-errors.csv']);
    const bytes = new Uint8Array(await blobs[0]!.arrayBuffer());
    assert.deepEqual([...bytes.slice(0, 3)], [0xef, 0xbb, 0xbf], 'a UTF-8 BOM');
    assert.strictEqual(
      new TextDecoder().decode(bytes),
      'Nombre,Precio,Fecha,Activo\r\nProducto 3,abc,03/11/2026,Sí\r\nProducto 7,xyz,07/11/2026,Sí',
      'the header line and the two lines, as in the file'
    );

    assert.strictEqual(submitText(), 'Import 25 lines', '"Import all" first');
    await click(q('euiSheetImportErrorChoice').querySelectorAll('input')[1]!);
    assert.strictEqual(submitText(), 'Import 23 lines');
    await click(SEL('euiSheetImportSubmit'));
    const skipped = screen.results[0]!;
    assert.strictEqual(skipped.rows.length, 23);
    assert.deepEqual(skipped.skippedLines, [3, 7]);
    assert.false(skipped.lines.includes(3));

    await click(q('euiSheetImportErrorChoice').querySelectorAll('input')[0]!);
    await click(SEL('euiSheetImportSubmit'));
    const kept = screen.results[1]!;
    assert.strictEqual(kept.rows.length, 25);
    assert.deepEqual(kept.skippedLines, []);
    assert.deepEqual(
      kept.rows[2]![1],
      'abc',
      'the text stays, for a rejection'
    );

    // a transform that throws writes '' (decision 15)
    screen.transforms = [BOOM];
    await settled();
    await select(q('euiSheetImportTransform', row(0)), 'boom');
    await click(SEL('euiSheetImportSubmit'));
    assert.deepEqual(
      screen.results[2]!.rows[0]![0],
      '',
      'a cell whose transform threw is empty'
    );
  });

  test('IW6 a saved mapping with the same header line wins over aliases; result.mapping round-trips', async function (assert) {
    const screen = new Screen();
    screen.transforms = [UPPER];
    const headers = ['Nombre', 'Precio', 'Fecha', 'Activo'];
    screen.savedMapping = {
      signature: importSignature(headers),
      columns: [
        {
          index: 0,
          header: 'Nombre',
          target: { field: 'notes' },
          transform: 'upper',
          trim: false
        },
        { index: 3, header: 'Activo', target: { field: 'active' } }
      ]
    };
    await renderScreen(screen);
    assert.deepEqual(
      targets(),
      ['f:notes', 'f:price', 'f:due', 'f:active'],
      'the saved targets, over the alias of Nombre'
    );
    assert.dom(q('euiSheetImportTransform', row(0))).hasValue('upper');
    assert
      .dom(q('euiSheetImportTrim', row(0)))
      .hasAttribute('aria-checked', 'false');
    await click(SEL('euiSheetImportSubmit'));
    const first = screen.results[0]!;
    assert.deepEqual(first.fieldIds, ['notes', 'price', 'due', 'active']);
    assert.strictEqual(first.rows[0]![0], 'PRODUCTO 1');
    assert.strictEqual(first.mapping!.signature, importSignature(headers));
    assert.deepEqual(first.mapping!.columns[0], {
      index: 0,
      header: 'Nombre',
      target: { field: 'notes' },
      transform: 'upper',
      trim: false
    });
    assert.deepEqual(first.mapping!.columns[3], {
      index: 3,
      header: 'Activo',
      target: { field: 'active' },
      valueMap: { Sí: true, No: false }
    });

    // passed back, the same plan and the same mapping
    screen.savedMapping = first.mapping;
    await settled();
    await click(SEL('euiSheetImportSubmit'));
    assert.deepEqual(screen.results[1]!.mapping, first.mapping);
    assert.deepEqual(screen.results[1]!.rows, first.rows);

    // another header line: the mapping is not used
    screen.text = csv(3).replace('Nombre,', 'Nombre del producto,');
    await settled();
    assert.deepEqual(targets(), ['skip', 'f:price', 'f:due', 'skip']);

    // without a header line no mapping is saved
    screen.text = csv(3);
    await settled();
    await click(SEL('euiSheetImportHeaders'));
    assert.deepEqual(all('euiSheetImportHeader').map(textOf), [
      'Column 1',
      'Column 2',
      'Column 3',
      'Column 4'
    ]);
    assert.deepEqual(
      targets(),
      ['f:name', 'f:price', 'f:due', 'f:active'],
      'by position'
    );
    assert.strictEqual(textOf(q('euiSheetImportLineCount')), '4 lines');
    await click(SEL('euiSheetImportSubmit'));
    assert.strictEqual(screen.results[2]!.mapping, null);
    assert.strictEqual(screen.results[2]!.rows.length, 4);
  });

  test('IW7 a rejected @onCreateFields or @onImport shows its message and imports nothing; a retry creates nothing twice', async function (assert) {
    const screen = new Screen();
    screen.creates = true;
    screen.create = () => Promise.reject(new Error('No room for fields'));
    await renderScreen(screen);
    await click(SEL('euiSheetImportSubmit'));
    assert.dom(SEL('euiSheetImportError')).hasText('No room for fields');
    assert.strictEqual(screen.results.length, 0, '@onImport not called');
    assert.strictEqual(targets()[3], 'new', 'still a new field');

    // the wrong number of fields
    screen.create = () => Promise.resolve([]);
    await click(SEL('euiSheetImportSubmit'));
    assert
      .dom(SEL('euiSheetImportError'))
      .hasText(defaultMessages.importCreateMismatch());
    assert.strictEqual(screen.results.length, 0);

    // created, then @onImport rejects
    screen.create = (drafts) =>
      Promise.resolve(drafts.map((draft) => ({ ...draft, id: 'activo' })));
    screen.onImportImpl = () => Promise.reject(new Error('Store is offline'));
    await click(SEL('euiSheetImportSubmit'));
    assert.dom(SEL('euiSheetImportError')).hasText('Store is offline');
    assert.strictEqual(screen.drafts.length, 3);
    assert.strictEqual(
      targets()[3],
      'f:activo',
      'the column goes to the created field'
    );
    assert.dom(SEL('euiSheetImportSubmit')).isNotDisabled('not busy any more');

    // the retry: no second field
    screen.onImportImpl = () => undefined;
    await click(SEL('euiSheetImportSubmit'));
    assert.strictEqual(
      screen.drafts.length,
      3,
      '@onCreateFields not called again'
    );
    assert.dom(SEL('euiSheetImportError')).doesNotExist();
    const result = screen.results[screen.results.length - 1]!;
    assert.deepEqual(result.fieldIds, ['name', 'price', 'due', 'activo']);
    assert.deepEqual(
      result.createdFields.map((field) => field.id),
      ['activo'],
      'the created field is reported until an import succeeds'
    );

    // a pending @onImport keeps the screen busy
    let finish: () => void = () => {};
    screen.onImportImpl = () =>
      new Promise<void>((resolve) => {
        finish = resolve;
      });
    q('euiSheetImportSubmit').click();
    await rerender();
    assert.dom(SEL('euiSheetImport')).hasAttribute('aria-busy', 'true');
    assert.dom(q('euiSheetImportTarget', row(0))).isDisabled();
    finish();
    await settled();
    assert.dom(SEL('euiSheetImport')).doesNotHaveAttribute('aria-busy');
    assert.deepEqual(
      screen.results[screen.results.length - 1]!.createdFields,
      [],
      'reported once'
    );
  });

  test('IW8 end to end with a sheet: appendRows(rows, fieldIds, { fields }) inserts one record per line in one change set, the new field included, before @fields re-renders; Ctrl/Cmd+Z removes them', async function (assert) {
    const owner = new SheetOwner();
    const screen = new Screen();
    screen.creates = true;
    screen.text = csv(5);
    screen.onImportImpl = (result) =>
      owner.api!.appendRows(result.rows, result.fieldIds, {
        fields: result.fields
      });
    await render(
      <template>
        <EuiSheet
          @fields={{owner.fields}}
          @records={{owner.records}}
          @getRecordId={{getId}}
          @onChange={{owner.onChange}}
          @registerApi={{owner.register}}
          @height={{300}}
        />
        <EuiSheetImport
          @fields={{owner.fields}}
          @text={{screen.text}}
          @onCreateFields={{screen.onCreateFields}}
          @onImport={{screen.onImport}}
        />
      </template>
    );
    await click(SEL('euiSheetImportSubmit'));
    assert.strictEqual(owner.log.length, 1, 'one change set');
    const set = owner.log[0]!;
    assert.strictEqual(set.source, 'paste');
    assert.deepEqual(
      set.inserts.map((insert) => insert.values),
      [1, 2, 3, 4, 5].map((i) => ({
        name: `Producto ${i}`,
        price: i + 0.5,
        due: `2026-11-${pad(i)}`,
        activo: i % 2 === 1
      })),
      'one insert per line, the new field (not in @fields) read as a checkbox'
    );
    assert.deepEqual(set.rejected, []);
    assert.false(
      owner.fields.some((field) => field.id === 'activo'),
      '@fields never had it'
    );
    assert.strictEqual(owner.records.length, 6);
    await focusCell(0, 0);
    await pressed('z', { ctrlKey: true });
    assert.deepEqual(
      owner.records.map((record) => record.id),
      ['r0'],
      'one undo removes them'
    );
  });

  test('IW9 keyboard: every control is a native, named, tabbable control in reading order; Escape closes the new-field form', async function (assert) {
    const screen = new Screen();
    screen.creates = true;
    screen.transforms = [CENTS];
    screen.text = csv(5).replace('3.5', 'abc');
    await renderScreen(screen);
    await click(q('euiSheetImportValuesToggle', row(3)));
    const root = q('euiSheetImport');
    const controls = [
      ...root.querySelectorAll<HTMLElement>(
        'button, select, input, a[href], textarea, [tabindex]'
      )
    ];
    assert.true(controls.length > 20, `${controls.length} controls`);
    const nameOf = (element: HTMLElement): string => {
      const label = element.getAttribute('aria-label');
      if (label) return label;
      const by = element.getAttribute('aria-labelledby');
      if (by) {
        return by
          .split(' ')
          .map((id) => textOf(document.getElementById(id)))
          .join(' ');
      }
      if (element.id) {
        const forLabel = root.querySelector(`label[for="${element.id}"]`);
        if (forLabel) return textOf(forLabel);
      }
      const wrapping = element.closest('label');
      if (wrapping) return textOf(wrapping);
      return textOf(element);
    };
    for (const control of controls) {
      const tag = control.tagName.toLowerCase();
      assert.true(
        ['button', 'select', 'input', 'a', 'textarea'].includes(tag),
        `${tag} is a native control`
      );
      assert.notStrictEqual(control.tabIndex, -1, `${tag} is tabbable`);
      assert.false(
        (control as HTMLButtonElement).disabled,
        `${tag} "${nameOf(control)}" is enabled`
      );
      assert.true(nameOf(control).length > 0, `${tag} has a name`);
    }
    const submit = q('euiSheetImportSubmit');
    assert.strictEqual(
      controls[controls.length - 1],
      submit,
      'Import is the last control'
    );
    const targetsSelects = all('euiSheetImportTarget');
    assert.deepEqual(
      targetsSelects.map((s) => s.getAttribute('aria-label')),
      [
        'Where "Nombre" goes',
        'Where "Precio" goes',
        'Where "Fecha" goes',
        'Where "Activo" goes'
      ]
    );
    assert.true(
      targetsSelects.every((s) => s.tagName === 'SELECT'),
      'native selects: they open with the keyboard'
    );

    // the new-field form: Escape closes it and gives focus back
    await click(q('euiSheetImportEditNewField', row(3)));
    assert.strictEqual(document.activeElement, q('euiSheetFieldName'));
    await triggerKeyEvent(q('euiSheetFieldName'), 'keydown', 'Escape');
    assert.dom(SEL('euiSheetImportNewFieldForm')).doesNotExist();
    assert.strictEqual(
      document.activeElement,
      q('euiSheetImportEditNewField', row(3))
    );
  });

  test('IW10 decision 14: an M/D/Y column of a D/M/Y field imports right with result.fields (not with createdFields only)', async function (assert) {
    const owner = new SheetOwner();
    const screen = new Screen();
    screen.text = 'Nombre,Fecha\r\nA,11/19/2026\r\nB,12/31/2026';
    screen.onImportImpl = () => undefined;
    await render(
      <template>
        <EuiSheet
          @fields={{owner.fields}}
          @records={{owner.records}}
          @getRecordId={{getId}}
          @onChange={{owner.onChange}}
          @registerApi={{owner.register}}
          @height={{300}}
        />
        <EuiSheetImport
          @fields={{owner.fields}}
          @text={{screen.text}}
          @onImport={{screen.onImport}}
        />
      </template>
    );
    assert.strictEqual(
      totals(),
      '0 lines ready, 2 with errors',
      'D/M/Y reads neither'
    );
    await select(q('euiSheetImportDateOrder', row(1)), 'mdy');
    assert.deepEqual(
      previewRows(),
      [
        ['A', '19/11/2026'],
        ['B', '31/12/2026']
      ],
      'read as M/D/Y, shown as the D/M/Y field shows it'
    );
    assert.strictEqual(totals(), '2 lines ready, 0 with errors');
    await click(SEL('euiSheetImportSubmit'));
    const result = screen.results[0]!;
    assert.deepEqual(result.fieldIds, ['name', 'due']);
    assert.deepEqual(
      result.fields[1],
      { ...FIELDS[2]!, dateOrder: 'mdy' },
      'a copy'
    );
    assert.strictEqual(
      FIELDS[2]!['dateOrder'],
      undefined,
      'the field unchanged'
    );
    assert.deepEqual(result.createdFields, []);

    owner.api!.appendRows(result.rows, result.fieldIds, {
      fields: result.createdFields
    });
    await settled();
    assert.deepEqual(
      owner.log[0]!.rejected.map((r) => r.text),
      ['11/19/2026', '12/31/2026'],
      'without the copy, rejected'
    );
    owner.api!.appendRows(result.rows, result.fieldIds, {
      fields: result.fields
    });
    await settled();
    assert.deepEqual(
      owner.log[1]!.inserts.map((insert) => insert.values),
      [
        { name: 'A', due: '2026-11-19' },
        { name: 'B', due: '2026-12-31' }
      ]
    );
    assert.deepEqual(owner.log[1]!.rejected, []);
  });

  test('IW12 a column with no text creates no field; a change of @transforms alone re-runs the dry run', async function (assert) {
    const screen = new Screen();
    screen.creates = true;
    screen.transforms = [UPPER];
    // a trailing delimiter on every line: a fifth column with no text
    screen.text = csv(4)
      .split('\r\n')
      .map((line) => `${line},`)
      .join('\r\n');
    await renderScreen(screen);
    assert.deepEqual(all('euiSheetImportHeader').map(textOf), [
      'Nombre',
      'Precio',
      'Fecha',
      'Activo',
      'Column 5'
    ]);
    assert.deepEqual(
      targets(),
      ['f:name', 'f:price', 'f:due', 'new', 'skip'],
      'Activo goes to a new field; the empty column is skipped'
    );
    await select(q('euiSheetImportTransform', row(0)), 'upper');
    assert.strictEqual(totals(), '4 lines ready, 0 with errors');
    // the same id, now throwing: the dry run follows the new @transforms
    screen.transforms = [{ ...UPPER, apply: BOOM.apply }];
    await settled();
    assert.strictEqual(totals(), '0 lines ready, 4 with errors');
    assert.strictEqual(
      textOf(q('euiSheetImportCantRead', row(0))),
      '4 can’t be read'
    );
    await click(SEL('euiSheetImportSubmit'));
    assert.deepEqual(
      screen.drafts,
      [[{ label: 'Activo', type: 'checkbox' }]],
      'one new field only'
    );
  });

  test('IW11 a windows-1252 file: the encoding found, accents right; the delimiter and the header switch re-read it', async function (assert) {
    const text = 'Año;Precio;Señal\r\nPeña;1,5;Sí\r\nNiño;12,25;No\r\n';
    const bytes = new Uint8Array([...text].map((char) => char.charCodeAt(0)));
    const screen = new Screen();
    screen.text = null;
    screen.fields = [{ id: 'year', label: 'Ano' }];
    screen.file = new File([bytes], 'precios.csv', { type: 'text/csv' });
    await renderScreen(screen);
    assert.dom(SEL('euiSheetImportFileName')).hasText('precios.csv');
    assert.dom(SEL('euiSheetImportEncoding')).hasText('Encoding: Windows-1252');
    assert.dom(SEL('euiSheetImportDelimiter')).hasValue(';');
    assert.deepEqual(all('euiSheetImportHeader').map(textOf), [
      'Año',
      'Precio',
      'Señal'
    ]);
    assert.deepEqual(targets(), ['f:year', 'skip', 'skip'], 'Año matches Ano');
    assert.deepEqual(badges(), [
      'Single line text · 100%',
      'Number, Comma (1,5) · 100%',
      'Checkbox · 100%'
    ]);
    assert.deepEqual(previewRows(), [['Peña'], ['Niño']]);
    assert.strictEqual(textOf(q('euiSheetImportLineCount')), '2 lines');

    await select(SEL('euiSheetImportDelimiter'), ',');
    assert.deepEqual(
      all('euiSheetImportHeader').map(textOf),
      ['Año;Precio;Señal', 'Column 2'],
      're-read with a comma: the header is one cell, the lines two (1,5)'
    );
    await select(SEL('euiSheetImportDelimiter'), ';');
    await click(SEL('euiSheetImportHeaders'));
    assert.deepEqual(all('euiSheetImportHeader').map(textOf), [
      'Column 1',
      'Column 2',
      'Column 3'
    ]);
    assert.strictEqual(textOf(q('euiSheetImportLineCount')), '3 lines');
    assert.deepEqual(previewRows()[0], ['Año'], 'the first line is data');
  });

  test('IW13 a new source starts from the defaults: no filter, "Import all"', async function (assert) {
    const screen = new Screen();
    screen.text = csv(25).replace('3.5', 'abc').replace('7.5', 'xyz');
    await renderScreen(screen);
    await click(q('euiSheetImportCantRead', row(1)));
    assert.strictEqual(previewRows().length, 2, 'filtered to the two lines');
    await click(q('euiSheetImportErrorChoice').querySelectorAll('input')[1]!);
    assert.strictEqual(
      submitText(),
      'Import 23 lines',
      '"Skip lines with errors"'
    );

    // another file in the same screen
    screen.text = csv(25).replace('5.5', 'nope');
    await settled();
    assert.strictEqual(totals(), '24 lines ready, 1 with errors');
    assert.strictEqual(previewRows().length, 20, 'no filter');
    assert.strictEqual(submitText(), 'Import 25 lines', '"Import all" again');
  });
});
