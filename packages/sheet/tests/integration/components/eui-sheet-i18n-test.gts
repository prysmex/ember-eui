/**
 * The built-in messages go through core's `eui-i18n` service (tokens
 * `euiSheet.*`), and `@messages` wins over both (decision Q6).
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import {
  cellTitle,
  clipboard,
  focusCell,
  isInvalid
} from '../../helpers/sheet.ts';

import type { EuiSheetField, SheetMessages } from '#src/core/index.ts';
import type EuiI18n from '@ember-eui/core/services/eui-i18n';

interface Row {
  id: string;
  name: string;
  qty: number | null;
}

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', required: true },
  { id: 'qty', type: 'number' }
];
const getId = (record: { id: string }) => record.id;
const rows = (): Row[] => [
  { id: 'r0', name: '', qty: 1 },
  { id: 'r1', name: 'b', qty: 2 }
];

module('Integration | Component | EuiSheet messages', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(messages?: Partial<SheetMessages>) {
    const store = localRecords<Row>(rows(), { getRecordId: getId });
    await render(
      <template>
        <EuiSheet
          @records={{store.records}}
          @fields={{FIELDS}}
          @getRecordId={{getId}}
          @onChange={{store.apply}}
          @messages={{messages}}
        />
      </template>
    );
    return store;
  }

  test('I1 English defaults', async function (assert) {
    const store = await renderSheet();
    assert.strictEqual(cellTitle(0, 0), 'Required');
    await focusCell(1, 1);
    await clipboard('paste', 'abc');
    assert.strictEqual(cellTitle(1, 1), '"abc" is not a number');
    assert.strictEqual(
      store.log[0]!.rejected[0]!.message,
      '"abc" is not a number'
    );
  });

  test('I2 a translation through eui-i18n', async function (assert) {
    const i18n = this.owner.lookup('service:eui-i18n') as EuiI18n;
    i18n.addTranslations({
      euiSheet: {
        required: 'Obligatorio',
        notANumber: '"{text}" no es un número'
      }
    });
    const store = await renderSheet();
    assert.strictEqual(cellTitle(0, 0), 'Obligatorio');
    await focusCell(1, 1);
    await clipboard('paste', 'abc');
    assert.true(isInvalid(1, 1));
    assert.strictEqual(cellTitle(1, 1), '"abc" no es un número');
    assert.strictEqual(
      store.log[0]!.rejected[0]!.message,
      '"abc" no es un número',
      'the change set carries the translated message'
    );
  });

  test('I3 @messages wins over a translation', async function (assert) {
    const i18n = this.owner.lookup('service:eui-i18n') as EuiI18n;
    i18n.addTranslations({ euiSheet: { required: 'Obligatorio' } });
    await renderSheet({ required: () => 'Falta' });
    assert.strictEqual(cellTitle(0, 0), 'Falta');
  });
});
