import plugin from '@docfy/core/lib/plugin.js';

/**
 * Docfy puts a page's "Examples" (its heading and demos) right before the
 * page's first `##` heading. Our pages wrap their prose in `<EuiText>`, and
 * that heading ("API reference", usually) is inside one, so every demo
 * rendered inside EuiText and picked up its prose styles: margins on lists
 * (a combo box's input moved right), paragraphs, headings and more.
 *
 * This plugin runs after docfy inserted the demos. When they landed inside
 * an open `<EuiText>`, it closes it after the "Examples" heading (which keeps
 * its prose style) and reopens it after the demos.
 */
const OPEN = /<EuiText[\s>]/g;
const CLOSE = /<\/EuiText>/g;

const isHtml = (node) => node.type === 'html';
const isDemo = (node) => isHtml(node) && node.value.startsWith('<DocfyDemo');
const html = (value) => ({ type: 'html', value });
const text = (node) => node.value ?? (node.children ?? []).map(text).join('');

/** How many `<EuiText>` are open before `index` in the page's top level. */
function openEuiTexts(children, index) {
  return children
    .slice(0, index)
    .filter(isHtml)
    .reduce(
      (open, { value }) =>
        open +
        (value.match(OPEN)?.length ?? 0) -
        (value.match(CLOSE)?.length ?? 0),
      0,
    );
}

export default plugin({
  runWithMdast(ctx) {
    ctx.pages.forEach((page) => {
      const children = page.ast.children;
      const heading = children.findIndex(
        (node, index) =>
          node.type === 'heading' &&
          node.depth === 2 &&
          text(node) === 'Examples' &&
          children.slice(index + 1).some(isDemo),
      );

      if (heading === -1 || openEuiTexts(children, heading) === 0) return;

      // the demos follow the heading up to the page's own next heading
      let end = heading + 1;

      while (end < children.length && children[end].type !== 'heading') end++;

      children.splice(end, 0, html('<EuiText>'));
      children.splice(heading + 1, 0, html('</EuiText>'));
    });
  },
});
