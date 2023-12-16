import argOrDefault from '../helpers/arg-or-default';
import EuiIcon from './eui-icon.gts';

import type { EuiIconSignature } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiHeaderLogoSignature {
  Element: HTMLAnchorElement;
  Args: {
    href?: string;
    target?: string;
    iconTitle?: string;
    iconType?: EuiIconSignature['Args']['type'];
  }
  Blocks: {
    default: []
  }
}

const EuiHeaderLogo: TemplateOnlyComponent<EuiHeaderLogoSignature> = <template>
  <a class="euiHeaderLogo" href={{@href}} target={{@target}} ...attributes>
    <EuiIcon
      aria-label={{@iconTitle}}
      @iconClasses="euiHeaderLogo__icon"
      @size="l"
      @type={{argOrDefault @iconType "logoElastic"}}
    />
    {{#if (has-block)}}
      <span class="euiHeaderLogo__text">
        {{yield}}
      </span>
    {{/if}}
  </a>
</template>;

export default EuiHeaderLogo;
