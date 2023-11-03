import { eq } from 'ember-truth-helpers';
import EuiLoadingSpinner from './eui-loading-spinner.gts';
import EuiIcon from './eui-icon.gts';
import classNames from '../helpers/class-names';
import argOrDefault from '../helpers/arg-or-default';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiButtonnContentSignature {
  Element: HTMLSpanElement;
  Args: {
    iconSide?: 'right';
    isLoading?: boolean;
    iconType?: string;
    iconSize?: EuiIcon['size'];
    iconClasses?: string;
    useSvg?: boolean;
    useComponent?: boolean;
    textClasses?: string;
  };
  Blocks: {
    default: [];
  };
}

const EuiButtonContent: TemplateOnlyComponent<EuiButtonnContentSignature> =
  <template>
    <span
      class={{classNames
        "euiButtonContent"
        (if (eq @iconSide "right") "euiButtonContent--iconRight")
      }}
      ...attributes
    >
      {{#if @isLoading}}
        <EuiLoadingSpinner
          class="euiButtonContent__spinner"
          {{!@glint-expect-error}}
          @size={{argOrDefault @iconSize "m"}}
        />
      {{else if @iconType}}
        <EuiIcon
          @iconClasses="euiButtonContent__icon {{@iconClasses}}"
          @type={{@iconType}}
          @size={{argOrDefault @iconSize "m"}}
          @useSvg={{@useSvg}}
          @useComponent={{@useComponent}}
          @color="inherit"
        />
      {{/if}}
      <span class={{@textClasses}}>
        {{yield}}
      </span>
    </span>
  </template>;

export default EuiButtonContent;
