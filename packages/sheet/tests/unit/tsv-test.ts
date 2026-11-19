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

module('Unit | Sheet | tsv quoted cells (v0.2)', function () {
  test('Q1 a quoted cell with a tab and a line break is one cell', function (assert) {
    assert.deepEqual(parseTsv('"a\tb\nc"\td\ne\tf'), [
      ['a\tb\nc', 'd'],
      ['e', 'f']
    ]);
  });

  test('Q2 "" inside a quoted cell is one "', function (assert) {
    assert.deepEqual(parseTsv('"say ""hi""\n"\tx'), [['say "hi"\n', 'x']]);
    assert.deepEqual(parseTsv('""""'), [['"']], 'a cell that is one quote');
    assert.deepEqual(parseTsv('""\tb'), [['', 'b']], 'an empty quoted cell');
  });

  test('Q3 a cell that starts with " and never closes is plain', function (assert) {
    assert.deepEqual(parseTsv('"abc\tdef\nx'), [['"abc', 'def'], ['x']]);
    assert.deepEqual(parseTsv('"12 in'), [['"12 in']]);
  });

  test('Q4 a quote that does not start the cell is plain', function (assert) {
    assert.deepEqual(parseTsv('12" pipe\tb"c"\n"d"e'), [
      ['12" pipe', 'b"c"'],
      ['"d"e']
    ]);
  });

  test('Q5 \\r\\n inside a quoted cell becomes \\n; \\r\\n between rows ends the row', function (assert) {
    assert.deepEqual(parseTsv('"one\r\ntwo"\tb\r\nc\td\r\n'), [
      ['one\ntwo', 'b'],
      ['c', 'd']
    ]);
  });

  test('Q6 toTsv quotes only the cells that need it', function (assert) {
    assert.strictEqual(
      toTsv([['plain', 'a\tb', 'two\nlines', 'cr\r', '"quoted', 'mid"dle']]),
      'plain\t"a\tb"\t"two\nlines"\t"cr\r"\t"""quoted"\tmid"dle'
    );
    assert.strictEqual(
      toTsv([
        ['a', 'b'],
        ['c', '']
      ]),
      'a\tb\nc\t'
    );
  });

  test('Q7 parseTsv(toTsv(m)) round-trips awkward matrices', function (assert) {
    const matrices: string[][][] = [
      [
        ['a', 'b'],
        ['c', 'd']
      ],
      [
        ['line 1\nline 2', 'x'],
        ['', 'tab\there']
      ],
      [['"'], ['""'], ['"a"'], ['a"']],
      [['ends with quote"\t'], ['"\t"', '\n']],
      [
        ['lone \r cr', '\n\n'],
        ['', '']
      ],
      [[''], ['x'], ['"start', 'end"']]
    ];
    for (const matrix of matrices) {
      assert.deepEqual(parseTsv(toTsv(matrix)), matrix, JSON.stringify(matrix));
    }
  });

  test('Q8 an Excel sample: a cell with two lines', function (assert) {
    // what Excel puts on the clipboard for A1="Name", B1="Notes",
    // A2="Ana", B2 = two lines (Alt+Enter), C2 = 5
    const excel = 'Name\tNotes\t\r\nAna\t"first line\nsecond ""line"""\t5\r\n';
    assert.deepEqual(parseTsv(excel), [
      ['Name', 'Notes', ''],
      ['Ana', 'first line\nsecond "line"', '5']
    ]);
  });
});
