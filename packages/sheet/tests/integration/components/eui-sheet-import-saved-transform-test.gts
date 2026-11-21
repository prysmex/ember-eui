/**
 * A saved mapping whose checkbox column has a transform and no value map
 * (READINESS.md item 5, IVM3): the screen prefills the value map from
 * the transformed texts when it proposes the plan. The texts' transform
 * gets each line's texts by header from the header line, not from the
 * plan being proposed (that read the plan while computing it).
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';

import EuiSheetImport from '#src/components/eui-sheet-import.gts';
import { importSignature } from '#src/core/index.ts';

import type {
  EuiSheetField,
  SheetImportMapping,
  SheetImportTransform
} from '#src/core/index.ts';
import type { SheetImportResult } from '#src/types.ts';

interface Row {
  id: string;
  [key: string]: unknown;
}

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Nombre' },
  { id: 'active', label: 'Activo', type: 'checkbox' }
];

const SEL = (subj: string) => `[data-test-subj="${subj}"]`;

const textOf = (element: Element | null | undefined) =>
  (element?.textContent ?? '').replace(/\s+/g, ' ').trim();

/** `sí` or `no` from the line's own `Nombre` (it uses `row`): `sí` when it starts with A. */
const BY_NAME: SheetImportTransform = {
  id: 'byName',
  label: 'From the name',
  apply: (_text, { row }) => (row['Nombre']?.startsWith('A') ? 'sí' : 'no')
};

module(
  'Integration | Component | EuiSheetImport saved transform',
  function (hooks) {
    setupRenderingTest(hooks);

    test('IVM3 a saved transform on a checkbox column: the map prefilled from its texts', async function (assert) {
      const headers = ['Nombre', 'Activo'];
      const saved: SheetImportMapping = {
        signature: importSignature(headers),
        columns: [
          { index: 0, header: 'Nombre', target: { field: 'name' } },
          {
            index: 1,
            header: 'Activo',
            target: { field: 'active' },
            transform: 'byName'
          }
        ]
      };
      const text = 'Nombre,Activo\r\nAna,x\r\nBo,x\r\nAlma,x';
      const transforms = [BY_NAME];
      const results: SheetImportResult<Row>[] = [];
      const onImport = (result: SheetImportResult<Row>) => {
        results.push(result);
      };
      const onCancel = () => {};
      await render(
        <template>
          <EuiSheetImport
            @fields={{FIELDS}}
            @text={{text}}
            @transforms={{transforms}}
            @savedMapping={{saved}}
            @onImport={{onImport}}
            @onCancel={{onCancel}}
          />
        </template>
      );
      const row = document.querySelector(
        `${SEL('euiSheetImportColumn')}[data-column="1"]`
      )!;
      assert.strictEqual(
        textOf(row.querySelector(SEL('euiSheetImportValuesToggle'))),
        'Values (2 mapped)',
        'sí and no, prefilled'
      );
      await click(
        row.querySelector<HTMLElement>(SEL('euiSheetImportValuesToggle'))!
      );
      assert.deepEqual(
        [
          ...document.querySelectorAll(`${SEL('euiSheetImportValueRow')} th`)
        ].map((th) => textOf(th)),
        ['sí', 'no'],
        'the transformed texts'
      );
      await click(
        document.querySelector<HTMLElement>(SEL('euiSheetImportSubmit'))!
      );
      assert.deepEqual(
        results[0]!.values.map((values) => values[1]),
        [true, false, true]
      );
    });
  }
);
