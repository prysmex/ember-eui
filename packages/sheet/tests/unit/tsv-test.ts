import { module, test } from 'qunit';

import { parseTsv, toTsv } from '#src/core/index.ts';

module('Unit | Sheet | tsv', function () {
  test('U2 parseTsv', function (assert) {
    assert.deepEqual(parseTsv('a\tb\nc\td'), [
      ['a', 'b'],
      ['c', 'd']
    ]);
    assert.deepEqual(
      parseTsv('a\tb\r\nc\td\r\n'),
      [
        ['a', 'b'],
        ['c', 'd']
      ],
      '\\r\\n, one trailing newline dropped'
    );
    assert.deepEqual(
      parseTsv('a\n'),
      [['a']],
      'only one trailing empty line is dropped'
    );
    assert.deepEqual(parseTsv('a\n\n'), [['a'], ['']]);
    assert.deepEqual(parseTsv('a\t\tc'), [['a', '', 'c']], 'empty cells kept');
    assert.deepEqual(parseTsv('v'), [['v']]);
  });

  test('U3 toTsv(parseTsv(x)) round-trips a block without trailing newline', function (assert) {
    const block = 'a\tb\tc\n\te\tf\ng\th\t';
    assert.strictEqual(toTsv(parseTsv(block)), block);
  });
});
