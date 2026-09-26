import { fn, hash } from '@ember/helper';
import { on } from '@ember/modifier';

import add from 'ember-math-helpers/helpers/add';
import sub from 'ember-math-helpers/helpers/sub';
import { eq } from 'ember-truth-helpers';

import EuiButtonIcon from '../eui-button-icon.gts';
import EuiI18n from '../eui-i18n.gts';

import type { EuiButtonIconSignature } from '../eui-button-icon';
import type { SafeClickHandler } from '../eui-pagination';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private The "next page" button of EuiPagination. */
export interface EuiPaginationNextButtonSignature {
  Element: EuiButtonIconSignature['Element'];
  Args: {
    /** Zero based index of the current page. */
    activePage: number;
    /** Goes to a page (ignores out of range pages). */
    safeClick: SafeClickHandler;
    /** Total number of pages. */
    pageCount: number;
    /** Extra props for the button: `{ disabled, aria-controls, href }`. */
    props: {
      disabled?: boolean;
      'aria-controls'?: string;
      href?: string;
    };
  };
}

const NextButton: TemplateOnlyComponent<EuiPaginationNextButtonSignature> =
  <template>
    <EuiI18n
      @token="euiPagination.nextPage"
      @default="Next page, {page}"
      @values={{hash page=(add @activePage 2)}}
      as |Token|
    >
      <Token as |nextPage|>
        <EuiI18n
          @token="euiPagination.disabledNextPage"
          @default="Next page"
          as |InnerToken|
        >
          <InnerToken as |disabledNextPage|>
            <EuiButtonIcon
              {{on "click" (fn @safeClick (add @activePage 1))}}
              @iconType="arrowRight"
              @color="text"
              aria-label={{if
                (eq @activePage (sub @pageCount 1))
                disabledNextPage
                nextPage
              }}
              aria-controls={{if @props.aria-controls @props.aria-controls}}
              href={{if @props.href @props.href}}
              disabled={{eq @props.disabled true}}
              ...attributes
            />
          </InnerToken>
        </EuiI18n>
      </Token>
    </EuiI18n>
  </template>;

export default NextButton;
