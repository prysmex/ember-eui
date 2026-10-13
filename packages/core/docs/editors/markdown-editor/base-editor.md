---
title: Base editor
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Base editor"/>
<EuiSpacer @size="l" />

<EuiText>

**EuiMarkdownEditor** provides a markdown authoring experience for the user. The component consists of a toolbar, text area, and a drag-and-drop zone to accept files (if configured to do so). There are two modes: a textarea that keeps track of cursor position, and a rendered preview mode that is powered by `EuiMarkdownFormat`. State is maintained between the two and it is possible to pass changes from the preview area to the textarea and vice versa.

```hbs
<EuiMarkdownEditor
  @value={{this.markdown}}
  @onChange={{this.updateMarkdown}}
  @height={{300}}
  @ariaLabel="Description"
/>

<EuiMarkdownFormat @value={{this.markdown}} />
```

`@onChange` receives the new markdown string. Both components support
GitHub-style markdown plus emoji (`:tada:`), task lists (`- [ ] todo`,
clickable in the preview) and tooltips (`!{tooltip[text](tooltip)}`).

The Ember EUI docs for the editor, `EuiMarkdownFormat` and the plugins
live on this page: the examples follow upstream's Editor, Format and
Plugins pages, followed by Ember EUI extras.

### Plugins

**EuiMarkdownEditor** and **EuiMarkdownFormat** use the same plugin
architecture to transform string based syntax into components. Unified JS
and Remark provide the markdown components, separated into a **parsing**
and a **processing** layer, and you provide **UI** to the editor to handle
interactions. In addition to running the full pipeline, the editor uses
just the parsing configuration to determine the input's validity, provide
messages back to the application and allow the toolbar buttons to interact
with existing markdown tags.

