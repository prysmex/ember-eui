import plugin from '@docfy/core/lib/plugin.js';

/**
 * Colours the inline code of the docs' markdown tables (the API tables of
 * scripts/generate-api-docs.mjs and the hand-written ones of the same
 * shape), TypeScript-like, at build time: the code in a "Type" or "Default"
 * column, and argument and block names (`@paddingSize`, `<:append>`) in
 * the first column. Each token becomes a `span.docsTok.docsTok--<kind>`
 * coloured in app.css; the markdown is not changed, and inline code outside
 * tables is left as it is.
 *
 * Runs on the hast, before @docfy/ember-vite's escape-curlies plugin, which
 * escapes `{{` per text node: so the tokenizer never splits `{{` or `}}`.
 */

/** Keywords and primitive types, coloured as the code theme's keywords. */
export const KEYWORDS = new Set([
  'any',
  'bigint',
  'boolean',
  'keyof',
  'never',
  'null',
  'number',
  'object',
  'readonly',
  'string',
  'symbol',
  'typeof',
  'undefined',
  'unknown',
  'void',
]);

/** Coloured as the code theme's booleans (like numbers). */
const BOOLEANS = new Set(['true', 'false']);

const RULES = [
  ['space', /^\s+/],
  ['string', /^'(?:[^'\\]|\\.)*'?/],
  ['string', /^"(?:[^"\\]|\\.)*"?/],
  ['number', /^(?:0[xX][\da-fA-F]+|\d[\d_]*(?:\.\d+)?(?:[eE][+-]?\d+)?)/],
  ['word', /^[A-Za-z_$][\w$]*/],
  [
    'punctuation',
    /^(?:=>|\.\.\.|\?\?|\?\.|\{\{|\}\}|\|\||&&|[|&<>[\](){}:,?.;=*+\-/!%~^#@])/,
  ],
];

/**
 * Splits TypeScript-like text (a type or a default) into tokens:
 * `{ type, value }` with type `keyword`, `boolean`, `string`, `number`,
 * `type` (a capitalised identifier), `punctuation`, or `text` (spaces, other
 * identifiers, property and parameter names, anything else). Their values
 * concatenate to the input.
 */
export function tokenize(source) {
  const raw = [];
  let rest = source;

  while (rest) {
    let match = null;
    let type = 'text';

    for (const [ruleType, pattern] of RULES) {
      match = pattern.exec(rest);
      if (match) {
        type = ruleType;
        break;
      }
    }

    const value = match ? match[0] : String.fromCodePoint(rest.codePointAt(0));

    raw.push({ type, value });
    rest = rest.slice(value.length);
  }

  const significant = (from, step) => {
    for (let i = from; i >= 0 && i < raw.length; i += step) {
      if (raw[i].type !== 'space') return raw[i];
    }

    return undefined;
  };

  const tokens = raw.map((token, index) => {
    if (token.type === 'space') return { type: 'text', value: token.value };
    if (token.type !== 'word') return token;

    const { value } = token;
    const before = significant(index - 1, -1);
    const after = significant(index + 1, 1);
    // `name:` or `name?:` is a property or parameter name; `a.b` a member
    const isName =
      after?.value === ':' ||
      (after?.value === '?' &&
        significant(raw.indexOf(after) + 1, 1)?.value === ':') ||
      before?.value === '.' ||
      before?.value === '?.';

    if (isName) return { type: 'text', value };
    if (KEYWORDS.has(value)) return { type: 'keyword', value };
    if (BOOLEANS.has(value)) return { type: 'boolean', value };
    if (/^[A-Z]/.test(value)) return { type: 'type', value };

    return { type: 'text', value };
  });

  // adjacent text merged: fewer nodes
  return tokens.reduce((merged, token) => {
    const last = merged[merged.length - 1];

    if (last && last.type === 'text' && token.type === 'text') {
      last.value += token.value;
    } else {
      merged.push({ ...token });
    }

    return merged;
  }, []);
}

const ARGUMENT = /^@[A-Za-z_$][\w$-]*$/;
const BLOCK = /^<:[A-Za-z_$][\w$-]*>$/;

const isElement = (node, tagName) =>
  node?.type === 'element' && (!tagName || node.tagName === tagName);

const elements = (node, tagName) =>
  (node.children ?? []).filter((child) => isElement(child, tagName));

const textOf = (node) =>
  node.type === 'text'
    ? node.value
    : (node.children ?? []).map(textOf).join('');

/** The text of a `code` element that holds only text, else null. */
function codeText(code) {
  return code.children.every((child) => child.type === 'text')
    ? code.children.map((child) => child.value).join('')
    : null;
}

const span = (kind, value) => ({
  type: 'element',
  tagName: 'span',
  properties: { className: ['docsTok', `docsTok--${kind}`] },
  children: [{ type: 'text', value }],
});

function highlightCode(code) {
  const source = codeText(code);

  if (source === null) return;
  code.children = tokenize(source).map((token) =>
    token.type === 'text'
      ? { type: 'text', value: token.value }
      : span(token.type, token.value),
  );
}

function nameCode(code) {
  const source = codeText(code);

  if (source === null) return;
  if (ARGUMENT.test(source)) code.children = [span('arg', source)];
  else if (BLOCK.test(source)) code.children = [span('block', source)];
}

/** Every `code` in a cell (also inside a link or emphasis), not nested ones. */
function codesIn(node, found = []) {
  for (const child of node.children ?? []) {
    if (isElement(child, 'code')) found.push(child);
    else if (isElement(child)) codesIn(child, found);
  }

  return found;
}

function highlightTable(table) {
  const head = elements(table, 'thead')[0];
  const headRow = head && elements(head, 'tr')[0];

  if (!headRow) return;

  const columns = elements(headRow).map((cell) =>
    textOf(cell).trim().toLowerCase(),
  );
  const typed = new Set(
    columns
      .map((label, index) => (/^(type|default)$/.test(label) ? index : -1))
      .filter((index) => index >= 0),
  );

  for (const body of elements(table, 'tbody')) {
    for (const row of elements(body, 'tr')) {
      elements(row).forEach((cell, index) => {
        if (typed.has(index)) codesIn(cell).forEach(highlightCode);
        else if (index === 0) codesIn(cell).forEach(nameCode);
      });
    }
  }
}

/** Colours the code in every table of a hast tree. */
export function highlightTables(node) {
  for (const child of node.children ?? []) {
    if (isElement(child, 'table')) highlightTable(child);
    else highlightTables(child);
  }
}

export default plugin({
  runWithHast(ctx) {
    ctx.pages.forEach((page) => highlightTables(page.ast));
  },
});
