/**
 * Writes the "API reference" section of the docs pages from the components'
 * TypeScript signatures: every argument with its type, default and the
 * JSDoc comment written above it, the named blocks, and where attributes go.
 *
 * Which components a page documents is listed in
 * scripts/api-docs-pages.json (`{ "packages/core/docs/…/index.md":
 * ["EuiButton", …] }`). The section is written between
 * `<!-- api:start -->` and `<!-- api:end -->` at the end of the page
 * (added if missing), so re-running the script only updates it:
 *
 *   node scripts/generate-api-docs.mjs          update every page
 *   node scripts/generate-api-docs.mjs --check  exit 1 if a page is stale
 *
 * The parser reads the signature's source text; it does not type-check.
 * `@private` args are left out and `@deprecated` ones listed last. Args
 * inherited through `OtherSignature['Args'] &` are mentioned by name.
 */
import { existsSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const pages = JSON.parse(
  readFileSync(join(root, 'scripts/api-docs-pages.json'), 'utf8')
);

const START = '<!-- api:start -->';
const END = '<!-- api:end -->';

/* ---------------------------------------------------------------------- */
/* finding a component's source file                                       */
/* ---------------------------------------------------------------------- */

function walk(dir) {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);

    return statSync(path).isDirectory() ? walk(path) : [path];
  });
}

const sources = walk(join(root, 'packages'))
  .filter((file) => /\/src\/components\/.*\.(gts|gjs)$/.test(file))
  .filter((file) => !file.includes('/node_modules/'));

function kebab(name) {
  return name.replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase();
}

/** Components whose file name doesn't follow from their name. */
const ALIASES = {
  EuiSplitPanelOuter: 'eui-split-panel/outer',
  EuiSplitPanelInner: 'eui-split-panel/inner'
};

/** `EuiButton` → packages/core/src/components/eui-button.gts */
function sourceOf(component) {
  if (ALIASES[component]) {
    const match = sources.find((path) =>
      path.endsWith(`/${ALIASES[component]}.gts`)
    );

    if (match) return match;
  }

  for (const extension of ['gts', 'gjs']) {
    const file = `${kebab(component)}.${extension}`;
    const matches = sources.filter((path) => path.endsWith(`/${file}`));

    if (matches.length === 1) return matches[0];

    // a public component is directly in a components folder; the others
    // are private parts of another component (in its own folder)
    const topLevel = matches.filter((path) => path.endsWith(`/components/${file}`));

    if (topLevel.length === 1) return topLevel[0];
    if (matches.length > 1) throw new Error(`Several ${file}: ${matches}`);
  }

  throw new Error(`No source file for ${component}`);
}

/* ---------------------------------------------------------------------- */
/* reading TypeScript declarations as text                                 */
/* ---------------------------------------------------------------------- */

const OPEN = { '{': '}', '(': ')', '[': ']', '<': '>' };
const CLOSE = new Set(['}', ')', ']', '>']);

/** Index just past the bracket closing the one at `start`. */
function closingIndex(text, start) {
  let depth = 0;

  for (let i = start; i < text.length; i++) {
    const char = text[i];

    if (char === '>' && text[i - 1] === '=') continue; // arrow `=>`
    if (OPEN[char]) depth++;
    else if (CLOSE.has(char)) {
      depth--;
      if (depth === 0) return i + 1;
    }
  }

  throw new Error('Unbalanced brackets');
}

