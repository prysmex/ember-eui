import type { CSSInterpolation } from '@emotion/css/create-instance';
import type { EuiThemeContext } from '../emotion/context.ts';
import type { EuiBorealisContext } from './theme.ts';

type Factory = (theme: EuiBorealisContext) => unknown;

/**
 * Factory output per resolved theme. `context.upstream` is `@cached`, so a
 * theme change yields a new object (and a fresh cache) while every consumer
 * of an unchanged theme shares one result. Mirrors upstream's
 * `useEuiMemoizedStyles`.
 */
const memo = new WeakMap<EuiBorealisContext, WeakMap<Factory, unknown>>();

/** Factories receive the real computed upstream theme, without React hooks. */
export function useEuiBorealisStyles<T>(
  context: EuiThemeContext,
  factory: (theme: EuiBorealisContext) => T
): T {
  return memoizedStyles(context.upstream, factory);
}

/** Same memoization for callers that already hold a resolved theme. */
export function memoizedStyles<T>(
  theme: EuiBorealisContext,
  factory: (theme: EuiBorealisContext) => T
): T {
  let byFactory = memo.get(theme);
  if (!byFactory) memo.set(theme, (byFactory = new WeakMap()));
  if (!byFactory.has(factory)) byFactory.set(factory, factory(theme));
  return byFactory.get(factory) as T;
}

/**
 * A theme function: the counterpart of upstream's `css` prop callback,
 * `({ euiTheme, colorMode, highContrastMode }) => styles`. It receives the
 * nearest provider's resolved theme; its result is memoized per resolved
 * theme and function identity, so define it once (module scope or a
 * stable class field), not inline in a getter that re-runs.
 */
export type EuiCssFunction = (theme: EuiBorealisContext) => EuiCss;

/**
 * Extra styles a caller composes into a migrated component's own class,
 * last — the Ember counterpart of upstream's `css` prop. An Emotion
 * interpolation (object, string, serialized styles), a theme function, or
 * an array of those. Use it to style a migrated child instead of adding a
 * second class, whose precedence would depend on rule insertion order.
 *
 * Keep values static: each distinct value adds rules that are never removed
 * (Emotion is append-only, as upstream). Put values that change often
 * (data- or animation-driven positions and sizes, per-item colors) in
 * `style` instead.
 */
export type EuiCss =
  | CSSInterpolation
  | EuiCssFunction
  | readonly EuiCss[];

function hasFunction(style: unknown): boolean {
  if (typeof style === 'function') return true;
  return Array.isArray(style) && style.some(hasFunction);
}

function resolveCss(
  theme: EuiBorealisContext,
  style: EuiCss
): CSSInterpolation {
  if (typeof style === 'function')
    return resolveCss(theme, memoizedStyles(theme, style));
  if (Array.isArray(style) && style.some(hasFunction))
    return (style as readonly EuiCss[]).map((s) => resolveCss(theme, s));
  return style as CSSInterpolation;
}

/**
 * Resolve theme functions in `@css`-style values against a context's
 * theme. Only reads `context.upstream` (a tracked dependency) when a
 * function is present.
 */
export function resolveEuiCss(
  context: EuiThemeContext,
  style: EuiCss
): CSSInterpolation {
  return hasFunction(style) ? resolveCss(context.upstream, style) : (style as CSSInterpolation);
}

/**
 * Class names per Emotion cache, in a trie walked with the styles passed to
 * `euiClass`. Serialized styles are a step by identity: upstream's style
 * factories return the same objects for a theme (see memoizedStyles).
 * Plain objects (often literals, a new object each call) are walked by
 * content, a step per property and value. Repeated rows composing the same
 * styles thus find their class without serializing and hashing again. Keyed on the cache's `inserted` record,
 * which `flush()` replaces: a flushed cache starts over, so a remembered
 * class always has its rules in the sheet.
 */
interface ClassNode {
  className?: string;
  values?: Map<unknown, ClassNode>;
  objects?: WeakMap<object, ClassNode>;
}

const classTries = new WeakMap<object, ClassNode>();
const ARRAY_START = Symbol('[');
const ARRAY_END = Symbol(']');
const OBJECT_START = Symbol('{');
const OBJECT_END = Symbol('}');

function isPlainObject(value: object): boolean {
  const prototype = Object.getPrototypeOf(value);

  return prototype === Object.prototype || prototype === null;
}

function step(node: ClassNode, value: unknown): ClassNode {
  let next: ClassNode | undefined;

  if (typeof value === 'object' && value !== null) {
    node.objects ??= new WeakMap();
    next = node.objects.get(value);
    if (!next) node.objects.set(value, (next = {}));
  } else {
    node.values ??= new Map();
    next = node.values.get(value);
    if (!next) node.values.set(value, (next = {}));
  }

  return next;
}

/**
 * The trie node for `style`, or `undefined` when it holds a function (whose
 * result is not known). A string that is a registered class name expands to
 * its styles, so it is keyed apart from the same string as raw css.
 */
function walk(
  node: ClassNode,
  style: unknown,
  registered: Record<string, unknown>
): ClassNode | undefined {
  if (Array.isArray(style)) {
    let next: ClassNode | undefined = step(node, ARRAY_START);

    for (const item of style) {
      next = walk(next, item, registered);
      if (!next) return undefined;
    }

    return step(next, ARRAY_END);
  }

  if (typeof style === 'function') return undefined;

  if (typeof style === 'string') {
    return step(node, (registered[style] === undefined ? 's' : 'r') + style);
  }

  if (typeof style === 'object' && style !== null && isPlainObject(style)) {
    const { name, styles } = style as { name?: unknown; styles?: unknown };

    if (typeof name !== 'string' || typeof styles !== 'string') {
      let next: ClassNode | undefined = step(node, OBJECT_START);

      for (const [property, value] of Object.entries(style)) {
        next = walk(step(next, property), value, registered);
        if (!next) return undefined;
      }

      return step(next, OBJECT_END);
    }
  }

  return step(node, style);
}

/**
 * Compose serialized upstream styles into a class in the provider-owned
 * cache. Theme functions anywhere in `styles` (e.g. a caller's `@css`) are
 * resolved here against the context's theme, so every component that
 * composes `@css` through `euiClass` supports them.
 *
 * The class is remembered per cache and styles (by identity), so rows of a
 * list or table composing the same styles serialize and hash them once.
 */
export function euiClass(context: EuiThemeContext, ...styles: EuiCss[]): string {
  const resolved = resolveEuiCss(context, styles);
  const emotion = context.cache;
  const { inserted, registered } = emotion.cache;
  let root = classTries.get(inserted);

  if (!root) classTries.set(inserted, (root = {}));

  const node = walk(root, resolved, registered);

  if (!node) return emotion.css(resolved);

  return (node.className ??= emotion.css(resolved));
}
