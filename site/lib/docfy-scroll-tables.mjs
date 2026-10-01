import plugin from '@docfy/core/lib/plugin.js';

/**
 * Wraps every markdown table of the pages (e.g. the API reference) in a
 * container that scrolls sideways (`.guideTableScroll` in app.css), so wide
 * tables scroll on their own on narrow screens instead of widening the page.
 * A wrapper keeps the table a table, unlike `display: block` on it.
 */
const html = (value) => ({ type: 'html', value });

function wrapTables(node) {
  if (!node.children) return;

  node.children = node.children.flatMap((child) => {
    if (child.type !== 'table') {
      wrapTables(child);

      return [child];
    }

    return [html('<div class="guideTableScroll">'), child, html('</div>')];
  });
}

export default plugin({
  runWithMdast(ctx) {
    ctx.pages.forEach((page) => wrapTables(page.ast));
  },
});
