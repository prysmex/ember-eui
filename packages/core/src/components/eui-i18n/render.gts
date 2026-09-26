import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private Renders a string looked up by EuiI18n. */
export interface EuiI18nRenderSignature {
  Args: {
    /** The translated text. */
    token: string;
  };
  Blocks: {
    /** Custom rendering; yields the text. */
    default: [string];
  };
}

const Render: TemplateOnlyComponent<EuiI18nRenderSignature> = <template>
  {{yield @token}}
</template>;

export default Render;
