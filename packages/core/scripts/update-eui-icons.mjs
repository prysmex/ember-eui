/**
 * Syncs the bundled EUI icons with the pinned upstream @elastic/eui:
 *
 * 1. Replaces vendor/icon/svgs (except `legacy/`) with upstream's
 *    `es/components/icon/svgs` (tokens included), plus the two
 *    EuiNotificationIcon glyphs (`notification/`), which upstream keeps out
 *    of its icon map.
 * 2. Rewrites the generated block of src/utils/css-mappings/eui-icon.ts:
 *    `typeToPathMap` (every upstream name from upstream's `icon_map`, the
 *    notification icons, then the legacy Ember names below), `deprecatedIconTypes`,
 *    `legacyIconAliases` and `legacyIconTypes`.
 *
 * Then run `node scripts/generate-icons.mjs` to regenerate the loaders.
 *
 *   node scripts/update-eui-icons.mjs && node scripts/generate-icons.mjs
 *
 * `--check` changes nothing and fails if the svgs or the block are stale.
 *
 * Upstream svgs are © Elasticsearch B.V., Elastic License 2.0 / SSPL v1
 * (see vendor/icon/NOTICE.txt).
 */
import {
  cpSync,
  existsSync,
  readFileSync,
  readdirSync,
  realpathSync,
  rmSync,
  writeFileSync
} from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const UPSTREAM_VERSION = '123.1.0';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const svgDir = join(root, 'vendor/icon/svgs');
const mappingFile = join(root, 'src/utils/css-mappings/eui-icon.ts');

/**
 * Upstream EuiNotificationIcon glyphs (`NOTIFICATION_ICONS_MAP`), which are
 * not in upstream's icon map; bundled so callouts and toasts can use
 * upstream's default icons by name.
 */
const NOTIFICATION_ICONS = {
  infoFill: 'info_fill',
  warningStatic: 'warning_static'
};

/**
 * Ember icon names that upstream renamed or dropped, mapped to the upstream
 * 123 icon they now render. Most follow upstream's renames (the EUI 118 icon
 * aliases and changelogs); the ones marked "Ember pick" have no declared
 * upstream successor and use the equivalent upstream glyph.
 */
