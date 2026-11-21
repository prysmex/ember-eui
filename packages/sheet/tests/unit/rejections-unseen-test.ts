/**
 * Redo of a rejection whose inserted record was not seen yet (READINESS.md
 * item 5, RI8): it is put back with the value the record has now.
 */
import { module, test } from 'qunit';

import { restoreRejections, UNSEEN } from '#src/-private/rejections.ts';

import type { Rejection } from '#src/-private/rejections.ts';

module('Unit | rejections of inserted records', function () {
  test('RI8 restoreRejections: an unseen value takes the record’s current one', function (assert) {
    const unseen: Rejection = {
      id: 'new-1',
      fieldId: 'qty',
      text: 'abc',
      message: 'bad',
      seenValue: UNSEEN
    };
    const seen: Rejection = { ...unseen, id: 'r2', seenValue: 3 };
    const next = restoreRejections(new Map(), [unseen, seen], (id) =>
      id === 'new-1' ? { found: true, value: null } : { found: true, value: 4 }
    );
    assert.deepEqual(
      [...next!.values()],
      [{ ...unseen, seenValue: null }],
      'the unseen one with the value now; the seen one changed since: not put back'
    );
    assert.strictEqual(unseen.seenValue, UNSEEN, 'the entry is not changed');
    assert.strictEqual(
      restoreRejections(new Map(), [unseen], () => ({
        found: false,
        value: undefined
      })),
      null,
      'not without its record'
    );
  });
});
