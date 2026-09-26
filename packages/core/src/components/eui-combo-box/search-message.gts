import EuiText from '../eui-text.gts';

import type { EuiTextSignature } from '../eui-text';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private Shown in EuiComboBox's options list. */
interface Signature {
  Element: EuiTextSignature['Element'];
  Args: {
    /** EuiComboBox's `@searchMessage`. */
    searchMessage?: string;
  };
}

const SearchMessageComponent: TemplateOnlyComponent<Signature> = <template>
  {{#if @searchMessage}}
    <EuiText @size="xs" class="euiComboBoxOptionsList__empty" ...attributes>
      <p>
        {{@searchMessage}}
      </p>
    </EuiText>
  {{/if}}
</template>;

export default SearchMessageComponent;
