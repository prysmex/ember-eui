import { diffTokens, words } from '../-private/text-diff.ts';

import type { DiffChunk } from '../-private/text-diff.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * Shows the changes between two texts inline: removed text in `<del>`,
 * added text in `<ins>`.
 */
export interface EuiTextDiffSignature {
  Element: HTMLSpanElement;
  Args: {
    /** The original text. */
    beforeText: string;
    /** The changed text. */
    afterText: string;
    /**
     * Compare whole `'words'` (easier to read) or single `'characters'`.
     * Defaults to `'words'`.
     */
    granularity?: 'words' | 'characters';
  };
  Blocks: {
    /**
     * Renders the diff yourself: yields its chunks, `[operation, text]`
     * pairs where the operation is `-1` (removed), `1` (added) or `0`.
     */
    default: [DiffChunk[]];
  };
}

function diff(before = '', after = '', granularity = 'words'): DiffChunk[] {
  return granularity === 'characters'
    ? diffTokens([...before], [...after])
    : diffTokens(words(before), words(after));
}

function chunkText(chunk: DiffChunk): string {
  return chunk[1];
}

function isAdded(chunk: DiffChunk): boolean {
  return chunk[0] === 1;
}

function isRemoved(chunk: DiffChunk): boolean {
  return chunk[0] === -1;
}

const EuiTextDiff: TemplateOnlyComponent<EuiTextDiffSignature> = <template>
  {{#let (diff @beforeText @afterText @granularity) as |chunks|}}
    {{#if (has-block)}}
      {{yield chunks}}
    {{else}}
      <span class="euiTextDiff" ...attributes>
        {{~#each chunks as |chunk|~}}
          {{~#if (isAdded chunk)~}}
            <ins>{{chunkText chunk}}</ins>
          {{~else if (isRemoved chunk)~}}
            <del>{{chunkText chunk}}</del>
          {{~else~}}
            {{chunkText chunk}}
          {{~/if~}}
        {{~/each~}}
      </span>
    {{/if}}
  {{/let}}
</template>;

export default EuiTextDiff;
