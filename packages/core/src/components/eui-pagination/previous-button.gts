import { eq } from 'ember-truth-helpers';
import { on } from '@ember/modifier';
import { fn, hash } from '@ember/helper';

import type { TemplateOnlyComponent } from '@ember/component/template-only';
import EuiButtonIcon from '../eui-button-icon';
import type { EuiButtonIconSignature } from '../eui-button-icon';
import EuiI18n from '../eui-i18n';
import type { SafeClickHandler } from '../eui-pagination';
import sub from 'ember-math-helpers/helpers/sub';

export interface EuiPaginationPreviousButtonSignature {
  Element: EuiButtonIconSignature['Element'];
  Args: {
    activePage: number;
    safeClick: SafeClickHandler;
    props?: {
      disabled?: boolean;
      'aria-controls'?: string;
      href?: string;
    };
  };
}

const PreviousButton: TemplateOnlyComponent<EuiPaginationPreviousButtonSignature> =
  <template>
    <EuiI18n
      @token="euiPagination.previousPage"
      @default="Previous page, {page}"
      @values={{hash page=@activePage}}
      as |Token|
    >
      <Token as |previousPage|>
        <EuiI18n
          @token="euiPagination.disabledPreviousPage"
          @default="Previous page"
          as |InnerToken|
        >
          <InnerToken as |disabledPreviousPage|>
            <EuiButtonIcon
              {{on "click" (fn @safeClick (sub @activePage 1))}}
              @iconType="arrowLeft"
              @color="text"
              aria-label={{if
                (eq @activePage 0)
                disabledPreviousPage
                previousPage
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

export default PreviousButton;
