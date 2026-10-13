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
very long documents. `@timeout` bounds how many seconds the comparison may take
(default `0.1`; past it the part that differs is shown as one removal and one
insertion; `0` waits for the full diff). The component renders the changes inline (the
equivalent of upstream's `useEuiTextDiff` hook); its block yields the
changes for custom rendering.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiTextDiff

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@tag` (required) |  |  |  |

</EuiText>
<!-- api:end -->
