import { module, test } from 'qunit';

import {
  builtInFieldTypes,
  defaultMessages,
  checkboxFieldType,
  multiSelectFieldType,
  ratingFieldType
} from '#src/core/index.ts';
import {
  FIT_MAX_WIDTH,
  FIT_MIN_WIDTH,
  FIT_RECORDS,
  fieldWidth
} from '#src/-private/fit-width.ts';

import type {
  EuiSheetField,
  FieldType,
  SheetContext
} from '#src/core/index.ts';

type Row = Record<string, unknown>;

/** A fake font: every character is 7 px wide. */
const measure = (text: string) => text.length * 7;
const measures = { cell: measure, header: measure };
const chrome = { header: 40, cell: 16, opener: 0 };

function ctx(
  records: Row[],
  types: Record<string, FieldType<any, any>> = {}
): SheetContext<Row> {
  return {
    records,
    fields: [],
    getRecordId: (row) => row['id'] as string,
    types: { ...builtInFieldTypes, ...types },
    messages: defaultMessages
  };
}

module('Unit | fit width (v0.4 01)', function () {
  test('FW8 fieldWidth: content plus padding, the header when it is wider, clamped', function (assert) {
    const field: EuiSheetField<Row> = { id: 'a', label: 'A' };
    const of = (values: string[], f = field) =>
      fieldWidth(
        ctx(values.map((v, i) => ({ id: i, a: v }))),
        f,
        measures,
        chrome
      );
    // 20 chars × 7 = 140, + 16
    assert.strictEqual(of(['x'.repeat(20), 'short']), 156, 'widest cell');
    assert.strictEqual(of(['ab']), FIT_MIN_WIDTH, 'at least 80');
    assert.strictEqual(of(['x'.repeat(200)]), FIT_MAX_WIDTH, 'at most 480');
    // a label of 30 chars: 210 + 40 = 250 over a 2-char cell
    assert.strictEqual(
      of(['ab'], { id: 'a', label: 'L'.repeat(30) }),
      250,
      'the header wins'
    );
    assert.strictEqual(
      of([], { id: 'a', label: 'L'.repeat(30) }),
      250,
      'no records: the header'
    );
    assert.strictEqual(
      of(['ab'], { id: 'a'.repeat(20) } as EuiSheetField<Row>),
      180,
      'no label: the id is the header (20 × 7 + 40)'
    );
    assert.strictEqual(
      fieldWidth(ctx([{ id: 1, a: 'x'.repeat(20) }]), field, measures, {
        ...chrome,
        opener: 28
      }),
      184,
      'the opener adds its room'
    );
    assert.strictEqual(
      fieldWidth(
        ctx([{ id: 1, a: 'x'.repeat(20) }]),
        field,
        { cell: (t) => t.length * 7 + 0.4, header: measure },
        chrome
      ),
      157,
      'rounded up'
    );
  });

  test('FW9 fieldWidth: a type`s contentWidth is used; format otherwise; only the first 2,000 records', function (assert) {
    const seen: unknown[] = [];
    const wide: FieldType<string> = {
      parse: (text) => ({ value: text }),
      format: (value) => String(value ?? ''),
      contentWidth: (value, _field, m) => {
        seen.push(value);
        return m(String(value)) * 2;
      }
    };
    const field: EuiSheetField<Row> = { id: 'a', label: 'A', type: 'wide' };
    const records = Array.from({ length: FIT_RECORDS + 5 }, (_, i) => ({
      id: i,
      a: i === FIT_RECORDS + 1 ? 'x'.repeat(60) : 'abcdef'
    }));
    // 6 chars × 7 × 2 = 84, + 16
    assert.strictEqual(
      fieldWidth(ctx(records, { wide }), field, measures, chrome),
      100
    );
    assert.strictEqual(seen.length, FIT_RECORDS, 'the rest is not measured');

    const formatted: FieldType<number> = {
      parse: () => ({ value: 0 }),
      format: (value) => `#${String(value)}#`
    };
    assert.strictEqual(
      fieldWidth(
        ctx([{ id: 1, a: 1234567890123 }], { formatted }),
        { id: 'a', type: 'formatted' },
        measures,
        chrome
      ),
      // "#1234567890123#": 15 chars × 7 + 16
      121
    );
  });

  test('FW10 the built-in contentWidth of checkbox, rating and chips', function (assert) {
    const context = { record: undefined, messages: defaultMessages };
    assert.strictEqual(
      checkboxFieldType.contentWidth!(
        true,
        { id: 'c', type: 'checkbox' },
        measure,
        context
      ),
      24
    );
    assert.strictEqual(
      ratingFieldType.contentWidth!(
        2,
        { id: 'r', type: 'rating', max: 10 },
        measure,
        context
      ),
      180
    );
    const tags = {
      id: 't',
      type: 'multiSelect' as const,
      options: [
        { value: 1, label: 'One' },
        { value: 2, label: 'Two' },
        { value: 3, label: 'Three' },
        { value: 4, label: 'Four' }
      ]
    };
    // "One" 21 + 24, "Two" 21 + 24, gap 4
    assert.strictEqual(
      multiSelectFieldType.contentWidth!([1, 2], tags, measure, context),
      94
    );
    // three chips (One, Two, Three: 21, 21, 35, each + 24), 2 gaps, then gap + "+1" (14)
    assert.strictEqual(
      multiSelectFieldType.contentWidth!([1, 2, 3, 4], tags, measure, context),
      21 + 21 + 35 + 72 + 8 + 4 + 14
    );
    assert.strictEqual(
      multiSelectFieldType.contentWidth!([], tags, measure, context),
      0
    );
  });
});
