import argOrDefault from '../helpers/arg-or-default.ts';
import EuiIcon from './eui-icon.gts';

import type { EuiIconSignature } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** The app's logo (and name) linking home, first in the header. */
export interface EuiHeaderLogoSignature {
  Element: HTMLAnchorElement;
  Args: {
    /** Where the logo links to, usually `'/'`. */
    href?: string;
    /** `target` of the link. */
    target?: string;
    /**
     * Accessible name of the logo. Needed when there is no text in the
     * block.
     */
    iconTitle?: string;
    /** The logo, anything `EuiIcon`'s `@type` accepts. Defaults to `'logoElastic'`. */
    iconType?: EuiIconSignature['Args']['type'];
  };
  Blocks: {
    /** The app's name, next to the logo. */
    default: [];
  };
}

const EuiHeaderLogo: TemplateOnlyComponent<EuiHeaderLogoSignature> = <template>
  <a class="euiHeaderLogo" href={{@href}} target={{@target}} ...attributes>
    <EuiIcon
      @aria-label={{@iconTitle}}
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