/** Body of `interface Name … {` or `type Name = … {` in the file. */
function declaration(source, name) {
  const pattern = new RegExp(
    `(?:interface\\s+${name}\\b[^{]*|type\\s+${name}\\s*(?:<[^>]*>)?\\s*=)`
  );
  const match = pattern.exec(source);

  if (!match) return undefined;

  const start = match.index + match[0].length;

  // a type alias may be an intersection: `CommonArgs & { … }`
  const rest = source.slice(start);
  const end = rest.search(/[;{]/);
  const head = rest.slice(0, end);

  if (rest[end] === ';') return { head, body: undefined };

  const open = start + end;

  return { head, body: source.slice(open + 1, closingIndex(source, open) - 1) };
}

/** Splits a `{ … }` body into members: `{ name, optional, type, doc }`. */
function members(body) {
  const result = [];
  let doc = '';
  let i = 0;

  while (i < body.length) {
    if (body.startsWith('/**', i)) {
      const end = body.indexOf('*/', i);

      doc = body.slice(i + 3, end);
      i = end + 2;
      continue;
    }

    if (body.startsWith('//', i)) {
      i = body.indexOf('\n', i);
      if (i === -1) break;
      continue;
    }

    if (body.startsWith('/*', i)) {
      i = body.indexOf('*/', i) + 2;
      continue;
    }

    const match = /^\s*['"]?([@\w-]+)['"]?(\?)?\s*:/.exec(body.slice(i));

    if (!match) {
      i++;
      continue;
    }

    // the type runs until a `;` or a newline at depth 0
    let j = i + match[0].length;
    let depth = 0;

    for (; j < body.length; j++) {
      const char = body[j];

      if (char === '>' && body[j - 1] === '=') continue;
      if (OPEN[char]) depth++;
      else if (CLOSE.has(char)) depth--;
      else if (depth === 0 && (char === ';' || char === '\n')) {
        // a type can continue on the next line around `|` or `&`
        const next = body.slice(j + 1).trimStart();
        const before = body.slice(i + match[0].length, j).trimEnd();

        if (char === '\n' && (/^[|&]/.test(next) || /[|&]$/.test(before))) {
          continue;
        }
        break;
      }
    }

    result.push({
      name: match[1],
      optional: Boolean(match[2]),
      type: body.slice(i + match[0].length, j).trim(),
      doc: cleanDoc(doc)
    });
    doc = '';
    i = j + 1;
  }

  return result;
}

function cleanDoc(doc) {
  return doc
    .split('\n')
    .map((line) => line.replace(/^\s*\*\s?/, '').trimEnd())
    .join('\n')
    .trim();
}

/** The signature of a component: its `Args`, `Blocks` and `Element`. */
function signature(source, component) {
  const candidates = [
    `${component}Signature`,
    `${component}ComponentSignature`,
    `${component.replace(/^Eui/, '')}Signature`
  ];

  // `extends Component<XSignature>` / `TemplateOnlyComponent<XSignature>`
  const used = /(?:Component|TemplateOnlyComponent)<\s*(\w+)\s*>/.exec(source);

  if (used) candidates.unshift(used[1]);

  for (const name of candidates) {
    const found = declaration(source, name);

    if (!found?.body) continue;

    const parts = Object.fromEntries(
      members(found.body).map((member) => [member.name, member])
    );

    // args-only signature, e.g. `Component<EuiSuperDatePickerArgs>`
    if (!parts.Args && !parts.Blocks && !parts.Element) {
      return { name, args: { type: name }, blocks: undefined, element: undefined, doc: docBefore(source, name) };
    }

    return {
      name,
      args: parts.Args,
      blocks: parts.Blocks,
      element: parts.Element,
      doc: docBefore(source, name)
    };
  }

  return undefined;
}

/** The JSDoc comment right above `interface Name` / `type Name`. */
function docBefore(source, name) {
  const match = new RegExp(`(/\\*\\*(?:(?!\\*/)[\\s\\S])*\\*/)\\s*(?:export\\s+)?(?:interface|type)\\s+${name}\\b`).exec(source);

  return match ? cleanDoc(match[1].slice(3, -2)) : '';
}

/**
 * Resolves an `Args` type expression to its own members plus the names of
 * other signatures it includes.
 */
function resolveArgs(source, typeText, seen = new Set()) {
  const own = [];
  const inherited = [];

  for (const part of splitIntersection(typeText)) {
    const trimmed = part.trim();

    if (trimmed.startsWith('{')) {
      // mapped type `{ [K in keyof X]: X[K] }`
      const mapped = /\[\w+ in keyof (\w+)\]/.exec(trimmed);

      if (mapped) {
        own.push(...resolveArgs(source, mapped[1], seen).own);
      } else {
        own.push(...members(trimmed.slice(1, -1)));
      }
    } else if (/^\w+$/.test(trimmed)) {
      if (seen.has(trimmed)) continue;
      seen.add(trimmed);

      const found = declaration(source, trimmed);

      if (found) {
        const nested = resolveArgs(
          source,
          `${found.head.replace(/^.*\bextends\b/s, '').replace(/[\s=]+$/, '')}${found.body !== undefined ? ` & {${found.body}}` : ''}`
            .replace(/^\s*&\s*/, ''),
          seen
        );

        own.push(...nested.own);
        inherited.push(...nested.inherited);
      } else if (trimmed !== 'CommonArgs') {
        inherited.push(trimmed);
      }
    } else {
      const other = /^(\w+?)(?:Component)?Signature\['Args'\]/.exec(trimmed);
      const omit = /^Omit<\s*(\w+?)(?:Component)?(?:Signature\['Args'\]|Args)/.exec(trimmed);
      const name = other?.[1] ?? omit?.[1];

      if (name) inherited.push(name.startsWith('Eui') ? name : `Eui${name}`);
    }
  }

  return { own, inherited };
}

function splitIntersection(text) {
  const parts = [];
  let depth = 0;
  let current = '';

  for (let i = 0; i < text.length; i++) {
    const char = text[i];

    if (char === '>' && text[i - 1] === '=') {
      current += char;
      continue;
    }
    if (OPEN[char]) depth++;
    else if (CLOSE.has(char)) depth--;

    if (char === '&' && depth === 0) {
      parts.push(current);
      current = '';
    } else {
      current += char;
    }
  }

  parts.push(current);

  return parts.filter((part) => part.trim());
}

/* ---------------------------------------------------------------------- */
/* rendering                                                               */
/* ---------------------------------------------------------------------- */

const TAGS = {
  HTMLButtonElement: 'button',
  HTMLAnchorElement: 'a',
  HTMLInputElement: 'input',
  HTMLTextAreaElement: 'textarea',
  HTMLSelectElement: 'select',
  HTMLDivElement: 'div',
  HTMLSpanElement: 'span',
  HTMLUListElement: 'ul',
  HTMLLIElement: 'li',
  HTMLFieldSetElement: 'fieldset',
  HTMLLegendElement: 'legend',
  HTMLLabelElement: 'label',
  HTMLFormElement: 'form',
  HTMLHRElement: 'hr',
  HTMLImageElement: 'img',
  HTMLOListElement: 'ol',
  HTMLProgressElement: 'progress',
  HTMLHeadingElement: 'h1…h6',
  HTMLParagraphElement: 'p',
  SVGSVGElement: 'svg',
  SVGElement: 'svg'
};

function elementNote(element) {
  if (!element) return '';

  const tags = [...element.type.matchAll(/\b(HTML\w+Element|SVG\w*Element)\b/g)]
    .map(([, name]) => TAGS[name])
    .filter(Boolean);
  const unique = [...new Set(tags)];

  if (unique.length === 0) return '';

  return `HTML attributes and modifiers (\`class\`, \`data-test-*\`, \`{{on …}}\`) are applied to its \`<${unique.join('>` / `<')}>\`.`;
}

function escapeCell(text) {
  return text.replace(/\|/g, '\\|').replace(/\n+/g, ' ').trim();
}

/** Short, readable type, or '' when the description says it better. */
function displayType(type) {
  const flat = type.replace(/\s+/g, ' ').trim();

  if (/keyof typeof|\['Args'\]|\['Blocks'\]|Signature\b|ReturnType|typeof /.test(flat)) return '';
  if (flat.length > 48) return '';

  return `\`${flat.replace(/\|/g, '\\|')}\``;
}

function splitDefault(doc) {
  const match = /\s*Defaults to\s+([\s\S]+?)\.(?:\s|$)/.exec(doc);

  if (!match) return { doc, def: '' };

  return {
    doc: (doc.slice(0, match.index) + ' ' + doc.slice(match.index + match[0].length)).trim(),
    def: match[1].replace(/\s+/g, ' ')
  };
}

function renderArgs(args) {
  const visible = args.filter((arg) => !/@private\b/.test(arg.doc));
  const current = visible.filter((arg) => !/@deprecated\b/.test(arg.doc));
  const deprecated = visible.filter((arg) => /@deprecated\b/.test(arg.doc));

  if (current.length === 0 && deprecated.length === 0) return '';

  const rows = current.map((arg) => {
    const { doc, def } = splitDefault(arg.doc);
    const required = arg.optional ? '' : ' (required)';

    return `| \`@${arg.name}\`${required} | ${displayType(arg.type)} | ${escapeCell(def)} | ${escapeCell(doc)} |`;
  });

  let out = `| Argument | Type | Default | Description |\n| --- | --- | --- | --- |\n${rows.join('\n')}\n`;

  if (deprecated.length) {
    out += `\nDeprecated: ${deprecated
      .map((arg) => `\`@${arg.name}\` (${escapeCell(arg.doc.replace(/@deprecated\s*/, ''))})`)
      .join('; ')}.\n`;
  }

  return out;
}

function renderBlocks(blocks) {
  const visible = blocks.filter(
    (block) => block.doc && !/^Unused\b/.test(block.doc) && !/@private\b/.test(block.doc)
  );

  if (visible.length === 0) return '';

  const rows = visible.map((block) => {
    const name = block.name === 'default' ? 'default block' : `\`<:${block.name}>\``;

    return `| ${name} | ${escapeCell(block.doc)} |`;
  });

  return `| Block | Description |\n| --- | --- |\n${rows.join('\n')}\n`;
}

