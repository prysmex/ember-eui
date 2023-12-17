import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiStepsHorizontalSignature {
  Element: HTMLOListElement;
  Blocks: {
    default: [];
  };
}

const EuiStepsHorizontal: TemplateOnlyComponent<EuiStepsHorizontalSignature> =
  <template>
    <ol class="euiStepsHorizontal" ...attributes>
      {{yield}}
    </ol>
  </template>;

export default EuiStepsHorizontal;
