import type { RehypeNode } from '../../markdown-types';
import EuiMarkdownFormatMarkdownCode from '../../../../components/eui-markdown-format/markdown-code.gts';
import EuiMarkdownFormatMarkdownCodeBlock from '../../../../components/eui-markdown-format/markdown-code-block.gts';
import { FENCED_CLASS } from '../../remark/remark-prismjs';
import EuiHoritzontalRule from '../../../../components/eui-horizontal-rule.gts';

type Visitor = (node: RehypeNode) => RehypeNode;

export const visit = (node: RehypeNode, visitor: Visitor) => {
  node = visitor(node);
  if (node) {
    let children: RehypeNode[] = [];
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

export const processor = function MarkdownAddComponents(): (
  tree: RehypeNode
) => void {
  return (tree) => {
    visit(tree, (node: RehypeNode) => {
      if (node.tagName === 'component') {
        node.type = 'component';
      }
      if (node.type === 'element' && node.tagName === 'a') {
        node.properties.className = ['euiLink', 'euiLink--primary'];
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
        node.properties.componentName = EuiHoritzontalRule;
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
