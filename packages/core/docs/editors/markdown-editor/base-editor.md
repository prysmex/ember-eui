---
title: Base editor
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Base editor"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiMarkdownEditor` is a markdown textarea with a formatting toolbar, a
preview tab and interactive task lists; `EuiMarkdownFormat` renders
markdown with EUI's styles (use it to show saved markdown).

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

### Plugins

The editor and the renderer share a pipeline you can extend:

| Kind | Arg | Does |
| --- | --- | --- |
| UI plugins | `@uiPlugins` | Add toolbar buttons that insert or wrap markdown. |
| Parsing plugins | `@parsingPluginList` | [remark](https://github.com/remarkjs/remark) plugins that understand new syntax. |
| Processing plugins | `@processingPluginList` | Plugins that turn the parsed tree into the rendered output, e.g. adding attributes. |

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

</EuiText>

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
| `@isInvalid` | `boolean` |  | Marks the textarea invalid for native form validation. |
| `@ariaLabel` | `string` |  | Accessible label of the textarea. |
| `@ariaLabelledBy` | `string` |  | Id of the element labelling the textarea (e.g. a form row label). |
| `@ariaDescribedBy` | `string` |  | Id of the element describing the textarea. |
| `@formatRootClasses` |  |  | `@rootClasses` of the preview's EuiMarkdownFormat. |
| `@formatTextSize` |  |  | `@textSize` of the preview's EuiMarkdownFormat. |
| `@formatShouldIncludeDefaultRootClasses` |  |  | `@shouldIncludeDefaultRootClasses` of the preview's EuiMarkdownFormat. |

### EuiMarkdownFormat

Renders markdown as EUI-styled content (headings, lists, code blocks,
tables, checkboxes, tooltips and emoji):
`<EuiMarkdownFormat @value={{this.markdown}} />`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@parsingPluginList` |  | `getDefaultEuiMarkdownParsingPlugins()` | remark parsing plugins. |
| `@processingPluginList` |  | `getDefaultEuiMarkdownProcessingPlugins()` | Processing plugins. |
| `@replaceNode` | `Replacer` |  | Called when rendered content edits the markdown, e.g. clicking a task list checkbox (`- [ ] todo`), with the node's position in the source and its new text. Splice it into your value to make checkboxes interactive; EuiMarkdownEditor does this for you. |
| `@value` (required) | `string` |  | The markdown to render. |
| `@rootClasses` | `string \| string[]` |  | Extra class(es) for the root element: a string or an array of strings. |
| `@textSize` |  | `'m'` | Text size, any `EuiText` size. |
| `@shouldIncludeDefaultRootClasses` | `boolean` | `true` | Keeps the default `euiMarkdownFormat` classes. |

</EuiText>
<!-- api:end -->
