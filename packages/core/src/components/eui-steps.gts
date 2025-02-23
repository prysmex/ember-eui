import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiStepsSignature {
  Element: HTMLDivElement;
  Args: {};
  Blocks: {
    default: [];
  };
}

const EuiSteps: TemplateOnlyComponent<EuiStepsSignature> = <template>
  <div class="euiSteps" ...attributes>
    {{yield}}
  </div>
</template>;

export default EuiSteps;
