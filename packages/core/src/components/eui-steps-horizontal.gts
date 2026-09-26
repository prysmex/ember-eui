import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A horizontal progress of steps (`EuiStepHorizontal`), e.g. a wizard's header. */
export interface EuiStepsHorizontalSignature {
  Element: HTMLOListElement;
  Blocks: {
    /** The `EuiStepHorizontal`s. */
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
