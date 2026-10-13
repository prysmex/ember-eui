# Gaps: text, i18n, search bar, markdown (branch eui-wave/gaps-text)

Verified against EUI 123.1.0 source (`components/markdown_editor`, `search_bar`, `i18n`, `context`, `call_out`, `color_picker/color_palette_picker`). Every gap named in the prompt exists upstream.

## Closed

| Component | What | Ember choice |
| --- | --- | --- |
| EuiCallOut | action `popoverProps` | Private `-private/eui-maybe-popover.gts` (upstream `withEuiPopover`): the args of `EuiPopover` plus `children` (text or component, `EuiRenderNode`). The tooltip sits inside the popover, as upstream. `closePopover` defaults to a no-op. |
| EuiColorPalettePicker | top-level `prepend` / `append` | `<:prepend as |className|>` / `<:append>` blocks, forwarded to `EuiSuperSelect`. SuperSelect got private `@isPrependProvided` / `@isAppendProvided` (default `has-block`) so a wrapper that always declares the blocks does not render empty slots. |
| EuiI18n | multi-token lookup | `@tokens` + `@defaults` (+ `@values`, `@i18n`) yield ONE array of texts (`as |texts|`, `{{get texts 0}}`). Upstream passes the array to `children`. Typed single-token only (Glint cannot express both); the tokens yield carries a `@glint-expect-error`. |
| EuiI18n | component-valued interpolation | `@values` entries may be components. The yielded `Text` renders the parts (strings, components invoked in place) when invoked without a block (new; it rendered nothing before), and yields each part to its block. Upstream's React `render` option is the existing `@i18n.renderComponent`. "Blocks" as values are components, since named blocks cannot be picked dynamically. Whitespace between yielded parts is now trimmed (`~`). |
| EuiContext | decided: not added | Every EUI component reads texts from the global `euiI18n` service, which cannot see the component tree. A provider could only scope the `<EuiI18n>` instances an app writes, and EUI's own components would stay untranslated, which is what `EuiContext` is for. Per-subtree locales are rare in apps; `@i18n={{hash mapping=...}}` covers one-off scoping. Explained in the i18n Context example. `mappingFunc` (and `formatDateTime`/`locale`) of upstream's `I18nShape` are not ported. |
| EuiSearchBar | `box.prepend` / `append` | Text becomes an `EuiFormPrepend` / `EuiFormAppend` label; a component renders as is in the slot. |
| EuiSearchBar | `box.onClick` / `onFocus` / `onBlur` | Called with the event from the input. `onFocus` runs next to the hint opening. |
| EuiSearchBar | filter option `view` as markup | `view?: string | ComponentLike`, rendered without args through `EuiRenderNode` in the list's `<:option>`. Strings still work. |
| EuiMarkdownEditor | `toolbarProps` | `{ className, right }`; `right` is text or a component and replaces the preview/editor switch (`right ?? default`, as upstream). |
| EuiMarkdownEditor | `getDefaultEuiMarkdownPlugins` `exclude` | `'tooltip' | 'checkbox' | 'emoji' | 'linkValidator' | 'lineBreaks'` for parsing; `'tooltip'` for UI. Config: `parsingConfig` (`emoji`, `linkValidator`) and `uiConfig`, as upstream. Processing plugins ignore `exclude`: the checkbox and tooltip parsers carry their component in the node, so leaving the parser out is enough. |
| EuiMarkdownEditor | link validator | `utils/markdown/plugins/markdown-link-validator.ts`: `euiMarkdownLinkValidator`, `validateUrl`, `mutateLinkToText`, `isDocumentRelativeUrl`, `DEFAULT_OPTIONS`, `EuiMarkdownLinkValidatorOptions` (allowProtocols, allowRelative, allowDocumentRelative, baseUrl), a straight port. Default-on in the parsing plugins, as upstream. |

## Behaviour changes (deliberate, upstream-faithful)

1. **`EuiMarkdownEditor @uiPlugins` is the whole list, default `defaultUiPlugins` (the tooltip plugin).** Before, the tooltip plugin was always prepended to it, so the tooltip button could not be removed (this was the "button stays" bug). Upstream: `uiPlugins = defaultUiPlugins`. Consumers passing only custom plugins lose the tooltip button; they spread `getDefaultEuiMarkdownUiPlugins()` first (docs demo d10 updated). The arg is no longer required. `markdownActions` is now rebuilt when the plugin list changes.
2. **The link validator is on by default.** `[x](javascript:...)`, `ftp:`, `file:` and document-relative (`[x](page)`) links in `EuiMarkdownFormat` / the editor preview now render as text (`[x](url)`, or the bare url when the text equals it), as upstream. Before, `javascript:` became a disabled link button and the others became links. Opt out with `exclude: ['linkValidator']`. No existing test changed.
3. Parsing plugin order now follows upstream's table (emoji, lineBreaks, linkValidator, checkbox, tooltip).
4. `EuiI18n`'s yielded `<Text />` without a block renders the text (it rendered nothing).

## Not done / found

- `processingConfig.linkProps` and `markdownFormatProps` (markdown): not ported (already noted in markdown-handoff.md).
- Upstream's `remark-parse-no-trim` and the intraword-underscore plugin (`foo__bar__baz` stays plain) are not in our parsing list (we use `remark-parse`). Not in the prompt; left as a row in docs-audit-gaps.md.
- `EuiSearchBar` `@box` still accepts only the options listed in `EuiSearchBoxOptions` (not every `EuiFieldSearchProps`).
- Shared files touched outside my families: `eui-super-select.gts` (the two private args above), `-private/search-bar.ts` (`view` type).

## Tests

- New `tests/integration/components/eui-text-gaps-test.gts` (module `Integration | Text gaps`): 17 tests (palette blocks; i18n tokens, component values, no-block Text; search box prepend/append/callbacks, hint with `onFocus`, component `view`; editor `toolbarProps`, tooltip button default/excluded/reactive; exclude lengths; format exclusions, validator, `parsingConfig`; validator utils).
- `eui-call-out-test.gts`: +1 (popoverProps primary/secondary).
- No existing assertion changed.
- Filtered runs: `Text gaps` 17/17, `i18n` 10/10 during work. Full suite: 1783 tests, 1782 passed, the 1 failure (my own callout popover test, a portal query) fixed and the callout module rerun 7/7.
- `eui-upstream-parity` 356/356, `generate-eui-styles --check` clean, `ember-tsc --noEmit` and eslint clean, `generate-api-docs` regenerated (palette picker, markdown editor, i18n pages), rollup run (package.json unchanged).

## Docs

New demos: callout `d09-action-popover`, palette picker `d03-prepend-append`, search bar `d07-box-prepend-append`, markdown `d11-toolbar-customization` and `d12-configuring-default-plugins`. Updated: callout d06, markdown d06 (the upstream five-switch exclude example) and d10, base-editor.md, i18n d04 (multi-token), d06 (the EuiContext decision), d07 (component values), search bar d04 (`view` as `EuiHealth`, as upstream) and index. The gjs blocks were only syntax-checked (content-tag), not run: no site build per the brief.
