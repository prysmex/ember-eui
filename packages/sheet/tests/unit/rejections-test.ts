import { module, test } from 'qunit';

import { cellKey } from '#src/core/index.ts';
import {
  clearRejections,
  remapRejections,
  restoreRejections
} from '#src/-private/rejections.ts';

import type { Rejection } from '#src/-private/rejections.ts';

const abc: Rejection = {
  id: 'r0',
  fieldId: 'hours',
  text: 'abc',
  message: '"abc" is not a number',
  seenValue: 0
};
const onTemp: Rejection = {
  id: 'new-1',
  fieldId: 'hours',
  text: 'zz',
  message: '"zz" is not a number',
  seenValue: undefined
};

const mapOf = (...rejections: Rejection[]) =>
  new Map(rejections.map((r) => [cellKey(r.id, r.fieldId), r]));

module('Unit | Sheet | rejections in the history', function () {
  test('RJ1 clearRejections drops only the entry’s own text and message', function (assert) {
    const later = { ...abc, text: 'xyz', message: '"xyz" is not a number' };
    assert.strictEqual(
      clearRejections(mapOf(later), [abc]),
      null,
      'a later rejection on the same cell is kept'
    );
    const sameText = { ...abc, message: 'another message' };
    assert.strictEqual(clearRejections(mapOf(sameText), [abc]), null);

    // a copy (remapIds and redo re-create the objects) is the same rejection
    const next = clearRejections(mapOf({ ...abc }, onTemp), [abc, onTemp]);
    assert.deepEqual(next && [...next.keys()], []);
    assert.strictEqual(clearRejections(new Map(), [abc]), null, 'none shown');
  });

  test('RJ2 restoreRejections needs the record and its value then', function (assert) {
    const rows: Record<string, Record<string, unknown>> = { r0: { hours: 0 } };
    const at = (id: string, fieldId: string) => ({
      found: id in rows,
      value: rows[id]?.[fieldId]
    });
    const next = restoreRejections(new Map(), [abc, onTemp], at);
    assert.deepEqual(
      next && [...next.values()],
      [abc],
      'the tempId row is gone'
    );

    rows['new-1'] = {};
    const both = restoreRejections(new Map(), [abc, onTemp], at);
    assert.deepEqual(both && [...both.values()], [abc, onTemp], 'it is back');

    rows['r0'] = { hours: 9 };
    const changed = restoreRejections(new Map(), [abc], at);
    assert.strictEqual(changed, null, 'the owner changed the value since');
  });

  test('RJ3 remapRejections', function (assert) {
    const remapped = remapRejections([abc, onTemp], (id) =>
      id === 'new-1' ? 'srv-1' : id
    );
    assert.strictEqual(remapped[0], abc, 'unchanged ids keep the object');
    assert.deepEqual(remapped[1], { ...onTemp, id: 'srv-1' });
  });
});
