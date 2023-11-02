import { eq } from 'ember-truth-helpers';
import { on } from '@ember/modifier';
import { fn, hash } from '@ember/helper';

import type { TemplateOnlyComponent } from '@ember/component/template-only';
import EuiButtonIcon from '../eui-button-icon';
import type { EuiButtonIconSignature } from '../eui-button-icon';
import EuiI18n from '../eui-i18n';
import type { SafeClickHandler } from '../eui-pagination';
import add from 'ember-math-helpers/helpers/add';
import sub from 'ember-math-helpers/helpers/sub';

export interface EuiPaginationNextButtonSignature {
  Element: EuiButtonIconSignature['Element'];
  Args: {
    activePage: number;
    safeClick: SafeClickHandler;
    pageCount: number;
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
