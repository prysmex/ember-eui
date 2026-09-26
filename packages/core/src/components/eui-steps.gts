import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A vertical list of numbered steps (`EuiStep`), e.g. setup instructions. */
export interface EuiStepsSignature {
  Element: HTMLDivElement;
  Args: {};
  Blocks: {
    /** The `EuiStep`s. */
    default: [];
  };
}

const EuiSteps: TemplateOnlyComponent<EuiStepsSignature> = <template>
  <div class="euiSteps" ...attributes>
    {{yield}}
  </div>
</template>;

export default EuiSteps;
