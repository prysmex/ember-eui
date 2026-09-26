import plugin from '@docfy/core/lib/plugin.js';

/**
 * @docfy/ember-vite renders every markdown page as a strict-mode `.gjs`
 * template, so components and helpers used in the prose (outside demos) must
 * be imported. The docs were written for the classic resolver, where
 * `<EuiText>` or `{{t "..."}}` just worked.
 *
 * This plugin scans each rendered page and adds the imports it needs, so the
 * markdown stays unchanged:
 * - `<EuiXxx>` components come from `@ember-eui/core/components`
 * - site components listed in SITE_COMPONENTS come from `site/components/*`
 * - helpers listed in HELPERS come from their packages
 *
 * Demo blocks are not affected: docfy emits them as colocated `.hbs` + `.js`
 * components, which the classic resolver still handles.
 */
const SITE_COMPONENTS = {
  Changelog: 'site/components/changelog',
  IconGallery: 'site/components/icon-gallery',
  TodoText: 'site/components/todo-text',
};

const HELPERS = {
  t: 'ember-intl',
  set: 'ember-set-helper',
  eq: 'ember-truth-helpers',
  not: 'ember-truth-helpers',
  and: 'ember-truth-helpers',
  or: 'ember-truth-helpers',
  array: '@ember/helper',
  hash: '@ember/helper',
  fn: '@ember/helper',
  concat: '@ember/helper',
  get: '@ember/helper',
  on: '@ember/modifier',
};

const TAG = /<([A-Z][A-Za-z0-9]*)[\s/>]/g;
const HELPER = /(?:\{\{#?|\()([a-z][\w-]*)[\s})]/g;

export function importsFor(rendered) {
  const imports = [];
  const seen = new Set();
  const named = new Map();

  for (const [, tag] of rendered.matchAll(TAG)) {
    if (seen.has(tag)) continue;
    seen.add(tag);

    if (tag.startsWith('Eui')) {
      named.set('@ember-eui/core/components', [
        ...(named.get('@ember-eui/core/components') ?? []),
        tag,
      ]);
    } else if (SITE_COMPONENTS[tag]) {
      imports.push({ name: tag, path: SITE_COMPONENTS[tag], isDefault: true });
    }
  }

  for (const [, helper] of rendered.matchAll(HELPER)) {
    if (seen.has(helper) || !HELPERS[helper]) continue;
    seen.add(helper);
    named.set(HELPERS[helper], [...(named.get(HELPERS[helper]) ?? []), helper]);
  }

  for (const [path, names] of named) {
    imports.push({
      name: names[0],
      path,
      isDefault: false,
      namedImports: names,
    });
  }

  return imports;
}

/**
 * Template source of a page: component tags and mustaches live in the `raw`
 * and `text` nodes of the hast tree. Code (`<code>`, `<pre>`) is skipped:
 * docfy escapes it, so `<EuiFoo>` written in backticks is text, not an
 * invocation. (`page.rendered` is only filled in by docfy's own
 * renderMarkdown plugin, which always runs last.)
 */
function templateSource(node) {
  if (node.type === 'raw' || node.type === 'text') {
    return node.value;
  }

  if (node.type === 'element' && ['code', 'pre'].includes(node.tagName)) {
    return '';
  }

  return (node.children ?? []).map(templateSource).join(' ');
}

export default plugin({
  runAfter(ctx) {
    ctx.pages.forEach((page) => {
      const imports = importsFor(templateSource(page.ast));

      if (imports.length) {
        page.pluginData.imports = [
          ...(page.pluginData.imports ?? []),
          ...imports,
        ];
      }
    });
  },
});
