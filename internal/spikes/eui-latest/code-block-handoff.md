# Code block family migration handoff

Branch `eui-wave/code-block`. Target EUI 123.1.0 / Borealis 8.1.0. Status: **Migrated** (full core suite passes in this worktree).

## Scope

EuiCodeBlock, `eui-code-block/controls.gts`, `eui-code-block/full-screen-display.gts`, `eui-code-block/virtualized.gts`, plus a new private `eui-code-block/annotation.gts` (upstream `EuiCodeBlockAnnotation`). The highlighting engine is unchanged: refractor (Prism) with the lazy language loader and Prism `token …` class names. Upstream token colors (`euiCodeSyntaxVariables().tokensCss`) come in through the root `euiCodeBlock` class and target those class names directly.

## Files

- Components: `eui-code-block.gts`, `eui-code-block/{controls,full-screen-display,virtualized}.gts` (Controls and FullScreenDisplay are now Glimmer classes with `@cached` class getters), new `eui-code-block/annotation.gts`.
- `src/utils/eui/code-block.ts` (new hand port with the upstream license header): `euiCodeBlockLineStyles`. Upstream builds it with `@emotion/css`, so the generator doesn't extract it. Parity test: every slot gives the same `css-<name>` class and the same registered styles as upstream's `@emotion/css`, across 12 theme configurations.
- `src/utils/code/utils.ts`: only the EuiCodeBlock line utilities changed. `wrapLines`/`highlightByLine` now produce upstream's markup and accept the composed line classes (`LineClasses`) and `annotations`. `getHtmlContent` also allows the `data-annotation-line` attribute. Nothing EuiCode uses has changed.
- `scripts/generate-eui-styles.mjs` (`// code-block` block) and the regenerated `styles.generated.ts` / `upstream-sources.json`: 255 → 262 factories. New: `euiCodeSyntaxVariables`, `euiCodeTextColors`, `euiCodeBlockStyles`, `euiCodeBlockPreStyles`, `euiCodeBlockCodeStyles`, `euiCodeBlockControlsStyles`, `euiCodeBlockAnnotationsStyles`, `mathWithUnits`. Existing factories changed only by esbuild renames. The worktree's `../../…/Users/…` source-path comments were normalized back to `node_modules/…`. A regenerate-and-normalize run reproduces the committed files byte for byte.
- `scripts/eui-upstream-parity.test.mjs`: 7 factories (everything except `mathWithUnits`) join the 12-configuration matrix, plus the hand-port test.
- Tests: new `tests/integration/components/eui-code-block-family-test.gts` (module `Borealis code block family`, 13 tests).
- API docs regenerated (`docs/editors/code/index.md`).

## Structure (upstream)

`div.euiCodeBlock` (Emotion: surface, font size, transparent, `hasControls`/`hasBothControls` min height, token CSS; inline `max-block-size` for numeric `@overflowHeight` or `block-size` for a string) contains:

- `pre.euiCodeBlock__pre` (padding, white space, controls offset, scrollbar, `tabindex` -1 or 0 when it overflows). Inside it: a screen-reader-only `div` ("`{language} code block:`", prefixed with `@ariaLabel`) followed by `code.euiCodeBlock__code[data-code-language]` with `...attributes`.
- `div.euiCodeBlock__controls`.
- In full screen: `EuiOverlayMask > div.euiCodeBlockFullScreen[role=dialog][aria-modal=true][aria-label="Expanded code block"]`.

Each line is `span.euiCodeBlock__line`. With line numbers it holds `span.euiCodeBlock__lineNumberWrapper` (inline `inline-size`, containing `span.euiCodeBlock__lineNumber[data-line-number][aria-hidden]` drawn by `::before`, plus an optional `span.euiCodeBlock__lineAnnotation`) and `span.euiCodeBlock__lineText`. Line classes are composed per variant in the nearest provider's cache, like upstream's `cx`, so they follow theme changes.

## API / default changes

