import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiI18nRenderSignature {
  Args: {
    token: string;
  };
  Blocks: {
    default: [string];
  };
}

const Render: TemplateOnlyComponent<EuiI18nRenderSignature> = <template>
  {{yield @token}}
</template>;

export default Render;
