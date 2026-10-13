import Component from '@glimmer/component';
import { on } from '@ember/modifier';

import EuiLink from '../eui-link.gts';

import type { EuiMarkdownLinkProps } from '../../utils/markdown/plugins/markdown-add-components/processor.ts';

/**
 * @private A markdown link rendered by EuiMarkdownFormat through EuiLink, as
 * upstream's default `a` renderer does (upstream color, secure `rel`,
 * `javascript:` URLs disabled). `linkProps` override the link's own values.
 */
export interface MarkdownLinkSignature {
  Args: {
    /** The parsed link node. */
    node: {
      href?: string;
      title?: string;
      target?: string;
      /** The `linkProps` of the processing plugins. */
      linkProps?: EuiMarkdownLinkProps;
      /** The rendered link text (a DOM node). */
      content: Node;
    };
  };
}

export default class MarkdownLink extends Component<MarkdownLinkSignature> {
  get props(): EuiMarkdownLinkProps {
    return this.args.node.linkProps ?? {};
  }

  get href() {
    return this.props.href ?? this.args.node.href;
  }

  get target() {
    return this.props.target ?? this.args.node.target;
  }

  handleClick = (event: MouseEvent) => this.props.onClick?.(event);

  <template>
    <EuiLink
      @href={{this.href}}
      @target={{this.target}}
      @color={{this.props.color}}
      @disabled={{this.props.disabled}}
      @external={{this.props.external}}
      @rel={{this.props.rel}}
      @type={{this.props.type}}
      title={{@node.title}}
      {{on "click" this.handleClick}}
    >{{@node.content}}</EuiLink>
  </template>
}
