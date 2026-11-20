// Shared parser for the 3c checks: reads a .ts or .gts file into its
// top-level declarations and class members, each with a canonical form
// that ignores layout (whitespace, line breaks, parentheses Prettier adds)
// and the path in front of a member (`this.`, `this.sheet.`,
// `this.sheet.<module>.`). Needs `typescript` and `content-tag`: set
// CHECKS_NODE_MODULES to a node_modules dir that has both (the Linux
// copy's root node_modules; content-tag is found under its .pnpm).
import { createRequire } from 'node:module';
import { readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const NM = process.env.CHECKS_NODE_MODULES;
if (!NM)
  throw new Error(
    'Set CHECKS_NODE_MODULES to a node_modules dir with typescript'
  );
const require = createRequire(join(NM, 'noop.js'));
export const ts = require('typescript');

function findContentTag() {
  const direct = join(NM, 'content-tag/pkg/node.cjs');
  if (existsSync(direct)) return direct;
  const pnpm = join(NM, '.pnpm');
  const versions = readdirSync(pnpm)
    .filter((d) => d.startsWith('content-tag@'))
    .sort();
  const last = versions.at(-1);
  if (!last) throw new Error('content-tag not found under ' + pnpm);
  return join(pnpm, last, 'node_modules/content-tag/pkg/node.cjs');
}
const { Preprocessor } = require(findContentTag());

/**
 * Replaces each `<template>` with plain TS: a class-member template becomes
 * `static __template = __tpl(`...`);`, an expression one `__tpl(`...`)`.
 * Returns the code and the templates' contents in order.
 */
export function stripTemplates(src, filename) {
  if (!filename.endsWith('.gts')) return { code: src, templates: [] };
  const parsed = new Preprocessor().parse(src, { filename });
  let out = '';
  let at = 0;
  const templates = [];
  for (const t of parsed) {
    const s = t.range.startUtf16Codepoint;
    const e = t.range.endUtf16Codepoint;
    out += src.slice(at, s);
    const lit = '`' + t.contents.replace(/[`\\$]/g, (c) => '\\' + c) + '`';
    out +=
      t.type === 'class-member'
        ? `static __template = __tpl(${lit});`
        : `__tpl(${lit})`;
    templates.push({ type: t.type, contents: t.contents });
    at = e;
  }
  out += src.slice(at);
  return { code: out, templates };
}

/** Whether `node` is `this`, `this.sheet`, `this.<module>` or `this.sheet.<module>`. */
function isHostPath(node, modules) {
  if (node.kind === ts.SyntaxKind.ThisKeyword) return true;
  if (!ts.isPropertyAccessExpression(node)) return false;
  const name = node.name.text;
  if (name === 'sheet')
    return node.expression.kind === ts.SyntaxKind.ThisKeyword;
  if (!modules.has(name)) return false;
  const inner = node.expression;
  // `this.<module>` (the component) or `this.sheet.<module>` (a module)
  if (inner.kind === ts.SyntaxKind.ThisKeyword) return true;
  return (
    ts.isPropertyAccessExpression(inner) &&
    inner.name.text === 'sheet' &&
    inner.expression.kind === ts.SyntaxKind.ThisKeyword
  );
}

/** A template's text with `<path>.<module>.` written `<path>.`, whitespace dropped. */
function normalTemplateText(text, modules) {
  const mods = [...modules].join('|');
  let s = text;
  if (mods)
    s = s.replace(
      new RegExp(
        `((?:@sheet|this\\.sheet|this\\.args\\.sheet|this)\\.)(?:${mods})\\.`,
        'g'
      ),
      '$1'
    );
  return s.replace(/\s+/g, '');
}

/**
 * The canonical form of a node: every token's text, parentheses dropped
 * (the tree keeps precedence), `export` dropped, and a member access on a
 * host path written `THIS.member`.
 */
export function canon(node, sf, modules) {
  const out = [];
  const walk = (n) => {
    if (ts.isParenthesizedExpression(n)) return walk(n.expression);
    if (ts.isParenthesizedTypeNode?.(n)) return walk(n.type);
    if (ts.isPropertyAccessExpression(n) && isHostPath(n.expression, modules)) {
      out.push('THIS', n.questionDotToken ? '?.' : '.', n.name.text);
      return;
    }
    // `<x>.sheet.<module>.member` (a -private component's `this.args.sheet`
    // or `sheet`) is written `<x>.sheet.member`.
    if (
      ts.isPropertyAccessExpression(n) &&
      ts.isPropertyAccessExpression(n.expression) &&
      modules.has(n.expression.name.text) &&
      /(^|\.)sheet$/.test(n.expression.expression.getText(sf))
    ) {
      walk(n.expression.expression);
      out.push(n.questionDotToken ? '?.' : '.', n.name.text);
      return;
    }
    if (n.kind === ts.SyntaxKind.ExportKeyword) return;
    if (n.kind === ts.SyntaxKind.SyntaxList && n.getChildCount(sf) === 0)
      return;
    // A `<template>` inside a declaration (stripTemplates made it
    // `__tpl(`...`)`): only its module paths may change, as for the
    // templates compared on their own (verbatim.mjs normalTemplate).
    if (
      n.kind === ts.SyntaxKind.NoSubstitutionTemplateLiteral &&
      ts.isCallExpression(n.parent) &&
      ts.isIdentifier(n.parent.expression) &&
      n.parent.expression.text === '__tpl'
    ) {
      out.push(normalTemplateText(n.getText(sf), modules));
      return;
    }
    const kids = n.getChildren(sf);
    if (kids.length === 0) {
      if (n.kind === ts.SyntaxKind.EndOfFileToken) return;
      out.push(n.getText(sf));
      return;
    }
    for (const k of kids) walk(k);
  };
  walk(node);
  return out.join(' ');
}

/** The comments inside a text, whitespace collapsed, in order. */
export function commentsOf(text) {
  const found = [];
  const scanner = ts.createScanner(
    ts.ScriptTarget.Latest,
    false,
    ts.LanguageVariant.Standard,
    text
  );
  let tok;
  while ((tok = scanner.scan()) !== ts.SyntaxKind.EndOfFileToken) {
    if (
      tok === ts.SyntaxKind.SingleLineCommentTrivia ||
      tok === ts.SyntaxKind.MultiLineCommentTrivia
    ) {
      found.push(scanner.getTokenText().replace(/\s+/g, ' ').trim());
    }
  }
  return found;
}

function memberKind(m) {
  if (ts.isGetAccessorDeclaration(m)) return 'getter';
  if (ts.isSetAccessorDeclaration(m)) return 'setter';
  if (ts.isMethodDeclaration(m)) return 'method';
  if (ts.isConstructorDeclaration(m)) return 'constructor';
  if (ts.isClassStaticBlockDeclaration(m)) return 'static-block';
  if (ts.isPropertyDeclaration(m)) {
    const init = m.initializer;
    if (init && (ts.isArrowFunction(init) || ts.isFunctionExpression(init)))
      return 'arrow-field';
    if (
      init &&
      ts.isCallExpression(init) &&
      init.expression.getText() === 'modifier'
    )
      return 'modifier';
    return 'field';
  }
  return ts.SyntaxKind[m.kind];
}

function decoratorsOf(m, sf) {
  return (
    (ts.getDecorators?.(m) ?? []).map((d) => d.getText(sf)).join(' ') || 'none'
  );
}

function nameOf(m, sf) {
  if (ts.isConstructorDeclaration(m)) return 'constructor';
  if (!m.name) return null;
  return m.name.getText(sf);
}

/**
 * Parses a file. Returns { tops, classes, templates, sf }:
 * tops: top-level declarations by name ({ name, kind, canon, comments, line });
 * classes: [{ name, members: [{ name, kind, decorators, canon, comments, line, end, static }], isHosted }].
 */
export function parseFile(src, filename, modules) {
  const { code, templates } = stripTemplates(src, filename);
  const sf = ts.createSourceFile(
    filename.replace(/\.gts$/, '.ts'),
    code,
    ts.ScriptTarget.Latest,
    true,
    ts.ScriptKind.TS
  );
  const lineOf = (pos) => sf.getLineAndCharacterOfPosition(pos).line + 1;
  const tops = [];
  const classes = [];
  const addTop = (name, kind, node) => {
    const text = node.getFullText(sf);
    tops.push({
      name,
      kind,
      canon: canon(node, sf, modules),
      comments: commentsOf(text),
      line: lineOf(node.getStart(sf)),
      end: lineOf(node.getEnd())
    });
  };
  for (const st of sf.statements) {
    if (ts.isImportDeclaration(st) || ts.isExportDeclaration(st)) continue;
    if (ts.isClassDeclaration(st)) {
      const name = st.name ? st.name.text : 'default';
      const members = [];
      for (const m of st.members) {
        const mname = nameOf(m, sf);
        if (mname === '__template' || mname === null) continue;
        const text = m.getFullText(sf);
        members.push({
          name: mname,
          kind: memberKind(m),
          decorators: decoratorsOf(m, sf),
          static: !!m.modifiers?.some(
            (x) => x.kind === ts.SyntaxKind.StaticKeyword
          ),
          canon: canon(m, sf, modules),
          comments: commentsOf(text),
          line: lineOf(m.getStart(sf)),
          end: lineOf(m.getEnd())
        });
      }
      const isHosted = members.some(
        (m) => m.name === 'sheet' && m.kind === 'field'
      );
      const isComponent =
        st.heritageClauses?.some((h) => h.getText(sf).includes('Component<')) ??
        false;
      classes.push({
        name,
        members,
        isHosted,
        isComponent,
        line: lineOf(st.getStart(sf)),
        end: lineOf(st.getEnd())
      });
      if (!isHosted && !isComponent) addTop(name, 'class', st);
      continue;
    }
    if (ts.isVariableStatement(st)) {
      const names = st.declarationList.declarations
        .map((d) => d.name.getText(sf))
        .join(',');
      addTop(names, 'var', st);
      continue;
    }
    if (
      ts.isFunctionDeclaration(st) ||
      ts.isInterfaceDeclaration(st) ||
      ts.isTypeAliasDeclaration(st) ||
      ts.isEnumDeclaration(st)
    ) {
      addTop(st.name.text, ts.SyntaxKind[st.kind], st);
      continue;
    }
    addTop('@stmt:' + lineOf(st.getStart(sf)), ts.SyntaxKind[st.kind], st);
  }
  return { tops, classes, templates, sf };
}
