import { fn } from '@ember/helper';

import add from 'ember-math-helpers/helpers/add';

import ArrowButton from './arrow-button.gts';

import type { EuiPaginationArrowButtonSignature } from './arrow-button.gts';
import type { SafeClickHandler } from '../eui-pagination.gts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private The "next page" button of EuiPagination (labelled "Next page"). */
export interface EuiPaginationNextButtonSignature {
  Element: EuiPaginationArrowButtonSignature['Element'];
  Args: {
    /** Zero based index of the current page. */
    activePage: number;
    /** Goes to a page (ignores out of range pages). */
    safeClick: SafeClickHandler;
    /** Total number of pages. */
    pageCount: number;
    /**
     * `{ disabled, aria-controls }`. An enabled button with `aria-controls`
     * links to `#<aria-controls>`. `href` is ignored (derived, as upstream).
     */
    props: {
      disabled?: boolean;
      'aria-controls'?: string;
      href?: string;
    };
  };
}

const NextButton: TemplateOnlyComponent<EuiPaginationNextButtonSignature> =
  <template>
    <ArrowButton
      @type="next"
      @disabled={{@props.disabled}}
      @ariaControls={{@props.aria-controls}}
      @onClick={{fn @safeClick (add @activePage 1)}}
      ...attributes
    />
  </template>;

export default NextButton;
