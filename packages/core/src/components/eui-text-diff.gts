import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { diffTokens, words } from '../-private/text-diff.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiTextDiffStyles } from '../utils/eui/styles.generated.ts';

import type { ComponentLike } from '@glint/template';
import type { TemplateOnlyComponent } from '@ember/component/template-only';
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
    /**
     * Time limit of the comparison in seconds; once exceeded the part that
     * differs is shown as one removal and one insertion instead of the
     * minimal diff. `0` removes the limit. Defaults to `0.1`, as upstream.
     */
    timeout?: number;
    /**
     * What wraps inserted text: an HTML tag name (e.g. `'mark'`) or a
     * component rendering its block. Defaults to `'ins'`.
     */
    insertComponent?: string | ComponentLike<{ Blocks: { default: [] } }>;
    /**
     * What wraps removed text: an HTML tag name or a component rendering
     * its block. Defaults to `'del'`.
     */
    deleteComponent?: string | ComponentLike<{ Blocks: { default: [] } }>;
    /**
     * What wraps text without changes: an HTML tag name or a component
     * rendering its block. Defaults to none (plain text).
     */
    sameComponent?: string | ComponentLike<{ Blocks: { default: [] } }>;
  };
  Blocks: {
    /**
     * Renders the diff yourself: yields its chunks, `[operation, text]`
     * pairs where the operation is `-1` (removed), `1` (added) or `0`.
     */
    default: [DiffChunk[]];
  };
}

function diff(
  before = '',
  after = '',
  granularity = 'words',
  timeout = 0.1
): DiffChunk[] {
  return granularity === 'characters'
    ? diffTokens([...before], [...after], timeout)
    : diffTokens(words(before), words(after), timeout);
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

interface WrapSignature {
  Args: { tag: string | ComponentLike<{ Blocks: { default: [] } }> };
  Blocks: { default: [] };
}

/** Wraps the text in an HTML element (a tag name) or a component. */
const Wrap: TemplateOnlyComponent<WrapSignature> = <template>
  {{~#if (isTag @tag)~}}
    {{~#let (element @tag) as |Tag|~}}<Tag>{{~yield~}}</Tag>{{~/let~}}
  {{~else~}}
    {{~#let @tag as |Custom|~}}<Custom>{{~yield~}}</Custom>{{~/let~}}
  {{~/if~}}
</template>;

const isTag = (tag: unknown) => typeof tag === 'string';

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
    return diff(
      this.args.beforeText,
      this.args.afterText,
      this.args.granularity,
      this.args.timeout
    );
  }

  <template>
    {{#if (has-block)}}
      {{yield this.chunks}}
    {{else}}
      <span class={{this.classes}} ...attributes>
        {{~#each this.chunks as |chunk|~}}
          {{~#if (isAdded chunk)~}}
            <Wrap @tag={{if @insertComponent @insertComponent "ins"}}>{{~chunkText chunk~}}</Wrap>
          {{~else if (isRemoved chunk)~}}
            <Wrap @tag={{if @deleteComponent @deleteComponent "del"}}>{{~chunkText chunk~}}</Wrap>
          {{~else if @sameComponent~}}
            <Wrap @tag={{@sameComponent}}>{{~chunkText chunk~}}</Wrap>
          {{~else~}}
            {{chunkText chunk}}
          {{~/if~}}
        {{~/each~}}
      </span>
    {{/if}}
  </template>
}
