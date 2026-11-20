/** The `barcode` type (V03-DESIGN.md 10.3.2, BC1). */
import { module, test } from 'qunit';

import { barcodeFieldType, defaultMessages } from '#src/core/index.ts';

import type { BarcodeField } from '#src/core/index.ts';

const type = barcodeFieldType;
const context = { record: undefined, messages: defaultMessages };

function field(extra: Partial<BarcodeField> = {}): BarcodeField {
  return { id: 'code', type: 'barcode', ...extra };
}

module('Unit | Sheet | barcode (V03 10.3.2)', function () {
  test('BC1 parse trims; pattern validates; copy and paste round-trip; compare', function (assert) {
    const parse = (text: string) =>
      type.parse(text, field(), { ...context, source: 'paste' });
    assert.deepEqual(parse('  7501234567890 \t'), { value: '7501234567890' });
    assert.deepEqual(
      parse('ABC-123 x'),
      { value: 'ABC-123 x' },
      'inner spaces kept'
    );
    assert.deepEqual(parse('   '), { value: null }, 'empty');
    assert.deepEqual(type.parse('', field(), { ...context, source: 'clear' }), {
      value: null
    });
    const ean = field({ pattern: '^\\d{13}$' });
    assert.deepEqual(type.validate!('7501234567890', ean, context), []);
    assert.deepEqual(type.validate!('750123', ean, context), [
      'Invalid format'
    ]);
    assert.deepEqual(
      type.validate!(
        '750123',
        field({
          pattern: '^\\d{13}$',
          patternMessage: 'An EAN-13 has 13 digits'
        }),
        context
      ),
      ['An EAN-13 has 13 digits']
    );
    assert.deepEqual(
      type.validate!('x', field({ pattern: '([' }), context),
      [],
      'a pattern that is not a valid RegExp is ignored'
    );
    for (const value of ['7501234567890', 'https://example.com/?q=1', 'A b']) {
      const copied = type.copyText!(value, field(), context);
      assert.strictEqual(copied, value);
      assert.deepEqual(parse(copied), { value }, `round trip ${value}`);
      assert.strictEqual(type.format(value, field(), context), value);
    }
    assert.strictEqual(type.format(null, field(), context), '');
    const compare = type.compare!;
    assert.true(compare('A1', 'B1', field()) < 0);
    assert.true(compare('B1', 'A1', field()) > 0);
    assert.strictEqual(compare('A1', 'A1', field()), 0);
    assert.true(compare(null, 'A1', field()) < 0, 'empty first');
  });
});
