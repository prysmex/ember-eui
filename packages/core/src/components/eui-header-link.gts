import EuiButtonEmpty from './eui-button-empty.gts';

import type { EuiButtonEmptySignature } from './eui-button-empty';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * A link in `EuiHeaderLinks`: an `EuiButtonEmpty` (all its args apply)
 * styled for the header. Upstream `EuiHeaderLink` has no styles of its own;
 * `EuiHeader @theme="dark"` recolors `.euiHeaderLink` and
 * `.euiHeaderLink-isActive`.
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

/**
 * Upstream `EuiHeaderLink`: `@color` defaults to `'primary'` when active and
 * `'text'` otherwise; `@size` defaults to `'s'`, as upstream.
 */
const EuiHeaderLink: TemplateOnlyComponent<EuiHeaderLinkSignature> = <template>
  <EuiButtonEmpty
    class="euiHeaderLink {{if @isActive 'euiHeaderLink-isActive'}}"
    @color={{if @color @color (if @isActive "primary" "text")}}
    @size={{if @size @size "s"}}
    @href={{@href}}
    @isLoading={{@isLoading}}
    @isDisabled={{@isDisabled}}
    @disabled={{@disabled}}
    @isSelected={{@isSelected}}
    @target={{@target}}
    @type={{@type}}
    @flush={{@flush}}
    @iconType={{@iconType}}
    @iconSide={{@iconSide}}
    @iconSize={{@iconSize}}
    @iconClasses={{@iconClasses}}
    @textClasses={{@textClasses}}
    @contentClasses={{@contentClasses}}
    ...attributes
  >
    {{yield}}
  </EuiButtonEmpty>
</template>;

export default EuiHeaderLink;
