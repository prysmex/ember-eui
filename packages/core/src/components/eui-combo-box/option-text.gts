import Component from '@glimmer/component';

import EuiHighlight, { highlightChunks } from '../eui-highlight.gts';
import EuiMark from '../eui-mark.gts';
import EuiTextTruncate from '../eui-text-truncate.gts';

import type { EuiTextTruncateSignature } from '../eui-text-truncate';

/** EuiTextTruncate arguments for options (upstream `truncationProps`). */
export type EuiComboBoxTruncationProps = Partial<
  Omit<EuiTextTruncateSignature['Args'], 'text'>
>;

interface Signature {
  Args: {
    /** The option's label. */
    text: string;
    /** The search text (untrimmed). */
    search?: string;
    isCaseSensitive?: boolean;
    /** EuiComboBox's `ignoreAccents`, to highlight what it matched. */
    ignoreAccents?: boolean;
    /** `'auto'` wraps the text instead of truncating it. */
    rowHeight?: number | 'auto';
    /** EuiComboBox's `@truncationProps` merged with the option's own. */
    truncationProps?: EuiComboBoxTruncationProps;
    /** Width shared by the rows, so only the first ones measure. */
    width?: number;
    onResize?: (width: number) => void;
  };
}

/**
 * @private The default option content of EuiComboBox's list, upstream
 * `renderTruncatedOption` / `renderVariableHeightOption`: CSS truncation
 * by default, EuiTextTruncate with `truncationProps`, and while searching
 * the match is highlighted and kept visible (`startEnd` truncation
 * around it).
 */
export default class EuiComboBoxOptionText extends Component<Signature> {
  get search(): string {
    return (this.args.search ?? '').trim();
  }

  get isAuto(): boolean {
    return this.args.rowHeight === 'auto';
  }

  /**
   * Upstream `searchPositionCenter`: the middle of the match, found like
   * EuiHighlight finds it (the match is not always the search's length
   * when ignoring accents).
   */
  get truncationPosition(): number {
    const { text, isCaseSensitive, ignoreAccents } = this.args;
    const search = this.search;
    const chunks = highlightChunks(text, search, isCaseSensitive, false, ignoreAccents);
    const index = chunks.findIndex((chunk) => chunk.highlight);

    if (index < 0) return -1 + Math.floor(search.length / 2);

    const start = chunks.slice(0, index).reduce((length, chunk) => length + chunk.text.length, 0);

    return start + Math.floor(chunks[index]!.text.length / 2);
  }

  /** Shorter truncated text than the search: mark all of it (upstream). */
  isShort = (text: string) => text.length < this.search.length;

  <template>
    {{#if this.isAuto}}
      {{#if this.search}}
        <EuiHighlight
          @text={{@text}}
          @search={{this.search}}
          @strict={{@isCaseSensitive}}
          @ignoreAccents={{@ignoreAccents}}
        />
      {{else}}
        {{@text}}
      {{/if}}
    {{else if this.search}}
      <EuiTextTruncate
        @text={{@text}}
        @width={{if @truncationProps.width @truncationProps.width @width}}
        @onResize={{@onResize}}
        @truncationOffset={{@truncationProps.truncationOffset}}
        @ellipsis={{@truncationProps.ellipsis}}
        @calculationDelayMs={{@truncationProps.calculationDelayMs}}
        @toolTipProps={{@truncationProps.toolTipProps}}
        @truncation="startEnd"
        @truncationPosition={{this.truncationPosition}}
        as |text|
      >
        {{#if (this.isShort text)}}
          <EuiMark>{{text}}</EuiMark>
        {{else}}
          <EuiHighlight
            @text={{text}}
            @search={{this.search}}
            @strict={{@isCaseSensitive}}
            @ignoreAccents={{@ignoreAccents}}
          />
        {{/if}}
      </EuiTextTruncate>
    {{else if @truncationProps}}
      <EuiTextTruncate
        @text={{@text}}
        @width={{if @truncationProps.width @truncationProps.width @width}}
        @onResize={{@onResize}}
        @truncation={{@truncationProps.truncation}}
        @truncationOffset={{@truncationProps.truncationOffset}}
        @truncationPosition={{@truncationProps.truncationPosition}}
        @ellipsis={{@truncationProps.ellipsis}}
        @calculationDelayMs={{@truncationProps.calculationDelayMs}}
        @toolTipProps={{@truncationProps.toolTipProps}}
      />
    {{else}}
      {{@text}}
    {{/if}}
  </template>
}
