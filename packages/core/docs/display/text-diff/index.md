---
title: Text diff
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Text diff"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiTextDiff` shows what changed between two versions of a text, inline:
removed text in `<del>` (struck through), added text in `<ins>`
(underlined). Use it for edit history, reviewing changes before saving, or
comparing a document's versions.

```hbs
<EuiTextDiff @beforeText={{this.saved}} @afterText={{this.draft}} />
```

By default it compares whole words, which reads best for prose;
`@granularity="characters"` shows changes inside words (typos, ids).
It finds the smallest set of changes, so it suits paragraphs rather than
very long documents.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiTextDiff

Shows the changes between two texts inline: removed text in `<del>`,
added text in `<ins>`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@beforeText` (required) | `string` |  | The original text. |
| `@afterText` (required) | `string` |  | The changed text. |
| `@granularity` | `'words' \| 'characters'` | `'words'` | Compare whole `'words'` (easier to read) or single `'characters'`. |

| Block | Description |
| --- | --- |
| default block | Renders the diff yourself: yields its chunks, `[operation, text]` pairs where the operation is `-1` (removed), `1` (added) or `0`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>`.

</EuiText>
<!-- api:end -->
