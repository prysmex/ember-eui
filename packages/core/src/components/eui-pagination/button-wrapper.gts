import { fn } from '@ember/helper';
import { on } from '@ember/modifier';

import { eq } from 'ember-truth-helpers';

import argOrDefault from '../../helpers/arg-or-default.ts';
import EuiPaginationButton from '../eui-pagination-button.gts';

import type { SafeClickHandler } from '../eui-pagination.gts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private Renders one EuiPaginationButton (in an `<li>`). */
export interface EuiPaginationButtonWrapperSignature {
  Args: {
    /** Wraps the button in an `<li class="euiPagination__item">`. Defaults to `true`. */
    inList?: boolean;
    /** Zero based index of the page. */
    pageIndex: number;
    /** EuiPagination's state: `{ pageCount, activePage, ariaControls, safeClick }`. */
    props: {
      pageCount?: number;
      activePage?: number;
      ariaControls?: string;
      safeClick: SafeClickHandler;
    };
  };
}

const ButtonWrapper: TemplateOnlyComponent<EuiPaginationButtonWrapperSignature> =
  <template>
    {{#if (argOrDefault @inList true)}}
      <li class="euiPagination__item">
        <EuiPaginationButton
          @isActive={{eq @pageIndex @props.activePage}}
          @totalPages={{@props.pageCount}}
          @pageIndex={{@pageIndex}}
          @ariaControls={{@props.ariaControls}}
          {{on "click" (fn @props.safeClick @pageIndex)}}
        />
      </li>
    {{else}}
      <EuiPaginationButton
        @isActive={{eq @pageIndex @props.activePage}}
        @totalPages={{@props.pageCount}}
        @pageIndex={{@pageIndex}}
        @ariaControls={{@props.ariaControls}}
        {{on "click" (fn @props.safeClick @pageIndex)}}
      />
    {{/if}}
  </template>;

export default ButtonWrapper;
