import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** Help text under a control; EuiFormRow renders it from `@helpText`. */
export interface EuiFormHelpTextSignature {
  Element: HTMLDivElement;
  Args: {
    /** Id, to reference from the control's `aria-describedby`. */
    id?: string;
  };
  Blocks: {
    /** The text. */
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