- Public args, `Element` type and `...attributes` (on `<code>`) are unchanged. `@className` stays on the root. MarkdownCodeBlock and the docs snippet callers type-check unchanged.
- **New args (upstream):** `@copyAriaLabel`, `@ariaLabel` (prefixes the screen reader label), and `lineNumbers.annotations` (`{ [line]: string }`): a round info button next to the number opens an `EuiPopover` (z-index `levels.mask + 1`, Escape closes it without leaving full screen). Annotations are **not rendered when `@isVirtualized`**, because virtual rows are detached DOM nodes.
- Removed legacy classes: `euiCodeBlock--font*`, `--padding*`, `--hasControl`, `--hasBothControls`, `--hasLineNumbers`, `--transparentBackground`, `euiCodeBlock__pre--whiteSpace*`, `--isVirtualized`, `euiCodeBlock-isFullScreen`, and **`euiCodeBlock__line--isHighlighted`** (highlighting is now an Emotion class on `__lineText`, as upstream). Line markup changed: the number now sits inside a `__lineNumberWrapper`, and `__lineText` no longer has inline margin/width styles.
- Copy: the button only renders when there is text to copy (upstream). The icon is `copy` (was `copyClipboard`) and the button has `data-test-subj="euiCodeBlockCopy"`. Labels use the i18n tokens `euiCodeBlockCopy.copy` and `euiCopy.copied`. **Deliberate difference:** the copied text is the block's source (trimmed) for both views. The old version copied rendered `innerText` and collapsed blank lines; upstream does the same for non-virtualized blocks. Copying the source keeps blank lines and can never include the screen reader label or annotation markup.
- Full screen: dialog semantics as above, forced large font and `xl` padding, controls offset `l`. Escape anywhere in the dialog closes it, except inside an annotation popover; the old version only listened on the `<pre>`. Focus returns to the Expand button after Escape or Collapse. The Collapse button is delayed by 10ms (`EuiDelayRender`, as upstream). Expand/Collapse labels use the `euiCodeBlockFullScreen.*` tokens. The focus trap uses `escapeDeactivates: false`, so Escape is handled by the component. **Fixed:** the full-screen `<code>` used to stay empty until the source changed; it now renders on open.
- Overflow: the initial `tabindex` is `-1` (was `1`, a bug) and becomes `0` only when the pre overflows. Virtualized pres are always `0`.
- Virtualized: a numeric `@overflowHeight` fixes the list height (`EuiAutoSizer @disableHeight`, as upstream). Rows get logical react-window-like styles (`inset-block-start`, `block-size`, `inline-size: 100%`). `code` is `position: relative`, so rows sit inside the padding. The old version positioned them against the pre's border box.
- Scoped resets standing in for upstream's global reset, each composed first into the element's own class: `pre { margin: 0 }` (upstream's `controlsOffset` margin still wins) and a button reset on the annotation button.

## Legacy test assertions changed

None. The existing `eui-code-block-test.gts` (rendered and virtualized checks) and the markdown tests pass unchanged.

## Checks (worktree, Chromium 130, CI=true, Node 22; pnpm unavailable, binaries run directly)

- Core (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **958 tests, 958 pass, 0 fail**. That includes the 13 new `Borealis code block family` tests; the base was 945.
- `node --test scripts/eui-upstream-parity.test.mjs`: **229/229 pass**.
- `node scripts/generate-eui-styles.mjs --check`: the expected worktree failure (symlinked `node_modules` path comments). A regenerate-and-normalize run is byte-identical to the committed files.
- `ember-tsc --noEmit`: pass. ESLint on all changed sources and the new test: pass. `node scripts/generate-api-docs.mjs`: 1 page updated.
- Environment note: during this session the shared `node_modules` lost its Linux esbuild binary (only `@esbuild/darwin-arm64` is present). The parity and generator scripts were run with `ESBUILD_BINARY_PATH=<scratchpad>/linux-natives/nm/@esbuild/linux-arm64/bin/esbuild` (same version, 0.28.2).
- Not run (coordinator): rollup build, site build/acceptance, showcase screenshots.

## Unresolved / for the coordinator

1. Annotations are not supported in virtualized mode (see above). Upstream supports them there.
2. `utils/css-mappings/eui-code-block.ts` is no longer used by the component (left in place).
3. MarkdownCodeBlock (markdown family) can pass `@copyAriaLabel`/`@ariaLabel` if it wants upstream's labels. No API change is needed there.
4. `getHtmlContent` logs `Unmapped node property` warnings for markdown component nodes (`language`, `componentName`, `fontSize`, `paddingSize`). This predates this branch.
5. Upstream's tabular copy markers (`hiddenNoCopyBoundary`) are not ported. They aren't needed, because the copy uses the source text.
