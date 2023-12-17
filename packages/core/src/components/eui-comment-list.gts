import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiCommentListSignature {
  Element: HTMLDivElement;
  Blocks: {
    default: [];
  };
}

const EuiCommentList: TemplateOnlyComponent<EuiCommentListSignature> =
  <template>
    {{!
    Comment List is basically a wrapper for various comments
  }}
    <div class="euiCommentList" ...attributes>
      {{yield}}
    </div>
  </template>;

export default EuiCommentList;