const LEGACY_ALIASES = {
  apmTrace: 'chartWaterfall',
  arrowDown: 'chevronSingleDown',
  arrowLeft: 'chevronSingleLeft',
  arrowRight: 'chevronSingleRight',
  arrowUp: 'chevronSingleUp',
  arrowStart: 'chevronLimitLeft',
  arrowEnd: 'chevronLimitRight',
  beaker: 'flask',
  checkInCircleFilled: 'checkCircleFill',
  cheer: 'popper',
  color: 'paintBucket',
  console: 'commandLine',
  controlsHorizontal: 'controls',
  controlsVertical: 'controls',
  copyClipboard: 'copy',
  crosshairs: 'crosshair',
  currency: 'money',
  cut: 'scissors',
  desktop: 'display',
  discuss: 'comment',
  doubleArrowLeft: 'chevronDoubleLeft',
  doubleArrowRight: 'chevronDoubleRight',
  editorAlignCenter: 'textAlignCenter',
  editorAlignLeft: 'textAlignLeft',
  editorAlignRight: 'textAlignRight',
  editorBold: 'textBold',
  editorChecklist: 'listCheck',
  editorCodeBlock: 'code',
  editorDistributeHorizontal: 'distributeHorizontal', // Ember pick
  editorDistributeVertical: 'distributeVertical', // Ember pick
  editorHeading: 'textHeading',
  editorItalic: 'textItalic',
  editorItemAlignBottom: 'alignBottom', // Ember pick
  editorItemAlignCenter: 'alignCenterHorizontal', // Ember pick
  editorItemAlignLeft: 'alignLeft', // Ember pick
  editorItemAlignMiddle: 'alignCenterVertical', // Ember pick
  editorItemAlignRight: 'alignRight', // Ember pick
  editorItemAlignTop: 'alignTop', // Ember pick
  editorLink: 'link',
  editorOrderedList: 'listNumber',
  editorPositionBottomLeft: 'alignBottomLeft', // Ember pick
  editorPositionBottomRight: 'alignBottomRight', // Ember pick
  editorPositionTopLeft: 'alignTopLeft', // Ember pick
  editorPositionTopRight: 'alignTopRight', // Ember pick
  editorRedo: 'redo',
  editorStrike: 'textStrike',
  editorTable: 'table',
  editorUnderline: 'textUnderline',
  editorUndo: 'undo',
  editorUnorderedList: 'listBullet',
  email: 'mail',
  eql: 'query',
  exit: 'logOut',
  expand: 'maximize',
  expandMini: 'maximize',
  exportAction: 'upload',
  eyeClosed: 'eyeSlash',
  glasses: 'readOnly',
  grab: 'dragVertical',
  grabHorizontal: 'dragHorizontal',
  heatmap: 'chartHeatmap',
  iInCircle: 'info',
  importAction: 'download',
  indexMapping: 'mapping',
  indexTemporary: 'tableTime',
  invert: 'contrast',
  kqlField: 'queryField',
  kqlOperand: 'queryOperand',
  kqlSelector: 'querySelector',
  kqlValue: 'queryValue',
  launch: 'rocket',
  lettering: 'text',
  lineDashed: 'lineDash',
  lineDotted: 'lineDot',
  logstashIf: 'if',
  logstashQueue: 'queue',
  magnifyWithExclamation: 'magnifyExclamation', // Ember pick
  magnifyWithMinus: 'magnifyMinus', // Ember pick
  magnifyWithPlus: 'magnifyPlus', // Ember pick
  minusInCircle: 'minusCircle',
  offline: 'wifiSlash',
  online: 'wifi',
  plusInCircle: 'plusCircle',
  popout: 'external',
  questionInCircle: 'question',
  returnKey: 'return',
  starFilledSpace: 'starFill', // Ember pick
  starMinusFilled: 'starMinusFill', // Ember pick
  starPlusFilled: 'starPlusFill', // Ember pick
  stopFilled: 'stopFill', // Ember pick
  submodule: 'merge',
  tableDensityCompact: 'tableDensityHigh',
  tableDensityExpanded: 'tableDensityLow',
  tableDensityNormal: 'table',
  timeRefresh: 'refreshTime',
  timeslider: 'clockControl',
  training: 'presentation',
  unlink: 'linkSlash',
  userAvatar: 'user',
  vector: 'vectorSquare',
  visAreaStacked: 'chartAreaStack',
  visBarHorizontal: 'chartBarHorizontal',
  visBarHorizontalStacked: 'chartBarHorizontalStack',
  visBarVerticalStacked: 'chartBarVerticalStack',
  visMapCoordinate: 'waypoint',
  visMapRegion: 'map',
  visMetric: 'chartMetric',
  visTagCloud: 'chartTagCloud',
  visText: 'text',
  visVega: 'code',
  tokenDenseVector: 'tokenVectorDense',};

/**
 * Ember icon names without an upstream 123 equivalent. They keep their
 * previous (pre-Borealis) artwork from vendor/icon/svgs/legacy.
 */
const LEGACY_ASSETS = {
  boxesHorizontal: 'boxes_horizontal',
  branchUser: 'branchUser',
  continuityAboveBelow: 'continuityAboveBelow',
  continuityBelow: 'continuityBelow',
  documentEdit: 'documentEdit',
  filterInCircle: 'filterInCircle',
  function: 'function',
  indexFlush: 'index_flush',
  listAdd: 'list_add',
  magnet: 'magnet',
  minusInCircleFilled: 'minus_in_circle_filled',
  node: 'node',
  pageSelect: 'pageSelect',
  playFilled: 'playFilled',
  plusInCircleFilled: 'plus_in_circle_filled',
  securitySignal: 'securitySignal',
  securitySignalResolved: 'securitySignalResolved',
  tear: 'tear',};

