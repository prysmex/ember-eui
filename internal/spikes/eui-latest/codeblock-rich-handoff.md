# EuiCodeBlock rich content: handoff

Branch `eui-wave/codeblock-rich`. Closes the EuiCodeBlock row of
docs-audit-gaps.md and the code block line in migrating-to-borealis.md
"Known gaps".

## Closed

1. **Rich content renders as-is** (`packages/core/src/components/eui-code-block.gts`).
   Upstream highlights `children` only when it is a string and renders
   anything else as-is (`getHtmlContent(data, children)` with `data = []`).
   Glimmer can't tell strings from nodes, so the block still renders into the
   detached element first, and the exported `isRichCodeContent(element)`
   decides from the DOM:
   - text: only text nodes (comments ignored), or one `<pre>`, `<code>` or
     `<pre><code>` wrapper around text, with whitespace-only text beside it.
     Docfy fences and demo snippets (`<pre><code class="language-x">`),
     markdown code and data grid popovers all have this shape and are
     highlighted as before.
   - rich: anything else. The hidden copy is torn down and the block is
     yielded straight into a visible `<code>` (same classes,
     `data-code-language`, `...attributes`), with no highlighting, line
     numbers, annotations or virtualization. Full screen yields the block
     again, as upstream renders `children` twice. Copy uses the code
     element's `innerText`, normalized like upstream's `useCopy` (blank lines
     collapsed). overflowHeight/tabindex work through the existing pre
     observers. A modifier on the visible `<code>` watches it; when the
     content turns back into text the hidden copy is rendered again and
     highlighted (switching updates in place).
   - The heuristic and edge cases are in the component's doc comment
     (pre-highlighted markup counts as rich; template whitespace is rendered,
     unlike JSX; a rich block is rendered twice when it first appears).
2. **Annotations with `@isVirtualized`** (`eui-code-block/virtualized.gts`).
   Each virtual row's helper now returns the row element plus its
   `[data-annotation-line]` placeholder; the row template renders the
   `Annotation` (with `EuiRenderNode` for text or components) into it with
   `in-element`, so rows scrolled into view get their annotations, inline and
   in full screen, as upstream's `nodeToHtml` in `ListRow`. The
   `delete final.annotations` for virtualized blocks is gone.
3. **EuiErrorMessage** (`eui-error-message.gts`): the `EuiTitle` is inside the
   `EuiCodeBlock` again, as upstream; the block is rich content, so it is not
   highlighted.

## Behaviour changes

- Markup inside EuiCodeBlock (other than a pre/code wrapper) used to be
  flattened to its text and highlighted; it is now rendered as-is. Added to
  the migration table.
- Rich content + `@isVirtualized`: upstream passes `data = []` to the
  virtualized list (an empty list, the content is lost); ours renders the
  content non-virtualized. Documented in the doc comment.
- Existing test changed: `eui-error-message-test` — old
  `.euiErrorBoundary .euiTitle` (title beside the code block) → new
  `.euiErrorBoundary .euiCodeBlock code .euiTitle` plus "not highlighted";
  upstream `error_boundary.tsx` `EuiErrorMessage` puts `EuiTitle` in
  `EuiCodeBlock`. Its other two tests now wait for the rich render.

## Not changed / notes

- Upstream also spreads `...rest` onto the virtualized `<code>`; ours never
  passed `...attributes` to the virtualized view (pre-existing, untouched).
- No upstream docs example was dropped for these gaps (upstream has no rich
  content example). The Code page prose explains text vs rich content.

## Tests / checks

- New `tests/integration/components/eui-code-block-rich-test.gts` (9 tests):
  detection unit cases, string path + source copy, docfy-shaped
  `<pre><code class>` highlighted + copy, markdown code highlighted, rich
  content not highlighted / no line numbers / not virtualized, rich copy
  text + full screen + overflow, text↔rich switching, error-title-in-block,
  virtualized annotations (row, scrolled-in row, full screen).
- Full core suite: 1954/1954. Code block filter 17/17 (+ 9 new).
  ember-tsc clean, eslint clean on changed files, upstream parity 357/357.
  `generate-api-docs` updated the Code page; rollup produced no
  package.json change.
- Site not built (coordinator).
