import { registerDeprecationHandler } from '@ember/debug';
import { module, test } from 'qunit';

import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';
import {
  euiPaletteColorBlind,
  euiPaletteColorBlindBehindText,
  euiPaletteComplementary,
  euiPaletteCool,
  euiPaletteForStatus,
  euiPaletteForTemperature,
  euiPaletteGray,
  euiPaletteGreen,
  euiPaletteOrange,
  euiPaletteRed,
  euiPaletteSkyBlue,
  euiPaletteWarm,
  euiPaletteYellow,
  useEuiPaletteColorBlind,
  useEuiPaletteColorBlindBehindText,
  useEuiPaletteComplementary,
  useEuiPaletteCool,
  useEuiPaletteForStatus,
  useEuiPaletteForTemperature,
  useEuiPaletteGray,
  useEuiPaletteGreen,
  useEuiPaletteOrange,
  useEuiPaletteRed,
  useEuiPaletteSkyBlue,
  useEuiPaletteWarm,
  useEuiPaletteYellow
} from '#src/utils/color/eui_palettes.ts';

import {
  euiPaletteComplimentary,
  euiPaletteForDarkBackground,
  euiPaletteForLightBackground,
  euiPaletteNegative,
  euiPalettePositive
} from '#src/utils/color/eui_palettes_deprecated.ts';

import type { EuiPaletteVisColors } from '#src/utils/color/eui_palettes.ts';

// Ported from @elastic/eui 123.1.0 services/color/eui_palettes.test.ts and
// eui_palettes_hooks.test.tsx (no React: the context is passed explicitly).
const light = resolveBorealisTheme('light');
const dark = resolveBorealisTheme('dark');
const lightHc = resolveBorealisTheme('light', {}, true);
const colorVis = light.euiTheme.colors.vis as EuiPaletteVisColors;
const custom = '#00ff00';

type Steps = (steps: number, props?: { colors?: EuiPaletteVisColors }) => string[];

