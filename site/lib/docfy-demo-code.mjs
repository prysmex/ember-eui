import plugin from '@docfy/core/lib/plugin.js';

/**
 * Docfy wraps every fence in DocfyCodeBlock, including demo snippets that
 * already render inside EuiCodeBlock. EUI reads the yielded DOM's textContent:
 * the nested block's Copy button and layout whitespace become source code.
 * Keep only the pre/code content in demo snippets; prose keeps its controls.
 */
export function unwrapDemoCode(node) {
  if (!node.children) return;

  let snippetDepth = 0;
  node.children = node.children.filter((child) => {
    if (child.type === 'raw') {
      if (/^<(?:demo\.)?Snippet(?:\s|>)/.test(child.value)) snippetDepth++;
      if (/^<\/(?:demo\.)?Snippet>/.test(child.value)) snippetDepth--;
      if (snippetDepth > 0 && /^<\/?DocfyCodeBlock(?:\s|>)/.test(child.value)) {
        return false;
      }
    }
    unwrapDemoCode(child);
    return true;
  });
}

export default plugin({
  // The built-in code-block plugin wraps fences during runWithHast.
  // runAfter sees those wrappers before renderMarkdown stringifies the tree.
  runAfter(ctx) {
    ctx.pages.forEach((page) => unwrapDemoCode(page.ast));
  },
});
