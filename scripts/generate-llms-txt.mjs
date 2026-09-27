/**
 * Writes site/public/llms.txt and site/public/llms-full.txt
 * (https://llmstxt.org): the docs as plain markdown for language models.
 *
 * - llms.txt: what Ember EUI is, the rules that trip people (and models)
 *   up, and an index of every docs page.
 * - llms-full.txt: every page's text, examples (with their code) and API
 *   reference, in one file.
 *
 * Both are built from the same markdown files docfy renders (docs/ and
 * packages/*\/docs), so they follow the docs. Run by the site's build:
 *
 *   node scripts/generate-llms-txt.mjs
 */
import { existsSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const SITE = 'https://ember-eui.vercel.app';
const PACKAGES = ['core', 'changeset-form', 'validated-form', 'pikaday', 'flatpickr'];

function walk(dir) {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);

    return statSync(path).isDirectory() ? walk(path) : [path];
  });
}

/* ---------------------------------------------------------------------- */
/* pages                                                                   */
/* ---------------------------------------------------------------------- */

function frontmatter(markdown) {
  const match = /^---\n([\s\S]*?)\n---\n/.exec(markdown);
  const data = {};

  if (match) {
    for (const line of match[1].split('\n')) {
      const [key, ...value] = line.split(':');

      if (value.length) data[key.trim()] = value.join(':').trim();
    }
  }

  return { data, body: match ? markdown.slice(match[0].length) : markdown };
}

/** Docs pages: markdown files that are not demos, with their URL. */
function pages() {
  const result = [];

  for (const file of walk(join(root, 'docs'))) {
    if (!file.endsWith('.md') || /\/package\/|introduction\.md$/.test(file)) continue;

    const path = relative(join(root, 'docs'), file).replace(/\.md$/, '');

    result.push({ file, url: `${SITE}/docs/${path}`, section: 'Guides' });
  }

  for (const pkg of PACKAGES) {
    const docs = join(root, 'packages', pkg, 'docs');

    if (!existsSync(docs)) continue;

    for (const file of walk(docs)) {
      if (!file.endsWith('.md') || /\/demo\/|-demo\//.test(file)) continue;

      const path = relative(docs, file)
        .replace(/\/index\.md$/, '')
        .replace(/\.md$/, '');

      result.push({ file, url: `${SITE}/docs/${pkg}/docs/${path}`, section: pkg });
    }
  }

  return result
    .map((page) => {
      const { data, body } = frontmatter(readFileSync(page.file, 'utf8'));
      const title =
        /@pageTitle="([^"]+)"/.exec(body)?.[1] ?? data.title ?? page.url.split('/').pop();

      return { ...page, title, order: Number(data.order ?? 99), body, demos: demosOf(page.file) };
    })
    .filter((page) => !/^disabled: true/m.test(readFileSync(page.file, 'utf8')))
    .sort((a, b) =>
      a.section === b.section
        ? a.url.localeCompare(b.url)
        : sectionRank(a.section) - sectionRank(b.section)
    );
}

function sectionRank(section) {
  return section === 'Guides' ? 0 : 1 + PACKAGES.indexOf(section);
}

function demosOf(pageFile) {
  const dir = pageFile.endsWith('/index.md')
    ? join(dirname(pageFile), 'demo')
    : pageFile.replace(/\.md$/, '-demo');

  if (!existsSync(dir)) return [];

  return readdirSync(dir)
    .filter((name) => name.endsWith('.md'))
    .map((name) => {
      const { data, body } = frontmatter(readFileSync(join(dir, name), 'utf8'));

      return { name, order: Number(data.order ?? 99), body };
    })
    .sort((a, b) => a.order - b.order || a.name.localeCompare(b.name));
}

/* ---------------------------------------------------------------------- */
/* markdown cleanup: docfy's template markup → plain markdown             */
/* ---------------------------------------------------------------------- */

const ENTITIES = { '&#123;': '{', '&#125;': '}', '&lt;': '<', '&gt;': '>', '&quot;': '"', '&amp;': '&', '&hellip;': '…', '&rsquo;': '’', '&nbsp;': ' ' };

