import { fn } from '@ember/helper';

import sub from 'ember-math-helpers/helpers/sub';

import ArrowButton from './arrow-button.gts';

import type { EuiPaginationArrowButtonSignature } from './arrow-button.gts';
import type { SafeClickHandler } from '../eui-pagination.gts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private The "previous page" button of EuiPagination (labelled "Previous page"). */
export interface EuiPaginationPreviousButtonSignature {
  Element: EuiPaginationArrowButtonSignature['Element'];
  Args: {
    /** Zero based index of the current page. */
    activePage: number;
    /** Goes to a page (ignores out of range pages). */
    safeClick: SafeClickHandler;
    /**
     * `{ disabled, aria-controls }`. An enabled button with `aria-controls`
     * links to `#<aria-controls>`. `href` is ignored (derived, as upstream).
     */
    props?: {
      disabled?: boolean;
      'aria-controls'?: string;
      href?: string;
    };
  };
}

const PreviousButton: TemplateOnlyComponent<EuiPaginationPreviousButtonSignature> =
  <template>
    <ArrowButton
      @type="previous"
      @disabled={{@props.disabled}}
      @ariaControls={{@props.aria-controls}}
      @onClick={{fn @safeClick (sub @activePage 1)}}
      ...attributes
    />
  </template>;

export default PreviousButton;
