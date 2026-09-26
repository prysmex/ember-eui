import { module, test } from 'qunit';

import { calculateThumbPosition } from '#src/helpers/get-range-tick.ts';

module('Unit | helpers | get-range-tick', function () {
  test('calculateThumbPosition compensates for the thumb on a measured track', function (assert) {
    // 16px thumb on a 160px track: the usable scale is 90%
    assert.strictEqual(calculateThumbPosition(10, 0, 10, 160, 16), 90);
    assert.strictEqual(calculateThumbPosition(0, 0, 10, 160, 16), 0);
  });

  test('calculateThumbPosition falls back to a plain percentage before the track is measured', function (assert) {
    assert.strictEqual(calculateThumbPosition(5, 0, 10, 0), 50);
    assert.strictEqual(calculateThumbPosition(10, 0, 10, 0), 100);
  });
});
