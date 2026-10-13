import EuiMark from './eui-mark.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * Renders a string with the parts matching `@search` highlighted, e.g.
 * search results or the options of a filtered list.
 */
export interface EuiHighlightSignature {
  Element: HTMLSpanElement;
  Args: {
    /** The text to show. */
    text: string;
    /**
     * What to highlight in it. Nothing is highlighted when empty. With
     * `@highlightAll`, an array highlights every one of several words or
     * phrases.
     */
    search?: string | string[];
    /** Match case exactly (by default "app" also matches "Apple"). */
    strict?: boolean;
    /** Highlight every match instead of only the first one. */
    highlightAll?: boolean;
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

export function highlightChunks(
  text: string,
  search?: string | string[],
  strict = false,
  highlightAll = false
): Chunk[] {
  if (!text) return [];
  const terms = (Array.isArray(search) ? search : [search ?? '']).filter(
    (term) => term.length > 0
  );
  if (!terms.length) return [{ text, highlight: false }];
  if (terms.length > 1 && !highlightAll)
    throw new Error(
      'Cannot parse multiple search strings without `highlightAll` enabled'
    );

  const regex = new RegExp(terms.map(escapeRegExp).join('|'), strict ? 'g' : 'gi');
  const chunks: Chunk[] = [];
  let last = 0;

  for (const match of text.matchAll(regex)) {
    const start = match.index;
    // an empty match cannot be highlighted
    if (!match[0]) continue;

    if (start > last) chunks.push({ text: text.slice(last, start), highlight: false });
    chunks.push({ text: match[0], highlight: true });
    last = start + match[0].length;

    if (!highlightAll) break;
  }

  if (last < text.length) chunks.push({ text: text.slice(last), highlight: false });

  return chunks;
}

const EuiHighlight: TemplateOnlyComponent<EuiHighlightSignature> = <template>
  <span ...attributes>
    {{~#each (highlightChunks @text @search @strict @highlightAll) as |chunk|~}}
      {{~#if chunk.highlight~}}
        <EuiMark
          @hasScreenReaderHelpText={{@hasScreenReaderHelpText}}
        >{{chunk.text}}</EuiMark>
      {{~else~}}
        {{chunk.text}}
      {{~/if~}}
    {{~/each~}}
  </span>
</template>;

export default EuiHighlight;
