import EuiText from '../eui-text.gts';

import type { EuiTextSignature } from '../eui-text';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private Shown in EuiComboBox's options list. */
interface Signature {
  Element: EuiTextSignature['Element'];
  Args: {
    /** EuiComboBox's `@noMatchesMessage`. */
    noMatchesMessage?: string;
  };
}

const NoMatchesMessageComponent: TemplateOnlyComponent<Signature> = <template>
  {{#if @noMatchesMessage}}
    <EuiText @size="xs" class="euiComboBoxOptionsList__empty" ...attributes>
      <p>
        {{@noMatchesMessage}}
      </p>
    </EuiText>
  {{/if}}
</template>;

export default NoMatchesMessageComponent;
