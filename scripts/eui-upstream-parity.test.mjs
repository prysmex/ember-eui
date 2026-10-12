import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createRequire, Module } from 'node:module';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { readFileSync } from 'node:fs';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(resolve(root, 'packages/core/package.json'));
const { buildSync } = require('esbuild');
const source = resolve(root, 'packages/core/src/utils/eui/styles.generated.ts');
const bundle = buildSync({
  entryPoints: [source],
  bundle: true,
  write: false,
  format: 'cjs',
  platform: 'node',
  external: [
    '@elastic/eui-theme-common',
    '@elastic/eui-theme-borealis',
    '@emotion/serialize',
    'chroma-js'
  ]
});
const filename = resolve(root, 'packages/core/eui-style-parity.cjs');
const adapted = new Module(filename);
adapted.paths = Module._nodeModulePaths(dirname(filename));
adapted._compile(bundle.outputFiles[0].text, filename);
const styles = adapted.exports;
const { EuiThemeBorealis } = require('@elastic/eui-theme-borealis');
const { getComputed, buildTheme } = require('@elastic/eui-theme-common');
const eui = dirname(require.resolve('@elastic/eui/package.json'));

const factories = {
  'components/spacer/spacer.styles.js': ['euiSpacerStyles'],
  'components/horizontal_rule/horizontal_rule.styles.js': [
    'euiHorizontalRuleStyles'
  ],
  'components/panel/panel.styles.js': ['euiPanelStyles'],
  'components/loading/loading_spinner.styles.js': [
    'euiLoadingSpinnerStyles',
    'euiSpinnerBorderColorsCSS'
  ],
  'components/button/button_display/_button_display.styles.js': [
    'euiButtonDisplayStyles'
  ],
  'components/button/button_display/_button_display_content.styles.js': [
    'euiButtonDisplayContentStyles'
  ],
  'global_styling/mixins/_button.js': ['euiButtonDisplaysColors'],
  'global_styling/mixins/_states.js': ['euiFocusRing'],
  'components/text/text.styles.js': ['euiTextStyles'],
  'components/text/text_color.styles.js': ['euiTextColorStyles'],
  'components/title/title.styles.js': ['euiTitleStyles'],
  'components/link/link.styles.js': ['euiLinkStyles'],
  'components/badge/badge.styles.js': ['euiBadgeStyles'],
  'components/badge/color_utils.js': ['euiBadgeColors'],
  'components/badge/badge_group/badge_group.styles.js': [
    'euiBadgeGroupStyles'
  ],
  'components/badge/beta_badge/beta_badge.styles.js': ['euiBetaBadgeStyles'],
  'components/badge/notification_badge/badge_notification.styles.js': [
    'euiNotificationBadgeStyles'
  ],
  'components/flex/flex_group.styles.js': ['euiFlexGroupStyles'],
  'components/flex/flex_grid.styles.js': ['euiFlexGridStyles'],
  'components/button/button_empty/button_empty.styles.js': [
    'euiButtonEmptyStyles'
  ],
  'components/button/button_icon/button_icon.styles.js': [
    'euiButtonIconStyles'
  ],
  // checkables
  'components/form/checkbox/checkbox.styles.js': ['euiCheckboxStyles'],
  'components/form/checkbox/checkbox_control.styles.js': [
    'euiCheckboxControlStyles'
  ],
  'components/form/checkbox/checkbox_group.styles.js': [
    'euiCheckboxGroupStyles'
  ],
  'components/form/radio/radio.styles.js': ['euiRadioStyles'],
  'components/form/radio/radio_group.styles.js': ['euiRadioGroupStyles'],
  'components/form/switch/switch.styles.js': ['euiSwitchStyles'],
  // content-blocks
  'components/call_out/call_out.styles.js': [
    'euiCallOutStyles',
    'euiCallOutHeaderStyles'
  ],
  'components/empty_prompt/empty_prompt.styles.js': ['euiEmptyPromptStyles'],
  'components/stat/stat.styles.js': ['euiStatStyles', 'euiStatTitleStyles']
};
function normalize(value) {
  if (Array.isArray(value)) return value.map(normalize);
  if (value && typeof value === 'object')
    return Object.fromEntries(
      Object.entries(value)
        .filter(([, v]) => typeof v !== 'function')
        .map(([k, v]) => [k, normalize(v)])
    );
  return value;
}
for (const [path, names] of Object.entries(factories)) {
  const reference = require(resolve(eui, 'lib', path));
  for (const name of names)
    test(`${name}: all serialized slots match upstream in 12 theme configurations`, () => {
      for (const colorMode of ['LIGHT', 'DARK'])
        for (const highContrastMode of [false, 'preferred', 'forced'])
          for (const modifications of [
            {},
            {
              base: 20,
              border: { radius: { panel: '20px' } },
              colors: {
                LIGHT: { primary: '#663399' },
                DARK: { primary: '#aa77dd' }
              }
            }
          ]) {
            const context = {
              colorMode,
              highContrastMode,
              modifications,
              euiTheme: getComputed(
                EuiThemeBorealis,
                buildTheme(modifications, 'parity'),
                colorMode,
                highContrastMode
              )
            };
            assert.deepEqual(
              normalize(styles[name](context)),
              normalize(reference[name](context)),
              `${colorMode}/${highContrastMode}/${JSON.stringify(modifications)}`
            );
          }
    });
}

