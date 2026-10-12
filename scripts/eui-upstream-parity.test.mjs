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
  external: ['@elastic/eui-theme-common', '@emotion/serialize']
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
  'global_styling/mixins/_states.js': ['euiFocusRing']
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