function renderComponent(component) {
  const file = sourceOf(component);
  const source = readFileSync(file, 'utf8');

  if (file.endsWith('.gjs')) {
    // no TypeScript signature: use the class's JSDoc
    const match = /\/\*\*((?:(?!\*\/)[\s\S])*)\*\/\s*export default class/.exec(source);
    const doc = match ? cleanDoc(match[1]).split(/\n\s*\n(?=The flatpickr lifecycle)/)[0] : '';

    return `### ${component}\n\n${doc}\n`;
  }

  const sig = signature(source, component);

  if (!sig) throw new Error(`No signature found for ${component} in ${file}`);

  const parts = [`### ${component}`];

  if (sig.doc) parts.push(sig.doc.replace(/^@private\s*/, ''));

  if (sig.args) {
    const { own, inherited } = resolveArgs(source, sig.args.type);
    const table = renderArgs(own);

    if (table) parts.push(table.trimEnd());
    if (inherited.length) {
      parts.push(
        `Also takes the args of ${[...new Set(inherited)].map((name) => `\`${name}\``).join(', ')}.`
      );
    }
  }

  if (sig.blocks?.type.trim().startsWith('{')) {
    const table = renderBlocks(members(sig.blocks.type.trim().slice(1, -1)));

    if (table) parts.push(table.trimEnd());
  }

  const note = elementNote(sig.element);

  if (note) parts.push(note);

  return `${parts.join('\n\n')}\n`;
}

function renderSection(components) {
  const body = components.map(renderComponent).join('\n');

  return `${START}
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
\`scripts/generate-api-docs.mjs\`.

${body}
</EuiText>
${END}`;
}

/* ---------------------------------------------------------------------- */

// `--print EuiButton EuiBadge`: print the sections instead of writing pages
if (process.argv.includes('--print')) {
  const names = process.argv.slice(process.argv.indexOf('--print') + 1);

  for (const name of names) console.log(renderComponent(name));
  process.exit(0);
}

let stale = [];

for (const [page, components] of Object.entries(pages)) {
  const path = join(root, page);

  if (!existsSync(path)) throw new Error(`Missing page ${page}`);

  const markdown = readFileSync(path, 'utf8');
  const section = renderSection(components);
  let next;

  if (markdown.includes(START)) {
    next =
      markdown.slice(0, markdown.indexOf(START)) +
      section +
      markdown.slice(markdown.indexOf(END) + END.length);
  } else {
    next = `${markdown.trimEnd()}\n\n${section}\n`;
  }

  if (next !== markdown) {
    stale.push(relative(root, path));
    if (!process.argv.includes('--check')) writeFileSync(path, next);
  }
}

if (process.argv.includes('--check')) {
  if (stale.length) {
    console.error(`API reference out of date in:\n${stale.join('\n')}`);
    process.exit(1);
  }
} else {
  console.log(`updated ${stale.length} of ${Object.keys(pages).length} pages`);
}
