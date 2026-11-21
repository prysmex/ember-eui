/**
 * A guessed currency's code (v0.4 batch E's open item, READINESS.md item
 * 5's "any other open item"), IG6-IG7: the code the sample names, else
 * the new field's `USD`.
 */
import { module, test } from 'qunit';

import { draftFromGuess } from '#src/-private/import/model.ts';
import {
  builtInFieldTypes,
  defaultMessages,
  guessColumn
} from '#src/core/index.ts';

const ctx = { types: builtInFieldTypes, messages: defaultMessages };
const first = (texts: string[]) => guessColumn(ctx, texts)[0];

module('Unit | import guess: the currency code', function () {
  test('IG6 the code every text that names one names', function (assert) {
    assert.deepEqual(first(['MXN 300', 'MXN 12.5']), {
      type: 'currency',
      share: 1,
      options: { decimalSeparator: '.', currency: 'MXN' }
    });
    assert.deepEqual(first(['12 €', '3,5 €']), {
      type: 'currency',
      share: 1,
      options: { decimalSeparator: ',', currency: 'EUR' }
    });
    assert.strictEqual(
      first(['£4', 'GBP 5'])!.options['currency'],
      'GBP',
      'a sign and its code agree'
    );
    for (const texts of [
      ['$12', '$3'],
      ['$1,200.00', 'MXN 300', '45.5 €'],
      ['ABC 3', 'ABC 4'],
      ['¢5', '¢6']
    ]) {
      const guess = first(texts)!;
      assert.strictEqual(guess.type, 'currency', texts.join(' | '));
      assert.false(
        'currency' in guess.options,
        `${texts.join(' | ')}: no code (a dollar sign, a mix, an unknown code or sign)`
      );
    }
  });

  test('IG7 the new field’s draft: the guessed code, else USD', function (assert) {
    assert.deepEqual(draftFromGuess('Precio', first(['12 €', '3,5 €'])), {
      label: 'Precio',
      type: 'currency',
      decimalSeparator: ',',
      currency: 'EUR'
    });
    assert.deepEqual(draftFromGuess('Precio', first(['$12', '$3'])), {
      label: 'Precio',
      type: 'currency',
      decimalSeparator: '.',
      currency: 'USD'
    });
  });
});
