import { isTextNode } from '../../-private/eui-render-node.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private Renders a string looked up by EuiI18n. */
export interface EuiI18nRenderSignature {
  Args: {
    /**
     * The translated text, or one part of it when the text has component
     * values (a string or a component).
     */
    token: any;
  };
  Blocks: {
    /** Custom rendering; yields the text (or, for a component value, that component's part). Without it the text or component renders as is. */
    default: [string];
  };
}

const Render: TemplateOnlyComponent<EuiI18nRenderSignature> = <template>
  {{~#if (has-block)~}}
    {{yield @token}}
  {{~else if (isTextNode @token)~}}
    {{@token}}
  {{~else if @token~}}
    {{#let @token as |Part|}}<Part />{{/let}}
  {{~/if~}}
</template>;

export default Render;
