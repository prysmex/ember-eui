import Component from '@glimmer/component';

import EuiHighlight from '../eui-highlight.gts';
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

  /** Upstream `searchPositionCenter`. */
  get truncationPosition(): number {
    const { text, isCaseSensitive } = this.args;
    const search = this.search;
    const start = isCaseSensitive
      ? text.indexOf(search)
      : text.toLowerCase().indexOf(search.toLowerCase());

    return start + Math.floor(search.length / 2);
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
