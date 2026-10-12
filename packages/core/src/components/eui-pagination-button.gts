import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { concat } from '@ember/helper';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import { euiPaginationButtonStyles } from '../utils/eui/styles.generated.ts';
import EuiButtonEmpty from './eui-button-empty.gts';

import type EuiI18nService from '../services/eui-i18n.ts';
import type { EuiButtonEmptySignature } from './eui-button-empty';

/** @private A page number button of EuiPagination. */
export interface EuiPaginationButtonSignature {
  Element: EuiButtonEmptySignature['Element'];
  Args: {
    /** @deprecated Has no effect. */
    paddingSize?: string;
    /** Zero based index of the page it goes to (shown plus one). */
    pageIndex?: number;
    /** Total number of pages, for the accessible label. */
    totalPages?: number;
    /**
     * Marks the current page: `aria-current="page"`, bold primary underlined
     * text, and disabled (upstream).
     */
    isActive?: boolean;
    /** Disables the button (e.g. a "…" placeholder). */
    isPlaceholder?: boolean;
    /** @deprecated Has no effect; EuiPagination's `@responsive` compresses it instead. */
    hideOnMobile?: boolean;
    /**
     * Id of the content the page changes; also makes the button a link to
     * it (`href="#id"`), as upstream.
     */
    ariaControls?: string;
  };
  Blocks: {
    /** Unused. */
    default: [];
  };
}

export default class EuiPaginationButton extends Component<EuiPaginationButtonSignature> {
  @service declare euiI18n: EuiI18nService;

  get pageNumber(): number {
    return (this.args.pageIndex ?? 0) + 1;
  }

  get ariaLabel(): string {
    const { totalPages } = this.args;
    return totalPages
      ? this.euiI18n.lookupToken(
          'euiPaginationButton.longPageString',
          'Page {page} of {totalPages}',
          { page: this.pageNumber, totalPages }
        )
      : this.euiI18n.lookupToken(
          'euiPaginationButton.shortPageString',
          'Page {page}',
          { page: this.pageNumber }
        );
  }

  /** Upstream's `css` on EuiButtonEmpty. */
  @cached
  get css(): EuiCss {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiPaginationButtonStyles);
    return [styles.euiPaginationButton, this.args.isActive && styles.isActive];
  }

  <template>
    <EuiButtonEmpty
      class="euiPaginationButton"
      @css={{this.css}}
      aria-label={{this.ariaLabel}}
      @size="s"
      @color="text"
      @href={{if @ariaControls (concat "#" @ariaControls)}}
      @isDisabled={{if @isActive true @isPlaceholder}}
      aria-current={{if @isActive "page"}}
      aria-controls={{@ariaControls}}
      data-test-subj="pagination-button-{{@pageIndex}}"
      ...attributes
    >
      {{this.pageNumber}}
    </EuiButtonEmpty>
  </template>
}
