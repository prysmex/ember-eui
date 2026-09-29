import { module, test } from 'qunit';

import { VIS_COLORS_BEHIND_TEXT } from '#src/-private/vis-colors.ts';
import { euiPaletteColorBlindBehindText } from '#src/utils/color/eui_palettes.ts';

module('Unit | -private | vis-colors', function () {
  test('the kept colors are the computed palette', function (assert) {
    assert.deepEqual([...VIS_COLORS_BEHIND_TEXT], euiPaletteColorBlindBehindText());
  });
});
