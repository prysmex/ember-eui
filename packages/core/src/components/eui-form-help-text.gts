import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiFormHelpTextSignature {
  Element: HTMLDivElement;
  Args: {
    id?: string;
  };
  Blocks: {
    default: [];
  };
}

const EuiFormHelpText: TemplateOnlyComponent<EuiFormHelpTextSignature> =
  <template>
    <div class="euiFormHelpText" id={{@id}} ...attributes>
      {{yield}}
    </div>
  </template>;

export default EuiFormHelpText;
