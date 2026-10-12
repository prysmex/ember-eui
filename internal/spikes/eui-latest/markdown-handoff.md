# Markdown family migration handoff (EuiMarkdownEditor, EuiMarkdownFormat and their parts)

Branch `eui-wave/markdown`. Target EUI 123.1.0 / Borealis 8.1.0. Status: **Migrated**. The full core suite passes in this worktree (941/941), along with upstream parity (226/226), types, lint and the API docs check.

## Files

- Components (all style getters `@cached`, factories only through `useEuiBorealisStyles`):
  - `eui-markdown-editor.gts`, `eui-markdown-editor-toolbar.gts`, `eui-markdown-editor-text-area.gts`, `eui-markdown-editor-footer.gts`, `eui-markdown-editor-drop-zone.gts`: the text area and drop zone are now Glimmer classes.
  - `eui-markdown-format.gts`, `eui-markdown-format/markdown-checkbox.gts`, `markdown-tooltip.gts`.
  - New private renderers: `eui-markdown-format/markdown-link.gts` (EuiLink) and `markdown-horizontal-rule.gts` (EuiHorizontalRule plus upstream's `euiHorizontalRule` class). They have no rows in `components.md`; the coordinator can add them.
  - Unchanged: `markdown-code.gts` (EuiCode), `markdown-code-block.gts` (still renders through the existing EuiCodeBlock; not edited), the two SVG icons (the markdown logo is identical to upstream).
- `src/utils/markdown/plugins/markdown-add-components/processor.ts`: links become EuiLink components instead of raw `<a class="euiLink euiLink--primary">`; `---` uses the new rule renderer; task list wrappers get `euiMarkdownFormat__checkbox`.
- `src/utils/markdown/plugins/to-dom.ts`: plugin component wrappers no longer receive `href`/`title`/… attributes or "Unmapped node property" warnings (their properties go to `@node`); `DynamicComponent` args gain `readOnly`.
- `src/utils/eui/markdown.ts` (new, upstream license header): hand ports of the two css objects that live in React renderer modules (`markdownCheckboxStyles`, the tooltip icon's `translateY(-1px)`).
- `scripts/generate-eui-styles.mjs` and `scripts/eui-upstream-parity.test.mjs`, `// markdown` block: `euiMarkdownEditorStyles`, `euiMarkdownEditorVariables`, `euiMarkdownEditorDropZoneStyles`, `euiMarkdownEditorFooterStyles`, `euiMarkdownEditorHelpButtonStyles`, `euiMarkdownEditorTextAreaStyles`, `euiMarkdownEditorToolbarStyles`, `euiMarkdownFormatStyles` (8 factories, all extracted cleanly; generator now 257). New parity test runs upstream's checkbox and tooltip renderers with React/Emotion stubbed and compares the hand ports. `styles.generated.ts` / `upstream-sources.json` regenerated (only esbuild `_refN` renames in existing code); worktree `../../…/Users/…` source-path comments normalized back to `node_modules/…`.
- Tests: new `tests/integration/components/eui-markdown-family-test.gts` (module `Borealis markdown family`, 13 tests). `eui-markdown-editor-test.gts`: the `euiMarkdownEditor--isPreviewing` assertion now checks upstream's `euiMarkdownEditor-isPreviewing` (the legacy modifier is gone).
- `docs/editors/markdown-editor/base-editor.md`: only the generated API section.

## API and default changes (latest-only)

**EuiMarkdownEditor**
- Root uses upstream styles (flex column; toolbar top radius and preview/footer bottom radius = `border.radius.panel`; `fullHeight` sets height 100%, `resize: none` and a full-height drop zone). Classes: `euiMarkdownEditor`, upstream `euiMarkdownEditor-isPreviewing`. Removed: `euiMarkdownEditor--isPreviewing`, `euiMarkdownEditor--fullHeight`.
- **While previewing, the textarea stays mounted and its container gets `display: none`** (upstream). Before, the textarea stayed visible below the preview unless legacy CSS hid it.
- The footer height is now measured (ResizeObserver, `offsetHeight`, reported on the next frame to avoid ResizeObserver loop errors) and subtracted from the textarea height/max height, as upstream. It was always 0 before, so the editor was footer-height taller than `@height`.
- New args (upstream): `@readOnly` (readonly textarea with upstream read-only styles, toolbar/preview switch/footer buttons disabled, drops ignored, preview checkboxes don't toggle), `@errors` (footer error popover + danger state), `@dropHandlers` (drag/drop and file picker, upstream `EuiMarkdownDropHandler`), `@showFooter` (default `true`). Ember extension: `@formatColor`.
- `@isInvalid` now also sets `aria-invalid="true"` and the drop zone's `hasError` styles (Ember extension; upstream has no prop).
- Textarea: upstream styles (min-height 150px, `size.m` padding, form font/color, line-height multiplier, thin border without bottom border, focus outline also on `:focus-within`), `data-test-subj="euiMarkdownEditorTextArea"`, the resize observer moved from the drop zone to the textarea (upstream).

**Toolbar**: upstream styles; every button (not only plugins) is highlighted when the cursor's node matches (upstream node ids `strong`, `emphasis`, `inlineCode`…; `data-test-subj="euiMarkdownEditorToolbarButton pressed"`); plugins without `button` are skipped and the plugin divider only renders when some plugin has a button; preview switch gets upstream `data-test-subj`s. **Tooltips use the default delay** (was `long`; upstream has no delay prop). Kept: bundled icon names (`editorBold`, `editorCodeBlock`…; upstream `textBold`, `listBullet`, `code`, `link` are not in the bundled set) and the `euiMarkdownEditorToolbar.preview` i18n token (upstream renamed it `previewMarkdown`).

**Footer**: upstream structure. Upload button (paperclip, "Open upload files modal"), unsupported-file button ("File type not supported", tooltip with supported files, autofocus), spinner while uploading, error popover (`upCenter`, padding s, `Errors` title, 300px, one EuiText per message). The help button gets upstream's 26px icon width through EuiButtonIcon `@css`, a tooltip ("Syntax help") and the label "Show markdown help" (was unlabeled). Help modal follows upstream (h1 title linked by `aria-labelledby`, "This editor uses GitHub flavored markdown" link, plugin help, Close button); without plugin help text it is a popover. **i18n tokens** are upstream's `euiMarkdownEditorHelpButton.*` / `euiMarkdownEditorFooter.*`; the old `euiMarkdownEditorFooter.syntaxTitle`/`.syntaxHelp` tokens are no longer used. Plugin help text is still rendered as markdown (Ember plugins pass strings).

**Drop zone**: was a stub; now implements upstream's drag states (`isDragging` primary background, `isDraggingError` danger background, `hasError` invalid textarea for unaccepted items/errors) and drop/picker handling. No handlers → dropping disabled, no upload button. The zone has no `role` (upstream unsets react-dropzone's `role="button"`).

**EuiMarkdownFormat**
- Root is a Glimmer-owned `<div class="euiMarkdownFormat euiText …">` that now forwards `...attributes` (`Element: HTMLDivElement`); parsed nodes are inserted into it, so size/color/class changes no longer re-render the content.
- One Emotion class composes EuiText (scoped reset, `euiText`, size, color) and upstream `euiMarkdownFormatStyles` (size scale + border colors) last, like upstream's `<EuiText css={…}>`. Legacy `euiText--medium`-style size classes are gone.
- New `@color` (default `'default'` = `textParagraph`, as upstream; any EuiText color or CSS color, which also tints blockquote/rule/table borders) and `@readOnly`.
- `@shouldIncludeDefaultRootClasses={{false}}` drops the `euiText` class and EuiText typography but keeps the markdown border/table styles.
- **Links render through EuiLink** (upstream): default color `text`, secure `rel="noreferrer"`, `javascript:` URLs become disabled buttons, `title` kept.
- Rules render EuiHorizontalRule with upstream's `euiHorizontalRule` class so the format's color rules apply (the Ember rule's own class is `euiBorealisHorizontalRule`).
- Task list: upstream's only effective checkbox rule (1em after the last task item) applies to the `.euiMarkdownFormat__checkbox` wrappers, which are `display: block`. Upstream's other two selectors never match its own checkbox markup, so they are ported for parity only. Read-only checkboxes get `readonly` and ignore clicks.
- Tooltip plugin: icon gets upstream's `translateY(-1px)` via EuiIcon `@css`; the `euiMarkdownTooltip__icon` class was dropped; the icon is still `questionInCircle` (upstream `question` is not bundled).

## Checks (2026-10-12, this worktree)

Environment: Node 22.22.1, binaries run directly, Chromium 130 via the scratchpad shim, `CI=true`. **During this run the shared `node_modules` (symlinked from the main checkout) lost its Linux native binaries** (`@rollup/rollup-linux-arm64-gnu`, `@esbuild/linux-arm64`; only darwin builds remain, so it looks like a host-side reinstall). I did not touch `node_modules`: I downloaded the two packages (rollup 4.63.5, esbuild 0.28.2) into `<scratchpad>/linux-natives/nm` and ran with `NODE_PATH=<that>` and `ESBUILD_BINARY_PATH=<that>/@esbuild/linux-arm64/bin/esbuild` (`<scratchpad>/linux-natives/env.sh`). Other agents and the coordinator will hit the same failure.

- Core (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **941 tests, 941 pass, 0 fail** (13 new). An earlier full run had 1 failure in the new test (a `click()` selector on a portaled modal), fixed and rerun.
- `node --test scripts/eui-upstream-parity.test.mjs`: **226/226** (217 at base + 8 factories + 1 hand-port test).
- `node scripts/generate-eui-styles.mjs --check`: expected worktree failure (symlinked `node_modules` source-path comments); regenerated and normalized.
- `ember-tsc --noEmit`: pass. ESLint on every changed component, util and test: pass. `node scripts/generate-api-docs.mjs --check`: pass after regenerating.
- Not run (coordinator): rollup core build, site build/acceptance, showcase/visual checks.

## Test coverage (`Borealis markdown family`)

Editor layout measured against tokens (toolbar/divider/buttons/textarea/drop zone/footer, radii, textarea + footer = `@height`, toggle-container height); toolbar labels and order, cursor-node highlighting, formatting through a button, editor/preview switch (container hidden, not re-rendered, buttons disabled, preview panel styles); height modes (fixed, max height, `full`, auto-expanding preview); footer help modal (labelled h1, link, plugin help, Close) and the bare-footer popover, errors popover and invalid outline; drop zone drag/error backgrounds, unsupported-file button + aria-label, focus reset, drop insertion with block padding, disabled without handlers; format typography, EuiLink/EuiCode/EuiCodeBlock/EuiHorizontalRule rendering, table/quote/rule borders and scale per size incl. `relative`, in-place size changes; colors (named/custom) on text and borders, root classes and `shouldIncludeDefaultRootClasses`; task list toggling via `replaceNode`, inside the editor preview, read-only; tooltip plugin (icon offset, tooltip, `aria-describedby`); reactive editor args without element replacement, focus ring, invalid, read-only, a11y attributes; light/dark nearest provider, island and sibling isolation, teardown; JS-object overrides (radius, `lightestShade`, nested override wins, scoped) and preferred contrast border colors; RTL (divider, quote, list indent, table end border, toolbar order).

## Unresolved / for the coordinator

1. **Shared `node_modules` lost Linux natives** (see Checks). It needs a Linux reinstall, or every agent needs the `NODE_PATH`/`ESBUILD_BINARY_PATH` workaround.
2. **EuiButtonEmpty lacks `@css`**: upstream composes `euiMarkdownEditorFooter__uploadError` (panel border radius) into the unsupported-file button; it's left out, with a comment in the footer.
3. **EuiCheckbox lacks `@css`**: `markdownCheckboxStyles` is hand-ported, but the effective rule is applied from the format root to the Ember wrappers instead.
4. **EuiText lacks `@css`** and doesn't export its scoped reset, so `eui-markdown-format.gts` carries a copy (`euiMarkdownTextReset`, plus a `table` reset). Exporting `euiTextReset` from `eui-text.gts` would remove the copy.
5. **EuiHorizontalRule's root class is `euiBorealisHorizontalRule`**, not upstream's `euiHorizontalRule`. Upstream selectors that target the rule (markdown format, maybe others) need the upstream class; the markdown renderer adds it itself.
6. Icon names: toolbar `textBold`/`textItalic`/`listBullet`/`listNumber`/`listCheck`/`code`/`link`, switch `code`, tooltip `question`. Switch when the icon set refreshes.
7. EuiCodeBlock is being migrated concurrently. Markdown passes `fontSize="m"`, `paddingSize="s"`, `isCopyable`. The code-block wrapper margin comes from the format styles. Re-check after merge (the test only asserts that `.euiCodeBlock` is present inside the wrapper).
8. Not ported: `toolbarProps.right`, `markdownFormatProps`, `linkProps` for processing plugins, `exclude` in processing plugins (already a no-op), and passing `null` to plugin editors when the selected node type differs.

## Next step

Coordinator: merge, union the `// markdown` generator/parity entries, regenerate in the main checkout, rerun the full suite (after fixing the native-binary issue), then do a visual check of `/docs/editors/markdown-editor` (preview toggle, help modal, link color).
