import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A shaded box inside an EuiStep for nested instructions. */
export interface EuiSubStepsSignature {
  Element: HTMLDivElement;
  Blocks: {
    /** The content. */
    default: [];
  };
}

const EuiSubSteps: TemplateOnlyComponent<EuiSubStepsSignature> = <template>
  <div class="euiSubSteps" ...attributes>
    {{yield}}
  </div>
</template>;

export default EuiSubSteps;
