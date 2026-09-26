---
title: Comment List
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Comment List"/>
<EuiSpacer/>
<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiCommentList

Stacks EuiComments along a shared timeline.

| Block | Description |
| --- | --- |
| default block | The `EuiComment`s. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiComment

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@type` |  | `'regular'` | `'regular'` for a comment with a body in a panel, `'update'` for a compact one-line event (e.g. "added a tag"). |
| `@timelineIcon` |  | a user icon (`'dot'` for updates) | Icon on the timeline, e.g. an `EuiAvatar` alternative. Use the `<:timelineIcon>` block for custom content such as `<EuiAvatar>`. |

| Block | Description |
| --- | --- |
| `<:timelineIcon>` | Custom timeline content, e.g. `<EuiAvatar @name="Jane" />`. |
| `<:username>` | Who wrote it. |
| `<:event>` | What happened, e.g. "added a comment" or "closed the issue". |
| `<:timestamp>` | When, e.g. "on Jan 1st, 2024"; wrapped in `<time>`. |
| `<:actions>` | Actions on the right of the header, e.g. an `EuiButtonIcon`. |
| `<:body>` | The comment's content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
