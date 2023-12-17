import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiModalBodySignature {
  Element: HTMLDivElement;
  Blocks: {
    default: [];
  };
}

const EuiModalBody: TemplateOnlyComponent<EuiModalBodySignature> = <template>
  <div class="euiModalBody" ...attributes>
    <div class="euiModalBody__overflow">
      {{yield}}
    </div>
  </div>
</template>;

export default EuiModalBody;