test('pure color and padding helpers match upstream for all migrated variants', () => {
  const { euiPaddingSize } = require(
    resolve(eui, 'lib/global_styling/mixins/_padding.js')
  );
  const { euiBackgroundColor, euiBorderColor } = require(
    resolve(eui, 'lib/global_styling/mixins/_color.js')
  );
  for (const mode of ['LIGHT', 'DARK']) {
    const context = {
      euiTheme: getComputed(EuiThemeBorealis, buildTheme({}, 'parity'), mode),
      colorMode: mode,
      highContrastMode: false
    };
    for (const size of ['none', 'xs', 's', 'm', 'l', 'xl'])
      assert.equal(
        styles.euiPaddingSize(context, size),
        euiPaddingSize(context, size)
      );
    for (const color of [
      'transparent',
      'plain',
      'subdued',
      'highlighted',
      'accent',
      'accentSecondary',
      'primary',
      'success',
      'warning',
      'danger'
    ]) {
      assert.equal(
        styles.euiBackgroundColor(context, color),
        euiBackgroundColor(context, color)
      );
      assert.equal(
        styles.euiBorderColor(context, color),
        euiBorderColor(context, color)
      );
    }
  }
});

test('generated artifact has no React or upstream hook execution paths', () => {
  const code = readFileSync(source, 'utf8');
  assert.doesNotMatch(
    code,
    /from ["'](?:react|react-dom|@emotion\/react)(?:["'/])/
  );
  assert.doesNotMatch(code, /React hooks cannot run in Ember/);
});

test('button interactions match upstream fill and overlay in every mode and contrast', () => {
  const reference = require(
    resolve(eui, 'lib/global_styling/mixins/_button.js')
  );
  const colors = {
    color: '#123456',
    background: '#eaf0fa',
    backgroundHover: '#ccddee',
    backgroundActive: '#8899aa',
    borderColor: 'transparent'
  };
  for (const colorMode of ['LIGHT', 'DARK'])
    for (const highContrastMode of [false, 'preferred', 'forced']) {
      const context = {
        colorMode,
        highContrastMode,
        euiTheme: getComputed(
          EuiThemeBorealis,
          buildTheme({}, 'parity'),
          colorMode,
          highContrastMode
        )
      };
      for (const kind of ['fill', 'overlay'])
        assert.equal(
          styles.euiButtonInteractionStyles(context, colors, kind),
          reference.euiButtonInteractionStyles(context, colors, kind)
        );
    }
});

test('text alignment slots match upstream static styles', () => {
  const reference = require(
    resolve(eui, 'lib/components/text/text_align.styles.js')
  );
  assert.deepEqual(
    normalize(styles.euiTextAlignStyles),
    normalize(reference.euiTextAlignStyles)
  );
});

test('typography factories match upstream with text token and font overrides', () => {
  const modifications = {
    font: { title: { weight: 'medium', letterSpacing: '0.02em' }, scale: { m: 1.1 } },
    size: { m: '14px' },
    colors: {
      LIGHT: { textParagraph: '#202020', textHeading: '#101010', textSubdued: '#555555' },
      DARK: { textParagraph: '#eeeeee', textHeading: '#ffffff', textSubdued: '#aaaaaa' }
    }
  };
  for (const [path, name] of [
    ['components/text/text.styles.js', 'euiTextStyles'],
    ['components/text/text_color.styles.js', 'euiTextColorStyles'],
    ['components/title/title.styles.js', 'euiTitleStyles']
  ]) {
    const reference = require(resolve(eui, 'lib', path));
    for (const colorMode of ['LIGHT', 'DARK']) {
      const context = {
        colorMode,
        highContrastMode: false,
        modifications,
        euiTheme: getComputed(
          EuiThemeBorealis,
          buildTheme(modifications, 'parity'),
          colorMode,
          false
        )
      };
      assert.deepEqual(
        normalize(styles[name](context)),
        normalize(reference[name](context)),
        `${name}/${colorMode}`
      );
    }
  }
});

test('flex item slots match upstream static styles', () => {
  const reference = require(resolve(eui, 'lib/components/flex/flex_item.styles.js'));
  assert.deepEqual(
    normalize(styles.euiFlexItemStyles),
    normalize(reference.euiFlexItemStyles)
  );
});

test('badge color helpers match upstream for named, custom and invalid colors', () => {
  const reference = require(resolve(eui, 'lib/components/badge/color_utils.js'));
  const colors = ['#ffffff', '#000000', '#E7664C', '#54B399', '#6092C0', 'rgb(200, 100, 50)'];
  for (const colorMode of ['LIGHT', 'DARK'])
    for (const highContrastMode of [false, 'preferred', 'forced']) {
      const context = {
        colorMode,
        highContrastMode,
        euiTheme: getComputed(
          EuiThemeBorealis,
          buildTheme({}, 'parity'),
          colorMode,
          highContrastMode
        )
      };
      for (const color of colors) {
        assert.deepEqual(
          styles.getBadgeColors(context, color),
          reference.getBadgeColors(context, color),
          `getBadgeColors ${color}`
        );
        assert.deepEqual(
          styles.getTextColor(context, color),
          reference.getTextColor(context, color)
        );
        assert.deepEqual(
          styles.getCustomInteractiveColors(context, color),
          reference.getCustomInteractiveColors(context, color)
        );
      }
    }
  for (const color of [...colors, 'primary', 'not-a-color', '#12', ''])
    assert.strictEqual(
      styles.getIsValidColor(color),
      reference.getIsValidColor(color),
      `getIsValidColor ${color}`
    );
});

test('global styles port matches upstream EuiGlobalStyles in every mode and contrast', () => {
  const { serializeStyles } = require('@emotion/serialize');
  const ported = buildSync({
    entryPoints: [resolve(root, 'packages/core/src/utils/eui/global-styles.ts')],
    bundle: true,
    write: false,
    format: 'cjs',
    platform: 'node',
    external: [
      '@elastic/eui-theme-common',
      '@elastic/eui-theme-borealis',
      '@emotion/serialize',
      'chroma-js'
    ]
  });
  const portFile = resolve(root, 'packages/core/eui-global-parity.cjs');
  const portModule = new Module(portFile);
  portModule.paths = Module._nodeModulePaths(dirname(portFile));
  portModule._compile(ported.outputFiles[0].text, portFile);
  const { euiGlobalStyles } = portModule.exports;

  // Run upstream's React component body with React/Emotion/hooks stubbed out.
  let current;
  const originalLoad = Module._load;
  Module._load = function (request, parent, isMain) {
    if (request === '@emotion/react')
      return {
        Global: 'Global',
        css: (...args) => serializeStyles(args),
        jsx: (type, props) => ({ type, props })
      };
    if (/services\/theme$/.test(request))
      return { useEuiTheme: () => current };
    return originalLoad.call(this, request, parent, isMain);
  };
  try {
    const globalsPath = resolve(eui, 'lib/global_styling/reset/global_styles.js');
    delete require.cache[globalsPath];
    const { EuiGlobalStyles } = require(globalsPath);
    for (const colorMode of ['LIGHT', 'DARK'])
      for (const highContrastMode of [false, 'preferred', 'forced'])
        for (const modifications of [{}, { font: { defaultUnits: 'px' }, base: 18 }]) {
          current = {
            colorMode,
            highContrastMode,
            modifications,
            euiTheme: getComputed(
              EuiThemeBorealis,
              buildTheme(modifications, 'parity'),
              colorMode,
              highContrastMode
            )
          };
          const upstream = EuiGlobalStyles({}).props.styles.styles;
          assert.strictEqual(
            serializeStyles(euiGlobalStyles(current)).styles,
            upstream,
            `${colorMode}/${highContrastMode}/${JSON.stringify(modifications)}`
          );
        }
  } finally {
    Module._load = originalLoad;
  }
});
