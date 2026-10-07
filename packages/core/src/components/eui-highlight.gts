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
    /** What to highlight in it. Nothing is highlighted when empty. */
    search?: string;
    /** Match case exactly (by default "app" also matches "Apple"). */
    strict?: boolean;
    /** Highlight every match instead of only the first one. */
    highlightAll?: boolean;
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
  search?: string,
  strict = false,
  highlightAll = false
): Chunk[] {
  if (!text) return [];
  if (!search) return [{ text, highlight: false }];

  const regex = new RegExp(escapeRegExp(search), strict ? 'g' : 'gi');
  const chunks: Chunk[] = [];
  let last = 0;

  for (const match of text.matchAll(regex)) {
    const start = match.index!;

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
        <EuiMark>{{chunk.text}}</EuiMark>
      {{~else~}}
        {{chunk.text}}
      {{~/if~}}
    {{~/each~}}
  </span>
</template>;

export default EuiHighlight;
