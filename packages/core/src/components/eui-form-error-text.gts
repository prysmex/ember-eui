import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiFormErrorTextSignature {
  Element: HTMLDivElement;
  Blocks: {
    default: [];
  };
}

const EuiFormErrorText: TemplateOnlyComponent<EuiFormErrorTextSignature> =
  <template>
    <div class="euiFormErrorText" aria-live="polite" ...attributes>
      {{yield}}
    </div>
  </template>;

export default EuiFormErrorText;
