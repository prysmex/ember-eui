import { modifier } from 'ember-modifier';
import { EuiMarkdownAstNode } from '../utils/markdown/markdown-types';

export const getCursorNode = (
  textareaRef: HTMLInputElement,
  parsed: any
): EuiMarkdownAstNode => {
  const { selectionStart } = textareaRef;

  let node: EuiMarkdownAstNode = parsed.result ?? parsed.contents;

  //eslint-disable-next-line
  outer: while (true) {
    if (node.children) {
      for (let i = 0; i < node.children.length; i++) {
        const child = node.children[i];
        if (
          child.position.start.offset < (selectionStart as number) &&
          (selectionStart as number) < child.position.end.offset
        ) {
          if (child.type === 'text') break outer; // don't dive into `text` nodes
          node = child;
          continue outer;
        }
      }
    }
    break;
  }

  return node;
};

function wrapper(
  textarea: HTMLInputElement,
  parsed: any,
  callback: (node: EuiMarkdownAstNode) => void
) {
  const node = getCursorNode(textarea, parsed);
  callback(node);
}

export default modifier(function getCursorNodeModifier(
  textarea: HTMLInputElement,
  [parsed, onSelectedNode]: [boolean, () => void]
) {
  const fn = wrapper.bind(null, textarea, parsed, onSelectedNode);
  textarea.addEventListener('keyup', fn);
  textarea.addEventListener('mouseup', fn);

  return () => {
    textarea.removeEventListener('keyup', fn);
    textarea.removeEventListener('mouseup', fn);
  };
});
