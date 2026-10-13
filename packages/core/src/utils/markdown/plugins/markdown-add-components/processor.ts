import EuiMarkdownFormatMarkdownCheckbox from '../../../../components/eui-markdown-format/markdown-checkbox.gts';
import EuiMarkdownFormatMarkdownCode from '../../../../components/eui-markdown-format/markdown-code.gts';
import EuiMarkdownFormatMarkdownCodeBlock from '../../../../components/eui-markdown-format/markdown-code-block.gts';
import EuiMarkdownFormatMarkdownHorizontalRule from '../../../../components/eui-markdown-format/markdown-horizontal-rule.gts';
import EuiMarkdownFormatMarkdownLink from '../../../../components/eui-markdown-format/markdown-link.gts';
import { FENCED_CLASS } from '../../remark/remark-prismjs.ts';

import type { RehypeNode } from '../../markdown-types.ts';

type Visitor = (node: RehypeNode) => RehypeNode;

export const visit = (node: RehypeNode, visitor: Visitor) => {
  node = visitor(node);

  if (node) {
    const children: RehypeNode[] = [];

    if (node.children) {
      node.children.forEach((child) => {
        child = visit(child, visitor);

        if (child) {
          children.push(child);
        }
      });
      node.children = children;
    }
  }

  return node;
};

/** Args of `EuiLink` (and a click handler) that `linkProps` applies to every link. */
export interface EuiMarkdownLinkProps {
  color?: string;
  disabled?: boolean;
  external?: boolean;
  href?: string;
  rel?: string;
  target?: string;
  type?: string;
  /** Called when a link is clicked. */
  onClick?: (event: MouseEvent) => void;
}

export interface MarkdownAddComponentsOptions {
  /**
   * Allows customizing all formatted links with any of the args of
   * `EuiLink` (upstream's `linkProps`), e.g. `{ target: '_blank' }`.
   * They override the link's own values.
   */
  linkProps?: EuiMarkdownLinkProps;
}

export const processor = function MarkdownAddComponents(
  options: MarkdownAddComponentsOptions = {}
): (tree: RehypeNode) => void {
  const { linkProps } = options ?? {};

  return (tree) => {
    visit(tree, (node: RehypeNode) => {
      if (node.tagName === 'component') {
        node.type = 'component';

        // Task list wrappers are styled by EuiMarkdownFormat
        if (
          node.properties.componentName ===
          (EuiMarkdownFormatMarkdownCheckbox as unknown)
        ) {
          node.properties.className = ['euiMarkdownFormat__checkbox'];
        }
      }

      // Links render through EuiLink, as upstream's `a` renderer does
      if (node.type === 'element' && node.tagName === 'a') {
        node.type = 'component';
        //@ts-expect-error
        node.properties.componentName = EuiMarkdownFormatMarkdownLink;
        node.properties['inline'] = true;
        node.properties['linkProps'] = linkProps;
      }

      if (node.type === 'element' && node.tagName === 'pre') {
        node.tagName = 'div';
        node.properties.className = ['euiMarkdownFormat__codeblockWrapper'];
      }

      if (node.type === 'element' && node.tagName === 'blockquote') {
        node.properties.className = ['euiMarkdownFormat__blockquote'];
      }

      if (node.type === 'element' && node.tagName === 'table') {
        node.properties.className = ['euiMarkdownFormat__table'];
      }

      if (node.type === 'element' && node.tagName === 'hr') {
        node.type = 'component';
        node.properties.componentName = EuiMarkdownFormatMarkdownHorizontalRule;
      }

      if (node.type === 'element' && node.tagName === 'code') {
        node.type = 'component';

        const hasBreaks = node.children?.find(
          (child: RehypeNode) =>
            /\r|\n/.exec(child.value) ||
            ((node.properties.className as string[]) &&
              (node.properties.className as string[]).indexOf(FENCED_CLASS) >
                -1)
        );

        if (hasBreaks) {
          //@ts-expect-error
          node.properties.componentName = EuiMarkdownFormatMarkdownCodeBlock;
          node.properties['fontSize'] = 'm';
          node.properties['paddingSize'] = 's';
        } else {
          //@ts-expect-error
          node.properties.componentName = EuiMarkdownFormatMarkdownCode;
          node.properties['inline'] = true;
        }
      }

      return node;
    });
  };
};
