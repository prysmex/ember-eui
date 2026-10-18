import { foldAccents, removeAccents } from '../-private/accents.ts';
import EuiMark from './eui-mark.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * Renders a string with the parts matching `@search` highlighted, e.g.
 * search results or the options of a filtered list.
 */
export interface EuiHighlightSignature {
  Element: HTMLSpanElement;
  Args: {
    /**
     * The text to show. Anything else (a number, `null`, …) renders as is,
     * with nothing highlighted.
     */
    text: string;
    /**
     * What to highlight in it. Nothing is highlighted when empty. With
     * `@highlightAll`, an array highlights every one of several words or
     * phrases. Anything but strings is ignored.
     */
    search?: string | string[];
    /** Match case exactly (by default "app" also matches "Apple"). */
    strict?: boolean;
    /** Highlight every match instead of only the first one. */
    highlightAll?: boolean;
    /**
     * Match ignoring accents ("medico" marks "Médico", and "médico" marks
     * "Medico"); defaults to `true`. `false` matches them exactly, like
     * upstream. Not upstream.
     */
    ignoreAccents?: boolean;
    /** Passed to each EuiMark; defaults to `true`. */
    hasScreenReaderHelpText?: boolean;
  };
}

interface Chunk {
  text: string;
  highlight: boolean;
}

function escapeRegExp(text: string): string {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

const isString = (value: unknown): value is string => typeof value === 'string';

/**
 * `isString` for the template, without the type guard: `@text` is typed a
 * string, so the guard would leave the `else` branch a `never`.
 */
const isText = (value: unknown): boolean => isString(value);

export function highlightChunks(
  text: unknown,
  search?: unknown,
  strict = false,
  highlightAll = false,
  ignoreAccents = true
): Chunk[] {
  if (!isString(text) || !text) return [];
  const terms = (Array.isArray(search) ? search : [search])
    .filter(isString)
    .map((term) => (ignoreAccents ? removeAccents(term) : term))
    .filter((term) => term.length > 0);
  if (!terms.length) return [{ text, highlight: false }];
  if (terms.length > 1 && !highlightAll)
    throw new Error(
      'Cannot parse multiple search strings without `highlightAll` enabled'
    );

  // without accents, matches in the folded text map back to the original
  const fold = ignoreAccents ? foldAccents(text) : undefined;
  const regex = new RegExp(terms.map(escapeRegExp).join('|'), strict ? 'g' : 'gi');
  const chunks: Chunk[] = [];
  let last = 0;

  for (const match of (fold?.folded ?? text).matchAll(regex)) {
    // an empty match cannot be highlighted
    if (!match[0]) continue;
    // a character can fold to several (Hangul to jamo): matches in one
    // original character must not overlap
    const start = fold ? Math.max(fold.starts[match.index]!, last) : match.index;
    const end = fold ? fold.ends[match.index + match[0].length - 1]! : match.index + match[0].length;
    if (end <= last) continue;

    if (start > last) chunks.push({ text: text.slice(last, start), highlight: false });
    chunks.push({ text: text.slice(start, end), highlight: true });
    last = end;

    if (!highlightAll) break;
  }

  if (last < text.length) chunks.push({ text: text.slice(last), highlight: false });

  return chunks;
}

const EuiHighlight: TemplateOnlyComponent<EuiHighlightSignature> = <template>
  <span ...attributes>
    {{~#if (isText @text)~}}
      {{~#each (highlightChunks @text @search @strict @highlightAll @ignoreAccents) as |chunk|~}}
        {{~#if chunk.highlight~}}
          <EuiMark
            @hasScreenReaderHelpText={{@hasScreenReaderHelpText}}
          >{{chunk.text}}</EuiMark>
        {{~else~}}
          {{chunk.text}}
        {{~/if~}}
      {{~/each~}}
    {{~else~}}
      {{@text}}
    {{~/if~}}
  </span>
</template>;

export default EuiHighlight;
