import type { TemplateOnlyComponent } from '@ember/component/template-only';
import EuiPaginationButton from '../eui-pagination-button';

import argOrDefault from '../../helpers/arg-or-default';

import { eq } from 'ember-truth-helpers';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';

export interface EuiPaginationButtonWrapperSignature {
  Args: {
    inList?: boolean;
    pageIndex: number;
    props: {
      pageCount?: number;
      activePage?: number;
      ariaControls?: string;
      safeClick: (page: number) => void;
    };
  };
}

const ButtonWrapper: TemplateOnlyComponent<EuiPaginationButtonWrapperSignature> =
  <template>
    {{#if (argOrDefault @inList true)}}
      <li>
        <EuiPaginationButton
          @isActive={{eq @pageIndex @props.activePage}}
          @totalPages={{@props.pageCount}}
          @pageIndex={{@pageIndex}}
          aria-controls={{@props.ariaControls}}
          @hideOnMobile={{true}}
          {{on "click" (fn @props.safeClick @pageIndex)}}
        />
      </li>
    {{else}}
      <EuiPaginationButton
        @isActive={{eq @pageIndex @props.activePage}}
        @totalPages={{@props.pageCount}}
        @pageIndex={{@pageIndex}}
        aria-controls={{@props.ariaControls}}
        @hideOnMobile={{true}}
        {{on "click" (fn @props.safeClick @pageIndex)}}
      />
    {{/if}}
  </template>;

export default ButtonWrapper;