function decode(text) {
  return text.replace(/&#123;|&#125;|&lt;|&gt;|&quot;|&amp;|&hellip;|&rsquo;|&nbsp;/g, (entity) => ENTITIES[entity]);
}

/** Prose (not code): drop layout components, turn simple HTML into markdown. */
function cleanProse(text) {
  const spans = [];
  // inline code keeps its content as is (it may contain tags)
  const protect = (code) => {
    spans.push(decode(code.trim()));

    return `\u0000${spans.length - 1}\u0000`;
  };

  let out = text
    .replace(/<!--[\s\S]*?-->/g, '')
    .replace(/\{\{'([^']*)'\}\}/g, '$1')
    // backticks first: they may show tags, e.g. `<EuiCode>…</EuiCode>`
    .replace(/`([^`\n]+)`/g, (_, code) => protect(code))
    .replace(/<EuiCode[^>]*>([\s\S]*?)<\/EuiCode>/g, (_, code) => protect(code))
    .replace(/<code[^>]*>([\s\S]*?)<\/code>/g, (_, code) => protect(code))
    .replace(/<EuiPageHeader[^>]*?\/>/g, '')
    .replace(/<EuiSpacer[^>]*?\/>/g, '')
    .replace(/<EuiHorizontalRule[^>]*?\/>/g, '')
    .replace(/<IconGallery\s*\/>/g, '*(An interactive gallery of every icon is on the site.)*')
    // docfy's demo marker; the demos are appended after the prose
    .replace(/^\[\[demos?-?[^\]]*\]\]$/gm, '')
    .replace(/<(strong|b)>([\s\S]*?)<\/\1>/g, '**$2**')
    .replace(/<(em|i)>([\s\S]*?)<\/\1>/g, '*$2*')
    .replace(/<EuiLink[^>]*@href="([^"]+)"[^>]*>([\s\S]*?)<\/EuiLink>/g, '[$2]($1)')
    .replace(/<a [^>]*href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/g, '[$2]($1)')
    .replace(/<EuiCallOut[^>]*@title=['"]([^'"]+)['"][^>]*>/g, '> **$1**\n')
    .replace(/<li>/g, '- ')
    .replace(/<\/(p|li|ul|ol|div)>/g, '\n')
    .replace(/<br\s*\/?>/g, '\n')
    // any other tag (HTML or component): keep its text only
    .replace(/<\/?(?:[a-z][\w-]*|Eui\w+|:\w+)(?:\s[^>]*)?\/?>/g, '');

  out = decode(out);

  // a span can hold another span's placeholder (e.g. <EuiCode> inside
  // backticks): restore until none are left
  while (/\u0000\d+\u0000/.test(out)) {
    out = out.replace(/\u0000(\d+)\u0000/g, (_, i) => `\`${spans[i]}\``);
  }

  return out
    .split('\n')
    .map((line) => line.replace(/^\t+/, '').trimEnd())
    .join('\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

/** Splits markdown into prose and fenced code, cleaning only the prose. */
function clean(markdown) {
  return markdown
    .split(/(```[\s\S]*?```)/g)
    .map((part) => (part.startsWith('```') ? part : cleanProse(part)))
    .join('\n\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

function pageBody(page) {
  const api = page.body.indexOf('<!-- api:start -->');
  const intro = api === -1 ? page.body : page.body.slice(0, api);
  const reference =
    api === -1
      ? ''
      : page.body
          .slice(api, page.body.indexOf('<!-- api:end -->'))
          .replace('<!-- api:start -->', '')
          .replace(/Generated from the components' TypeScript signatures by\s*`scripts\/generate-api-docs.mjs`\./, '')
          .replace(/^## API reference/m, '');

  // a page placing its demos by hand has its own "Examples" heading; each
  // demo below gets an "Example: …" heading anyway
  const parts = [
    `# ${page.title}`,
    `Source: ${page.url}`,
    clean(page.demos.length ? intro.replace(/^## Examples$/m, '') : intro),
  ];

  for (const demo of page.demos) {
    const body = demo.body
      .replace(/```hbs template/g, '```hbs')
      .replace(/```(js|javascript) component/g, '```js');
    const title = /^# (.+)$/m.exec(body)?.[1];

    parts.push(`## Example${title ? `: ${title}` : ''}`);
    parts.push(clean(body.replace(/^# .+$/m, '')));
  }

  if (reference.trim()) {
    parts.push('## API reference');
    parts.push(clean(reference).replace(/^### /gm, '### '));
  }

  return parts.filter(Boolean).join('\n\n');
}

/** First sentence of the page's intro, for the index. */
function summary(page) {
  const api = page.body.indexOf('<!-- api:start -->');
  const text = clean(api === -1 ? page.body : page.body.slice(0, api))
    .split(/```[\s\S]*?```/)[0]
    .replace(/\s+/g, ' ')
    .trim();
  const sentence = /^(.+?[.!?])(\s|$)/.exec(text)?.[1] ?? text;

  return sentence.length > 220 ? `${sentence.slice(0, 217)}…` : sentence;
}

/* ---------------------------------------------------------------------- */

const RULES = `## Rules for using Ember EUI

- Install \`@ember-eui/core\` with its peer dependencies (\`@ember/string\`, \`ember-basic-dropdown\`, \`ember-concurrency\`, \`ember-focus-trap\`, \`ember-power-select\`, \`moment\`) and import a theme once: \`import '@ember-eui/core/themes/light.css'\` (or \`dark.css\`) and \`import '@ember-eui/core/styles/ember-eui.css'\`.
- In \`.gjs\`/\`.gts\`, import components by name: \`import { EuiButton, EuiFormRow } from '@ember-eui/core/components';\`. In classic \`.hbs\` templates they are available without imports.
- Component options are arguments with \`@\` (\`@iconType="check"\`, \`@size="s"\`). Plain HTML attributes and modifiers (\`class\`, \`aria-label\`, \`placeholder\`, \`{{on "click" …}}\`) go to the component's main element. Writing an argument without \`@\` (\`size="s"\`) silently does nothing.
- Form controls don't store their value: pass \`@value\` (or \`@checked\`) and update it from the event, e.g. \`{{on "input" this.update}}\` with \`event.target.value\`. \`EuiSwitch\` calls \`@onChange(event)\`; \`EuiComboBox\` calls \`@onChange(selectedOptions)\` with an array.
- Wrap controls in \`EuiFormRow\` for a label, help text and errors (\`@isInvalid\` + \`@error\`); it links the label to the control automatically.
- \`EuiTitle\` renders the heading itself: \`<EuiTitle @size="s" @tagName="h2">Title</EuiTitle>\`. Don't nest an \`<h2>\` inside it.
- Icons: \`<EuiIcon @type="bell" />\` with EUI's icon names (lazy loaded), or your own svgs imported with \`@svg-jar/plugin\` and passed as \`@type\` / registered in the \`euiIcon.icons\` config. Icon-only buttons (\`EuiButtonIcon\`) need an \`aria-label\`.
- Overlays (EuiModal, EuiFlyout, EuiPopover) are controlled: render modals/flyouts inside \`{{#if this.isOpen}}\` and close them in \`@onClose\`; popovers take \`@isOpen\` and \`@closePopover\`, with the trigger in the \`<:button>\` block and the content in \`<:content>\`.
- Named blocks are used for parts of components (\`<:title>\`, \`<:content>\`, \`<:prepend>\`, …); each page's API reference lists them.`;

const all = pages();

const index = [
  '# Ember EUI',
  '',
  "> Ember components for Elastic's EUI design system: over a hundred accessible, themeable components (buttons, forms, layout, overlays, data display, a markdown editor, date pickers) for Ember apps, as v2 addons.",
  '',
  `Full text of every page, with examples and API references: ${SITE}/llms-full.txt`,
  '',
  RULES,
  '',
  ...[...new Set(all.map((page) => page.section))].flatMap((section) => [
    `## ${section === 'Guides' ? 'Guides' : `@ember-eui/${section}`}`,
    '',
    ...all
      .filter((page) => page.section === section)
      .map((page) => `- [${page.title}](${page.url}): ${summary(page)}`),
    ''
  ])
].join('\n');

const full = [
  '# Ember EUI documentation',
  '',
  `Generated from the docs at ${SITE}. Each section is one page: its explanation, examples (template and component code) and API reference.`,
  '',
  RULES,
  '',
  ...all.map((page) => `${pageBody(page)}\n\n---\n`)
].join('\n');

writeFileSync(join(root, 'site/public/llms.txt'), `${index.trimEnd()}\n`);
writeFileSync(join(root, 'site/public/llms-full.txt'), `${full.trimEnd()}\n`);

console.log(`llms.txt: ${all.length} pages, llms-full.txt: ${Math.round(full.length / 1024)} KB`);
