import Component from '@glimmer/component';

import EuiHighlight from '../eui-highlight.gts';
import EuiMark from '../eui-mark.gts';
import EuiTextTruncate from '../eui-text-truncate.gts';

import type { EuiSelectableTruncationProps } from '../../-private/selectable-options.ts';

interface Signature {
  Args: {
    /** The option's label. */
    text: string;
    /** The search, highlighted when `@highlight` is set. */
    search: string;
    /** Highlight the search (upstream `highlightSearch`). */
    highlight: boolean;
    /**
     * EuiTextTruncate arguments (with the shared `width`), or nothing for
     * CSS truncation / wrapping (upstream `getTruncationProps`).
     */
    truncationProps?: EuiSelectableTruncationProps;
  };
}

/**
 * @private The default label of an EuiSelectableList option, upstream
 * `renderSearchedText` / `renderTruncatedText`: plain text by default,
 * EuiTextTruncate with `truncationProps`, and while searching the match is
 * highlighted and kept visible (`startEnd` truncation around it).
 */
export default class EuiSelectableOptionText extends Component<Signature> {
  /** Upstream `searchPositionCenter`. */
  get truncationPosition(): number {
    const { text, search } = this.args;
    const start = text.toLowerCase().indexOf(search.toLowerCase());

    return start + Math.floor(search.length / 2);
  }

  /** Shorter truncated text than the search: mark all of it (upstream). */
  isShort = (text: string) => text.length < this.args.search.length;

  <template>
    {{#if @highlight}}
      {{#if @truncationProps}}
        <EuiTextTruncate
          @text={{@text}}
          @width={{@truncationProps.width}}
          @onResize={{@truncationProps.onResize}}
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
            <EuiHighlight @text={{text}} @search={{@search}} />
          {{/if}}
        </EuiTextTruncate>
      {{else}}
        <EuiHighlight @text={{@text}} @search={{@search}} />
      {{/if}}
    {{else if @truncationProps}}
      <EuiTextTruncate
        @text={{@text}}
        @width={{@truncationProps.width}}
        @onResize={{@truncationProps.onResize}}
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
