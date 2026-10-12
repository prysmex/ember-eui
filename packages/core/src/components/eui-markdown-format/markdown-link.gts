import EuiLink from '../eui-link.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * @private A markdown link rendered by EuiMarkdownFormat through EuiLink, as
 * upstream's default `a` renderer does (upstream color, secure `rel`,
 * `javascript:` URLs disabled).
 */
export interface MarkdownLinkSignature {
  Args: {
    /** The parsed link node. */
    node: {
      href?: string;
      title?: string;
      target?: string;
      /** The rendered link text (a DOM node). */
      content: Node;
    };
  };
}

const MarkdownLink: TemplateOnlyComponent<MarkdownLinkSignature> = <template>
  <EuiLink
    @href={{@node.href}}
    @target={{@node.target}}
    title={{@node.title}}
  >{{@node.content}}</EuiLink>
</template>;

export default MarkdownLink;
