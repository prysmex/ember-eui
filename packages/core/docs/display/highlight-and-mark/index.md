---
title: Highlight and mark
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Highlight and mark"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiHighlight` renders a string with the parts that match a search
highlighted, e.g. in search results or a filtered list. `EuiMark` is the
highlight itself, a styled `<mark>`, for marking text you already split.

```hbs
<EuiHighlight @text={{item.name}} @search={{this.query}} />
<EuiMark>highlighted</EuiMark>
```

By default only the first match is highlighted and case is ignored:
`@highlightAll` marks every match, `@strict` matches case exactly. The
search is plain text, not a regular expression.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiHighlight

Renders a string with the parts matching `@search` highlighted, e.g.
search results or the options of a filtered list.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@text` (required) | `string` |  | The text to show. |
| `@search` | `string` |  | What to highlight in it. Nothing is highlighted when empty. |
| `@strict` | `boolean` |  | Match case exactly (by default "app" also matches "Apple"). |
| `@highlightAll` | `boolean` |  | Highlight every match instead of only the first one. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>`.

### EuiMark

Highlights text with a `<mark>`, e.g. the part of a result that matches
a search. To highlight the matches in a string, use `EuiHighlight`.

| Block | Description |
| --- | --- |
| default block | The highlighted text. |

</EuiText>
<!-- api:end -->
