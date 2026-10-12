import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { diffTokens, words } from '../-private/text-diff.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiTextDiffStyles } from '../utils/eui/styles.generated.ts';

import type { DiffChunk } from '../-private/text-diff.ts';

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

export default class EuiTextDiff extends Component<EuiTextDiffSignature> {
  /** Upstream: deletions in `textDanger`, insertions in `textSuccess`. */
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTextDiffStyles);

    return `euiTextDiff ${euiClass(context, styles.euiTextDiff)}`;
  }

  @cached
  get chunks(): DiffChunk[] {
    return diff(this.args.beforeText, this.args.afterText, this.args.granularity);
  }

  <template>
    {{#if (has-block)}}
      {{yield this.chunks}}
    {{else}}
      <span class={{this.classes}} ...attributes>
        {{~#each this.chunks as |chunk|~}}
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
  </template>
}