| Kind | Arg | Does |
| --- | --- | --- |
| UI plugins | `@uiPlugins` | Add toolbar buttons that insert or wrap markdown. |
| Parsing plugins | `@parsingPluginList` | [remark](https://github.com/remarkjs/remark) plugins that understand new syntax. |
| Processing plugins | `@processingPluginList` | Plugins that turn the parsed tree into the rendered output, e.g. adding attributes. |

The defaults are remark-parse, code block pre-processing, emoji, line
breaks, task list checkboxes and tooltips for parsing; remark-rehype and
the component renderer for processing; and the tooltip button for the UI.
Start from the defaults and add yours:

```js
import {
  getDefaultEuiMarkdownParsingPlugins,
  getDefaultEuiMarkdownProcessingPlugins,
} from '@ember-eui/core/utils/markdown/plugins/markdown-default-plugins/index';

const parsingPlugins = [...getDefaultEuiMarkdownParsingPlugins(), [myRemarkPlugin, {}]];
const processingPlugins = [...getDefaultEuiMarkdownProcessingPlugins(), [myProcessingPlugin, {}]];
```

Pass the same lists to `EuiMarkdownFormat` where you render the result.
`getDefaultEuiMarkdownPlugins({ exclude: ['tooltip'] })` returns all three
lists at once with a default plugin unregistered.



<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiMarkdownEditor

A markdown textarea with a formatting toolbar, a preview, file drop and
extensible syntax (plugins). Attributes go to the `<textarea>`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@initialViewMode` | `string` | `'editing'` | Starts in `'editing'` (textarea) or `'viewing'` (preview) mode. |
| `@editorId` | `string` | a generated id | Id of the editor. |
| `@uiPlugins` (required) | `EuiMarkdownEditorUiPlugin[]` |  | Toolbar plugins added after the built-in ones (bold, lists, …), e.g. a button inserting a chart. See the markdown editor docs page. |
| `@parsingPluginList` |  | `getDefaultEuiMarkdownParsingPlugins()`; extend that list to add syntax | remark plugins parsing the markdown. |
| `@processingPluginList` |  | `getDefaultEuiMarkdownProcessingPlugins()`; extend it to render custom nodes with your components | Plugins turning the parsed markdown into the preview. |
| `@value` (required) | `string` |  | The markdown text. Update it in `@onChange`. |
| `@onChange` (required) | `(str: string) => void` |  | Called with the new markdown text on every change. |
| `@onParse` |  |  | Called after each parse with the error (or `null`) and `{ messages, ast }`, e.g. to show plugin validation messages. |
| `@height` | `number \| string` | `250` | Height of the editor in px, or `'full'` to fill its container. |
| `@maxHeight` | `number \| string` | `500` | Maximum height in px when the textarea grows. |
| `@autoExpandPreview` | `boolean` | `true` | Grows the preview to fit its content. |
| `@disabled` | `boolean` |  | Disables the textarea. |
| `@isInvalid` | `boolean` |  | Marks the textarea invalid: native validity, `aria-invalid` and the danger state styling. |
| `@readOnly` | `boolean` |  | Read-only: the textarea is `readonly`, toolbar/footer buttons are disabled, file drops are ignored and preview checkboxes do not toggle. |
| `@errors` | `EuiMarkdownParseError[]` |  | Errors listed in the footer's error popover (e.g. from `@onParse` messages). Any error also gives the textarea the danger state. |
| `@dropHandlers` | `EuiMarkdownDropHandler[]` | none | Handlers turning dropped or picked files into markdown: `{ supportedFiles, accepts(type), getFormattingForItem(file) }`. Any handler adds the footer's upload button. |
| `@showFooter` | `boolean` | `true` | Renders the footer (upload, errors and syntax help). |
| `@ariaLabel` | `string` |  | Accessible label of the textarea. |
| `@ariaLabelledBy` | `string` |  | Id of the element labelling the textarea (e.g. a form row label). |
| `@ariaDescribedBy` | `string` |  | Id of the element describing the textarea. |
| `@formatRootClasses` |  |  | `@rootClasses` of the preview's EuiMarkdownFormat. |
| `@formatTextSize` |  |  | `@textSize` of the preview's EuiMarkdownFormat. |
| `@formatColor` |  |  | `@color` of the preview's EuiMarkdownFormat. |
| `@formatShouldIncludeDefaultRootClasses` |  |  | `@shouldIncludeDefaultRootClasses` of the preview's EuiMarkdownFormat. |

### EuiMarkdownFormat

Renders markdown as EUI-styled content (headings, lists, code blocks,
tables, checkboxes, tooltips and emoji):
`<EuiMarkdownFormat @value={{this.markdown}} />`. Attributes go to the
root `<div class="euiMarkdownFormat">`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@parsingPluginList` |  | `getDefaultEuiMarkdownParsingPlugins()` | remark parsing plugins. |
| `@processingPluginList` |  | `getDefaultEuiMarkdownProcessingPlugins()` | Processing plugins. |
| `@replaceNode` | `Replacer` |  | Called when rendered content edits the markdown, e.g. clicking a task list checkbox (`- [ ] todo`), with the node's position in the source and its new text. Splice it into your value to make checkboxes interactive; EuiMarkdownEditor does this for you. |
| `@readOnly` | `boolean` |  | Renders interactive plugin content (task list checkboxes) read-only. |
| `@value` (required) | `string` |  | The markdown to render. |
| `@rootClasses` | `string \| string[]` |  | Extra class(es) for the root element: a string or an array of strings. |
| `@textSize` |  | `'m'` | Text size, any `EuiText` size; `'relative'` scales with the parent's font size. |
| `@color` | `EuiTextColorValue` | `'default'` | Any EuiText color: a named color (`'subdued'`, `'danger'`…) or a CSS color. Also tints blockquote, rule and table borders. |
| `@shouldIncludeDefaultRootClasses` | `boolean` | `true`; `false` keeps only the markdown-specific styles | Applies EuiText typography (and the `euiText` class) to the content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
