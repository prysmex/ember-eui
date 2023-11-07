import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiSubStepsSignature {
  Element: HTMLDivElement;
  Blocks: {
    default: [];
  };
}

const EuiSubSteps: TemplateOnlyComponent<EuiSubStepsSignature> = <template>
  <div class="euiSubSteps" ...attributes>
    {{yield}}
  </div>
</template>;

export default EuiSubSteps;
