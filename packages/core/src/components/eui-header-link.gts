import classNames from '../helpers/class-names.ts';
import EuiButtonEmpty from './eui-button-empty.gts';

import type { EuiButtonEmptySignature } from './eui-button-empty';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * A link in `EuiHeaderLinks`: an `EuiButtonEmpty` (all its args apply)
 * styled for the header.
 */
export interface EuiHeaderLinkSignature {
  Element: EuiButtonEmptySignature['Element'];
  Args: EuiButtonEmptySignature['Args'] & {
    /** Highlights the link, e.g. for the current page. */
    isActive?: boolean;
  };
  Blocks: {
    /** The link's text. */
    default: [];
  };
}

const EuiHeaderLink: TemplateOnlyComponent<EuiHeaderLinkSignature> = <template>
  <EuiButtonEmpty
    class={{classNames "euiHeaderLink" (if @isActive "euiHeaderLink-isActive")}}
    @color={{if @isActive "primary" "text"}}
    @href={{@href}}
    @isLoading={{@isLoading}}
    @isDisabled={{@isDisabled}}
    @target={{@target}}
    @iconType={{@iconType}}
    @iconSide={{@iconSide}}
    @iconClasses={{@iconClasses}}
    @textClasses={{@textClasses}}
    ...attributes
  >
    {{yield}}
  </EuiButtonEmpty>
</template>;

export default EuiHeaderLink;