function upstreamDir() {
  const pkg = realpathSync(join(root, 'node_modules/@elastic/eui'));
  const { version } = JSON.parse(readFileSync(join(pkg, 'package.json'), 'utf8'));

  if (version !== UPSTREAM_VERSION) {
    throw new Error(`Expected @elastic/eui ${UPSTREAM_VERSION}, found ${version}`);
  }

  return join(pkg, 'es/components/icon');
}

/** Upstream `typeToPathMap` entries in order: name, asset, deprecation. */
function readUpstreamMap(iconDir) {
  const source = readFileSync(join(iconDir, 'icon_map.js'), 'utf8');
  const start = source.indexOf('export var typeToPathMap = {');
  const body = source.slice(start, source.indexOf('\n};', start));
  const entries = [
    ...body.matchAll(
      /^ {2}(\w+): (?:withMetadata\()?function[^{]*\{\s*return import\('\.\/assets\/([^']+)'\);/gm
    )
  ];

  if (start < 0 || entries.length === 0) {
    throw new Error('Could not read typeToPathMap from upstream icon_map.js');
  }

  return entries.map((match, i) => {
    // babel moves upstream's trailing `// Deprecated …` comment below the entry
    const rest = body.slice(match.index, entries[i + 1]?.index ?? body.length);
    const comment = rest.match(/\/\/ (Deprecated[^\n]*)/)?.[1];

    return {
      name: match[1],
      asset: match[2],
      deprecated: comment !== undefined,
      replacement: comment?.match(/`(\w+)`/)?.[1] ?? null
    };
  });
}

/** Relative svg paths (without `.svg`) under `dir`, recursively. */
function svgFiles(dir, prefix = '') {
  return readdirSync(join(dir, prefix), { withFileTypes: true }).flatMap((entry) => {
    const path = prefix ? `${prefix}/${entry.name}` : entry.name;

    if (entry.isDirectory()) return svgFiles(dir, path);

    return entry.name.endsWith('.svg') ? [path.slice(0, -'.svg'.length)] : [];
  });
}

const check = process.argv.includes('--check');
const iconDir = upstreamDir();

// relative path under vendor/icon/svgs → upstream source file
const sources = new Map(
  svgFiles(join(iconDir, 'svgs')).map((path) => [path, join(iconDir, 'svgs', `${path}.svg`)])
);

for (const file of Object.values(NOTIFICATION_ICONS)) {
  sources.set(`notification/${file}`, join(iconDir, '../notification_icon/svgs', `${file}.svg`));
}

function svgPath(asset) {
  for (const path of [asset, `tokens/${asset}`]) {
    if (sources.has(path)) return path;
  }

  throw new Error(`No svg for upstream asset "${asset}"`);
}

const stale = [];

if (check) {
  const local = svgFiles(svgDir).filter((path) => !path.startsWith('legacy/'));

  for (const path of local) if (!sources.has(path)) stale.push(`extra svgs/${path}.svg`);

  for (const [path, from] of sources) {
    const to = join(svgDir, `${path}.svg`);

    if (!existsSync(to) || !readFileSync(to).equals(readFileSync(from))) {
      stale.push(`svgs/${path}.svg`);
    }
  }
} else {
  for (const entry of readdirSync(svgDir)) {
    if (entry !== 'legacy') rmSync(join(svgDir, entry), { recursive: true });
  }

  for (const [path, from] of sources) cpSync(from, join(svgDir, `${path}.svg`));
}

const upstream = readUpstreamMap(iconDir);
const paths = new Map(upstream.map(({ name, asset }) => [name, svgPath(asset)]));

for (const [name, file] of Object.entries(NOTIFICATION_ICONS)) {
  if (paths.has(name)) throw new Error(`Notification icon "${name}" is in the icon map`);
  paths.set(name, `notification/${file}`);
}

for (const [name, target] of Object.entries(LEGACY_ALIASES)) {
  if (paths.has(name)) throw new Error(`Legacy alias "${name}" is an upstream name`);
  if (!paths.has(target)) throw new Error(`Alias "${name}" → unknown icon "${target}"`);
}

for (const [name, file] of Object.entries(LEGACY_ASSETS)) {
  if (paths.has(name)) throw new Error(`Legacy icon "${name}" is an upstream name`);
  if (!existsSync(join(svgDir, `legacy/${file}.svg`))) {
    throw new Error(`Missing vendor/icon/svgs/legacy/${file}.svg`);
  }
}

const key = (name) => (/^\w+$/.test(name) ? name : `'${name}'`);
const map = [
  ...[...paths],
  ...Object.entries(LEGACY_ALIASES).map(([name, target]) => [name, paths.get(target)]),
  ...Object.entries(LEGACY_ASSETS).map(([name, file]) => [name, `legacy/${file}`])
];
const deprecated = upstream.filter((entry) => entry.deprecated);

const block = `// <generated by scripts/update-eui-icons.mjs: do not edit by hand>

/**
 * Every named icon and its svg under vendor/icon/svgs (without \`.svg\`):
 * the ${upstream.length} icons of upstream EUI ${UPSTREAM_VERSION} (upstream's order) and its
 * ${Object.keys(NOTIFICATION_ICONS).length} EuiNotificationIcon glyphs, then
 * ${Object.keys(LEGACY_ALIASES).length} legacy Ember names that render an upstream icon
 * (\`legacyIconAliases\`) and ${Object.keys(LEGACY_ASSETS).length} legacy names that keep their previous
 * artwork (\`legacyIconTypes\`).
 */
export const typeToPathMap = {
${map.map(([name, path]) => `  ${key(name)}: '${path}'`).join(',\n')}
};

/**
 * Upstream names that upstream deprecated, with the replacement upstream
 * names (\`null\`: no replacement or a contextual one). They still render.
 */
export const deprecatedIconTypes: Partial<
  Record<keyof typeof typeToPathMap, keyof typeof typeToPathMap | null>
> = {
${deprecated.map(({ name, replacement }) => `  ${key(name)}: ${replacement ? `'${replacement}'` : 'null'}`).join(',\n')}
};

/**
 * Ember icon names that upstream renamed or dropped → the upstream icon they
 * render (the same svg).
 */
export const legacyIconAliases = {
${Object.entries(LEGACY_ALIASES).map(([name, target]) => `  ${key(name)}: '${target}'`).join(',\n')}
} as const satisfies Partial<Record<string, keyof typeof typeToPathMap>>;

/**
 * Ember icon names without an upstream equivalent; they keep their previous
 * artwork (vendor/icon/svgs/legacy).
 */
export const legacyIconTypes = [
${Object.keys(LEGACY_ASSETS).map((name) => `  '${name}'`).join(',\n')}
] as const;

// </generated>`;

const source = readFileSync(mappingFile, 'utf8');
const pattern =
  /\/\/ <generated by scripts\/update-eui-icons\.mjs[^\n]*>[\s\S]*?\/\/ <\/generated>|export const typeToPathMap = \{[\s\S]*?\n\};/;

if (!pattern.test(source)) throw new Error(`No icon block in ${mappingFile}`);

const updated = source.replace(pattern, block);

if (check) {
  if (updated !== source) stale.push('src/utils/css-mappings/eui-icon.ts');

  if (stale.length > 0) {
    console.error(`Stale icons (run node scripts/update-eui-icons.mjs):\n${stale.join('\n')}`);
    process.exit(1);
  }
} else {
  writeFileSync(mappingFile, updated);
}

console.log(
  `${upstream.length} upstream icons (${deprecated.length} deprecated upstream), ` +
    `${Object.keys(NOTIFICATION_ICONS).length} notification icons, ` +
    `${Object.keys(LEGACY_ALIASES).length} legacy aliases, ` +
    `${Object.keys(LEGACY_ASSETS).length} legacy assets: ${map.length} names`
);
