---
title: Suggest
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Suggest"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiSuggest` is a text field that suggests values while you type, like a
query bar suggesting fields, values and saved queries. You filter the
`@suggestions` from the text (`@onInputChange`) and handle the chosen one
(`@onItemClick`).

```hbs
<EuiSuggest
  @suggestions={{this.suggestions}}
  @onInputChange={{this.filter}}
  @onItemClick={{this.choose}}
  aria-label="Query"
/>
```

A suggestion is `{ type: { iconType, color }, label, description }`; the
color is `'tint0'` to `'tint10'`. `@status` shows whether the query is
`'saved'`, `'unsaved'` or `'loading'`. `EuiSuggestItem` renders one
suggestion on its own.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiSuggest

A text field that suggests values as you type (fields, saved queries,
recent searches), with an optional save status. You filter the
suggestions from the typed text (`@onInputChange`) and handle the
chosen one (`@onItemClick`).

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@suggestions` (required) | `EuiSuggestion[]` |  | The suggestions to show. |
| `@onItemClick` | `(item: EuiSuggestion) => void` |  | Called with the clicked suggestion. |
| `@onInputChange` | `(value: string) => void` |  | Called with the field's text on every change. |
| `@status` | `EuiSuggestStatus` | `'unchanged'` | `'unsaved'`, `'saved'`, `'loading'` or `'unchanged'`. |
| `@tooltipContent` | `string` |  | Tooltip of the status icon. |
| `@placeholder` | `string` |  | Placeholder of the field. |

| Block | Description |
| --- | --- |
| `<:append>` | Content after the field, e.g. a button. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<input>`.

### EuiSuggestItem

One suggestion of an `EuiSuggest`: a colored type icon, a label and an
optional description. With `@onClick` it is a button.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@type` (required) | `EuiSuggestItemType` |  | The suggestion's type: its icon and color. |
| `@label` (required) | `string` |  | The suggestion. |
| `@description` | `string` |  | More about it, after the label. |
| `@labelDisplay` | `'fixed' \| 'expand'` | `'fixed'` (`'expand'` without a description) | `'fixed'` keeps the label at `@labelWidth`; `'expand'` lets it take the space it needs. |
| `@labelWidth` |  | `'50'` | Width of the label in percent, `'20'` to `'90'` by tens. |
| `@descriptionDisplay` | `'truncate' \| 'wrap'` | `'truncate'` | `'truncate'` or `'wrap'` a long description. |
| `@onClick` | `(event: MouseEvent) => void` |  | Makes it a button. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>` / `<div>`.

### EuiSuggestInput

The text field of an `EuiSuggest`, opening a popover with the
suggestions while it has text. Usually rendered for you by `EuiSuggest`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@hasSuggestions` (required) | `boolean` |  | Whether there are suggestions to show (the popover opens only then). |
| `@status` | `EuiSuggestStatus` | `'unchanged'` | `'unsaved'` (dot), `'saved'` (check), `'loading'` (spinner) or `'unchanged'` (nothing). |
| `@tooltipContent` | `string` |  | Tooltip of the status icon, instead of "Saved." / "Changes have not been saved.". |
| `@sendValue` | `(value: string) => void` |  | Called with the field's text on every change. |
| `@placeholder` | `string` |  | Placeholder of the field. |

| Block | Description |
| --- | --- |
| default block | The suggestions, shown in the popover. |
| `<:append>` | Content after the field (and the status icon). |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<input>`.

</EuiText>
<!-- api:end -->
