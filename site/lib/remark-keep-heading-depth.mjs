/**
 * Docfy runs remark-normalize-headings on every page, which turns a page's
 * first heading into an `<h1>` when the page has none. Our pages title
 * themselves with `<EuiPageHeader>` instead of a `#` heading, so the first
 * `##` (usually "API reference") was promoted: docfy then named untitled
 * pages after it, put the demos under it, and nested the API reference
 * headings under "Examples" in the table of contents (and the side nav).
 *
 * This plugin runs after the normalization and gives every heading back
 * the depth written in the markdown.
 */
export default function remarkKeepHeadingDepth() {
  return (tree, file) => {
    const source = String(file.value ?? '');

    const walk = (node) => {
      const offset = node.position?.start.offset;

      if (node.type === 'heading' && offset !== undefined) {
        // ATX headings only: setext headings (underlined) keep their depth
        const hashes = /^#{1,6}(?=\s|$)/.exec(source.slice(offset));
        if (hashes) node.depth = hashes[0].length;
      }

      node.children?.forEach(walk);
    };

    walk(tree);
  };
}
