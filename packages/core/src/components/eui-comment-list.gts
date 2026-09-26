import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** Stacks EuiComments along a shared timeline. */
export interface EuiCommentListSignature {
  Element: HTMLDivElement;
  Blocks: {
    /** The `EuiComment`s. */
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
