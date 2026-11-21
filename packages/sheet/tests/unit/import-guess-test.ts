/**
 * The import guess for timestamps and phone numbers (READINESS.md item 5,
 * IG4-IG5): `dateTime` before `date` when a text has a time of day,
 * `phone` before `number` when the texts are written as phone numbers.
 */
import { module, test } from 'qunit';

import {
  builtInFieldTypes,
  CREATABLE_FIELD_TYPES,
  defaultMessages,
  guessColumn
} from '#src/core/index.ts';

const ctx = { types: builtInFieldTypes, messages: defaultMessages };
const WITH_DATE_TIME = [...CREATABLE_FIELD_TYPES, 'dateTime'];

const typesOf = (texts: string[], candidates?: readonly string[]) =>
  guessColumn(ctx, texts, candidates).map((guess) => guess.type);

module('Unit | import guess: timestamps and phones', function () {
  test('IG4 ISO timestamps guess dateTime when it is available', function (assert) {
    assert.deepEqual(
      typesOf(['2026-11-19T10:30', '2026-11-20T08:00:00Z'], WITH_DATE_TIME),
      ['dateTime', 'date', 'text'],
      'with a T'
    );
    assert.strictEqual(
      typesOf(['2026-11-19 10:30', '2026-11-20 18:05:10'], WITH_DATE_TIME)[0],
      'dateTime',
      'with a space'
    );
    assert.strictEqual(
      typesOf(['2026-11-19', '2026-11-20T08:00'], WITH_DATE_TIME)[0],
      'dateTime',
      'one text with a time is enough (dateTime reads a date alone)'
    );
    assert.deepEqual(
      guessColumn(ctx, ['2026-11-19T10:30'], WITH_DATE_TIME)[0],
      { type: 'dateTime', share: 1, options: { dateOrder: 'dmy' } }
    );
    assert.deepEqual(
      typesOf(['2026-11-19', '19/11/2026'], WITH_DATE_TIME),
      ['date', 'dateTime', 'text'],
      'dates alone stay date'
    );
    assert.deepEqual(
      typesOf(['2026-11-19T10:30', '2026-11-20T08:00']),
      ['date', 'text'],
      'without dateTime among the candidates (the default list): date, as before'
    );
  });

  test('IG5 phone numbers written as such guess phone; plain digits stay number', function (assert) {
    assert.deepEqual(
      typesOf(['+52 81 1234 5678', '+52 55 9876 5432']),
      ['phone', 'number', 'text'],
      'spaced, with +'
    );
    assert.strictEqual(
      typesOf(['81 1234 5678', '55 9876 5432'])[0],
      'phone',
      'spaced'
    );
    assert.strictEqual(
      typesOf(['(81) 1234-5678', '(55) 9876-5432'])[0],
      'phone',
      'parentheses (number never read them)'
    );
    assert.strictEqual(typesOf(['+528112345678'])[0], 'phone', 'a + first');
    assert.strictEqual(
      typesOf(['81-1234-5678', '55-9876-5432'])[0],
      'phone',
      'dashes'
    );
    for (const texts of [
      ['5281123456', '5512345678'],
      ['12', '30', '7'],
      ['1 234 567', '2 000 000'],
      ['1234.5678', '12.5'],
      ['-1234567', '42'],
      ['+5', '+12']
    ]) {
      assert.strictEqual(typesOf(texts)[0], 'number', texts.join(' | '));
    }
    assert.strictEqual(
      typesOf(['81 1234 5678', '42', '7', '3', '1'])[0],
      'number',
      'under 95% written as phones: number first'
    );
    assert.deepEqual(
      typesOf(['81 1234 5678', '55 9876 5432'], ['number', 'text']),
      ['number', 'text'],
      'without phone among the candidates'
    );
  });
});
