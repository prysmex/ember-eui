export const visit = (node, visitor) => {
  node = visitor(node);
  if (node) {
    let children = [];
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

export default function MarkdownAddComponents(): (
  tree: any,
  file: any
) => void {
  return (tree, file) => {
    visit(tree, (node) => {
      console.log(node);
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
        node.properties.name = 'eui-horizontal-rule';
      }
      if (node.type === 'element' && node.tagName === 'code') {
        node.type = 'component';
        const hasBreaks = node.children.find((child: any) =>
          /\r|\n/.exec(child.value)
        );
        if (hasBreaks) {
          node.properties.name = 'eui-markdown-format/markdown-code-block';
          node.properties.fontSize = 'm';
          node.properties.paddingSize = 's';
        } else {
          node.properties.name = 'eui-markdown-format/markdown-code';
        }
      }
      return node;
    });
  };
}
