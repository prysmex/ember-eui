/** Reproducibly extract pure EUI style factories without React components/hooks. */
import { createRequire } from 'node:module';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(resolve(root, 'packages/core/package.json'));
const { build } = require('esbuild');
const euiRoot = dirname(require.resolve('@elastic/eui/package.json'));
const expected = {
  '@elastic/eui': '123.1.0',
  '@elastic/eui-theme-borealis': '8.1.0',
  '@elastic/eui-theme-common': '10.1.0'
};
for (const [name, version] of Object.entries(expected)) {
  const actual = JSON.parse(
    readFileSync(
      name === '@elastic/eui'
        ? resolve(euiRoot, 'package.json')
        : resolve(dirname(require.resolve(name)), '../../package.json')
    )
  ).version;
  if (actual !== version)
    throw new Error(`${name}: expected ${version}, found ${actual}`);
}
const entries = {
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
  'components/text/text.styles.js': ['euiTextStyles'],
  'components/text/text_color.styles.js': ['euiTextColorStyles'],
  'components/text/text_align.styles.js': ['euiTextAlignStyles'],
  'components/title/title.styles.js': ['euiTitleStyles'],
  'components/link/link.styles.js': ['euiLinkStyles'],
  'components/badge/badge.styles.js': ['euiBadgeStyles'],
  'components/badge/color_utils.js': [
    'euiBadgeColors',
    'getBadgeColors',
    'getTextColor',
    'getCustomInteractiveColors',
    'getIsValidColor'
  ],
  'components/badge/badge_group/badge_group.styles.js': [
    'euiBadgeGroupStyles'
  ],
  'components/badge/beta_badge/beta_badge.styles.js': ['euiBetaBadgeStyles'],
  'components/badge/notification_badge/badge_notification.styles.js': [
    'euiNotificationBadgeStyles'
  ],
  'components/flex/flex_group.styles.js': ['euiFlexGroupStyles'],
  'components/flex/flex_item.styles.js': ['euiFlexItemStyles'],
  'components/flex/flex_grid.styles.js': ['euiFlexGridStyles'],
  'components/button/button_empty/button_empty.styles.js': [
    'euiButtonEmptyStyles'
  ],
  'components/button/button_icon/button_icon.styles.js': [
    'euiButtonIconStyles'
  ],
  'global_styling/mixins/_states.js': ['euiFocusRing'],
  'global_styling/reset/reset.js': ['resetStyles'],
  'global_styling/mixins/_helpers.js': ['euiScrollBarStyles'],
  'services/color/manipulation.js': ['transparentize'],
  'global_styling/mixins/_padding.js': ['euiPaddingSize'],
  'global_styling/mixins/_color.js': ['euiBackgroundColor', 'euiBorderColor'],
  'global_styling/mixins/_button.js': [
    'euiButtonDisplaysColors',
    'euiButtonInteractionStyles'
  ],
  // utilities
  'components/accessibility/screen_reader_only/screen_reader_only.styles.js': [
    'euiScreenReaderOnly',
    'euiScreenReaderOnlyStyles'
  ],
  'components/accessibility/skip_link/skip_link.styles.js': [
    'euiSkipLinkStyles'
  ],
  'components/progress/progress.styles.js': [
    'euiProgressStyles',
    'euiProgressDataStyles',
    'euiProgressLabelStyles',
    'euiProgressValueTextStyles'
  ],
  'services/color/contrast.js': ['makeHighContrastColor'],
  'components/skeleton/skeleton_text.styles.js': ['euiSkeletonTextStyles'],
  'components/loading/loading_chart.styles.js': [
    'euiLoadingChartStyles',
    'euiLoadingChartBarStyles'
  ],
  'components/loading/loading_elastic.styles.js': ['euiLoadingElasticStyles'],
  'components/loading/loading_logo.styles.js': ['euiLoadingLogoStyles'],
  'global_styling/utility/animations.js': ['euiAnimFadeIn'],
  'global_styling/functions/high_contrast.js': ['highContrastModeStyles'],
  'global_styling/functions/logicals.js': ['logicalCSS'],
  'components/code/code.styles.js': ['euiCodeStyles'],
  'components/image/image.styles.js': ['euiImageStyles'],
  'components/image/image_wrapper.styles.js': ['euiImageWrapperStyles'],
  'components/image/image_button.styles.js': [
    'euiImageButtonStyles',
    'euiImageButtonIconStyles'
  ],
  'components/image/image_caption.styles.js': ['euiImageCaptionStyles'],
  'components/image/image_fullscreen_wrapper.styles.js': [
    'euiImageFullscreenWrapperStyles'
  ]
};
const hooks = `export function useEuiTheme(){throw new Error('React hooks cannot run in Ember')}
export function useEuiMemoizedStyles(){throw new Error('React hooks cannot run in Ember')}`;
const result = await build({
  stdin: {
    contents: Object.entries(entries)
      .map(
        ([path, names]) =>
          `export { ${names.join(', ')} } from ${JSON.stringify(resolve(euiRoot, 'es', path))};`
      )
      .join('\n'),
    resolveDir: root,
    sourcefile: 'eui-style-entry.js'
  },
  bundle: true,
  write: false,
  format: 'esm',
  platform: 'browser',
  target: 'es2022',
  metafile: true,
  external: [
    '@elastic/eui-theme-common',
    '@elastic/eui-theme-borealis',
    '@emotion/serialize',
    'chroma-js'
  ],
  define: { 'process.env.NODE_ENV': '"production"' },
  plugins: [
    {
      name: 'ember-eui-pure-styles',
      setup(builder) {
        builder.onResolve({ filter: /^@emotion\/react$/ }, () => ({
          path: 'emotion',
          namespace: 'ember-eui'
        }));
        builder.onResolve({ filter: /^(react|react-dom)(\/|$)/ }, (args) => {
          throw new Error(`Unexpected React runtime dependency: ${args.path}`);
        });
        builder.onLoad({ filter: /.*/, namespace: 'ember-eui' }, () => ({
          contents: `import { serializeStyles } from '@emotion/serialize';
export const css = (...args) => serializeStyles(args);
export const keyframes = (...args) => { const value = css(...args); const name = 'animation-' + value.name; return { name, styles: '@keyframes ' + name + '{' + value.styles + '}', anim: 1, toString() { return '_EMO_' + name + '_' + this.styles + '_EMO_'; } }; };`,
          loader: 'js'
        }));
        builder.onLoad(
          { filter: /\/es\/global_styling\/index\.js$/ },
          (args) => ({
            contents: readFileSync(args.path, 'utf8').replace(
              "export * from './reset/global_styles';",
              ''
            ),
            resolveDir: dirname(args.path),
            loader: 'js'
          })
        );
        builder.onLoad(
          { filter: /\/es\/services\/theme\/(index|hooks)\.js$/ },
          () => ({ contents: hooks, loader: 'js' })
        );
        builder.onLoad({ filter: /\/es\/services\/index\.js$/ }, (args) => ({
          contents: `${hooks}\nexport * from './color/contrast';\nexport * from './color/manipulation';\nexport * from './color/is_color_dark';`,
          resolveDir: dirname(args.path),
          loader: 'js'
        }));
        builder.onLoad(
          { filter: /\/es\/services\/color\/index\.js$/ },
          (args) => ({
            contents: readFileSync(args.path, 'utf8').replace(
              /^export .*eui_palettes_hooks.*$/m,
              ''
            ),
            resolveDir: dirname(args.path),
            loader: 'js'
          })
        );
        builder.onLoad({ filter: /\/es\/components\/common\.js$/ }, () => ({
          contents: 'export const keysOf = Object.keys;',
          loader: 'js'
        }));
      }
    }
  ]
});
const typedOutput = result.outputFiles[0].text
  .replace(
    /(function euiSpinnerBorderColorsCSS\d*\()(\w+)(\) \{)/,
    '$1$2: EuiBorealisContext, _colors?: { border?: string; highlight?: string }$3'
  )
  .replace(
    /(function euiButtonDisplaysColors\d*\(\w+\)) \{/,
    '$1: Record<string, Record<string, import("@emotion/serialize").SerializedStyles>> {'
  );
const generated =
  '// @ts-nocheck\n// GENERATED by scripts/generate-eui-styles.mjs. Do not edit.\n// Upstream sources licensed under Elastic License 2.0 or SSPL v1; see vendor/eui-latest.\n' +
  "import type { EuiBorealisContext } from './theme.ts';\n" +
  typedOutput;
if (
  /React hooks cannot run in Ember|from ["'](?:react|@emotion\/react)/.test(
    generated
  )
)
  throw new Error('React-dependent code survived style extraction');
const files = Object.keys(result.metafile.inputs).filter(
  (path) => !path.startsWith('ember-eui:') && !path.includes('style-entry')
);
const provenance = {
  versions: expected,
  adapters: [
    'Emotion serialization only',
    'pure style barrels',
    'Object.keys helper'
  ],
  sources: files
    .map((path) => ({
      path: path.includes('/es/')
        ? '@elastic/eui/es/' + path.split('/es/')[1]
        : path,
      sha256: createHash('sha256')
        .update(readFileSync(resolve(root, path)))
        .digest('hex')
    }))
    .sort((a, b) => a.path.localeCompare(b.path))
};
const targets = [
  ['packages/core/src/utils/eui/styles.generated.ts', generated],
  [
    'internal/spikes/eui-latest/upstream-sources.json',
    JSON.stringify(provenance, null, 2) + '\n'
  ]
];
for (const [path, content] of targets) {
  const target = resolve(root, path);
  if (process.argv.includes('--check')) {
    if (readFileSync(target, 'utf8') !== content)
      throw new Error(`Stale generated artifact: ${path}`);
  } else {
    mkdirSync(dirname(target), { recursive: true });
    writeFileSync(target, content);
  }
}
console.log(
  `EUI ${expected['@elastic/eui']}: extracted ${Object.values(entries).flat().length} style factories; React-free output verified`
);
