import EuiText from '../eui-text';

import type { EuiTextSignature } from '../eui-text.gts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

interface Signature {
  Element: EuiTextSignature['Element'];
  Args: {
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
