import EuiText from '../eui-text.gts';

import type { EuiTextSignature } from '../eui-text';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

interface Signature {
  Element: EuiTextSignature['Element'];
  Args: {
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
