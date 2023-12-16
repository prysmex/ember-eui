import classNames from '../helpers/class-names';
import EuiButtonEmpty from './eui-button-empty.gts';

import type { EuiButtonEmptySignature } from './eui-button-empty';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiHeaderLinkSignature {
  Element: EuiButtonEmptySignature['Element'];
  Args: EuiButtonEmptySignature['Args'] & {
    isActive?: boolean;
  };
  Blocks: {
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