module('Unit | utils | color | eui_palettes', function () {
  test('euiPaletteColorBlind and BehindText accept custom colors', function (assert) {
    const colors = { ...colorVis, euiColorVis0: custom };

    assert.strictEqual(euiPaletteColorBlind({ colors })[0], custom);
    assert.strictEqual(euiPaletteColorBlindBehindText({ colors })[0], custom);
  });

  test('euiPaletteColorBlind defaults, rotations and sortBy', function (assert) {
    const base = Array.from({ length: 10 }, (_, i) => (colorVis as Record<string, string>)[`euiColorVis${i}`]);

    assert.deepEqual(euiPaletteColorBlind(), base);
    assert.strictEqual(euiPaletteColorBlind({ rotations: 3 }).length, 30);
    assert.deepEqual([...euiPaletteColorBlind({ sortBy: 'natural' })].sort(), [...base].sort());
    assert.strictEqual(euiPaletteColorBlind({ rotations: 2, order: 'group', direction: 'both' }).length, 20);
  });

  test('deprecated palettes still work and report a deprecation', function (assert) {
    const ids: string[] = [];

    registerDeprecationHandler((_message, options, next) => {
      const id = String(options?.id ?? '');
      if (id.startsWith('ember-eui.eui-palette-')) ids.push(id);
      else next(_message, options);
    });

    assert.deepEqual(euiPaletteComplimentary(4), euiPaletteComplementary(4));
    assert.strictEqual(euiPaletteNegative(1)[0], '#E7664C');
    assert.strictEqual(euiPalettePositive(1)[0], '#54B399');
    assert.strictEqual(euiPaletteForLightBackground().length, 5);
    assert.strictEqual(euiPaletteForDarkBackground().length, 5);
    assert.strictEqual(ids.length, 5);
  });

  const cases: [string, Steps, string, string, string][] = [
    ['ForStatus', euiPaletteForStatus, '#c8e3b8', 'euiColorVisSuccess0', 'status'],
    ['ForTemperature', euiPaletteForTemperature, '#f1f6ff', 'euiColorVisWarm2', 'temp'],
    ['Complementary', euiPaletteComplementary, '#c4dcfd', 'euiColorVisComplementary0', 'comp'],
    ['Red', euiPaletteRed, '#feb7b0', 'euiColorVisDanger0', 'last'],
    ['Green', euiPaletteGreen, '#9fdfc6', 'euiColorVisSuccess0', 'last'],
    ['SkyBlue', euiPaletteSkyBlue, '#a6d8ec', 'euiColorVisNeutral0', 'last'],
    ['Yellow', euiPaletteYellow, '#f9d290', 'euiColorVisWarning0', 'last'],
    ['Orange', euiPaletteOrange, '#ffc1a1', 'euiColorVisRisk0', 'last'],
    ['Cool', euiPaletteCool, '#adccff', 'euiColorVisCool2', 'last'],
    ['Warm', euiPaletteWarm, '#ffb5ac', 'euiColorVisWarm2', 'last'],
    ['Gray', euiPaletteGray, '#7b8aa4', 'euiColorVisGrey3', 'last']
  ];

  for (const [name, fn, sixth, overrideKey, kind] of cases) {
    test(`euiPalette${name}: upstream values and custom colors`, function (assert) {
      assert.strictEqual(fn(6, { colors: colorVis })[2], sixth, 'correct colors');
      assert.deepEqual(fn(6), fn(6, { colors: colorVis }), 'defaults to the Borealis vis colors');

      const colors = { ...colorVis, [overrideKey]: custom };
      const result = fn(3, { colors });
      const index = kind === 'status' || kind === 'comp' ? 0 : 2;

      assert.strictEqual(result[index], custom, 'custom color is used');
    });
  }

  module('theme-aware versions', function () {
    test('ColorBlind follows the color mode and high contrast', function (assert) {
      assert.deepEqual(useEuiPaletteColorBlind(light), Object.keys(colorVis).filter((k) => /^euiColorVis\d$/.test(k)).map((k) => (colorVis as Record<string, string>)[k]));
      assert.deepEqual(useEuiPaletteColorBlind(dark), useEuiPaletteColorBlind(light), 'vis colors are the same in dark mode');
      assert.deepEqual(useEuiPaletteColorBlind(lightHc), [
        '#065B58', '#009E99', '#154399', '#2476F0', '#831652',
        '#D13680', '#7F1F27', '#DA3737', '#6A4906', '#AD7E00'
      ]);
    });

    test('ColorBlindBehindText', function (assert) {
      assert.deepEqual(useEuiPaletteColorBlindBehindText(lightHc), useEuiPaletteColorBlind(lightHc));
      assert.deepEqual(useEuiPaletteColorBlindBehindText(light), useEuiPaletteColorBlind(light));
    });

    for (const context of [light, dark, lightHc]) {
      const vis = context.euiTheme.colors.vis as Record<string, string>;
      const label = `${context.colorMode}${context.highContrastMode ? ' high contrast' : ''}`;

      test(`step palettes read the ${label} vis colors`, function (assert) {
        const lc = (value: string | undefined) => value!.toLowerCase();

        assert.deepEqual(useEuiPaletteForStatus(context, 3), [lc(vis['euiColorVisSuccess0']), lc(vis['euiColorVisWarning1']), lc(vis['euiColorVisDanger0'])]);
        assert.strictEqual(useEuiPaletteForTemperature(context, 3)[0], lc(vis['euiColorVisCool2']));
        assert.strictEqual(useEuiPaletteForTemperature(context, 3)[2], lc(vis['euiColorVisWarm2']));
        assert.strictEqual(useEuiPaletteComplementary(context, 3)[0], lc(vis['euiColorVisComplementary0']));
        assert.strictEqual(useEuiPaletteComplementary(context, 3)[2], lc(vis['euiColorVisComplementary1']));
        assert.strictEqual(useEuiPaletteRed(context, 5)[4], lc(vis['euiColorVisDanger0']));
        assert.strictEqual(useEuiPaletteGreen(context, 5)[4], lc(vis['euiColorVisSuccess0']));
        assert.strictEqual(useEuiPaletteSkyBlue(context, 5)[4], lc(vis['euiColorVisNeutral0']));
        assert.strictEqual(useEuiPaletteYellow(context, 5)[4], lc(vis['euiColorVisWarning0']));
        assert.strictEqual(useEuiPaletteOrange(context, 5)[4], lc(vis['euiColorVisRisk0']));
        assert.strictEqual(useEuiPaletteCool(context, 3)[2], lc(vis['euiColorVisCool2']));
        assert.strictEqual(useEuiPaletteWarm(context, 3)[2], lc(vis['euiColorVisWarm2']));
        assert.strictEqual(useEuiPaletteGray(context, 4)[3], lc(vis['euiColorVisGrey3']));
      });
    }

    test('high contrast changes the step palettes', function (assert) {
      assert.notDeepEqual(useEuiPaletteRed(lightHc, 5), useEuiPaletteRed(light, 5));
    });
  });
});
